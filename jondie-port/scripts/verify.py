#!/usr/bin/env python3
"""Inspect source/package contracts, including unmodified modern arm64e ABI."""
import hashlib
import json
import pathlib
import plistlib
import struct
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
PACKAGE = 'com.johndie.pulloverpro-rootless'
VERSION = '3.0.2~rc1'
PREFIX = pathlib.Path('var/jb')


def require(condition, message):
    if not condition:
        raise AssertionError(message)


def plist(path):
    with path.open('rb') as stream:
        return plistlib.load(stream)


def source_checks():
    for path in ROOT.rglob('*.plist'):
        if any(part in ('.theos', 'diagnostics') for part in path.parts):
            continue
        plist(path)
    expected_filter = {'Filter': {'Bundles': ['com.apple.springboard']}}
    require(plist(ROOT / 'Tweak/PullOverPro.plist') == expected_filter, 'SpringBoard-only injection filter changed')
    require((ROOT / 'LICENSE').read_text().startswith('                    GNU GENERAL PUBLIC LICENSE'), 'GPL licence missing')
    require('076da8f07e707453bc58ed9baadeefb40f0e93e4' in (ROOT / 'PROVENANCE.md').read_text(), 'Pinned upstream provenance missing')
    for path in (ROOT / 'layout').rglob('*'):
        require(path.name not in ('preinst', 'postinst', 'prerm', 'postrm', 'extrainst_'), 'Unexpected maintainer script')
    control = (ROOT / 'control').read_text()
    require(f'Package: {PACKAGE}\n' in control, 'Wrong package identity')
    require(f'Version: {VERSION}\n' in control, 'Wrong candidate version')
    require('Conflicts: com.renatasy83.pulloverpro.diagnostic\n' in control, 'Dual-injection conflict missing')
    require('com.opa334.altlist' in control, 'AltList runtime dependency missing')
    makefile = (ROOT / 'Makefile').read_text()
    require('THEOS_PACKAGE_SCHEME = rootless' in makefile, 'Not configured rootless')
    require('ARCHS = arm64 arm64e' in makefile, 'Required architecture missing')
    print('Source contracts: plist schemas, filter, GPL/provenance, package identity and rootless build passed')


def inspect_macho(path):
    raw = path.read_bytes()
    require(len(raw) >= 8, f'Truncated Mach-O: {path}')
    magic = raw[:4]
    slices = []
    if magic in (b'\xca\xfe\xba\xbe', b'\xca\xfe\xba\xbf'):
        count = struct.unpack_from('>I', raw, 4)[0]
        require(0 < count <= 8, 'Invalid FAT slice count')
        fat64 = magic == b'\xca\xfe\xba\xbf'
        entry_size = 32 if fat64 else 20
        require(8 + count * entry_size <= len(raw), 'Truncated FAT entries')
        ranges = []
        for index in range(count):
            entry = 8 + index * entry_size
            cpu, subtype = struct.unpack_from('>II', raw, entry)
            offset, size = struct.unpack_from('>QQ' if fat64 else '>II', raw, entry + 8)
            require(size >= 32 and offset >= 8 + count * entry_size and offset + size <= len(raw), 'Invalid FAT slice bounds')
            require(all(offset >= end or offset + size <= start for start, end in ranges), 'Overlapping FAT slices')
            ranges.append((offset, offset + size))
            slices.append((cpu, subtype, raw[offset:offset + size]))
    else:
        require(magic == b'\xcf\xfa\xed\xfe', 'Expected little-endian 64-bit Mach-O')
        cpu, subtype = struct.unpack_from('<II', raw, 4)
        slices.append((cpu, subtype, raw))
    seen = set()
    for fat_cpu, fat_subtype, image in slices:
        require(image[:4] == b'\xcf\xfa\xed\xfe', 'Unexpected slice Mach-O format')
        cpu, subtype, filetype, ncmds, sizeofcmds = struct.unpack_from('<IIIII', image, 4)
        require((cpu, subtype) == (fat_cpu, fat_subtype), 'FAT/header architecture mismatch')
        require(filetype in (6, 8), 'Expected dylib or bundle')
        require(cpu == 0x0100000c, 'Unexpected CPU')
        require(subtype in (0, 0x80000002), f'Unsupported ARM ABI subtype {subtype:#x}; never patch/relabel the header')
        require(subtype not in seen, 'Duplicate architecture')
        seen.add(subtype)
        require(0 < ncmds < 1000 and 32 + sizeofcmds <= len(image), 'Invalid load commands')
        offset = 32
        signed = False
        for _ in range(ncmds):
            require(offset + 8 <= 32 + sizeofcmds, 'Truncated load command')
            cmd, size = struct.unpack_from('<II', image, offset)
            require(size >= 8 and offset + size <= 32 + sizeofcmds, 'Invalid load command bounds')
            if cmd == 0x1d:
                require(size >= 16, 'Truncated code signature command')
                dataoff, datasize = struct.unpack_from('<II', image, offset + 8)
                require(datasize > 20 and dataoff + datasize <= len(image), 'Invalid code signature bounds')
                require(image[dataoff:dataoff + 4] == b'\xfa\xde\x0c\xc0', 'Invalid signature superblob')
                signed = True
            offset += size
        require(offset == 32 + sizeofcmds, 'Load command size mismatch')
        require(signed, 'Unsigned Mach-O slice')
    require(seen == {0, 0x80000002}, 'Both arm64 and modern arm64e must be present')
    return {'binary': path.name, 'slices': ['arm64', 'arm64e ABI v2'], 'codeSignaturePresent': True}


