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

## Current implementation: 0.7.2 touch acceptance

Preserved `stable/verified-safari-rendering` at3c7d3f0265e4a9b938ec45dd5ea7ad99ad06fa1e. Content still starts read-only. An explicit header button toggles only public UIKit userInteractionEnabled while the trial is active and permitted. No private dispatch surface was expanded; no key-window/first-responder/event-deferral APIs were enabled. Reports now identify opt-in, final presenter state and close reason. Touch/keyboard delivery remains unverified; source analysis is not proof of input reaching Safari. See TOUCH_TRIAL.md and INPUT_23A355.md.
