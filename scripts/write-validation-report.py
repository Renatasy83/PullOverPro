"""Summarize successful CI evidence without implying iOS runtime validation."""
from pathlib import Path
import json
import platform
import sys

directory = Path(sys.argv[1])
commit = sys.argv[2]
markers = {
    'favorite-apps-tests.log': 'Favorite apps tests passed:',
    'favorites-store-tests.log': 'Favorites store tests passed:',
    'picker-state-tests.log': 'Picker state tests passed:',
    'floating-presentation-tests.log': 'Floating presentation tests passed:',
    'floating-geometry-tests.log': 'Floating window geometry tests passed:',
    'scene-capability-tests.log': 'Scene capability tests passed:',
    'bundle-reader-tests.log': 'Bundle scene reader tests passed:',
    'owned-admission-tests.log': 'Owned admission tests passed:',
    'lock-state-tests.log': 'Screen lock state tests passed:',
    'window-lifetime-tests.log': 'Window lifetime tests passed:',
    'owned-scene-tests.log': 'Owned scene host tests passed:',
    'visibility-tests.log': 'Visibility context tests passed:',
    'layer-probe-tests.log': 'Scene layer probe tests passed:',
    'geometry-tests.log': 'Host geometry tests passed:',
    'host-slot-tests.log': 'Host session slot tests passed:',
    'presenter-tests.log': 'Scene presenter tests passed:',
    'scene-tests.log': 'Scene preflight tests passed;',
    'lifecycle-tests.log': 'Lifecycle tests passed:',
    'appdata-tests.log': 'App data tests passed',
    'launcher-tests.log': 'Launch ABI tests passed',
    'process-tests.log': 'Process tests passed',
    'bridge-io-tests.log': '365 checks passed',
    'bridge-protocol-tests.log': 'Bridge protocol tests passed',
    'bridge-service-tests.log': 'Bridge service policy tests passed',
    'bridge-integration-tests.log': 'Bridge subprocess integration:',
}
for name, marker in markers.items():
    if marker not in (directory / name).read_text():
        raise SystemExit(f'Missing successful test evidence: {name}')

not_run = [
    'iOS launchd bootstrap/removal and service permissions',
    'SpringBoard sandbox access to the file mailbox',
    'LaunchServices app launching from the new service context',
    'Application scene rendering, touch/keyboard routing and teardown',
    'Lock/unlock, orientation, process death and watchdog integration',
    'Keep mode beyond fifteen seconds and lock-transition frame exposure',
    'Favorites directory sandbox access, UIKit filter/star/long-press behavior and quick selection on iOS',
    'Dopamine and ElleKit runtime compatibility',
    'vphone-cli: no compatible physical Apple Silicon Mac is accessible',
]
report = {
    'commit': commit,
    'host': platform.platform(),
    'successful_test_logs': list(markers),
    'build': 'Theos rootless; arm64 and arm64e; SDK16.5; deployment15.0',
    'package_inspection': 'payload, lifecycle scripts, license and architecture checks passed',
    'sha256sums': (directory / 'SHA256SUMS').read_text().strip(),
    'not_executed': not_run,
    'floating_application_hosting_implemented': 'Owned scenes and selected-app manifest eligibility; public owned-window controls plus a bounded persistent favorite picker. New-version UIKit favorite interactions and store sandbox access remain unverified.',
    'prior_device_baseline': '0.14.0 Safari minimize/restore/kept/bar-X/default expiry/reuse and user-confirmed restored/underlying input;0.13.0 resize/move;0.12.0 Contacts installed-info;0.11.0 Reminders and0.10.0 Safari Keep/lock/reuse. No full-platform compatibility claim.',
    'dopamine_ellekit_compatibility_confirmed': False,
    'final_candidate': False,
    'emergency_disable': 'Policy and subprocess fixtures cover marker presence; missing/error distinctions; disable during refresh. Not device-tested.',
}
(directory / 'VALIDATION.json').write_text(json.dumps(report, indent=2) + '\n')
(directory / 'VALIDATION.md').write_text(
    '# Development validation report\n\n'
    f'Commit: `{commit}`\n\n'
    '**Not a final candidate. Dynamic candidate apps require fresh selected-app manifest inspection through the mobile service. Metadata is eligibility evidence, not authenticated permission or runtime compatibility. Baseline Safari/Reminders/Contacts observations remain version-specific. Current favorites/filter/quick-selection UI and sandboxed persistence require actual device validation. No original source scene is hosted or mutated. Full Dopamine/ElleKit compatibility remains unconfirmed.**\n\n'
    'Emergency disable is covered before workspace access, after inventory refresh and in actual subprocess exchange using an isolated marker fixture. This cannot revoke an already submitted OS request.\n\n'
    'Passed: Clang analysis, Theos build, rootless payload/architecture inspection and these automated test suites:\n\n'
    + '\n'.join(f'- `{name}`' for name in markers)
    + '\n\nNot executed by this CI run:\n\n'
    + '\n'.join(f'- {name}' for name in not_run)
    + '\n\nNative subprocess integration uses a fake workspace. It exercises the actual mailbox/client/event loop, not private iOS APIs.\n\n'
    + report['sha256sums'] + '\n'
)