def package_checks(deb):
    deb = deb.resolve()
    expected = {'Package': PACKAGE, 'Version': VERSION, 'Architecture': 'iphoneos-arm64'}
    for field, value in expected.items():
        actual = subprocess.check_output(['dpkg-deb', '-f', str(deb), field], text=True).strip()
        require(actual == value, f'{field}: {actual!r}, expected {value!r}')
    with tempfile.TemporaryDirectory(prefix='pullover-inspect-') as directory:
        base = pathlib.Path(directory)
        payload, control = base / 'payload', base / 'control'
        subprocess.run(['dpkg-deb', '-x', str(deb), str(payload)], check=True)
        subprocess.run(['dpkg-deb', '-e', str(deb), str(control)], check=True)
        for name in ('preinst', 'postinst', 'prerm', 'postrm', 'extrainst_'):
            require(not (control / name).exists(), f'Unexpected maintainer action: {name}')
        files = [path for path in payload.rglob('*') if path.is_file() or path.is_symlink()]
        require(files, 'Empty package')
        for path in files:
            relative = path.relative_to(payload)
            require(relative.is_relative_to(PREFIX), f'Non-rootless payload: {relative}')
            require(relative.parts[:4] != ('var', 'jb', 'var', 'jb'), f'Doubled rootless prefix: {relative}')
            require(not path.is_symlink(), f'Unexpected symlink in candidate payload: {relative}')
            require('PullOverProDiagnostic' not in path.name and 'ppo-bridge' not in path.name, 'Old diagnostic payload included')
        dylib = payload / PREFIX / 'Library/MobileSubstrate/DynamicLibraries/PullOverPro.dylib'
        prefs = payload / PREFIX / 'Library/PreferenceBundles/PullOverProPrefs.bundle'
        filter_path = dylib.with_suffix('.plist')
        require(plist(filter_path) == {'Filter': {'Bundles': ['com.apple.springboard']}}, 'Package injection filter differs')
        info = plist(prefs / 'Info.plist')
        require(info['NSPrincipalClass'] == 'POPRootListController' and info['CFBundleExecutable'] == 'PullOverProPrefs', 'Preference bundle metadata invalid')
        require(plist(prefs / 'Root.plist'), 'Settings resource missing')
        loader = plist(payload / PREFIX / 'Library/PreferenceLoader/Preferences/PullOverPro.plist')
        require(loader['entry']['bundle'] == 'PullOverProPrefs', 'PreferenceLoader target invalid')
        doc = payload / PREFIX / 'usr/share/doc' / PACKAGE
        require((doc / 'LICENSE').read_bytes() == (ROOT / 'LICENSE').read_bytes(), 'Installed GPL licence differs')
        require((doc / 'PROVENANCE.md').read_bytes() == (ROOT / 'PROVENANCE.md').read_bytes(), 'Installed provenance differs')
        binaries = [inspect_macho(dylib), inspect_macho(prefs / 'PullOverProPrefs')]
    result = {'package': deb.name, 'bytes': deb.stat().st_size, 'sha256': hashlib.sha256(deb.read_bytes()).hexdigest(),
              'rootless': True, 'maintainerScripts': [], 'binaries': binaries,
              'deviceRuntimeTested': False, 'dopamineEllekitCompatibilityConfirmed': False}
    print(json.dumps(result, indent=2))
    return result


if __name__ == '__main__':
    source_checks()
    for argument in sys.argv[1:]:
        result = package_checks(pathlib.Path(argument))
        output = ROOT / 'diagnostics/PACKAGE_VALIDATION.json'
        output.parent.mkdir(exist_ok=True)
        output.write_text(json.dumps(result, indent=2) + '\n')
