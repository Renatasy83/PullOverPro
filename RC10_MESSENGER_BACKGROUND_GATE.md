# Next RC10 device gate: Messenger over NewTerm, no new package

The latest confirmed candidate remains1.0.9~rc10/sourcefd8e3b24305624ccb984c9063ac0667e52f925af. Its bounded120second Keep and visible full-screen return were user-confirmed. No runtime change, build, install or repeated two-minute test is necessary for this next gate.

## Read-only code/evidence audit

PPOOwnedSafariTrial requires normal foreground Messenger/nonempty original layers for initial admission. Its ongoing checkLifetime and lifecycle observers use the SpringBoard host scene and the independently owned child. Original Messenger's scene is sampled read-only; it is not required to remain foreground during every heartbeat. The120second root cap and lock/protected/disable/scene/render/cleanup guards remain. If owned activity/rendering disappears, the existing closure guards still apply.

PPOMessengerReturnAgent can rebind the exact tracked window to the still-connected original ordinary scene when that scene is backgrounded. It requests no app activation/focus/key window. Visibility is hidden/deferred (flag32) until the app/original scene becomes foreground and protected data is available. CurrentRootOwned and exact identity checks remain mandatory. The window is weakly tracked after bounded handoff release; real background retention and later unhide cannot be proven by reading the code or native policy fixtures.

Two independent read-only audits found no code blocker to trying this existing behavior. Neither supplied RC9 nor RC10 retained report proves Messenger-over-NewTerm. RC10's late source samples remain active/not backgrounded. Older pre-hosting RC5 background source0layers does not establish current hosted-child behavior; Safari's earlier background success is not Messenger evidence. A bounded event ring cannot prove no brief unrecorded transition ever occurred.

The installed candidate already passed39 native suites/analysis/rootless checks. Rebuilding or rerunning unchanged host tests would not exercise iOS rendering/input/app lifecycle, and no compatible physical device/Mac/vphone environment is accessible here.

## Minimum necessary real-device procedure

1. On currently installed1.0.9, open Messenger normally, open its PPO window and select "Păstrează (max. 2 min)" before15seconds. Do not terminate Messenger or respring.
2. Switch to NewTerm. For about10seconds, observe whether the small Messenger window remains visible and responds; also check NewTerm receives touches outside the panel. No shell command, conversation submission or data change is required.
3. If the window remains functional, close it with X while NewTerm is foreground. NewTerm should stay foreground and usable; Messenger must not be forced forward.
4. Open Messenger normally and verify its full-screen content/function returns. Send the new /var/mobile/Library/Logs/PullOverPro/host-1.0.9.json and observations.

If the window turns black, closes automatically or refuses, stop that attempt and send the report/exact observation rather than repeating or reinstalling. Manual X uses the existing closeBecause/own teardown path, but the Messenger/background combination is unverified. This combines actual background hosting and deferred return in a single short test instead of waiting another two-minute cap.

Helper flag32 in the saved report can be a legitimate deferred visibility state while NewTerm is foreground. Root samples stop about2seconds after closure; they may not reflect a later manual return to Messenger. User-observed later unhide must be distinguished from the frozen snapshot. Do not diagnose failure from flag32 alone or claim pixels/touch from layer metadata.

Recovery remains the already documented manual PPO disable/respring or Dopamine-without-injection/uninstall-only-PPO if unusable. No automatic phone action, new private method, personal-data deletion or other-tweak modification was performed. Main/stable/candidate archives remain unchanged.
