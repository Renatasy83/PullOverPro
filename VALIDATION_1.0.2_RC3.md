# PullOver Pro 1.0.2 RC3 validation

[Download the single RC3 DEB](https://raw.githubusercontent.com/Renatasy83/PullOverPro/87d5d1ef8ddf122edc255c54250694861f6de15d/release-candidates/1.0.2-rc3/com.renatasy83.pulloverpro.diagnostic_1.0.2~rc3_iphoneos-arm64.deb) · [Preserved user-confirmed RC2 DEB](https://raw.githubusercontent.com/Renatasy83/PullOverPro/8d360d8ded7df9e8e857b29088c5642769679172/release-candidates/1.0.1-rc2/com.renatasy83.pulloverpro.diagnostic_1.0.1~rc2_iphoneos-arm64.deb) · [Controls and essential new test](PUBLIC_KEYBOARD_MANUAL_NUB_RC3.md)

**RC3's public keyboard-notification and manual-nub integration is implemented and compiled, but not yet phone-confirmed.** RC2's source-independent Safari content/navigation/keyboard/X baseline remains preserved. Full Dopamine/ElleKit compatibility, every-app support and exact original parity are not claimed.

| Item | Evidence |
| --- | --- |
| Version | `1.0.2~rc3` |
| Tested executable source | `847ba8e8da6d22ffbbf0da42190ed089b6606636` |
| Branch | `debug/original-keyboard-nub` |
| Actions | [41430907037](https://github.com/Renatasy83/PullOverPro/actions/runs/41430907037), successful job `125228938245` |
| Artifact | `13133389798`, 1,214,280-byte ZIP |
| Permanent archive | `87d5d1ef8ddf122edc255c54250694861f6de15d` on `release-candidates/1.0.2-rc3` |
| DEB SHA256 | `d80e67b8117f95bcfcc45f06c3f3d94175604ab77c7f0cd8b00169eb2fb6aaa4` |
| ZIP SHA256 | `0e19b7b4a59a118f5afe8f4dff8b3a31a6ddb337da5437238520ebbe1da75017` |
| Build | Pinned Theos, SDK16.5, deployment15.0, rootless arm64 + arm64e, macOS15 Intel Actions |

## Changes and safety scope

A closed-handle drag towards its outside edge commits a manual nub independently of auto-hide. Gesture direction/axis locks before inspection; pending/outward/vertical/cancelled samples do not authorize a new app request. Invalid live samples retract partial public layout; late/duplicate events are ignored. Existing held-intent/selection/metadata checks still control any inward request.

Settings adds **Evită tastatura**, strict Boolean/default off. A public UIKit monitor receives keyboard end-frame notifications, validates and converts scene/screen coordinates, and discards stale/invalid/locked/inactive observations. The pure layout moves only the handle/compact chooser, with no focus/key-window request. Hiding/disabling restores the configured ratio without notification-driven persistence; intentional vertical dragging is an explicit user position edit. Changed hit regions cancel held choices; a known keyboard leaving no safe band refuses the chooser.

All unrelated repository blobs/modes were compared against the preserved RC2 tree. The private owner/admission/bridge/lock/eligibility sources are unchanged. `PPOOwnedSafariTrial.mm` differs only in report-version/path strings; its normalized source was compared with RC2. No new private keyboard, hosting or icon API is enabled. Icon audit findings are documented in [ICON_PARITY_AUDIT_23A355.md](ICON_PARITY_AUDIT_23A355.md); synchronous rendering and unresolved execution/I/O contracts keep those calls out of this build.

Own diagnostics `/var/mobile/Library/Logs/PullOverPro/interface-1.0.2.json` contain capped public observation/counter/geometry state, with no keyboard text or app content. A single worker write plus one newest pending snapshot bounds diagnostic work. The host report path is `host-1.0.2.json`. No phone install, respring, process kill, personal-data removal or other-tweak modification is automated.

## Executed checks

Clang analyzed the Logos-generated root UI, public keyboard monitor, existing adapters/helpers, preferences and Settings. The pinned Theos build and rootless package/lifecycle/license/filter checks passed, and CI verified both architectures in all five executable payloads.

All **32** required successful logs were independently checked after artifact download. ZIP digest, DEB hash, report commit, rootless payload and production binary markers were checked again. Both dylib architecture slices contain the public monitor, new preference, manual-nub event and interface-report markers, alongside the guarded source-free host. The bridge/Settings binary policy and absence of test-only paths were checked. The permanent archive's Git blob SHA and raw DEB download were verified.

Local C++17/Werror/ASan/UBSan runs passed keyboard geometry649,349 and nub policy464,164 checks; lifecycle fixtures passed46. Selected native/pure CI suites use ASan/UBSan. These are policies/Foundation fixtures, not actual UIKit event delivery or Apple private-framework runtime tests.

| Selected final native suite | Checks |
| --- | ---: |
| `keyboard-avoidance-tests.log` | 649349 |
| `handle-nub-tests.log` | 464164 |
| `user-preferences-tests.log` | 1288 |
| `owned-scene-tests.log` | 839 |
| `owned-cold-scene-tests.log` | 192 |
| `picker-state-tests.log` | 119 |
| `window-lifetime-tests.log` | 439 |

All successful logs:

- `keyboard-avoidance-tests.log`
- `handle-nub-tests.log`
- `classic-geometry-tests.log`
- `owned-cold-scene-tests.log`
- `edge-drawer-tests.log`
- `interaction-intent-tests.log`
- `user-preferences-tests.log`
- `favorite-apps-tests.log`
- `favorites-store-tests.log`
- `picker-state-tests.log`
- `floating-presentation-tests.log`
- `floating-geometry-tests.log`
- `scene-capability-tests.log`
- `bundle-reader-tests.log`
- `owned-admission-tests.log`
- `lock-state-tests.log`
- `window-lifetime-tests.log`
- `owned-scene-tests.log`
- `visibility-tests.log`
- `layer-probe-tests.log`
- `geometry-tests.log`
- `host-slot-tests.log`
- `presenter-tests.log`
- `scene-tests.log`
- `lifecycle-tests.log`
- `appdata-tests.log`
- `launcher-tests.log`
- `process-tests.log`
- `bridge-io-tests.log`
- `bridge-protocol-tests.log`
- `bridge-service-tests.log`
- `bridge-integration-tests.log`

Build warning inspection: 10 linker warnings about the existing obsolete `-multiply_defined` flag; no missing shell/locale failure.

## Not executed and indispensable new phone check

The [bounded firmware delivery audit](PUBLIC_KEYBOARD_DELIVERY_AUDIT_23A355.md) confirms an in-process public posting path, while the inspected SpringBoard PIP controller uses private variants. It neither rules out nor proves public delivery for remote-app keyboards; no private keyboard observer was added.

Actual SpringBoard delivery of public keyboard notifications, handle/list pixels, physical outward nubbing/reveal, restoration after hide, rotation/lock/typing stress and new Settings control behavior remain unexecuted by CI. Existing source-free Safari success does not validate those new UI paths. No compatible physical Apple Silicon Mac is available for vphone-cli. A successful build does not rule out runtime hangs or watchdog failures; the existing main-queue host deadline cannot interrupt a blocked private call.

The only new combined device check after manually installing/respringing this candidate is: with the owned PPO window closed, drag the handle outward to nub and tap it to reveal; enable **Evită tastatura** in Settings, place the handle low while the keyboard is hidden, then show/hide NewTerm's keyboard and observe temporary movement/restoration. Send `/var/mobile/Library/Logs/PullOverPro/interface-1.0.2.json`. Notification count zero means this public path was not demonstrated, not that an absent keyboard was proved. No per-app or source-free Safari replay is requested.

Recovery stays at `stable/verified-rc2-safari-source-free-classic-reuse` (`e5c6e53...`, runtime source1392af0) and the permanent RC2 DEB above; RC1 and0.17 archives remain. Main remains Alpha4. Existing emergency routes are `/var/mobile/.ppo_disable` plus manual respring, or Dopamine startup without injection followed by uninstalling only PPO. No other tweak needs changing.
