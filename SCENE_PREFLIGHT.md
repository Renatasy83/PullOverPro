# Read-only scene selection gate

The panel-to-service Safari launch is confirmed by the user on0.6.1. That source is preserved in `stable/verified-safari-launch`; main and the older picker baseline are untouched.

0.7.0 adds a scene preflight to the explicit **Diagnostic API** tap. It does not inspect scenes at injection, respring, panel opening or app launch. The tap runs at most once per SpringBoard process. It inspects only Safari; all other selections produce a report without private scene calls.

Before scene access the production wrapper checks the three loaded framework UUIDs against exact23A355 FrontBoard, FrontBoardServices and UIKitCore identities. Method inspection reads declared method tables without invoking dynamic method resolution. It checks the emergency-disable marker and rejects missing/incorrect method ABIs. Signature validation alone does not establish that hooks are absent or that object state/lifecycle is compatible.

Selection uses FBSceneManager.sharedInstance and enumerateScenesWithBlock:. The callback shape is grounded in the exact firmware implementation (scene argument and local stop-byte pointer). Only ordinary +0 getters are invoked: clientHandle/bundleIdentifier and definition/clientIdentity/bundleIdentifier, plus the scene identifier. Both identities must match exactly. Ambiguous scenes, invalid objects, missing getters, exceptions, over256 callbacks or exceeded cooperative100ms budget produce no selected identifier. System scenes with no client handle/application identifier are skipped. The time budget cannot preempt a stalled private getter or external hook; no claim of guaranteed SpringBoard safety is made.

No scene/presenter is created, activated, resized, destroyed or invalidated. No KVC, ivar access, method replacement, foreground mutation, app termination or new process creation occurs in SpringBoard. Only snapshot dictionaries leave the main-thread inspection; report I/O runs on a worker.

The report is `/var/mobile/Library/Logs/PullOverPro/scene-0.7.0.json`. It contains expected/observed UUIDs, selector encodings and the selected scene identifier if unique. It does not dump all installed apps or scene contents. Existing historical metadata output is retained separately.

## Automated versus device validation

Native macOS fixtures exercise exact and conflicting identities, substring rejection, duplicate/multiple matches, nil system identities, bad getter/block ABI, wrong factory objects, unexpected scene objects, callback limits, exceptions and thread refusal. The production wrapper refuses macOS framework identities. These tests never invoke private iOS methods.

Clang analysis, Theos rootless build and payload inspection are required before a device test. At the next gate the actual device must confirm loaded UUIDs, the runtime selector encodings and whether Safari has a unique matching scene. Those observations cannot be produced by the Linux firmware image or macOS fixture objects.

For that gate only: keep the working0.6.1 DEB, install the verified preflight build and respring after successful configuration. Open the app list and select Safari; launch Safari from PPO, then open PPO over Safari and tap Diagnostic API once. Return the scene JSON. A framework mismatch is a stop result, not an instruction to bypass the allowlist. Do not enable hosting based solely on a unique result.

Recovery: the existing `.ppo_disable` marker suppresses inspection and the overlay on next injection; forced reboot and Dopamine without injection permit removal of PPO's own package if SpringBoard becomes unresponsive. Nothing is automatically installed, resprung or deleted by the preflight action.
