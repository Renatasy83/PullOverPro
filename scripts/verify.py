"""Source policy and Debian payload checks; these do not prove runtime safety."""
from pathlib import Path, PurePosixPath
import io
import plistlib
import re
import subprocess
import sys
import tarfile

ROOT = Path(__file__).resolve().parents[1]


def require(condition, message):
    if not condition:
        raise SystemExit(message)


source = '\n'.join((ROOT / path).read_text() for path in ['Tweak.xm', 'PPOAppData.mm', 'PPOBridgeClient.mm', 'PPOBridgeProtocol.mm', 'PPOBridgeIO.cpp'])
for pattern in (r'%hook\b', r'%init\b', r'objc_msgSend', r'NSClassFromString',
                r'NSSelectorFromString', r'valueForKey:', r'launchApplication',
                r'method_getImplementation', r'method_invoke', r'dlopen', r'dlsym',
                r'\bsystem\s*\(', r'\bpopen\s*\(', r'\bfork\s*\(', r'\bkill\s*\(',
                r'performSelector', r'NSInvocation', r'dispatch_sync', r'dispatch_semaphore_wait', r'\bsleep\s*\('):
    require(not re.search(pattern, source), f'Unexpected runtime operation: {pattern}')
require('THEOS_PACKAGE_SCHEME := rootless' in (ROOT / 'Makefile').read_text(),
        'Rootless scheme missing')
filter_path = ROOT / 'PullOverProDiagnostic.plist'
expected_filter = '{Filter={Bundles=("com.apple.springboard");};}'
require(re.sub(r'\s+', '', filter_path.read_text()) == expected_filter,
        'Injection must target SpringBoard only')
duplicate = ROOT / 'layout/Library/MobileSubstrate/DynamicLibraries/PullOverProDiagnostic.plist'
require(not duplicate.exists(), 'Duplicate injection filter in layout')
print('Source policy OK (not a runtime test)')

for arg in sys.argv[1:]:
    deb = Path(arg)
    def field(name):
        return subprocess.check_output(['dpkg-deb', '-f', str(deb), name], text=True).strip()
    require(field('Package') == 'com.renatasy83.pulloverpro.diagnostic', 'Unexpected package')
    require(field('Architecture') == 'iphoneos-arm64', 'Unexpected architecture')
    require(field('Version').startswith('0.6.0~dev.bridge1'), 'Unexpected version')
    require('ellekit' in field('Depends'), 'ElleKit dependency missing')
    payload = subprocess.check_output(['dpkg-deb', '--fsys-tarfile', str(deb)])
    base = 'var/jb/Library/MobileSubstrate/DynamicLibraries/'
    required = {base + 'PullOverProDiagnostic.dylib', base + 'PullOverProDiagnostic.plist',
                'var/jb/usr/bin/ppo-apps', 'var/jb/usr/bin/ppo-open', 'var/jb/usr/bin/ppo-bridge',
                'var/jb/Library/LaunchDaemons/com.renatasy83.ppo.bridge.plist',
                'var/jb/usr/share/doc/com.renatasy83.pulloverpro.diagnostic/copyright'}
    found = set()
    with tarfile.open(fileobj=io.BytesIO(payload)) as archive:
        for member in archive:
            name = member.name.removeprefix('./')
            require('..' not in PurePosixPath(name).parts and not name.startswith('/'),
                    f'Unsafe archive path: {name}')
            if member.isdir():
                continue
            require(member.isfile() and name in required, f'Unexpected payload: {name}')
            require(name not in found, f'Duplicate payload: {name}')
            if name in {'var/jb/usr/bin/ppo-apps', 'var/jb/usr/bin/ppo-open', 'var/jb/usr/bin/ppo-bridge'}:
                require(member.mode & 0o111, 'Helper is not executable')
            found.add(name)
            if name.endswith('copyright'):
                require(archive.extractfile(member).read() == (ROOT / 'layout/usr/share/doc/com.renatasy83.pulloverpro.diagnostic/copyright').read_bytes(), 'License/attribution mismatch')
            if name.endswith('.dylib') or name == 'var/jb/usr/bin/ppo-bridge':
                require(b'PPO_BRIDGE_TEST_PATH' not in archive.extractfile(member).read(), 'Test path override leaked into release binary')
            if name.endswith('com.renatasy83.ppo.bridge.plist'):
                raw = archive.extractfile(member).read()
                require(plistlib.loads(raw) == plistlib.loads((ROOT / 'layout/Library/LaunchDaemons/com.renatasy83.ppo.bridge.plist').read_bytes()), 'Bridge service plist mismatch')
            elif name.endswith('.plist'):
                raw = archive.extractfile(member).read()
                if raw.startswith(b'bplist') or raw.lstrip().startswith(b'<?xml'):
                    require(plistlib.loads(raw) == {'Filter': {'Bundles': ['com.apple.springboard']}},
                            'Packaged binary/XML filter mismatch')
                else:
                    require(re.sub(r'\s+', '', raw.decode()) == expected_filter,
                            'Packaged OpenStep filter mismatch')
    require(found == required, f'Missing payload: {required - found}')
    metadata = subprocess.check_output(['dpkg-deb', '--ctrl-tarfile', str(deb)])
    control_found = set()
    with tarfile.open(fileobj=io.BytesIO(metadata)) as archive:
        for member in archive:
            if member.isdir():
                continue
            name = member.name.removeprefix('./')
            require(member.isfile() and name in {'control', 'md5sums', 'postinst', 'prerm'},
                    f'Unexpected maintainer script or metadata: {name}')
            control_found.add(name)
            if name in {'postinst', 'prerm'}:
                require(member.mode & 0o111, 'Nonexecutable service lifecycle script')
                require(archive.extractfile(member).read() == (ROOT / 'layout/DEBIAN' / name).read_bytes(), 'Service lifecycle script mismatch')
    require({'control', 'postinst', 'prerm'} <= control_found, 'Missing service lifecycle scripts')
    print(f'Rootless payload OK: {deb.name} (not a runtime test)')

