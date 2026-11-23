# PullOver Pro — OpenCode / ChatGPT handoff (2026-11-23)

## Active work: stability corrections to Jond_ie’s GPL port

User authorized implementing the reviewed corrections and supplying one candidate DEB for necessary phone checks. Active branch: `improve/jondie-stability`. Source lives in `jondie-port/`; it is imported from Jond-ie/pulloverpro commit `076da8f07e707453bc58ed9baadeefb40f0e93e4`. Original upstream files and GPL attribution are preserved. This is an independent derivative, not an official upstream release. Root legacy code is retained for historical recovery; build the `jondie-port` directory, not the root legacy Makefile.

Candidate: `com.johndie.pulloverpro-rootless`, version `3.0.2~rc1`, rootless arm64/modern arm64e. Same package identity upgrades the Jond_ie port and preserves its preference domain. It conflicts with `com.renatasy83.pulloverpro.diagnostic` to prevent dual SpringBoard injection; no Replaces/removal scripts, automatic install or respring. Do not install both. Existing main, debug, stable branches and package archives remain untouched.

Implemented: final-keyboard-frame geometry with coordinate conversion and restoration; idempotent drawer transitions; one launch request per startup, cancellable generation-bound polling with a 20-second startup deadline (no healthy-window lifetime); visible retry/error state; rollback for partial presenter creation; guarded scene/presenter API calls using existing signatures; immutable valid QuickSwitch selection, safe-area viewport and edge autoscroll; in-memory preference type/range validation. Manual vertical handle dragging ends the previous keyboard-restoration session so hiding the keyboard does not undo that deliberate move. Controller disappearance/close invalidates startup and delayed selection so old controllers cannot reopen after Settings replacement.

## Candidate ready for the real-device gate

[Full validation and grouped phone plan](docs/JOND_IE_STABILITY_RC1_VALIDATION.md).
Build source `22adc654e237d21d26a67535a994f63c4980b4bd`; successful Mac Actions run45205953764 / job137801616407. Six suites passed, including66 actual-manager/fake-platform checks and13 signature test methods plus malformed subcases. Clang analyzed10 production units without findings. Theos release and exact rootless payload/modern-arm64e checks passed. All embedded primary/alternate CodeDirectory/page/special-slot digests passed (216 page-hash checks). The downloaded package was inspected independently on Linux and ZIP digests matched Actions metadata.

DEB `com.johndie.pulloverpro-rootless_3.0.2~rc1_iphoneos-arm64.deb` (92432bytes), SHA256 `b3f8fc9a946ea4d87a7c0a8bd5649ab8deef54b6fe05c026f6e2ab2b3bb9b50d`. Preserved at `candidate-packages/jondie-stability-3.0.2-rc1/` and branch `candidate/jondie-stability-3.0.2-rc1`, alongside complete evidence. Actions package artifact14833169352, evidence14833367214. These are the only approved candidate bytes for this checkpoint; earlier failed CI packages are not candidates.

Mac codesign rejects the upstream-style ldid fakesign format; the actual diagnostic is retained in JSON, separate from hash-integrity verification. No certificate authenticity, Apple trust, jailbreak device acceptance, SpringBoard/UIKit behavior, general app compatibility or battery improvement is claimed. The user must now execute only the grouped real-device probes in the report. No additional automated gate is pending.

## Continuation and recovery

Read `jondie-port/PROVENANCE.md`, the workflow evidence, and `docs/JOND_IE_IMPROVEMENT_REVIEW.md`. Future per-app sizing/multiple-window work is out of scope for this stability candidate. Fresh-fetch remote head and this handoff before editing; preserve tandem OpenCode changes with explicit deltas and CAS. Keep the handoff current and never force-reset others’ work.

Preserved custom recovery: RC13 `stable/verified-rc13-messenger586-minimize` at `c87589dc45eb4d5039081eff7015f48ad1ff4a7e`, archive `7f77890d4229375c83050683eb0ef6718b90b9ef`. Last custom RC15 source `becd7123fec59177684f52cfd58fc8aea03e23e3`, archive `fb57ef02e5d04d721e058cdaa14d8adccd4b26d9`, SHA256 `8d2242c49276bf4a7a71dc19e07d1e452545e2b124139ff0d3a279528d8e99a2`, is not phone-confirmed. Upstream original3.0.1 remains at https://jond-ie.github.io/repo/.

Previous context: [handoff before derivative](docs/OPENCODE_HISTORY_BEFORE_JOND_IE_PATCHES.md), [external package reference](EXTERNAL_PORT_REFERENCE.md), [earlier validation/recovery history](docs/OPENCODE_HISTORY_THROUGH_RC15_VALIDATION.md). Do not delete preferences/personal data or alter unrelated tweaks. No automatic phone actions.
