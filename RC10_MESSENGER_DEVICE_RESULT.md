# RC10 device result — bounded Messenger Keep and full-screen return confirmed

On2026-11-05 the user supplied host-1.0.9.json and explicitly reported that it works, closes after two minutes and returns to normal full-screen Messenger. This is the requested bounded Keep result, not a new request for testing. No raw report, conversations or application Data is published here.

One Messenger session uses1.0.9~rc10, lifetimeMode kept, messengerMaximumSeconds120, closeReason messenger-session-limit. The report's absolute deadline77409.589860875 gives budget start77289.589860875. The prepare-requested event is77289.59009145833, about0.000231seconds after budget start; owned-scene-prepared is77289.61521141668. The Keep action is recorded at77295.18507237501, about5.595212seconds into the budget. Thus this was explicitly kept and did not simply use the normal15second timeout.

Kept heartbeats occur around35.822148,65.821159 and96.071323seconds into the budget. Close-returned is77409.67751020833:120.087649seconds from budget start, about0.087649seconds after its absolute deadline, consistent with periodic checks/cleanup rather than exact hard-real-time scheduling. The visible window-shown event is no longer retained in the bounded16-event history; do not call this an exact visible-window duration.

The late owned/original scene samples at77409.66011258334/77409.66042816667 are active, not backgrounded, with2layers each; live state is sampled/valid/active at77409.66044329166. These samples precede close-returned. They support late live scene/layer observations but do not independently establish post-close pixels or real touch/keyboard delivery.

The companion reports transportSchema4, phase3, flags31: capture1 + owned scope2 + accepted migration4 + public original-window/current-root return readback8 + absent/different old root baseline16. Bit16 does not distinguish release from replacement. No refusal128, exception64 or deferred-visibility32 flags are set. ready=false is expected after a completed/consumed session.

Own proxy/child is verified distinct from the original source; controller/workspace invalidations returned, closed=true, pinned=false, poisoned=false, replacementAllowed=true. Three after-close observation events are retained at77409.88716379167,77410.513542625 and77411.76973454167. Helper state is a report/session snapshot, not per-event continuous rendering proof.

The user's explicit normal full-screen return supplies the visible outcome missing from raw telemetry. touchDeliveryVerified and keyboardRoutingVerified remain false automatic flags; do not turn them into independently verified input-routing evidence. The report has no PID/boot/generation echo, and this single session establishes no broader continuity claim.

## Scoped conclusion

Confirmed as reported for this device/exact reviewed Messenger profile: explicit bounded Keep beyond the normal15second window, automatic closure at the120second budget, clean own-object teardown and return to normal full-screen Messenger. RC9's previously confirmed repeated timed openings remain separate baseline evidence. No reinstallation/repeated same test/new DEB is needed to record this success.

Not established: unlimited or renewable Keep, long repeated cycles, manual-X/minimize/resize/cold/background/lock/protected transitions for Messenger, every app/version, actual signature trust or general Dopamine/ElleKit compatibility. The125second companion cap is not permission to remove the120second root cap. Any broader lifetime requires a coordinated design/protocol, tests and a separate device gate, not simply deleting limits.

Exact candidate remains sourcefd8e3b24305624ccb984c9063ac0667e52f925af, Actions41946753360/all39 suites, immutable archive50b1390a373052f90622b47376a59aaa92c56898, DEB321086bytes/SHA256fd4a6aba30a603e5dcbb33efa9c6ee4b19a1aa6fa589e8727597fc685a9c72cf. Main/stable/RC9/older recovery untouched. This checkpoint changes documentation only; no automatic phone action, new build, personal-data deletion or other-tweak modification.
