# Validation — 0.13.0~dev.geometry1

Executable:c86083b77575af887973c195e73b0beff28ccfef on debug/floating-window-geometry.

[Successful Actions run41246925116](https://github.com/Renatasy83/PullOverPro/actions/runs/41246925116) · [artifact13060155969](https://github.com/Renatasy83/PullOverPro/actions/runs/41246925116/artifacts/13060155969).

The downloaded artifact contains exactly one DEB and the generated machine/human validation reports, analysis/build/test/dependency/UUID logs, checksums and symbols. New-version UIKit controls still require the minimal actual-phone gate. Complete original functionality and full Dopamine/ElleKit compatibility are not claimed.

## Concrete change

An additional ↗ control cycles the already hosted app's public viewport through Medium300x480, Large380x680 and Compact260x420. Title dragging and resizing are bounded by captured scene-relative public insets plus8-point margins; preset sizes are constrained when necessary. Controls remain reachable at minimum240x320. Public window/root/content geometry and existing wrapper aspect fit change; the child keeps its single native pre-containment frame assignment. This adds no private selector, private geometry write, scene recreation or implicit Keep. See FLOATING_WINDOW_GEOMETRY.md.

Original0.12.0 owner/admission/lock/lifetime, metadata/helper protocol, package lifecycle and identity proof source files are unchanged. Size/drag controls refuse closing/pending/inactive sessions and preserve the15-second default. Existing size/orientation change closure remains. Insets are captured before creating the small window so floating-window-relative insets do not cause placement feedback. Missing full-scene safe-area information has a documented status-bar/bounds fallback; avoidance of every system overlay is not claimed.

## Automated evidence

Executed and passed for the exact source above:

- All21 automated suites. New floating geometry108812 checks passed in macOS CI and locally with C++17, -Wall/-Wextra/-Werror and ASan/UBSan; local libstdc++ assertions also passed. Fixtures cover finite bounds, fractional cancellation, preset/minimum sizing, centered resize/clamped movement,10000 mixed operations, unchanged native aspect fit and unchanged timed/kept safety decisions.
- Existing scene ownership825, lock175, lifetime410, metadata655, bundle reader175, immutable admission80, geometry1027, presenter342, visibility613, layers229, session slot229, IO365, subprocess71, lifecycle46 and app-data/launch/protocol/service/scene-selection suites passed. Applicable sanitizer fixtures passed.
- iOS Clang static analysis of the tweak, helpers, owner/public UI, metadata, lock and session modules.
- Pinned Theos rootless arm64/arm64e build with SDK16.5/deployment15.0. Binary architecture/dependency/UUID inspection and rootless payload/service/lifecycle/dependency/GPL attribution/license checks passed. Test mailbox overrides are absent from packaged release binaries.
- Local source policy, Python lifecycle46, Python/Bash syntax checks, and independent actual downloaded DEB rootless/lifecycle/license inspection.
- ZIP digest matches GitHub metadata; the single DEB digest matches diagnostics/SHA256SUMS. VALIDATION.json identifies this source and21 successful logs, final_candidate=false and dopamine_ellekit_compatibility_confirmed=false.
- Remote tree/ref checks preserve all private owner/admission/lock/lifetime/helper/package lifecycle source, main at af336d84a6b4812e6b6406af87803fb15bf29c3b, Contacts stable6d176ad4bec086cad6a99c72e360d136efa79cff and Reminders stable0bb57241e7aeb54a35b434e59f7b24bf844cc7c5.

The existing obsolete -multiply_defined linker-option warnings did not prevent success. Native fixtures run local fake private classes/workspace where applicable, not real iOS clients.

Package:packages/com.renatasy83.pulloverpro.diagnostic_0.13.0~dev.geometry1_iphoneos-arm64.deb

DEB SHA256:4364c47e92754b4b7c9794ceb9598a0b259a6f96efa59b3b8250c76ef85e6427

Artifact ZIP SHA256:f68a7b6ebd0c86a78a1cb8330116e351925155d86762f0e61f10f7c419b70e4d

Two independent read-only UIKit reviews found no concrete build/main-thread/ownership blocker. They identified the real-device inset/remote-input limits described here. These reviews do not replace Apple SDK compilation or the actual iOS compositor.

## Existing actual phone baseline

The supplied0.12.0 report contains two Contacts sessions with fresh installed-info eligibility, unique original selection, verified own-child binding and returned controller/workspace invalidations. Manual closure occurs at9.431s; reopening11.574s later ends by timeout at15.064s. The user confirms the requested test works. Source6d176ad4bec086cad6a99c72e360d136efa79cff is preserved as stable/verified-contacts-installed-metadata; [artifact13057987055](https://github.com/Renatasy83/PullOverPro/actions/runs/41241693750/artifacts/13057987055) is the fallback. Earlier Safari/Reminders baselines remain preserved. See DEVICE_VALIDATION.md for observational limits.

## Not executed here

- New-version iOS installation, actual public safe-inset availability, UIKit window movement/resizing, visible hosted content and remote touch/keyboard coordinates after resizing.
- X/reopen/timeout and lock/Keep integration for this exact executable. Private lifetime/cleanup source is unchanged; native tests do not establish device outcomes.
- Orientation, process death, prolonged global process/client/session/resource cleanup, watchdog or zero lock-transition frame exposure.
- Nonbaseline dynamic clients, complex/single-scene apps, minimize/restore, simultaneous windows and full original feature parity.
- Full Dopamine/ElleKit compatibility. Actual prior tests remain operation/version-specific; exact Dopamine version remains unknown.
- vphone-cli: no compatible physical Apple Silicon Mac is accessible. Linux/macOS Intel CI cannot substitute for iOS runtime.

## Minimal indispensable live gate after successful CI

Install the verified DEB manually and respring. Use one already working app, for example Contacts or Safari. Open its PPO window, press ↗ three times, drag the title near screen edges and check that content/scrolling and X remain usable. Close with X and reopen once; leave Keep off for the short test. No personal records need editing. Provide /var/mobile/Library/Logs/PullOverPro/host-0.13.0.json. Schema9 records actual window/native/wrapper frames, sizePreset, completedMoves/completedResizes, captured placementInsets and owned cleanup; historical samples are not post-close readings.

Recovery:X/default15-second timeout; /var/mobile/.ppo_disable; manual respring for pinned quarantine. If injection prevents startup, start Dopamine without injection and remove only this package. Tested0.12.0 remains available. Main and all tested source references remain untouched. No automatic phone install/respring, personal-record modification/deletion or other-tweak change is performed.

## Subsequent device result — 2026-10-31

The user confirms the test works. Two actual Safari sessions record11 completed resizes,5 completed moves, kept37.014s/manual closure then timed9.378s/manual closure after2.908s reuse. Recorded native frames remain414x896, captured insets are{44,0,34,0}, both owned invalidations return and replacement is allowed without quarantine. Preserved source:stable/verified-safari-window-geometry atc86083b77575af887973c195e73b0beff28ccfef. This does not establish a0.13.0 lock/timeout, keyboard or global compatibility result. See DEVICE_VALIDATION.md. This addendum changes no executable.
