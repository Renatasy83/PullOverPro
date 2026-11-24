# Current continuation — movable window RC3 (2026-11-24)

The user reports resizing works but wants practical free window movement by a top bar. Continue on `feature/jondie-window-move`, source `jondie-port/`. Read the [current OpenCode handoff](https://github.com/Renatasy83/PullOverPro/blob/feature/jondie-window-move/OPENCODE_HANDOFF.md) and [RC3 validation / necessary phone gate](https://github.com/Renatasy83/PullOverPro/blob/feature/jondie-window-move/docs/JOND_IE_WINDOW_MOVE_RC3_VALIDATION.md).

RC3 adds a draggable top bar/X, retained resize grip and per-app positions. Source7cf87439e67a7f5bb7494a04946eb72366bd220a; successful Actions run45481859945. Ten suites,12 production analyzer units and rootless/modern-arm64e/embedded-signature inspections passed. Archive `candidate/jondie-window-move-3.0.2-rc3` at2acb5a1a760e8e9e7278d0722171c1bc0c8f8a56; DEB105096bytes, SHA256 `cb7450093d305e65762d7ba1c5d68aac05f6b3ea6dfa36d9b0ac8a8aecdc19cd`. RC3 is not phone-confirmed. Tests now needed only for real drag/paging/touch, position/reset and respring persistence. Maximum app canvas reserves space for the bar (354.857x768points for414x896 with44/34insets).

This branch retains its prior runtime; only this documentation pointer changes. RC2 recovery remains intact at archive dd5e7e3ec5dd73231d65dd9e7fae18614ee8b865 and checkpoint821e91052c5f08cb82bbb1b54c9fe15a3254e529. Keep main and existing archives/checkpoints unchanged. No automatic phone actions.

## Previous handoff / recovery history

# Current continuation — window-size RC2 (2026-11-24)

Current development is on `feature/jondie-window-size`, source directory `jondie-port/`. Read the [current OpenCode handoff](https://github.com/Renatasy83/PullOverPro/blob/feature/jondie-window-size/OPENCODE_HANDOFF.md) and [RC2 validation / necessary phone gate](https://github.com/Renatasy83/PullOverPro/blob/feature/jondie-window-size/docs/JOND_IE_WINDOW_SIZE_RC2_VALIDATION.md).

Candidate3.0.2~rc2 implements aspect-preserving resizing and saved size per application. Source93b0304e39d1a97ba90eb0511d57e9e3780f95a2; successful Mac Actions run45332058212. Eight suites,11 production analyzer units, rootless/modern-arm64e and embedded page-hash inspections passed. Archive `candidate/jondie-window-size-3.0.2-rc2` at `dd5e7e3ec5dd73231d65dd9e7fae18614ee8b865`; DEB SHA256 `59bf2fc4426c4ed78b28654af622574fc385d50c219d61d96998f9e3582fd5e4`. On 2026-11-24 the user replied “Funcționează corect” after RC2 delivery. This records user-reported correct operation of the delivered resizing/per-app-size candidate on the previously stated setup; individual probes/apps, respring persistence and long-duration results were not separately enumerated. Do not request repetition just to fill this record.

This branch retains the RC1 runtime as a baseline; only this handoff pointer changed. RC1 remains preserved and user-reported working at `checkpoint/user-reported-working-jondie-3.0.2-rc1` and original archive6c3fdc2fe19b09d1fa5d11a5be9f0aec095fb463. Keep main/recovery refs/packages unchanged. No automatic phone actions.

## RC2 user-feedback recovery checkpoint

Preserved checkpoint: `checkpoint/user-reported-working-jondie-3.0.2-rc2` at `821e91052c5f08cb82bbb1b54c9fe15a3254e529`. Exact archived DEB, build evidence and source identity are unchanged. Read the current feature-branch handoff for the confirmation record. This update changes documentation only, with no rebuild or phone action. RC1 recovery and main remain intact.

## Previous RC1 handoff and confirmation scope

# PullOver Pro — OpenCode / ChatGPT handoff (2026-11-23)

## Active work: stability corrections to Jond_ie’s GPL port

User authorized implementing the reviewed corrections and supplying one candidate DEB for necessary phone checks. Active branch: `improve/jondie-stability`. Source lives in `jondie-port/`; it is imported from Jond-ie/pulloverpro commit `076da8f07e707453bc58ed9baadeefb40f0e93e4`. Original upstream files and GPL attribution are preserved. This is an independent derivative, not an official upstream release. Root legacy code is retained for historical recovery; build the `jondie-port` directory, not the root legacy Makefile.

Candidate: `com.johndie.pulloverpro-rootless`, version `3.0.2~rc1`, rootless arm64/modern arm64e. Same package identity upgrades the Jond_ie port and preserves its preference domain. It conflicts with `com.renatasy83.pulloverpro.diagnostic` to prevent dual SpringBoard injection; no Replaces/removal scripts, automatic install or respring. Do not install both. Existing main, debug, stable branches and package archives remain untouched.

Implemented: final-keyboard-frame geometry with coordinate conversion and restoration; idempotent drawer transitions; one launch request per startup, cancellable generation-bound polling with a 20-second startup deadline (no healthy-window lifetime); visible retry/error state; rollback for partial presenter creation; guarded scene/presenter API calls using existing signatures; immutable valid QuickSwitch selection, safe-area viewport and edge autoscroll; in-memory preference type/range validation. Manual vertical handle dragging ends the previous keyboard-restoration session so hiding the keyboard does not undo that deliberate move. Controller disappearance/close invalidates startup and delayed selection so old controllers cannot reopen after Settings replacement.

## User-reported working checkpoint

[Full validation and grouped phone plan](docs/JOND_IE_STABILITY_RC1_VALIDATION.md).
Build source `22adc654e237d21d26a67535a994f63c4980b4bd`; successful Mac Actions run45205953764 / job137801616407. Six suites passed, including66 actual-manager/fake-platform checks and13 signature test methods plus malformed subcases. Clang analyzed10 production units without findings. Theos release and exact rootless payload/modern-arm64e checks passed. All embedded primary/alternate CodeDirectory/page/special-slot digests passed (216 page-hash checks). The downloaded package was inspected independently on Linux and ZIP digests matched Actions metadata.

DEB `com.johndie.pulloverpro-rootless_3.0.2~rc1_iphoneos-arm64.deb` (92432bytes), SHA256 `b3f8fc9a946ea4d87a7c0a8bd5649ab8deef54b6fe05c026f6e2ab2b3bb9b50d`. Preserved at `candidate-packages/jondie-stability-3.0.2-rc1/` and branch `candidate/jondie-stability-3.0.2-rc1`, alongside complete evidence. Actions package artifact14833169352, evidence14833367214. These are the only approved candidate bytes for this checkpoint; earlier failed CI packages are not candidates.

On 2026-11-23 the user replied “Funcționează” (“It works”) to delivery of this candidate. Record this as user-reported working behavior on the previously stated iPhone12,5 / iOS26.0.1 (23A355) / Dopamine / ElleKit1.2 setup. The message does not separately document all three grouped probes, the tested apps, prolonged stability, battery use or performance. Do not mark those individual checks as passed or ask for their repetition solely to fill this record. No new package or automatic phone action is required for this confirmation.

Preserved recovery checkpoint: `checkpoint/user-reported-working-jondie-3.0.2-rc1`, containing the same archived DEB and its source/evidence. Candidate archive `candidate/jondie-stability-3.0.2-rc1` remains at `6c3fdc2fe19b09d1fa5d11a5be9f0aec095fb463`. See [the device confirmation record](docs/device-confirmations/jondie-3.0.2-rc1-2026-11-23.json).

Mac codesign still rejects the upstream-style ldid fakesign format; the actual diagnostic remains separate from hash-integrity verification. The user report adds real-device feedback, not assistant-run phone testing or an Apple trust/certificate validation. No general app compatibility or measured battery/performance improvement is established.

## Continuation and recovery

Read `jondie-port/PROVENANCE.md`, the workflow evidence, and `docs/JOND_IE_IMPROVEMENT_REVIEW.md`. Future per-app sizing/multiple-window work is out of scope for this stability candidate. Fresh-fetch remote head and this handoff before editing; preserve tandem OpenCode changes with explicit deltas and CAS. Keep the handoff current and never force-reset others’ work.

Preserved custom recovery: RC13 `stable/verified-rc13-messenger586-minimize` at `c87589dc45eb4d5039081eff7015f48ad1ff4a7e`, archive `7f77890d4229375c83050683eb0ef6718b90b9ef`. Last custom RC15 source `becd7123fec59177684f52cfd58fc8aea03e23e3`, archive `fb57ef02e5d04d721e058cdaa14d8adccd4b26d9`, SHA256 `8d2242c49276bf4a7a71dc19e07d1e452545e2b124139ff0d3a279528d8e99a2`, is not phone-confirmed. Upstream original3.0.1 remains at https://jond-ie.github.io/repo/.

Previous context: [handoff before derivative](docs/OPENCODE_HISTORY_BEFORE_JOND_IE_PATCHES.md), [external package reference](EXTERNAL_PORT_REFERENCE.md), [earlier validation/recovery history](docs/OPENCODE_HISTORY_THROUGH_RC15_VALIDATION.md). Do not delete preferences/personal data or alter unrelated tweaks. No automatic phone actions.
