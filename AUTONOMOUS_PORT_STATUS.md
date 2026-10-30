# Autonomous port status — 2026-10-30

Current isolated candidate:0.9.0~dev.ownedscene1 on debug/owned-safari-scene. This is an incomplete Safari-only independent-scene trial, not a final release or confirmed Dopamine/ElleKit compatibility.

## Preserved references

main remains Alpha4 at af336d84a6b4812e6b6406af87803fb15bf29c3b. Existing picker/launch baselines remain. stable/verified-safari-over-newterm and stable/verified-safari-timeout preserve the previously user-tested0.7.2 source411cd127fa18005989d05f2aefff59b697ee1029. debug/autonomous-port retains the0.8.3 work. Original PullOver Pro attribution and GPL-3.0 remain.

## Device evidence driving the change

The target is iPhone12,5, iOS26.0.1 build23A355; Dopamine rootless is user-reported and ElleKit1.2 was shown on the phone. The exact Dopamine version is not recorded.

The user confirmed overlay/picker operation, Safari launching from the panel through the mobile file-mailbox service, and earlier Safari rendering/input observations.0.8.2 directly recorded source layer count2 to0 while settingsBackgrounded became true, with PPO window visible and presenter active/hosting still true.0.8.3 recorded visibility already enabled in two sessions, and a successful false-to-true context operation in another; background source layers remained absent. All three owned presenter cleanups completed. JSON is not a visual or input ownership trace. The historical watchdog root cause remains unconfirmed because the actual reports were not supplied. See DEVICE_VALIDATION.md.

## Independent scene architecture

Verified exact firmware manifests declare Safari supports multiple application scenes (BrowserWindowScene/BrowserSceneDelegateRouter), while Settings does not. The candidate therefore creates only a new Safari scene in a fresh empty random workspace. The original Safari scene supplies immutable identity/specification inputs and is never hosted, invalidated or mutated by this adapter. Before UIKit attachment, guards prove new pointer/namespace/client identity, component binding and inactive state. Native public child geometry precedes attachment; UIKit's own lifecycle/provider performs activation and settings updates for the new scene.

Uncertain private constructors remain strongly pinned because their automatic destruction can invalidate scene state. Cleanup invalidates only the verified owned controller, then requires invalid own scene and empty workspace before workspace invalidation. The UI remains bounded to15 seconds, cleanup polling to2 seconds, and uncertain cleanup blocks another attempt. The old borrowed-scene UI adapter is excluded from the production Makefile. No guessed foreground/security/mask/assertion mode or manual event-deferral operation is added.

See OWNED_SAFARI_SCENE_23A355.md for concrete static evidence, native test boundaries, normal destructor semantics and recovery. Report schema7:/var/mobile/Library/Logs/PullOverPro/host-0.9.0.json separates hosted-scene samples from original-scene samples.

## Completed automation and remaining live gate

Executable sourcea51c7cdfbb5515cff23f0ec29fc60dd29184f9a0 passed GitHub Actions run41116185796. New ownership tests573 checks with ASan/UBSan; existing suites, iOS Clang analysis, Theos rootless build, arm64/arm64e binary checks, package/lifecycle/license inspection and evidence generation passed. Artifact13005358295 contains DEB and full validation reports.

Local execution is Linux; Actions uses macOS Intel native mocks, not iOS SpringBoard/WindowServer. No compatible physical Apple Silicon Mac is accessible for vphone-cli; it was not used. Actual Safari scene admission/connection, pixels, input and client/process/session persistence cleanup remain untested for this candidate. All-app support, persistent windows, lock/orientation/process-death stress and full platform compatibility remain outstanding.

The indispensable next gate is one separate Safari trial over NewTerm plus visual outcome and host-0.9.0.json. No repeat of the already understood visibility-only experiment is requested. Nothing was installed or resprung automatically. Recovery is X/timeout, disabling new attempts with /var/mobile/.ppo_disable, and manual respring for quarantined resources. If injection prevents startup, boot Dopamine without injection and remove only this package. Personal data and other tweaks are not modified.
