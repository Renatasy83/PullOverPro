# Autonomous port status — 2026-10-29

## Preserved baselines

main remains Alpha 4 at af336d84a6b4812e6b6406af87803fb15bf29c3b.
stable/verified-app-picker preserves the user-confirmed 0.5.8 picker.
stable/verified-safari-launch preserves 0.6.1 at e22b2efab141fe31dfd7e39365ae42c7667fb116, with actual Safari opening from PPO confirmed by the user.

Development is isolated on debug/autonomous-port. None of these observations establishes complete Dopamine/ElleKit compatibility.

## Device evidence

The 0.5.11 report recorded UID501 and SpringBoard posix_spawn EPERM; the same helper opened Safari from NewTerm. The exact enforcement cause remains unconfirmed. The 0.6 bridge architecture uses a mobile launchd service and a bounded file mailbox instead of spawning a helper from SpringBoard. The 0.6.1 installer accommodates the device's /var/jb/usr/bin/launchctl.

The supplied scene-0.7.0.json confirms the exact three 23A355 framework UUIDs, complete enumeration of 5 scenes, and one exact Safari identity match. Presenter methods were observed as metadata only. See DEVICE_VALIDATION.md.

## 0.7.1 rendering baseline

The ordinary public UIKit overlay/picker and service launch path are retained. A separately reviewed adapter can obtain the scene's presentation manager, create a unique PPO presenter, adopt its own unattached presentation view, activate it, and invalidate only that owned presenter on close. Dispatch is guarded by the exact framework UUIDs, declared method ABI and actual receiver/return types. No priorities, KVC/ivars, scene foreground mutations or process termination are used.

The explicit Safari-only button attempts live rendering once per SpringBoard process. It opens a draggable window for at most 15 seconds while the main queue remains responsive. Hosted content input is disabled. There is no hosting during initialization/respring or automatic retries after uncertain cleanup. Cleanup failures poison and retain the session. See HOSTING_TRIAL.md for the complete gate and recovery.

The user has since supplied host-0.7.1.json and confirmed actual live Safari rendering and normal restoration after manual X-close. This is one device operation; automatic close, touch, keyboard and lifecycle stress remain unverified. No final candidate has been produced.

## Automated validation

The workflow runs on a standard macos-15-intel runner, with pinned Theos and SDK16.5, strict Clang analysis, native fixture suites, sanitizer checks, real macOS subprocess mailbox tests, Theos arm64/arm64e packaging and exact rootless payload/lifecycle/license inspection. The artifact contains per-suite logs, SHA256 and VALIDATION.md/json. Read the specific successful run; implementation alone is not a test result.

Local Linux execution passed 365 transport checks with AddressSanitizer/UBSan, 24 package lifecycle checks and source-policy checks. Objective-C/UIKit compilation and native Foundation tests require Actions in this environment.

## Runtime limit

No compatible physical Apple Silicon Mac is accessible. Lakr233/vphone-cli requires physical Apple Silicon/macOS15+ and host security configuration, and does not support macOS VMs. It was not installed or run. The Intel Actions machine is a build/test host, not a compatible iPhone runtime.

The first actual Safari presentation/manual-close device gate passed on0.7.1. The next device gate is touch/scroll delivery via the public UIKit opt-in on0.7.2. Touch/keyboard routing, other apps, scene resizing, foreground policy, lock/unlock, orientation, process death and repeated stress remain unimplemented or unverified. No phone installation, respring, personal-data deletion or change to other tweaks is automated.

## Historical 0.7.2 touch switch (not a reliable blocking control)

Preserved `stable/verified-safari-rendering` at3c7d3f0265e4a9b938ec45dd5ea7ad99ad06fa1e. Content still starts read-only. An explicit header button toggles only public UIKit userInteractionEnabled while the trial is active and permitted. No private dispatch surface was expanded; no key-window/first-responder/event-deferral APIs were enabled. Reports now identify opt-in, final presenter state and close reason. Touch/keyboard delivery remains unverified; source analysis is not proof of input reaching Safari. See TOUCH_TRIAL.md and INPUT_23A355.md.

## Current correction: 0.7.3 input reporting

The user observed scrolling while0.7.2 displayed Atingeri: oprite. Its JSON also completed automatic timeout invalidation after15.03s, without an input-enabled event. UIView.userInteractionEnabled cannot be treated as proof of remote input blocking in this configuration. The exact routing mechanism and possible interaction with Safari underneath remain unconfirmed. The0.7.3 code removes the misleading switch and renames report fields (schema2), while retaining the existing container flag and unchanged private presenter lifecycle. No new device installation is needed solely to validate this label/report correction. See INPUT_REPORT_CORRECTION.md.

## Safari keyboard/navigation observation

The user now confirms that keyboard entry and navigation work in the small Safari window on the installed0.7.2 build. No additional private input/focus API was required for that observed operation. Context of the underlying foreground app remains to be established before treating this as independent multitasking/background focus. Continue from the existing working path; do not add event-deferral or key-window changes without evidence of a missing behavior.

##0.8.0 development: controlled sessions

The user confirmed the requested Safari-over-NewTerm scenario, with NewTerm visible and automatic close. The exercised0.7.2 source is preserved on stable/verified-safari-over-newterm. Development now introduces an explicit one-session slot, allowing replacement only after confirmed cleanup or resource-free refusal. Active/uncertain sessions cannot be overwritten; unknown cleanup poisons the slot until process restart. Settings is the first additional controlled target. Private getter/create/activate/invalidate calls, framework UUID guards, and the15-second timeout are unchanged. New native ownership/failure/reentrancy fixtures and repeated presenter fixtures run with sanitizers. Actual repeated UIKit/WindowServer sessions and Settings hosting remain unverified. See HOST_SESSIONS.md.
