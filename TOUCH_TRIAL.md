# 0.7.2 Safari touch-acceptance gate

This development DEB is not the final port. The existing Safari render/manual-close path was user-confirmed in0.7.1. 0.7.2 enables only a public UIKit touch-acceptance opt-in; actual touch delivery and keyboard focus are unverified. main, stable/verified-safari-launch and stable/verified-safari-rendering are preserved.

The trial opens through the same explicit PPO button and starts read-only. Its header has Safari ·15s, Atingeri: oprite and X. Pressing the touch button changes userInteractionEnabled on PPO's content container. It does not force key-window status, synthesize events, modify Safari's scene, or call private input/focus APIs. The button can switch touches off again and never extends the15-second deadline.

Safeguards: same Safari-only unique selection, exact loaded-library UUIDs and ABI guards, one attempt per SpringBoard process, owned-presenter-only invalidation, disable marker checks, automatic close and host-scene/protected-data notifications. A main-queue timer cannot interrupt a private call that blocks. Neither successful compilation nor the previous render trial proves lock-screen safety or full jailbreak compatibility.

## Necessary real-device test after CI passes

Keep the working0.7.1 DEB available in Filza. Install only the artifact from the successful run identified for this revision, then respring manually. Open Safari through PPO, with a page already available for scrolling. Open Probă fereastră Safari, press Atingeri: oprite once to enable it, and try scrolling within the page. Observe whether Safari responds in the small window and whether closing returns the phone to normal. Keyboard entry is outside this test's scope; no keyboard-routing fix is claimed.

The report is /var/mobile/Library/Logs/PullOverPro/host-0.7.2.json. Share it and the observed scroll behavior. It records opt-in and the reason for close. A true inputEnabled field proves only the public property setting, not delivery to Safari. The report collects no URLs, typed content, key events or touch coordinates.

If SpringBoard stays responsive, create /var/mobile/.ppo_disable in NewTerm as mobile to stop future operations; the trial timer checks it. If SpringBoard hangs, force restart, enable Dopamine without tweak injection and uninstall only com.renatasy83.pulloverpro.diagnostic. No automatic installation/respring, personal-data deletion or changes to other tweaks are performed.

## Automated verification

CI analyzes the UIKit trial and existing private adapter, runs the existing native presenter/scene/parser/bridge/lifecycle suites (including sanitizers), compiles rootless arm64+arm64e, and inspects payload/license/maintainer scripts. Source policy prohibits private input calls, forced key/first-responder changes and startup opt-in. Actual UIKit hit testing, remote Safari scrolling, focus and keyboard behavior cannot be established by the native macOS fixtures. See INPUT_23A355.md and artifact VALIDATION.md/json.
