# PullOver Pro — OpenCode / ChatGPT handoff (2026-11-24)

## Active task: draggable window bar and free position

Latest user feedback: RC2 resizing works but is impractical without moving the window. The user requests a separate control/status-style bar to grab and move the window anywhere. We implement a draggable top bar with close button, preserving the resize grip below. Active branch `feature/jondie-window-move`, based on user-feedback head821e91052c5f08cb82bbb1b54c9fe15a3254e529 of `feature/jondie-window-size`. Source is `jondie-port/`; build there, not the legacy root Makefile. Candidate3.0.2~rc3 is an independent GPL-3.0 c1d3r/Jond_ie derivative.

## Implementation

- One owned `windowChrome` contains top bar28+gap2, native app canvas uniformly scaled, and bottom gap2+resize grip18. Dragging the top bar moves the whole group. The X closes via the existing controller path. Physical double tap on the bar restores only this app's position; double tap on the resize grip restores only its maximum size, clamping the full window into view.
- Pure-C `POFloatingWindowGeometry.h` calculates the full safe-area envelope, normalized free-space positions and fixed-origin aspect-preserving resize. The controller uses logical parent translations, including mirrored mode. Full chrome is hidden when the drawer is closed, since a moved window can extend into the old fixed handle margin.
- The complete bar/app/grip remains on screen. The title-bar reserve changes the iPhone11ProMax maximum pane to354.857x768points, rather than RC2's earlier dimensions. Do not claim default app geometry is unchanged. Shrink first for more movement space.
- New Foundation `POWindowPositionStore` stores `windowPositionsV1` per bundleID in existing POStateDomain. Reads do not write. Only completed valid move/resize gestures save; closing, changing app/controller or invalid viewport/insets cancels intermediate changes. Existing `windowSizeFractionsV1` is retained. Reset affects only the selected app's position; sibling/global state and unknown fields survive.
- Position/size operations modify only owned UIKit frames/transforms, keeping the native app canvas and existing presenter alive. No new private API signatures or host restart during dragging. Original edge activation and outside-tap behavior are retained. VoiceOver has directional movement/reset actions. Close button and background tap remain separate from move/resize gesture areas.

## Validated RC3 ready for the phone gate

[Full validation, download and necessary phone checks](docs/JOND_IE_WINDOW_MOVE_RC3_VALIDATION.md).

Build source7cf87439e67a7f5bb7494a04946eb72366bd220a; Mac Actions run45481859945 / job138756816704 succeeded. All ten suites passed, including272 actual position-store checks,123 size-store checks and66 manager/fake-platform checks. Clang analyzed12 production units with zero findings. Theos rootless release, complete payload/modern-arm64e/embedded-signature inspection passed (244 page-hash checks). Downloaded ZIP digests matched Actions metadata and the DEB was independently inspected on Linux.

Candidate `com.johndie.pulloverpro-rootless_3.0.2~rc3_iphoneos-arm64.deb` (105096bytes), SHA256 `cb7450093d305e65762d7ba1c5d68aac05f6b3ea6dfa36d9b0ac8a8aecdc19cd`, preserved in `candidate-packages/jondie-window-move-3.0.2-rc3/` and branch `candidate/jondie-window-move-3.0.2-rc3`, with complete evidence. Package artifact14961898471; evidence14962620697. RC1/RC2 packages and checkpoints remain unchanged.

Only real-device checks remain: top-bar drag versus paging on both edges, app touches/keyboard after moving/resizing, X and separate position/size resets, independent A/B profiles and respring persistence. RC3 has not run on a phone. The previous user reports do not confirm these new controls. Fixtures do not execute UIKit remote touch or iOS respring behavior. No all-app/battery/long-stability or Apple/device trust claims. Do not ask for intermediate installs or exhaustive per-app checks.

## Recovery and tandem continuation

RC2 remains the reported-working recovery package: archive dd5e7e3ec5dd73231d65dd9e7fae18614ee8b865 at `candidate/jondie-window-size-3.0.2-rc2`, checkpoint `checkpoint/user-reported-working-jondie-3.0.2-rc2` at821e91052c5f08cb82bbb1b54c9fe15a3254e529. DEB98020bytes, SHA256 `59bf2fc4426c4ed78b28654af622574fc385d50c219d61d96998f9e3582fd5e4`. User said “Funcționează corect” then specifically confirmed resizing works while requesting movement; individual probes/apps/long stability were not enumerated. Keep RC1/RC2/main/archive/checkpoint refs untouched. [Previous handoff](docs/OPENCODE_BEFORE_WINDOW_MOVE.md) preserves exact earlier evidence.

Same package ID `com.johndie.pulloverpro-rootless` upgrades RC2 and preserves preferences; conflict with old `com.renatasy83.pulloverpro.diagnostic` remains. Never inject both. No install/respring/process termination/personal-data deletion or other-tweak changes are automatic. Recover by manual downgrade to saved RC2; if SpringBoard stalls use reboot/Dopamine without injection, then remove/downgrade only this package. RC2 ignores the new position key.

Keep GPL attribution and installed provenance. Existing ldid signing format and strict embedded page-hash gates remain; macOS codesign diagnostic is separate from Apple/device trust. Fresh-fetch remote head/handoff, preserve OpenCode changes with explicit deltas and CAS, update this file at checkpoints. Historical records: [RC2 validation](docs/JOND_IE_WINDOW_SIZE_RC2_VALIDATION.md), [RC2 feedback](docs/device-confirmations/jondie-3.0.2-rc2-2026-11-24.json).
