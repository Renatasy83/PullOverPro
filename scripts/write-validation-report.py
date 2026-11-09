"""Summarize successful CI evidence without implying iOS runtime validation."""
from pathlib import Path
import json
import platform
import sys

directory = Path(sys.argv[1])
commit = sys.argv[2]
markers = {
    'messenger-keep-tests.log': 'Messenger bounded Keep policy tests passed:',
    'messenger-prepare-tests.log': 'Messenger prepare client tests passed:',
    'messenger-return-tests.log': 'Messenger return state tests passed:',
    'messenger-trial-tests.log': 'Messenger trial profile tests passed:',
    'scene-observation-tests.log': 'Scene observation tests passed:',
    'handle-interaction-tests.log': 'Handle interaction tests passed:',
    'capability-diagnostics-tests.log': 'Capability diagnostics tests passed:',
    'keyboard-avoidance-tests.log': 'Keyboard avoidance tests passed:',
    'handle-nub-tests.log': 'Handle nub state tests passed:',
    'classic-geometry-tests.log': 'Classic interface geometry tests passed:',
    'owned-cold-scene-tests.log': 'Owned cold scene tests passed:',
    'edge-drawer-tests.log': 'Edge drawer geometry tests passed:',
    'interaction-intent-tests.log': 'Interaction intent tests passed:',
    'user-preferences-tests.log': 'User preferences tests passed:',
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
    'RC11 Messenger drag/resize, input-after-transform and background cleanup on actual UIKit',
    'RC4 first-touch/inward-pull chooser-only flow, distinct second-tap/row app opening and already-open window toggling on iOS',
    'RC4 bounded per-app refusal history in the actual SpringBoard file-writing context',
    'Messenger app delegate and independent-scene behavior remain unproven; RC5 foreground/background source samples are available and do not prove multiple scenes.',
    'Actual public keyboard visibility, handle/compact-chooser avoidance and restoration on iOS: RC3 received47 public events but retained samples show hidden only',
    'Physical manual outward nub/reveal and automatic-nub integration: RC3 records one commit counter but no retained commit/reveal sequence',
    'Cold owned-scene process bootstrap, first rendered layer, input and cleanup on actual23A355',
    'Classic headerless drawer, moving handle, compact quick switch and outside tap on iOS',
    'iOS launchd bootstrap/removal and service permissions',
    'SpringBoard sandbox access to the file mailbox',
    'LaunchServices app launching from the new service context',
    'Application scene rendering, touch/keyboard routing and teardown',
    'Lock/unlock, orientation, process death and watchdog integration',
    'Keep mode beyond fifteen seconds and lock-transition frame exposure',
    'New full-scene passthrough drawer pixels/input, left/right gestures and Settings PreferenceLoader discovery/live controls/favorite editor on iOS',
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
    'floating_application_hosting_implemented': 'User confirmed RC10 bounded120second Keep/full-screen return and later Messenger-overNewTerm/manualX/laternormalforeground. Background session has originalbg0layers vs ownednonbg2layers, schema4 phase3 flags47 deferredvisibility and cleanowncleanup. RC11 enables only public host move/resize paths; actual transformed Messenger input/rendering remain untested. Keep120/companion125/v4 and minimize/cold guards remain.',
    'prior_device_baseline': 'RC3 supplied reports: four source-independent kept sessions (Safari118.583783s, Files10.076879s, Calendar282.295437s, Safari7.937405s), all closed/unpinned/unpoisoned with controller/workspace invalidations returned and replacement allowed. Interface received47 public keyboard events and manualNubCount1; all15 retained post-startup samples are hidden/not-adjusted, so visible movement/restoration is not demonstrated and older discarded observations are unknown. User requested correction of first-touch/pull app opening and reported unverified-window-support refusals for Messages/Messenger; neither app appears in the supplied host/capability files. RC2 Safari: user confirmed visible page, web navigation, keyboard and X; three source-independent scenes with active nonempty layers, Keep, sampled headerless drawer geometry and clean own controller/workspace teardown. Source1392af09d382be746ea8ece2a86380a1914fef29 is preserved as the scoped stable baseline. Process termination before launch and global compatibility are not established. RC1 Safari report: manual close after34.83s in Keep;7completed resizes/3moves; clean own controller/workspace cleanup. User reports RC1 works. 0.17.0 Files named-configuration admission/rendering with two clean default-timeout sessions;0.16.0 Calendar programmatic owned-window/kept/minimize/restore/resize/manual/default-timeout;0.15.0 own favorites store read/long-press access with1favorite;0.14.0 Safari minimize/restore/kept/bar-X/default expiry/reuse and user-confirmed restored/underlying input;0.13.0 resize/move;0.12.0 Contacts installed-info;0.11.0 Reminders and0.10.0 Safari Keep/lock/reuse. No full-platform compatibility claim.',
    'dopamine_ellekit_compatibility_confirmed': False,
    'final_candidate': False,
    'rc8_scope': 'Exact same captured UIWindow is preserved; only the current root actually owned by that window may travel back. No old root is reinstalled. Schema2/channelv2 distinguishes legitimate root replacement from old root-mismatch refusal. Bounded handoff retention/polling and all exact-profile/owner/lock/target gates remain. Actual return remains a phone gate.',
    'rc7_scope': 'Exact-profile Messenger-only public UIKit companion conditionally returns only the same original UIWindow/root from an exact PPO-prefix disconnected session to its still-connected original scene. No screenshots, focus/key-window request or direct FBScene mutation. Bounded state telemetry via libnotify. Trial refuses missing/stale companion readiness. Actual public session-name mapping, migration and restored pixels require the phone.',
    'historical_rc6_scope': 'Exact installed Messenger585.0.0/build1101076820 plist SHA256 profile only, unknown/eligible=false proof with explicit warm-trial admission. Unique normal existing foreground source/layers required, no cold fallback; same verified owned-child API, automatic15s close,8s render deadline, no Keep/resize/minimize. No Messenger runtime success is inferred.',
    'rc5_scope': 'Read-only Messenger missing-manifest source observation only; no Messenger hosting authorization or fix. No launch/create/activate/present/mutation; max4 explicit snapshots per SpringBoard process,2 retained. Existing floating windows remain implemented.',
    'emergency_disable': 'Policy and subprocess fixtures cover marker presence; missing/error distinctions; disable during refresh. Not device-tested.',
}
(directory / 'VALIDATION.json').write_text(json.dumps(report, indent=2) + '\n')
current_summary = report['floating_application_hosting_implemented']
(directory / 'VALIDATION.md').write_text(
    '# Development validation report\n\n'
    f'Commit: `{commit}`\n\n'
    f'**Current scope:** {current_summary}\n\n'
    'Emergency disable is covered before workspace access, after inventory refresh and in actual subprocess exchange using an isolated marker fixture. This cannot revoke an already submitted OS request.\n\n'
    'Passed: Clang analysis, Theos build, rootless payload/architecture inspection and these automated test suites:\n\n'
    + '\n'.join(f'- `{name}`' for name in markers)
    + '\n\nNot executed by this CI run:\n\n'
    + '\n'.join(f'- {name}' for name in not_run)
    + '\n\nNative subprocess integration uses a fake workspace. It exercises the actual mailbox/client/event loop, not private iOS APIs.\n\n'
    + report['sha256sums'] + '\n'
)
