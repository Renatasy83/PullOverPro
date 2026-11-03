# RC6 Messenger warm owned-scene trial

Candidate1.0.5~rc6. This is a time-bounded real-window experiment, not confirmed Messenger compatibility. Existing working apps remain on their previous paths. Source/run/hash/download evidence is recorded in OPENCODE_HANDOFF.md and the final validation document after CI completes.

## Basis and exact scope

RC5 target-device observations found a unique Messenger source with exact normal UIApplicationSceneSpecification/normal application role and matching23A355 framework UUIDs. The foreground-marked sample had3published type1 layers; the separate background-marked sample had0layers. Those observations establish an existing source, not independent-child rendering. The UIKit audit shows that manifest absence alone cannot decide delegate adoption. This trial tests the remaining independent-child question using only the already audited owned-scene APIs.

The installed-bundle reader computes public CommonCrypto SHA256 over the bounded, securely opened Info.plist bytes. Only com.facebook.Messenger585.0.0/build1101076820 with exact previously supplied hash741517f9808a10ac225c6490d2af5bd835ff56b112464c5d53ce670d7ff92e30 and checked executable/package/families may produce reviewed-messenger585-warm-trial. Raw plist is not published. The original attachment is no longer mounted during this turn; the expected hash/version are from earlier computed evidence, while the phone reader recomputes the actual installed file hash. Changed bytes refuse the exception. A launch-screen name is not treated as an app storyboard.

The seven-field descriptor deliberately remains unknown/eligible=false. The new reserved reason binds only Messenger, cannot be normalized into eligible/ineligible or another identifier, and receives an explicit reviewed-messenger-warm-trial admission basis rather than generic installed-info eligibility. Ordinary missing manifests are still refused. Old clients lacking this reserved reason fail closed. No replay/nonce/freshness, explicit-negative, marker or firmware controls are removed.

## Runtime guards

An explicit ordinary second-tap/row app-opening action is required; first handle reveal and pans still do not create scenes. A fresh bridge capability must match the selected identifier/intent/epoch. Exact firmware UUIDs, unlocked/protected-data and active host checks remain. There must already be one uniquely identity-bound Messenger source. Its existing layer-state read must be sampled, active, not backgrounded and have nonzero layers. If absent/ambiguous/backgrounded/unsupported, refuse before constructing the trial; do not launch the app or fall back to application-identity factories. The core owner independently rejects a nil source for this reason before cold factories or workspace allocation.

The unchanged private selector surface validates source definition/client identity, exact normal specification/role, fresh empty workspace, distinct child scene/identifier, exact created child/client/workspace, inactive pre-attachment state and activation-component proxy binding. It does not copy/reparent source layers or mutate/invalidate the original scene. Own-controller/workspace cleanup, pinned uncertainty/quarantine and replacement blocking remain. The owner's only production control change beyond imports is explicit no-source rejection; this is not a new guessed private API path.

Trial presentation uses nonpersistent local standard-size/timed preferences. Keep is blocked in both user action and automatic preference logic. Resize/minimize/restore/pan handlers refuse this trial and controls are disabled. CloseX remains available. The existing250ms lifetime timer closes at15seconds or earlier on disable/lock/inactive/invalid state; existing warm activation grace is2seconds. A new8second child-render deadline closes on absent sampled child layers. Read-only samples use the existing layer probe at most twice per second during the bounded trial. No automatic repeated Messenger opening is introduced. Persistent user preferences are not changed.

Private calls already entered cannot be preempted by the main-thread timer; compilation/fixtures do not establish safety on the actual app. The known recovery is required, and no automatic installation/respring/phone process termination occurs.

## Automated coverage

Existing35 suites remain, plus a synthetic Messenger profile/digest/negative-field/identifier/status/freshness/bridge/frozen-admission suite. The supplied-digest fixtures test the pure profile decision, not a claim that their synthetic plist serializes to the real hash. The actual reader hashes the bytes through CommonCrypto. Existing owner fixtures now test warm Messenger distinct-child ownership/cleanup with original unchanged; cold fixtures test refusal before either factory/workspace allocation. Clang analysis, sanitizer-configured native suites, pinned Theos rootless arm64/arm64e build and payload inspection must pass before delivery. See final validation for actual results.

## Only necessary phone test after manual installation/respring

Open Messenger normally and leave it full-screen. In PPO select/open Messenger once. Observe the new small window only: whether it shows actual Messenger content and responds to a harmless scroll; do not send messages. Leave it to close automatically within15seconds (it may close earlier if activation/rendering fails). Do not use Keep or repeat opening in a loop. Send /var/mobile/Library/Logs/PullOverPro/host-1.0.5.json and state whether content appeared and scrolled inside the small window. Do not infer small-window input from the full-screen app responding underneath.

If a verification/refusal message prevents a window, send capability-1.0.5.json instead; do not repeat installation or restart the service to hide the error. A profile mismatch or missing foreground source is a refusal, not proof of a rendering failure. If cleanup is uncertain/quarantined, do not attempt replacement; preserve the report.

This one trial does not establish cold start, permanent Keep, keyboard, other apps or full original parity. Do not collect Messenger Data/conversations or change its bundle. Messages and unrelated already-working applications need no repeated test for this gate.

## Recovery and previous build

Create /var/mobile/.ppo_disable then manually respring to disable PPO. If SpringBoard is unusable, reboot and enable Dopamine without injection, then uninstall only PPO as previously done. No personal data/other tweaks are to be modified. The user's battery attribution for ongoing slowdown remains unverified and is not diagnosed by this trial.

Permanent RC5 (previous read-only candidate):
https://raw.githubusercontent.com/Renatasy83/PullOverPro/bfd53b813bef2801dc5d1b7f09061945fe29331e/release-candidates/1.0.4-rc5/com.renatasy83.pulloverpro.diagnostic_1.0.4~rc5_iphoneos-arm64.deb
SHA2569346849e94861872ecfd7eed27bf0f379b8f86b3bc84dc83356b37bf5e1612a2.

Earlier RC4/stable/recovery and main remain preserved. GPL-3.0 original attribution and package license remain intact.
