# Validation — 1.0.0 RC1

Executable: `f3653171e59fd04cb2ae0c7b70ba28acf4c20fef` on `debug/original-interface-rc`.

[Successful Actions run41337396599](https://github.com/Renatasy83/PullOverPro/actions/runs/41337396599) · [artifact13095304677](https://github.com/Renatasy83/PullOverPro/actions/runs/41337396599/artifacts/13095304677). The final-source archive was downloaded and independently inspected. It contains exactly one rootless DEB plus validation reports,28 passing logs, checksums and symbols.

[Download the verified RC1 DEB](https://raw.githubusercontent.com/Renatasy83/PullOverPro/8b63669eb2dc68032848843bb0316a76caa71d8a/release-candidates/1.0.0-rc1/com.renatasy83.pulloverpro.diagnostic_1.0.0~rc1_iphoneos-arm64.deb) · [Permanent archive](https://github.com/Renatasy83/PullOverPro/tree/release-candidates/1.0.0-rc1/release-candidates/1.0.0-rc1)

The package is archived at commit `8b63669eb2dc68032848843bb0316a76caa71d8a`, based on the exact executable source, with checksum and machine report. Public raw download was rehashed successfully; availability does not depend on Actions retention.

## Delivered behavior

This candidate brings the main original edge-drawer flow to the owned-scene port: an80x34 default blurred capsule clipped by a50-point left/right edge strip, vertical positioning, tap/inward/outward sliding of retained app content, long-press recent/favorite selection, hover enlargement/haptics, and the central drag/drop target for normal launching. A normal-launch row menu is also available. Private native app geometry is supplied once before containment; subsequent sliding changes only PPO’s own public panel transform.

The default Sertar preset preserves content aspect beneath a44-point header within safe margins. Small/standard/large presets and minimized-bar restore remain. Rootless Configurări → PullOver Pro adds16 controls and a real favorite add/remove/reorder editor using the existing bounded CAS store. Its bundle name PullOverProPortPreferences avoids the upstream package’s bundle path. It uses the exact23A355-audited PSViewController base and its own public UIKit table; PreferenceLoader is a package dependency. Settings and inventory/favorites I/O run on worker queues.

The default window is persistent, matching the requested original-style behavior. Configured Keep is applied once only after active-scene observation through the existing lifetime policy. Turning Keep off selects the approximate15-second mode on the next opening; it does not retroactively restart an active window’s timer. Lock/protected-data/scene/disable/geometry checks still stop sessions. Appearance/initial size/persistence are frozen per active window. Changing edge closes the current owned window; disable hides/closes PPO. Handle preferences apply without respring. The old explicit .ppo_enable_overlay marker is no longer required; .ppo_disable remains higher priority.

See [ORIGINAL_STYLE_INTERFACE.md](ORIGINAL_STYLE_INTERFACE.md) for controls, gesture details, storage behavior and recovery, and [ORIGINAL_FEATURE_PARITY.md](ORIGINAL_FEATURE_PARITY.md) for remaining differences.

## Safety and scope

The private scene owner/admission, helper protocol/dispatch, metadata policy, lock reader and lifetime implementations are unchanged from the preserved0.17 source. Source/child exact specification and role, fresh selected-ID metadata, independent identity/proxy/namespace proof, inactive preparation, explicit owned teardown and quarantine remain. No original scene transfer, KVC foreground write, guessed SpringBoard hook/flag, key-window request or private input/focus call is added.

The public UI coordinator holds gesture intents until an inward gesture is committed and consumes them once before constructing a host. Cancelled/closed/locked/stale selection responses cannot create a hidden scene. Only one helper inspection may be in flight; cancellation cannot fill the worker queue with stale requests. Frozen row identity/generation guards normal-launch drops. Root target allocation precedes UIControl attachment, timer allocation is checked and partially built UI is hidden on synchronous setup failure.

The new transparent full-scene windows accept UIKit hits only in the handle/chooser or visible app panel. Whether actual remote iOS app input passes correctly is a device result, including during animation; pure geometry cannot establish exact per-frame event routing. Cached samples cannot establish zero-frame lock exposure, post-teardown global resource release or indefinite leak freedom.

## Executed verification

Executed and passed for the exact executable above:

- **28 automated suites**, including edge geometry **504519**, interaction intent **416496**, shared preferences **1232**, owned scene **839**, admission **87**, metadata **2456** and protocol **176** checks. The new pure suites cover safe aspect/placement/translation, finite bounds and offsets, gesture cancellation/held/commit/one-shot/replay/exhaustion sequences, strict preference types/defaults/bounds/immutable copies,18-key normalization and invalid edits rejected before I/O. They do not run UIKit or actual app clients.
- Existing floating presentation403376/12000 mixed cycles, floating geometry108812, aspect fit1027, lock175, lifetime410, bundle reader175, presenter342, visibility613, layers229, slot229, favorites268/store264/picker94, IO365, real service subprocess71, lifecycle46 and app-data/launch/service/selection suites pass. Applicable native fixtures use ASan/UBSan. Lifecycle checks use Python; the suite count is not described as28 native suites.
- iOS Clang analysis of the actual main UI, host, helper, shared preferences and Settings controller passes. C++17 matches production. The pinned Theos rootless build with SDK16.5/deployment15.0 produces arm64 and arm64e slices for tweak, helpers and Settings bundle. CI inspects architecture/dependencies/UUIDs, package/filter/loader entry, service lifecycle and GPL attribution/full license. Only the existing obsolete `-multiply_defined` linker-option warnings remain.
- Local source policy, lifecycle46, portable geometry/intent ASan/UBSan, Python/Bash syntax and whitespace checks pass. Explicit tree verification preserves every other blob and file mode and deletes no files; the19-file source delta and subsequent three-file public-UI completion leave private owner/admission/helper/metadata/lock/lifetime implementations unchanged. Main and stable sources remain preserved.
- Downloaded ZIP SHA256/byte count match GitHub artifact metadata. Exactly one DEB matches `SHA256SUMS` and the machine report’s checksum. `VALIDATION.json` binds sourcef3653171e59fd04cb2ae0c7b70ba28acf4c20fef and28 successful logs, with `final_candidate=false` and `dopamine_ellekit_compatibility_confirmed=false`.
- Independent local DEB inspection passes strict rootless payload/filter/lifecycle/license checks. Actual tweak/bridge/Settings Mach-O binaries contain arm64+arm64e. Tweak and bridge contain the matching v3 metadata policy; tweak and Settings contain the same own preference domain, and the Settings binary has the expected controller/base references. No bridge test-path override or old v2 policy is present.
- Separate source reviews checked cancellation, in-flight bounding, target initialization, timer allocation, partial UI failure, transform/base-frame separation, immutable preferences, favorite CAS/readback and bundle identity. Those reviews do not replace the target-device gate.

Package: `com.renatasy83.pulloverpro.diagnostic_1.0.0~rc1_iphoneos-arm64.deb`

DEB SHA256: `344439230bc4edd2994cccfbf012d5e00f91a66af6cbb6426c951b04bc387cda`

Artifact ZIP SHA256: `605fe2f52d0ad6fa0ad8821d669c7dbd7c24b577a0e9a52e53ff6f4a873ceaf4`

## Prior actual device evidence

The supplied0.17 Files report exercises installed-info/v3 declared-named-application-configurations in two sessions, with four matching hosting UUIDs, uniquely selected originals and independently created proxies. Both close cleanly by timeout at15.066145/15.060634s; neither records a manual X. The user confirms functionality. This preserves a representative named-configuration result, not all-app compatibility. See DEVICE_VALIDATION.md and VALIDATION_0.17.0.md for sampled layers/native-frame and operation limits.

Calendar0.16 programmatic admission/control/cleanup, Safari/Reminders/Contacts observations and favorite read/quick-access evidence retain their stated version scopes. iPhone12,5/iOS26.0.1 build23A355/ElleKit1.2 have supplied evidence. Dopamine rootless is user-reported; its exact version is unknown. Earlier watchdog IPS were not supplied, so their causes remain unconfirmed.

## Not executed here / remaining differences

- Installing RC1 on the target phone; actual new full-scene window rendering, remote touch/keyboard routing, edge/drag/drop gesture delivery and animated passthrough.
- Actual PreferenceLoader discovery, Settings sandbox access to the cache/favorite directory, favorite edits/reorder and live Settings-to-SpringBoard notifications.
- New-interface persistent mode/lock/unlock, orientation/process-death/watchdog stress and prolonged/global resource cleanup.
- All app clients. An app may need to be opened normally once to supply the unique eligible source scene; the port does not use a guessed suspended launch or Home operation. Explicit no-multiple-scene and unreviewed complex declarations remain excluded. Successful Safari/Reminders/Contacts/Calendar/Files operations are not universal compatibility.
- Exact original icons, OS-wide switcher history, dimming/outside-tap behavior, dedicated keyboard avoidance/private focus or iOS13-only external-keyboard scene-stack behavior. Public symbols and PPO’s own bounded persisted recent choices are used. One independently owned session is supported; simultaneous hosted clients are not enabled.
- General Dopamine/ElleKit compatibility and complete original parity.
- vphone-cli: no compatible physical Apple Silicon Mac is accessible. Linux/macOS Intel fixtures cannot run actual jailbroken iOS clients.

## One combined necessary device gate

After final automation/package inspection succeeds, manually install the one RC DEB through a dependency-aware package manager and respring. PreferenceLoader must be installed; Sileo can resolve it. Reopen Configurări and confirm PullOver Pro appears. Check edge choice and preserved favorites, then use a previously working Safari/Files window over NewTerm: visible content, scrolling, slide out/in, X/reopen and default persistence past15 seconds. Check the underlying app where PPO should pass touches and lock/unlock closure. Turning PPO off in Settings should hide/close it without respring. The new normal-launch drop can be checked within this same session; no test of every installed app is requested.

Send `/var/mobile/Library/Logs/PullOverPro/host-1.0.0.json`, plus the exact message for a Settings/drawer failure. If admission refuses before hosting, use capability-1.0.0.json. Avoid opening/editing/deleting personal documents or records merely to test the interface. This combined gate concerns new UI/OS integration that these desktop fixtures cannot execute.

## Preserved fallback

The last user-confirmed executable0.17.0 is stable/verified-files-named-config-reuse at `ad6ece8c6cbde196cc4be1ee0b2910cd9c832134`. Its DEB is permanently archived on recovery/0.17.0, commit `a5c6ac9bcd6d188b9fb2b5d6032ff84cd0911920`, independently of Actions expiration.

[Download0.17.0 recovery DEB](https://raw.githubusercontent.com/Renatasy83/PullOverPro/a5c6ac9bcd6d188b9fb2b5d6032ff84cd0911920/recovery/0.17.0/com.renatasy83.pulloverpro.diagnostic_0.17.0~dev.namedconfigs1_iphoneos-arm64.deb)

SHA256: `0e2d6a5792167e29d3eec58f843b3fc121efb93b51c20a0bf70703c530010bda`.

Use X or Settings Off first. RC defaults to persistent mode, so waiting15 seconds is not recovery unless timed mode was selected before opening. Create /var/mobile/.ppo_disable and respring manually if needed. Pinned uncertain resources require a manual respring. If injection prevents startup, start Dopamine without injection and remove only PPO or return manually to the archived package. Do not clear favorite/selection data. The older build also expects its existing .ppo_enable_overlay marker.

Main remains Alpha4 at `af336d84a6b4812e6b6406af87803fb15bf29c3b`; previous stable refs and recovery files remain. GPL-3.0 attribution/full license and corresponding sources/build scripts are provided. No automatic phone installation/respring, personal-record edit/deletion or other-tweak modification occurs.
