# RC11 Messenger move and resize

1.0.10~rc11 enables only the existing public header-pan and size-button paths for the reviewed Messenger profile. It removes four local UI restrictions: title interaction override, early return in pan:, disabled size button, early return in resizeFromButton:. No new private API or scene mutation is added.

## Why these controls can share one candidate

Both paths reuse the existing PPOFloatingWindowPresentation/PPOFloatingWindowGeometry and applyWindowFrame. They change PPO's own panel/content and public wrapper aspect fit. Native child frame is assigned once before containment, then read without a private resize/frame setter. Existing aspect-fit/geometry/presentation fixtures cover clamping, invalid input, safe areas, immutable native dimensions and independent lifetime.

App-specific remote input conversion after changing the wrapper transform cannot be established by generic geometry alone. One physical test may cover move plus all three size presets while checking input and underlying NewTerm passthrough, then the already existing background-close/foreground-return path.

Initial Standard size, warm-only admission, manual120second Keep, companion125second/v4 protocol, all profile/firmware/root/owner/cleanup/quarantine/lifetime/lock/render guards remain. Messenger minimizeFromButton:/restoreFromButton: early blocks and menu containing only bounded Keep remain; no cold, unlimited Keep or headerless drawer mode is enabled.

The Agent and transport source are unchanged. A currently loaded compatible v4 companion is sufficient; this stage does not require terminating Messenger to load a new protocol. Root tweak install/respring remains necessary for the new controls.

## Baseline and verification

Completed validation: source192758bb746b3dcd3d4b4113fa11bcb652c10d67, macOS42061254065/artifact13432397857,39 successful suites, pinned rootless build and independent source/hash/payload/ABI checks. Exact permanent DEB/evidence in VALIDATION_1.0.10_RC11.md and OPENCODE_HANDOFF.md. Physical geometry/input remains the next gate.

The user confirmed RC10 background procedure works. Supplied second session is kept/manual, original scene bg=true/0layers while owned child stays active/nonbg2layers, helper4/phase3/flags47 includes deferred visibility32, clean own cleanup. User confirmation supplies NewTerm identity/input/no focus stealing and later normal Messenger appearance, not raw layer metadata. Read RC10_MESSENGER_BACKGROUND_RESULT.md. Keep prior RC10 archive50b1390a373052f90622b47376a59aaa92c56898.

Local13 portable suites/source policy and changed owner Clang analysis passed. Existing geometry108812/presentation403376/aspect-fit fixtures are reused instead of duplicate implementation-mirroring tests. Full39-suite macOS CI/rootless build and independent artifact checks completed; see validation for warnings/historical report caveats. This does not establish physical input-after-transform.

## Only necessary phone gate after validation

Install/respring, open Messenger normally, create PPO window and choose bounded Keep. Switch to NewTerm. Drag Messenger by its title, then use its size button to cycle Large/Compact/Standard, checking content and a simple tap/scroll after changes and NewTerm touches outside the panel. Close PPO with X, then manually foreground Messenger and check normal full-screen UI. Send host-1.0.10.json; on refusal/black/automatic closure retain exact message/interface-1.0.10.json and stop repetitions. No messages need to be sent, no app Data uploaded, and no other-app/repeated2minute test is required.

Actual transformed Messenger rendering/input and return remain untested for RC11 until this gate. No global Dopamine/ElleKit/general app compatibility or signature trust claim. Main/stable/previous archives/GPL preserved, no automatic phone actions or other-tweak/personal-data changes.
