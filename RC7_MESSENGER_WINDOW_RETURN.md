# RC7 conditional Messenger window return

Candidate1.0.6~rc7. This targets return of the app UI after the timed window closes; it does not promise simultaneous copies of Messenger UI or a complete black-background fix. Source/run/hash/download are recorded in OPENCODE_HANDOFF.md after final validation.

## Actual RC6 result

User confirms small-window Messenger content, touch, scrolling and other interaction. The original full-screen surface became black and stayed black after automatic close, requiring the user to exit the app. One supplied session lasted15.0341385seconds from window-shown to close-returned, reason timeout. The child proxy matched the created scene and not the original. Owned layers changed0→1, original samples reported2layers/active/not-backgrounded. Own controller/workspace invalidation returned; owner closed/unpinned/unpoisoned and replacementAllowed=true. These confirm scoped content/input and own-object cleanup; layer metadata does not prove the original view is visible. The exact UIWindow/root migration pattern is still unverified.

## Separate exact-profile app component

The original SpringBoard injection filter stays SpringBoard-only. A second hookless PPOMessengerReturnAgent dylib has its own com.facebook.Messenger-only filter. It runs only after checking the existing reviewed585.0.0/build1101076820 Info.plist SHA256 and exact UIKitCore UUID. It uses public UIKit, Foundation, dyld metadata and libnotify APIs; no guessed private selector, app bundle modification, Data-container write, screenshot/snapshot, key-window/focus request or direct FBScene operation. No other app receives this component.

On Messenger's main thread it captures one normal-level ordinary foreground key UIWindow and its root/scene as weak references. Before any PPO scene appears, a legitimate app root replacement can update the baseline. Once a PPO session is observed, it freezes that identity. A migration is recognized only when the exact same original window/root belongs to a distinct normal-role session named com.renatasy83.ppo.scene.UUID.

UIKit23A355 _persistenceIdentifierForScene at0x18916e358 prefers UI persistenceIdentifier and otherwise FBScene.identifier. Thus a matching public session prefix is NOT assumed: an unmatched name refuses the restoration. Likewise a different window/root, disconnected original scene, different screen or unknown migration pattern refuses arbitrary reparenting.

After that exact PPO session's public disconnect notification, the agent waits one main-queue turn for UIKit/app callbacks to unwind, then rechecks identity/root, target connection/role/screen and that the window still belongs to the closing scene or is detached. It uses the public UIWindow.windowScene setter to return only that exact window to its original scene and checks readback. Visibility is restored only with active app/target and protected data available; otherwise it remains hidden and visibility is deferred to a later safe activation. No key-window request or synthetic input is made. If the root disappears/changes or a setter fails, status is refused; no success is inferred.

The component does not recreate a deleted UIWindow/root/controller, duplicate the UI, recover unknown window transfers or force another app's focus. The black original surface DURING an active trial can remain if only one app window supplies content. The principal real-device gate is the original UI AFTER closure.

## Limits, telemetry and host behavior

Only bounded phase/flags/uptime are published through a named libnotify state. No pointers, app text/pixels, scene IDs or app files cross this channel. The SpringBoard side requires a fresh captured readiness state before starting another reviewed Messenger trial. A consumed, missing, stale or unavailable companion prevents the old unprotected trial; it does not imply that Messenger became incompatible. Sandbox delivery/state access is a device gate, not presumed because the code compiles.

Phase0=waiting,1=captured,2=migrated,3=returned/readback-verified,4=refused. Flags1=primary captured,2=owned scope seen,4=matching migration,8=return readback,16=root/window mismatch,32=visibility deferred,64=exception,128=unsupported/uncertain pattern. A logical return/readback does not prove restored pixels/input. Readiness expires after30seconds and is consumed after an owned session is seen. One app process does not silently reset to authorize repeated experiments.

Public notification observers are idle between events. A read-only timer, if needed while a recognized PPO scene is active, is bounded to20seconds and stopped at disconnect. Existing RC6 exact installed profile, normal foreground source/layers, no cold fallback, ownership/proxy/ABI/framework/lock controls,15second maximum,8second child-render deadline, no Keep/resize/minimize/pan and cleanup/quarantine remain. The root records helper states before and after cleanup, with three read-only delayed observations; no automatic app relaunch or scene retry.

The server-side borrowedSourceMutationRequested=false field continues to describe the owner adapter's FBScene operations. The new helper intentionally reassigns its own app UIWindow through public UIKit; that action is separately represented by helper phase/flags, not concealed by the older field.

## Automated and actual limits

The new pure transition/transport suite has168 checks locally under ASan/UBSan: capture/migration order, foreign scope, identity/root changes, every restoration gate, terminal/replay refusal, failed readback, clock/expiry/schema corruption. Existing36 suites remain. CI analyzes both new components, compiles both tweak targets and checks the exact separate filters/rootless payload and both architectures. Final results are in the handoff/validation report.

These fixtures do not run Messenger, UIKit window movement or actual libnotify sandbox transport. Public session mapping, notification delivery/order, same-window migration, protected visibility, real return/input and the black-background outcome remain untested until the new phone report. No full Dopamine/ElleKit or Messenger compatibility claim follows from a build. No compatible physical Apple Silicon Mac is available for vphone-cli.

## Only necessary phone gate

After manual install and one manual respring, close Messenger once from the app switcher and reopen it normally. This is required to load the NEW app-filtered library; a respring alone may leave Messenger's old process alive. Do not kill it through a script, delete data or modify its bundle. Open the PPO trial promptly after Messenger is visible so the initial readiness is fresh.

Run one timed Messenger window. Existing small-window content/input need no broad retest. Let it close automatically, wait about two seconds, then observe whether the original full-screen Messenger UI has returned and responds. Send /var/mobile/Library/Logs/PullOverPro/host-1.0.6.json plus that visual result. The background can still be black while the small window is active; report that separately from the after-close result.

If it refuses with a helper-readiness message, stop rather than repeat old trials: send host-1.0.6.json. If verification fails earlier, send capability-1.0.6.json. No repeated reinstall/respring/service restart loop, unrelated-app tests, chat sending or Data-container collection is requested. A missing/unsupported helper state is useful evidence.

Recovery: /var/mobile/.ppo_disable plus manual respring, or the known reboot/Dopamine-without-injection/uninstall-only-PPO route if SpringBoard is unusable. Disabling injection also disables the Messenger component. Prior RC6 content/input candidate remains archived, with its original-UI restoration defect explicitly retained; RC5 read-only and older stable/recovery/main are also preserved. Original GPL-3.0/c1d3r attribution and license remain in the package. No automatic phone action was performed.
