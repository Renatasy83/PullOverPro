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


HASHES = {1: ('sha1', 20), 2: ('sha256', 32), 3: ('sha256', 20), 4: ('sha384', 48)}
CD_MAGIC = 0xfade0c02
BLOB_MAGICS = {2: 0xfade0c01, 5: 0xfade7171, 7: 0xfade7172, 0x10000: 0xfade0b01}


def digest_bytes(raw, hash_type):
    name, size = HASHES[hash_type]
    return hashlib.new(name, raw).digest()[:size]


def cstring_end(blob, offset, lower_bound, upper_bound, label):
    require(lower_bound <= offset < upper_bound, f'Invalid {label} offset')
    end = blob.find(b'\0', offset, upper_bound)
    require(end > offset, f'Invalid/empty {label}')
    return end + 1


def inspect_embedded_signature(image, dataoff, datasize, external_slots=None):
    """Verify embedded page/special-slot digests, not Apple identity or device trust."""
    external_slots = external_slots or {}
    require(0 < dataoff and 12 <= datasize and dataoff + datasize <= len(image), 'Invalid signature extent')
    signature = image[dataoff:dataoff + datasize]
    magic, length, count = struct.unpack_from('>III', signature)
    require(magic == 0xfade0cc0, 'Invalid signature superblob')
    require(12 <= length <= datasize and 0 < count <= 16 and 12 + count * 8 <= length, 'Invalid superblob index')
    require(not any(signature[length:]), 'Nonzero data after signature superblob')
    blobs = {}
    extents = []
    for index in range(count):
        slot, offset = struct.unpack_from('>II', signature, 12 + index * 8)
        require(slot not in blobs, 'Duplicate signature slot')
        require(12 + count * 8 <= offset and offset + 8 <= length, 'Invalid signature blob offset')
        blob_magic, blob_length = struct.unpack_from('>II', signature, offset)
        require(blob_length >= 8 and offset + blob_length <= length, 'Invalid signature blob length')
        require(all(offset >= end or offset + blob_length <= start for start, end in extents), 'Overlapping signature blobs')
        extents.append((offset, offset + blob_length))
        if slot == 0 or 0x1000 <= slot < 0x1005:
            require(blob_magic == CD_MAGIC, 'CodeDirectory slot has wrong magic')
        else:
            require(slot in BLOB_MAGICS and blob_magic == BLOB_MAGICS[slot], 'Unsupported signature blob type')
        blobs[slot] = signature[offset:offset + blob_length]
    require(0 in blobs, 'Primary CodeDirectory is missing')
    # Padding is not authenticated by a CodeDirectory; accept only zero padding.
    cursor = 12 + count * 8
    for start, end in sorted(extents):
        require(not any(signature[cursor:start]), 'Nonzero unindexed signature data')
        cursor = end
    require(not any(signature[cursor:length]), 'Nonzero trailing signature data')
    directories = []
    for slot, cd in sorted(blobs.items()):
        if slot != 0 and not 0x1000 <= slot < 0x1005:
            continue
        require(len(cd) >= 44, 'Truncated CodeDirectory')
        _, cd_length, version, flags, hash_offset, identifier_offset, n_special, n_code, code_limit = struct.unpack_from('>9I', cd)
        hash_size, hash_type, platform, page_shift = struct.unpack_from('>4B', cd, 36)
        require(0x20001 <= version <= 0x20600, 'Unsupported CodeDirectory version')
        header_size = 44
        for threshold, size in ((0x20100, 48), (0x20200, 52), (0x20300, 64), (0x20400, 88), (0x20500, 96), (0x20600, 108)):
            if version >= threshold:
                header_size = size
        require(cd_length == len(cd) and len(cd) >= header_size, 'Truncated versioned CodeDirectory')
        require(struct.unpack_from('>I', cd, 40)[0] == 0, 'Nonzero CodeDirectory reserved field')
        if version >= 0x20100:
            require(struct.unpack_from('>I', cd, 44)[0] == 0, 'Scatter signing is unsupported')
        team_offset = struct.unpack_from('>I', cd, 48)[0] if version >= 0x20200 else 0
        if version >= 0x20300:
            require(struct.unpack_from('>I', cd, 52)[0] == 0, 'Nonzero CodeDirectory reserved field')
            wide_limit = struct.unpack_from('>Q', cd, 56)[0]
            if wide_limit:
                code_limit = wide_limit
        if version >= 0x20500:
            require(struct.unpack_from('>I', cd, 92)[0] == 0, 'Pre-encrypt hash table is unsupported')
        if version >= 0x20600:
            require(not any(cd[96:108]), 'Linkage signing is unsupported')
        require(hash_type in HASHES and hash_size == HASHES[hash_type][1], 'Unsupported CodeDirectory hash type/size')
        require(n_special <= 7 and 0 < n_code, 'Invalid CodeDirectory slot counts')
        require(page_shift <= 30, 'Invalid CodeDirectory page size')
        require(code_limit == dataoff, 'CodeDirectory must cover every byte before the signature')
        page_bytes = (1 << page_shift) if page_shift else code_limit
        require(n_code == (code_limit + page_bytes - 1) // page_bytes, 'CodeDirectory page count mismatch')
        special_start = hash_offset - n_special * hash_size
        require(header_size <= special_start <= hash_offset and hash_offset + n_code * hash_size <= len(cd), 'CodeDirectory hash table outside blob')
        cstring_end(cd, identifier_offset, header_size, special_start, 'signing identifier')
        if team_offset:
            cstring_end(cd, team_offset, header_size, special_start, 'team identifier')
        for page in range(n_code):
            start = page * page_bytes
            digest = digest_bytes(image[start:min(start + page_bytes, code_limit)], hash_type)
            require(cd[hash_offset + page * hash_size:hash_offset + (page + 1) * hash_size] == digest, f'Code page hash mismatch (slot {slot:#x}, page {page})')
        verified_special = []
        for special in range(1, n_special + 1):
            actual = cd[hash_offset - special * hash_size:hash_offset - (special - 1) * hash_size]
            content = blobs.get(special, external_slots.get(special))
            if not any(actual):
                require(special not in blobs, f'Embedded special slot {special} has no digest')
            else:
                require(content is not None, f'Unvalidated nonzero special slot {special}')
                require(actual == digest_bytes(content, hash_type), f'Special slot {special} hash mismatch')
                verified_special.append(special)
        for special in (2, 5, 7):
            require(special not in blobs or special <= n_special, f'Embedded special slot {special} is not covered')
        directories.append({'slot': slot, 'version': hex(version), 'flags': hex(flags),
                            'hashType': hash_type, 'hash': HASHES[hash_type][0] + ('-truncated20' if hash_type == 3 else ''),
                            'pagesVerified': n_code, 'pageBytes': page_bytes, 'codeLimit': code_limit,
                            'specialSlotsVerified': verified_special, 'platform': platform})
    require(any(cd['hashType'] in (2, 4) for cd in directories), 'A full SHA256 or SHA384 CodeDirectory is required')
    return {'codeDirectories': directories, 'embeddedPageHashIntegrityVerified': True,
            'cmsPresent': 0x10000 in blobs, 'appleTrustVerified': False, 'deviceTrustVerified': False}


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
    external = {}
    if path.parent.suffix == '.bundle':
        for special, relative in ((1, 'Info.plist'), (3, '_CodeSignature/CodeResources')):
            resource = path.parent / relative
            if resource.is_file():
                external[special] = resource.read_bytes()
    seen = set()
    signatures = []
    for fat_cpu, fat_subtype, image in slices:
        require(image[:4] == b'\xcf\xfa\xed\xfe' and len(image) >= 32, 'Unexpected/truncated slice Mach-O format')
        cpu, subtype, filetype, ncmds, sizeofcmds = struct.unpack_from('<IIIII', image, 4)
        require((cpu, subtype) == (fat_cpu, fat_subtype), 'FAT/header architecture mismatch')
        require(filetype in (6, 8), 'Expected dylib or bundle')
        require(cpu == 0x0100000c, 'Unexpected CPU')
        require(subtype in (0, 0x80000002), f'Unsupported ARM ABI subtype {subtype:#x}; never patch/relabel the header')
        require(subtype not in seen, 'Duplicate architecture')
        seen.add(subtype)
        require(0 < ncmds < 1000 and 32 + sizeofcmds <= len(image), 'Invalid load commands')
        offset = 32
        signature_extent = None
        for _ in range(ncmds):
            require(offset + 8 <= 32 + sizeofcmds, 'Truncated load command')
            cmd, size = struct.unpack_from('<II', image, offset)
            require(size >= 8 and offset + size <= 32 + sizeofcmds, 'Invalid load command bounds')
            if cmd == 0x1d:
                require(signature_extent is None and size == 16, 'Invalid/duplicate code signature command')
                signature_extent = struct.unpack_from('<II', image, offset + 8)
            offset += size
        require(offset == 32 + sizeofcmds, 'Load command size mismatch')
        require(signature_extent is not None, 'Unsigned Mach-O slice')
        dataoff, datasize = signature_extent
        require(dataoff >= 32 + sizeofcmds, 'Signature overlaps Mach-O header/load commands')
        require(dataoff + datasize == len(image), 'Unvalidated trailing bytes after signature')
        signatures.append({'architecture': 'arm64e' if subtype == 0x80000002 else 'arm64',
                           **inspect_embedded_signature(image, dataoff, datasize, external)})
    require(seen == {0, 0x80000002}, 'Both arm64 and modern arm64e must be present')
    return {'binary': path.name, 'slices': ['arm64', 'arm64e ABI v2'], 'signatures': signatures,
            'embeddedPageHashIntegrityVerified': True, 'appleTrustVerified': False, 'deviceTrustVerified': False}

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
