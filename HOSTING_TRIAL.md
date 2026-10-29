# 0.7.1 Safari live-rendering gate

Input correction: subsequent0.7.2 device feedback showed scrolling while the same container flag was NO. Historical descriptions of this property as disabling remote touch are superseded by INPUT_REPORT_CORRECTION.md. It is not a verified input-blocking mechanism.

Historical trial: the user subsequently confirmed live Safari rendering and normal restoration after manual X-close. See DEVICE_VALIDATION.md. Current touch development and remaining test instructions are in TOUCH_TRIAL.md.

This is a development trial, not a final candidate or confirmed Dopamine/ElleKit compatibility. Stable baseline remains `stable/verified-safari-launch` at e22b2efab141fe31dfd7e39365ae42c7667fb116; main is untouched.

## What changed

An explicit `Probă fereastră Safari` button selects the unique existing Safari FBScene using the read path already exercised on the target phone. A separate adapter checks the exact three loaded framework UUIDs, declared method encodings and actual receiver types before obtaining `uiPresentationManager`, creating a uniquely named PPO presenter, reading its presentation view and activating it. No guessed priority, ivar/KVC access, scene mutation, app process termination, entitlements or new SpringBoard hooks are used.

The UIKit window has a draggable header and close button. It scales its own presentation view without changing Safari's scene geometry or foreground settings, does not become key, and sets the content container's interaction flag to NO. Subsequent feedback does not support treating that flag as a remote-input blocking guarantee. This is intended to display live application content, not a screenshot/demo; actual rendering is not yet demonstrated.

Only one manual attempt is allowed per SpringBoard process. Nothing is hosted automatically on install/respring or app launch. A 15-second main-queue timer closes it; disable-marker detection, host-scene deactivation/backgrounding and protected-data-unavailable notification also request cleanup. These mechanisms cannot interrupt a blocked private call and are not proof of lock-screen safety.

Only the newly created presenter bearing the exact PPO identifier may be invalidated. Never invalidate the FBScene, shared manager or any existing presenter. A view already attached elsewhere is refused. Unconfirmed cleanup poisons the session, retains its references, records failure and prevents retries. Successful `invalidate` plus `isInvalidated` is still not proof that SpringBoard restored its original visual presentation.

The report `/var/mobile/Library/Logs/PullOverPro/host-0.7.1.json` contains ordered lifecycle snapshots. `active`/`hosting` flags are diagnostic state, never a claim about visible pixels, input routing or restored system presentation. Writes are asynchronous; a hang can prevent a final snapshot from being written.

## Evidence and remaining device gate

The previous device report confirmed exact framework UUIDs and unique Safari selection (5 scenes, 1 match). It observed ABI metadata for manager creation/view/activate/invalidate; it did not call these operations. Additional bool state getters are guarded against the exact `_Bool` ABI from the 23A355 UIKitCore declarations and checked on each receiver before invocation.

Native Foundation fixtures exercise the actual presenter adapter against fake classes, including ownership refusal, ABI refusal before factory invocation, exceptions, idempotent cleanup, reentrancy, thread guards and invalidation failure. They do not load private iOS frameworks. CI additionally analyzes the UIKit trial, compiles both arm64/arm64e, inspects the rootless DEB, and runs the existing parser, protocol, filesystem, subprocess and package lifecycle suites.

A real jailbroken target is indispensable next: observe whether Safari appears live, whether closing/automatic close returns Safari and SpringBoard to normal, and whether the report records confirmed invalidation. Touch/keyboard routing, app background behavior, multi-app support, resizing scene geometry, orientation, app death and repeated stress remain unimplemented or unverified. No compatible accessible Apple Silicon Mac exists for vphone-cli; the Intel Actions build host is not a substitute for Dopamine/ElleKit runtime testing.

## Controlled test after CI passes

1. Charge the phone. Keep the previously tested 0.6.1 package available in Filza. Do not install an unverified CI artifact.
2. Install the single 0.7.1 artifact identified by the successful run and respring manually. The new hosting operation does not run during startup.
3. Select Safari and launch it through the existing PPO button. In PPO tap `Probă fereastră Safari` once. Observe content, header movement, close button and the automatic 15-second close. The container flag is NO; this is not proof that remote touch is blocked.
4. Share `host-0.7.1.json` and what appeared/restored. Do not retry if cleanup is unconfirmed. There is no need to run other intermediate commands or reinstall older diagnostic builds.

## Recovery

If the phone is responsive, create PPO's existing disable marker as mobile in NewTerm:

```sh
touch /var/mobile/.ppo_disable
```

This stops future bridge operations and is checked by the trial timer; it cannot revoke a private call already in progress. If SpringBoard hangs, force restart, enable Dopamine with tweak injection disabled, and uninstall only `com.renatasy83.pulloverpro.diagnostic` with Sileo (or `dpkg -r com.renatasy83.pulloverpro.diagnostic` as root). Reinstall the known 0.6.1 baseline only after recovery. No automatic respring, reboot, installation or personal-data removal is performed by this work.
