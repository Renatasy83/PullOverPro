# RC9 explicit repeat preparation for Messenger

1.0.8~rc9 extends the one-cycle RC8 Messenger return that the user confirmed visually after automatic expiry. The exact RC8 source/archive remains the recovery reference; repeated same-process behavior is not yet device-confirmed.

## Why this is separate

RC8 deliberately left its companion in a consumed Restored state. A second PPO open in the same Messenger process was therefore refused. RC9 lets an explicit user opening intent request fresh readiness without terminating or launching the app. It does not enable Keep, cold start, resize/minimize, or change private scene methods.

The companion prepares only when all eight gates hold: explicit request; exact original window; that window in the exact still-connected original normal scene; current root/view owned by that window; active foreground/visible/key/normal-level original UI; protected data available; no PPO session connected; no active timer/retained handoff/deferred unhide. Only a successfully completed state with all capture/scope/migration/return flags may rearm. Refused, active migration and deferred/exception states remain blocked. An unconsumed capture can refresh only with the same gates.

Each completed-to-captured rearm advances a nonwrapping generation. Disconnect callbacks must match that generation and the exact moved scene (or the exact captured window actually in its closing scene). Duplicate completion callbacks, queued prior-generation callbacks and old notifications arriving after rearm cannot operate on a later cycle. Activation/deactivation notifications must also refer to a currently connected owned scene; an old disconnected notification cannot consume the next readiness. Timer callbacks additionally require their captured generation and the still-current timer/deadline, so a cancelled old timer cannot expire or cancel a new trial.

SpringBoard posts one public notify request per explicit UI intent and polls only metadata asynchronously at50ms for at most1second. It rechecks cancellation/selection/overlay/admission before consuming that intent and creating a private child. No semaphore, synchronous wait, automatic retry/open/app activation, new private signature, root reassignment or arbitrary view reparenting. Notify is a readiness hint, not authenticated ownership/entitlement proof; existing host/agent ownership/profile checks still decide.

Schema3/channelsv3 isolate old one-shot v2 loaded components. Manual Messenger close/reopen after installing remains necessary to load the new app-filtered library. The same version is used by producer and consumer; old schemas cannot authorize a trial.

## Automation and actual limits

Local ASan/UBSan state fixtures passed1803 assertions: eight-gate combinations, terminal/refusal/deferred/generation-overflow checks,100 repeat cycles and stale disconnect rejection. Modified Agent/client/Logos tweak cross-target Clang analysis passed. A new native macOS client fixture executes actual main-queue scheduling around stubbed notify boundaries, covering fresh capture, delayed acknowledgement, bounded no-ack timeout, stale-capture refresh, active/refused/missing producer and post failure. It does not simulate UIKit or execute real daemon authorization.

Full macOS CI now requires38 suites, analysis, pinned Theos/SDK16.5 rootless arm64+arm64e packaging and payload inspection. Results, source/run/hash/archive are recorded in the handoff only after they actually complete. Ubuntu's existing ABI probe must still skip unsupported packaging; no binary relabeling or weaker checks.

A passing build cannot verify original-window key status, real notify delivery, UIKit session disconnect ordering, repeated input/rendering or locked transitions. Only one required phone test follows full artifact validation: with newly loaded companion, two consecutive timed Messenger PPO windows in the SAME app process, no app-switcher termination between them, observe full-screen recovery after each. Keep remains disabled. Collect host-1.0.8.json; on readiness refusal, retain its exact message and interface-1.0.8.json rather than repeated attempts. No other-app test or personal Data is needed.
