"""Audit scene declarations in the exact 23A355 cache; never execute iOS code."""
import argparse
import json
from pathlib import Path
import re
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--ipsw-tool', required=True)
parser.add_argument('--cache', required=True)
parser.add_argument('--output', required=True)
args = parser.parse_args()
output = Path(args.output)
output.mkdir(parents=True, exist_ok=True)
expected = {
    'FrontBoard': 'ED43ADA7-7107-3242-928F-09708F2FD9F3',
    'UIKitCore': 'C98EAB32-B273-3430-B0C5-46522C904CBB',
}
targets = {
    'FBSceneManager', 'FBSceneWorkspace', 'FBScene', 'FBSceneClientHandle',
    'UIScenePresentationManager', '_UIScenePresenter',
    '_UISceneLayerHostContainerView',
}
records = []
for library, uuid in expected.items():
    destination = output / f'{library}-declarations.txt'
    with destination.open('w') as stream:
        subprocess.run([
            args.ipsw_tool, '--verbose', 'dyld', 'macho', args.cache,
            f'/System/Library/PrivateFrameworks/{library}.framework/{library}',
            '--objc', '--loads',
        ], stdout=stream, check=True, timeout=120)
    dump = destination.read_text()
    match = re.search(r'LC_UUID\s+([0-9A-Fa-f-]{36})', dump)
    if not match or match[1].upper() != uuid:
        raise SystemExit(f'{library}: unexpected UUID; this audit requires 23A355')
    owner, address = None, None
    for line in dump.splitlines():
        declaration = re.match(r'@interface\s+(\w+)', line)
        if declaration:
            owner, address = declaration[1], None
        elif line.startswith('@end'):
            owner, address = None, None
        elif re.fullmatch(r'// 0x[0-9a-fA-F]+', line):
            address = line[3:]
        elif re.match(r'[-+] \(', line):
            if owner in targets or (owner == 'NSObject' and 'uiPresentationManager' in line):
                records.append({'library': library, 'class_in_dump': owner,
                                'address': address, 'declaration': line,
                                'runtime_validated': False})
            address = None

report = {
    'build': '23A355', 'library_uuids': expected,
    'runtime_validated': False, 'hosting_implemented': False,
    'limitations': [
        'Declarations do not establish scene ownership, input routing or safe activation.',
        'Block callback types are erased; inspect the implementation separately.',
        'A category receiver in the dump does not prove a valid concrete receiver.',
    ],
    'methods': records,
}
(output / 'scene-contracts.json').write_text(json.dumps(report, indent=2) + '\n')
print(f'Audited {len(records)} declarations; exact library UUIDs matched. No iOS code executed.')
