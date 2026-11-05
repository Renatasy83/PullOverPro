# RC8 device result — original Messenger restored after timed closure

The user supplied host-1.0.7.json on2026-11-05 and subsequently explicitly confirmed: after the automatic PPO window closure, the normal full-screen Messenger application displayed its normal content and worked; the screen was not black. Only aggregate state/timing and this user observation are published; no raw report or application content is committed.

Version1.0.7~rc8, one retained Messenger warm-trial session. The companion reports transportSchema2, phase3, flags15, sampled uptime53471. In the delivered PPOReturnState, phase3 is Restored (logical readback); flags15 are captured1 + owned-session-seen2 + accepted migration4 + verified public return8. Refusal128, exception64 and deferred-visibility32 are absent. ready=false is expected for an already consumed/completed session, not evidence of readiness failure.

Unlike RC7 phase4/flags147, this session passed current public root ownership/exact window/original target/screen/session gates and reported windowScene==original target plus CurrentRootOwned(window) after the public assignment. This is app-side state evidence of the executed return/readback path, not compositor pixels or touch delivery. Flag16 is absent: no root replacement was observed at the accepted migration check. Do not infer that a root replacement occurred here or that the root never changed elsewhere.

The window was shown at53456.450253625; close-returned at53471.48406145834, approximately15.033808seconds later, reason timeout. The owned child/proxy was distinct from the original source, its controller/workspace invalidation returned, closed=true, pinned=false, poisoned=false, replacementAllowed=true. The final original scene sample at53471.469775125006 (2layers, active, not backgrounded) is BEFORE close-returned; it does not establish post-close rendering.

Three post-close messenger-return-observation events occur at53471.694865958336,53472.31539416667 and53473.577325000006. Helper telemetry is the report/session snapshot; these event records do not supply per-event helper snapshots or continuous after-close pixel evidence. Its packed timestamp is integer53471 and need not advance after the bounded timer stops.

## Scoped result confirmed by the user

The already-performed timed trial returned to normal full-screen Messenger with visible content and normal operation, rather than a black surface. Together with the phase3/flags15 readback and clean owned-scene teardown, this confirms the scoped RC8 after-timeout restoration result for this device/app/profile/test. It resolves the previously pending visual question; do not ask the user to repeat it or present it as still missing.

No reinstall, respring, app-data upload or new package is needed to record this result. This does not establish repeated trials in the same Messenger process, manual-X/Keep/minimize/resize behavior for the reviewed Messenger exception, lock/protected transitions, all app versions or global compatibility. Preserve this exact candidate as the recovery point before independently developing or testing any broader lifecycle.

The original full-screen background DURING the trial is a separate known limitation; this gate concerns AFTER-close return. The successful visual answer does not prove general app/Dopamine/ElleKit compatibility, every lock/background transition or repeated-session behavior.

No runtime/package change or new CI run was needed for this evidence checkpoint. Exact existing candidate remains source e92284e6e2679cfc11235273da367b5a32dc50a1, macOS Actions41903532726/all37 suites, immutable archive ad0a2b4703d22e7a29588cbdbb8f15374126c58f, DEB SHA2566a2784f8a3194220669a96a68e2cfdbec10ea42799c957d73477f48f70632c69. Main/stable/older archives remain untouched.
