# Autonomous port status — 2026-10-30

## Scope and preserved baselines

Development remains on debug/autonomous-port. main is unchanged Alpha4 at af336d84a6b4812e6b6406af87803fb15bf29c3b. The verified picker and Safari launch references remain preserved; stable/verified-safari-over-newterm and stable/verified-safari-timeout preserve the previously user-tested0.7.2 source at411cd127fa18005989d05f2aefff59b697ee1029. Original PullOver Pro by c1d3rdev/Will Smillie remains attributed under GPL-3.0.

This is an incomplete port. Current hosting is an explicit, single-session,15-second trial restricted to Safari and Settings. Arbitrary-app hosting, a persistent window product, independent input isolation and full platform compatibility are not established.

## Actual device evidence

The target is iPhone12,5, iOS26.0.1 build23A355. Dopamine rootless is user-reported; ElleKit1.2 and OS/device identifiers were shown on the phone. The exact Dopamine version is not recorded.

The public UIKit overlay and application picker work according to the user. Safari launch from the panel through the mobile launchd/file-mailbox service was confirmed on0.6.1. SpringBoard does not spawn a helper or call private LaunchServices. Rootless launchctl lookup was corrected to accommodate /var/jb/usr/bin/launchctl. Personal data and other tweaks are outside this task.

The user confirmed Safari rendering, touch controls and keyboard/navigation on0.7.2, then confirmed Safari over NewTerm and automatic close. The old touch toggle was misleading and removed: UIView.userInteractionEnabled does not prove remote event blocking. Those observations are separate from trace-level input ownership.

0.8.0/0.8.1 produced black content in the other-app arrangement. On0.8.1, foreground Safari rendered, but became black after switching to NewTerm. Reports showed context-host views present in the later Safari sessions and absent in the black ones with equal geometry.

The actual0.8.2 report now brackets the source-layer transition between2.038s and4.032s: source layer count2 to0, settingsBackgrounded false totrue, while source FBScene.isActive and the owned presenter active/hosting flags remain true. The own window stays visible, and owned teardown completes by timeout at15.043s without poisoning. This confirms source-layer loss accompanying backgrounding in the reproduced failure. It does not demonstrate process suspension, a specific entitlement/injection failure or a safe foreign-scene foreground mutation. The original watchdog reports were not supplied; their root cause remains unconfirmed. See DEVICE_VALIDATION.md.

## Current candidate:0.8.3~dev.visibility1

Exact23A355 static inspection identified a scoped option: _UIScenePresenter.modifyPresentationContext: copies its own context/settings, invokes a synchronous mutable-copy callback and updates its own view. The candidate changes only that copy's visibility-propagation Boolean, with declared-ABI/class/callback/readback guards. UIKit manages its own scoped visibility-inheritance grant and drops its own propagation target on invalidation.

No foreign scene foreground/security flag, shared default context, guessed layer mask or assertion mode is changed. The broad SBAppViewController path was rejected because it changes existing secure-host state, workspace/layout transactions and can background the scene at close. Background source rendering from the new scoped propagation operation remains a live-device question, not a conclusion from binary inspection or fake receivers.

All trial bounds, cleanup ownership and emergency-disable behavior remain. Report schema6 is /var/mobile/Library/Logs/PullOverPro/host-0.8.3.json; historical configuration-before/after flags do not establish delivered OS grants. See VISIBILITY_PROPAGATION_23A355.md.

## Execution and remaining gate

Executable source1e2fc59dd5659451ed63618093b0308d12f44e25 completed GitHub Actions run41023747037 successfully: iOS Clang analysis,613 native visibility-context checks with ASan/UBSan, all existing suites, rootless Theos compilation for arm64/arm64e, payload/lifecycle/license inspection and generated validation reports. Artifact12962158828 contains the DEB and evidence. These are completed automated checks, not actual WindowServer/client background-rendering tests.

The available local environment is Linux, and Actions uses macOS Intel for SDK/Theos and native fixtures. No compatible physical Apple Silicon Mac is accessible for vphone-cli; it was not used. Native UIKit/WindowServer/RunningBoard behavior, lock/orientation/process-death handling and full Dopamine/ElleKit compatibility cannot be claimed from this environment.

The next indispensable device gate is one0.8.3 foreground-Safari to NewTerm transition, its visible outcome and host-0.8.3.json. No automatic install/respring is performed. No repeated tests on the already understood0.8.2 transition are needed.

Recovery remains manual X or the15-second timeout, with /var/mobile/.ppo_disable checked for active/new trials and overlay startup. If SpringBoard injection prevents startup, boot Dopamine without tweak injection and remove only this package. Complete compatibility and final-candidate status remain false until broader actual-device evidence exists.
