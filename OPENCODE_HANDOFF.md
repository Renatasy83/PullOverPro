# PullOver Pro — current OpenCode / ChatGPT handoff (2026-11-24)

## Active task: per-application window sizing

The user accepted implementing the recommended first feature: aspect-preserving window resizing and remembered size per application. Active branch: `feature/jondie-window-size`, based on `improve/jondie-stability` head4c986fb7b881f9b80ce5eb747057f3b0c3153ef7. Build source lives in `jondie-port/`, not the older root diagnostic Makefile. Preserve original c1d3r/Jond_ie GPL-3.0 attribution and source. Candidate3.0.2~rc2 is independent of the official Jond_ie releases.

RC1 remains the user-reported working recovery package. Its exact archive, source and user-confirmation scope are preserved below and in [the preceding handoff](docs/OPENCODE_BEFORE_WINDOW_SIZE.md). Main, recovery/checkpoint and candidate branches must remain untouched. No automatic installation, respring, process termination, personal-data deletion or changes to other tweaks.

## Implementation

- New visible resize grip is a sibling below the hosted app, outside its content. Drag to resize; physical double tap restores this app to original size. VoiceOver can adjust or reset through standard accessibility actions.
- Uniform scale preserves the native app aspect ratio. The range is55–100percent of the largest pane that fits the original drawer and safe-area bounds. Default geometry on iPhone11ProMax414x896 matches RC1. The scene/presenter is kept active; no new private API signatures or scene restart is introduced during resize.
- `Shared/POWindowSizeGeometry.h` supplies actual pure-C geometry and pan projection used by UIKit. Logical parent coordinates handle left/right mirroring; the old handle-position scale stays independent of app size.
- `Tweak/POWindowSizeStore.h/.m` supplies actual Foundation persistence. State key `windowSizeFractionsV1` in the existing POStateDomain stores a normalized fraction per bundle ID. Reads do not write. Saving/resetting changes only the selected app, preserving sibling entries and unrelated state. Production does not call synchronize or removePersistentDomain.
- Only completed valid gestures save. Close/app switch/controller disappearance cancels unfinished resize; stale generations cannot save to another app. Layout changes invalidate the gesture. Accessibility size adjustments are discrete commits.

## User-reported correct operation — RC2 checkpoint

[Full validation, download and necessary phone checks](docs/JOND_IE_WINDOW_SIZE_RC2_VALIDATION.md).

Build source93b0304e39d1a97ba90eb0511d57e9e3780f95a2; Mac Actions run45332058212 / job138235302471 succeeded. All eight suites passed, including123 actual Foundation size-store checks and the existing66 manager/fake-platform checks. Clang analyzed11 production units without findings. Theos rootless release and exact payload/modern-arm64e/embedded-signature checks passed (228 page-hash checks). Downloaded ZIP digests matched Actions metadata, and the DEB was independently inspected on Linux.

Candidate `com.johndie.pulloverpro-rootless_3.0.2~rc2_iphoneos-arm64.deb` (98020bytes), SHA256 `59bf2fc4426c4ed78b28654af622574fc385d50c219d61d96998f9e3582fd5e4`, preserved in `candidate-packages/jondie-window-size-3.0.2-rc2/` and branch `candidate/jondie-window-size-3.0.2-rc2`, with complete evidence. Package artifact14892313021; evidence14892058549. Previous packages are unchanged.

On 2026-11-24 the user replied “Funcționează corect” (“It works correctly”) after delivery of RC2. Record this as user-reported correct operation of the delivered window-sizing feature on the previously stated iPhone12,5 / iOS26.0.1 (23A355) / Dopamine rootless / ElleKit1.2 setup. The message does not separately enumerate every grouped probe, the apps tested, respring persistence, prolonged stability or measured battery/performance results. Do not mark those individual checks as separately passed, or request repetition solely to fill documentation.

Preserved recovery checkpoint: `checkpoint/user-reported-working-jondie-3.0.2-rc2`, containing the same DEB/source/evidence; original candidate archive remains at `dd5e7e3ec5dd73231d65dd9e7fae18614ee8b865`. See [the RC2 device-feedback record](docs/device-confirmations/jondie-3.0.2-rc2-2026-11-24.json). No new build, installation or phone action was performed for this confirmation. RC1's archive/checkpoint also remains intact.

This feedback adds the user's real-device observation; the assistant did not execute independent phone tests. No all-app/long-stability/battery or Apple-trust claim is made. Historical CI evidence retains its original automation-only scope. macOS codesign diagnostics remain separate from embedded-hash integrity and jailbreak/device acceptance.

## Recovery and continuation

RC1: `com.johndie.pulloverpro-rootless_3.0.2~rc1_iphoneos-arm64.deb`,92432bytes, SHA256 `b3f8fc9a946ea4d87a7c0a8bd5649ab8deef54b6fe05c026f6e2ab2b3bb9b50d`, archive6c3fdc2fe19b09d1fa5d11a5be9f0aec095fb463 at `candidate/jondie-stability-3.0.2-rc1`; user-feedback checkpoint `checkpoint/user-reported-working-jondie-3.0.2-rc1` at4c986fb7b881f9b80ce5eb747057f3b0c3153ef7. User replied “Funcționează”; individual probes/apps/long stability were not separately specified. RC2 must not replace that archived DEB. Reverting is a manual downgrade with that saved DEB. If SpringBoard stalls, use the known reboot/Dopamine-without-injection recovery, then remove or downgrade only this package; preserve preferences.

Rootless ID/dependencies/conflict with the older `com.renatasy83.pulloverpro.diagnostic` remain the same. Do not inject both packages. Installed GPL/provenance and strict rootless/modern-arm64e/embedded CodeDirectory page-hash checks are retained. macOS codesign diagnostics remain explicitly separate from jailbreak/device trust; the upstream ldid fakesign format is unchanged.

Fresh-fetch branch head and handoff before edits, preserve tandem OpenCode changes with explicit Git deltas and CAS, and keep this file current. Prior evidence: [RC1 report](docs/JOND_IE_STABILITY_RC1_VALIDATION.md), [original improvement review](docs/JOND_IE_IMPROVEMENT_REVIEW.md), [confirmation record](docs/device-confirmations/jondie-3.0.2-rc1-2026-11-23.json).
