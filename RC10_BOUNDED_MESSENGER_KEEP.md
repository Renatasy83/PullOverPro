# RC10 bounded Messenger Keep

Version1.0.9~rc10 adds only an explicit "Păstrează (max. 2 min)" action for the reviewed Messenger profile. Default remains15seconds. This is a bounded step toward Keep, not unlimited lifetime or general multi-scene compatibility.

## Evidence baseline

User supplied host-1.0.8.json and confirmed the requested RC9 procedure works. Two distinct timed sessions lasted15.025650/15.024213seconds, helper schema3 phase3 flags31/15, both clean own controller/workspace invalidations, closed/unpinned/unpoisoned/replacementAllowed=true. First flag16 means the old weak root was absent OR differed; current root ownership on the tracked window passed. Same-process continuity follows the requested procedure/user confirmation, not independent PID/boot telemetry. Read RC9_MESSENGER_DEVICE_RESULT.md. Preserve exact RC9 archive3a1eecdbffba0c576ea7790af541bb2db68b192c.

## Absolute lifetime coordination

New pure PPOMessengerKeepPolicy starts ONCE before any owned scene allocation/prepare. Its120second absolute root deadline includes preparation time and cannot restart on Keep or repeated presses. Normal PPOWindowLifetime15second/activation/render/lock/scene/disabled/protected conditions still apply. Manual Keep requires fresh positive owned-layer rendering and freshly sampled lifetime/time after that probe; a late request crossing15seconds cannot be accepted using an earlier timestamp.

The app-side companion observes each identified owned scope for at most125seconds, using the same header constant. Scope observation begins after the root budget start, preserving at least5seconds of nominal cleanup margin after the root deadline. This is not a guarantee of private-call duration or callback delivery under a frozen process. Existing timer-generation/deadline/disconnected-notification safeguards remain.

The longer protocol uses schema4/channelsv4. A still-loaded v3/20second companion cannot authorize this candidate. No new private method, foreground/focus/key-window request, arbitrary root/view reparenting, app bundle modification, automatic launch or user-data action. Keep is manual only for Messenger; its global Keep preference remains ignored, cold/resize/minimize/pan remain disabled. Other apps retain existing behavior.

The menu label discloses the maximum, measured from pre-prepare session start, not an additional120seconds after pressing. Root reports messengerMaximumSeconds120 and messengerAbsoluteDeadline; lifetimeMode remains backward-compatible "kept" while those fields distinguish this bound. At cap the owner closes with messenger-session-limit. The original full-screen return remains the v4 companion's existing public exact-window/current-root path.

## Verification and remaining phone gate

598 local ASan/UBSan policy checks cover invalid/backward/huge clocks, no restart, root/scope ordering, default15seconds, surviving20seconds after explicit Keep, late Keep, lock/disabled/invalid-scene precedence and slow prepare without activation-grace changes. Return-state tests1804 reject old v3 readiness. Modified Agent/client/tweak/owner cross-target Clang checks passed. Full CI requires39 macOS suites (new Keep fixture), analysis/pinned Theos/SDK16.5 rootless build, and13 portable Linux suites; do not claim completed results until actual runs and independent package checks finish.

Only after full validation, one phone test: manually install/respring and close/reopen Messenger initially to load v4, open one PPO Messenger window and choose "Păstrează (max. 2 min)" before15seconds. Confirm it remains usable beyond20seconds, then let the absolute cap close it near two minutes from opening/preparation, and confirm normal full-screen Messenger returns. Collect host-1.0.9.json. On refusal retain exact message/interface-1.0.9.json without loops. No new other-app, personal Data or repeated RC9 test is required.

Actual long UIKit/window lifetime, v4 real IPC/render/input and later return remain untested. No general Dopamine/ElleKit/unlimited Keep claim. Preserve main/stable/older archives and GPL-3.0; no automatic phone action is performed.
