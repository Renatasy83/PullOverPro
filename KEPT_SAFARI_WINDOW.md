# Explicit Keep for the owned Safari window — 0.10.0

This isolated stage adds one capability: an explicit Păstrează button keeps the independently hosted Safari scene open after its normal15-second deadline. Default sessions still time out. It does not generalize the hosted-app allowlist, change remote-input flags, take key-window ownership, synthesize input, request keyboard focus or add private foreground/security/assertion writes. The previously tested0.9.1 executable025cf5d835d4454c60c771fea19e17e60c126add is preserved as stable/verified-safari-ownscene-input-reuse and stable/verified-safari-ownscene-timeout.

## Actual prior-device evidence

The latest0.9.1 report has five sessions total: the exact previously uploaded timeout plus four additional trials. Two close by timeout and three manually; all have verified own proxy binding, both invalidations returned, closed/unpinned/unpoisoned state and replacement allowed. Visible durations are about15.044,15.030,11.680,1.991 and3.365 seconds. The shortest close-to-next-prepare gap is about1.999 seconds. The original remains logically backgrounded with no layers while each owned scene acquires layers.

The user explicitly confirms X, reopening, continued display over a different foreground app, actual interaction and web navigation. Accept these observations; UIView interaction flags remain distinct from remote input routing. No explicit keyboard-routing, lock, orientation, prolonged lifetime, other hosted app or complete Dopamine/ElleKit compatibility claim follows. Global inspected scene counts7/8/8/8/9 do not by themselves establish a leak. Raw phone JSON and page contents are not committed.

## New lifetime decisions

PPOWindowLifetime.h is a side-effect-free policy with injected observations. Default timeout is15 seconds. Keep is accepted only while healthy, active and before the existing deadline; it does not reset clocks or revive a stopped session. An inactive newly created scene gets at most2 seconds to activate; unknown/invalid state fails immediately. Once active has been observed, later inactivity closes the session. Disabled/unreadable disable marker, protected-data unavailability, inactive host, unknown/locked/pending-lock state, invalid scene and invalid/backwards monotonic clock all cause closure, including in kept mode. Changing coordinate-space size also closes the UI rather than attempting unverified orientation/resizing behavior.

A250ms main-queue timer checks simple health flags. Full geometry/layer observations are not made at that rate. A kept session records a heartbeat every30 seconds. Reports retain at most16 events, preserving the first two ownership events and the most recent fourteen including final close, with at most8 session summaries and8 view nodes. schema8 adds cached lock/data observations and lifetimeMode; kept is a historical session choice after close, not a claim that a window remains open. Sample timestamps remain authoritative for historical observations.

Original-scene references remain retained until closure under the existing ownership model. Long-lived resource and Safari client/session persistence behavior still require observation; this stage does not claim global process/session cleanup.

## Read-only lock evidence — exact23A355

New image gate: /System/Library/PrivateFrameworks/SpringBoard.framework/SpringBoard, UUID8676BE2A-9484-3492-888E-7DE10333250F, in addition to the three existing framework UUIDs. A mismatch refuses preparation before a workspace is created.

SBLockScreenManager +sharedInstanceIfExists at0x21d5429ec passes createIfNeeded=NO. Helper0x21dedeb8c takes its direct existing-instance load/retain-return branch0x21dedec04, bypassing allocation and dispatch-once. The constructing +sharedInstance is not used. isUILocked at0x21d538a78 and isWaitingToLockUI at0x21d5b43fc are direct masked-Boolean loads without calls or mutation. Production uses the actual declared methods, not ivar offsets, and requires main thread, the matching firmware, class/instance validation and exact object/bool getter ABI before dispatch. Nil, unknown, bad ABI or exceptions remain unknown and fail closed. Native fixtures inject classes; no manager is constructed by the reader.

The Foundation notification literal SBDeviceLockStateChangedNotification was verified from the exact firmware: _sendUILockStateChangedNotification0x21d5a8644 posts through NSNotificationCenter at0x21d5a87bc. Its name resolves through SpringBoard GOT0x2780349f0, SpringBoardUI exported storage0x2786178e0, CFString0x282dfa7e8 and string0x21cf68640, length36. A public Foundation main-queue observer conservatively closes on any such transition without interpreting userInfo or registering private observer protocols. It is removed during cleanup.

Protected-data availability is an additional public data guard, not proof of an unlocked screen. Polling has scheduling latency, and notification delivery cannot guarantee zero lock-transition frames. Real lock-screen behavior is unconfirmed. The UI is hidden before private teardown, and uncertain owned cleanup still quarantines resources and blocks another opening.

## Automation and remaining device gate

Native policy tests cover boundary times, explicit Keep, latching/precedence, lock/pending/unknown, data loss, scene loss and clocks. Native lock-reader fixtures cover metadata/ABI rejection, missing/foreign receiver, main/firmware refusal, getter exceptions and repeated changing observations without allocation. These are model/adapter checks, not SpringBoard execution. CI also runs all existing suites, iOS Clang analysis, Theos rootless arm64/arm64e build and package/lifecycle/license inspection. CI for this revision is pending.

After successful CI, one package supports the essential live gates in order. First open the unchanged default15-second mode and lock/unlock the phone: it should close and must not remain visible on the lock screen. If that passes, reopen, press Păstrează within15 seconds, leave it for at least30 seconds, then close with X and reopen once. Do not repeat the already confirmed ordinary input/web navigation tests or start broad app/keyboard stress. Supply the visual outcome and /var/mobile/Library/Logs/PullOverPro/host-0.10.0.json.

Recovery: X; in default mode the15-second timeout; /var/mobile/.ppo_disable to prevent new attempts and request closure; manual respring for quarantine. Kept mode deliberately has no timed expiry. If injection prevents startup, boot Dopamine without injection and remove only this package; the0.9.1 artifact remains a fallback. Nothing is installed or resprung automatically; personal data and other tweaks are not modified.
