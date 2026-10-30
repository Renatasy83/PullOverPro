# Own-presenter visibility propagation — 0.8.3

This is a controlled functional candidate, not confirmed background hosting or a final release. On the device-tested0.8.2 path, Safari source layers changed from2 to0 when settingsBackgrounded became true, while the FBScene and PPO presenter still reported active. No rendering repair is established by those flags.

## Exact firmware evidence and ownership

The inspected images come from the already digest-verified iPhone12,5 iOS26.0.1 build23A355 firmware. Production still requires all three existing loaded-framework UUID matches before creating a presenter. No Apple binary is added to source or the DEB.

- UIScenePresentationContext's default initializer block at0x188d14484 sets visibility propagation toNO. This is a default observation, not proof of every runtime presenter's effective value.
- _UIScenePresenter.modifyPresentationContext: at0x1897a44a4 obtains a mutable copy of its current context, synchronously invokes the supplied block once with the copy in x1 at0x1897a4510..4518, copies the result into its own context property and updates its own view. It does not modify the presentation manager's shared default context.
- UIScenePresentationContext.mutableCopyWithZone: at0x1897b5b80 creates UIMutableScenePresentationContext. The initializer at0x1897b4a64 obtains a mutable copy of the underlying settings while preserving only a reference to the default context as fallback. _setVisibilityPropagationEnabled: at0x1897b6f70 writes the Boolean into the copied settings key0xc via setFlag:forSetting:. It does not write a layer mask or app-scene foreground property.
- _UIScenePresentationView initialization at0x1897a2914 configures its inherited visibility interaction from its presenter context. The context-update path at0x1897a3838..3874 updates that interaction when the context changes.
- The visibility interaction's processing path at0x188ad4ce0 uses BSServiceConnectionEndpointInjector. Its configuration block at0x188ad5018 constructs RBSHereditaryGrant with __UISVisibilityNamespace and the source environment, and supplies it to the injector. Target/environment loss invalidates the stored injector. This establishes a scoped visibility-inheritance path, not a proven guarantee that Safari continues supplying render layers while its scene is backgrounded.
- _UIScenePresentationView.invalidate at0x188d43a4c removes its observations and clears its own interaction's target at0x188d43abc..ae4. PPO continues detaching only its own UI and invalidating only its newly created presenter. No old scene settings snapshot is restored and no foreign scene/presenter is invalidated.

The raw presenter setVisibilityPropagationEnabled: at0x1897a5090 merely writes a field. The port uses the copied presentation context operation above, not that unrelated raw setter or a shared-manager default update.

## Candidate behavior and failure boundaries

After preparation and before activation, PPO checks declared method tables for the current own presenter and its context. Object/Boolean getter encodings, the void block argument encoding(@?) and the void Boolean setter encoding(B) must match exactly. No dynamic resolution, KVC or presumed IMP is used. The callback must be main-thread, synchronous, exactly once, and receive the expected mutable class with a distinct identity from the original context. Before and after reads validate context classes and the Boolean getter. Already-enabled own contexts need no mutation; successful configuration is not retried.

A missing class/ABI, unexpected object, failed readback or Objective-C exception closes only the owned presenter. Unknown invalidation remains poisoned/retained under the existing session gate. A retained or late callback is ignored without a setter call; worker callbacks return before accessing main-thread callback state. Mixed off-thread and valid synchronous callbacks are not claimed to be fully detected. Successful readback records visibilityPropagationConfigured=true as a historical configuration result. visibilityPropagationInitiallyEnabled records the actual pre-configuration Boolean (null if unavailable), so an already-enabled/no-change operation can be distinguished from a new request. Neither flag establishes grant delivery, effective process state, pixels, input ownership or keyboard focus.

The report is schema6 at /var/mobile/Library/Logs/PullOverPro/host-0.8.3.json. Existing source-layer reads, bounded transition samples,15-second timeout, disable marker, lock/host-inactive stops and manual X remain. Only Safari and Settings are allowed. Nothing is hosted automatically on install/respring.

## Alternatives rejected during review

The complete SBAppViewController is not used as a shortcut. Exact SpringBoard code setsHostedSecureApp:YES/NO on an existing handle, creates application/workspace transactions with geometry/layout effects, and can call setForeground:NO during deactivation. Those broad effects do not establish a safe own-token rollback when the user changes the foreground app. No app-protection visibility assertion, jetsam/activity enum guess, scene foreground setter, event-deferral API or shared security flag is enabled.

## Validation and indispensable live gate

Native fixtures check the adapter's own-copy boundary, declared ABI rejection, zero/double/late/worker callbacks, wrong context, exceptions before/after mutation, readback failure, reentrancy, thread rejection, repeated cycles and uncertain cleanup. They cannot reproduce UIKit/RunningBoard visibility delivery. CI must also pass Clang analysis, existing ownership/mailbox suites, rootless Theos build and package/architecture/license inspection before device recommendation.

After successful automation, the necessary device observation is one foreground-Safari to NewTerm transition using this candidate and the resulting host-0.8.3.json. No success is assumed in advance; both visible content and report source layers matter. No installation/respring is performed by the agent. Recovery remains X or the15-second timeout; /var/mobile/.ppo_disable stops new trials/overlay startup and is checked by the active trial. If injection causes a startup problem, boot Dopamine without tweak injection and remove only this package. Main and stable references remain intact. Full Dopamine/ElleKit compatibility, lock/orientation/process-death stress and all-app support remain unverified.


## Executed automated result

Executable source1e2fc59dd5659451ed63618093b0308d12f44e25 completed Actions run41023747037 successfully. The new visibility-context suite passed613 checks under native ASan/UBSan, including100 configure/activate/close cycles with fake receivers. Existing presenter342, geometry1027, session-slot229 and layer-probe229 checks passed, alongside lifecycle, inventory, launch ABI, process, protocol, IO, service and actual fake-workspace subprocess suites. iOS Clang static analysis, rootless Theos compilation, arm64/arm64e binary inspection, payload/lifecycle/license checks and validation-report generation passed. Only the existing obsolete -multiply_defined linker warnings were recorded.

Artifact12962158828 contains the0.8.3~dev.visibility1 DEB, diagnostic logs and VALIDATION.md/VALIDATION.json. No device installation, effective visibility grant, restored background rendering or complete Dopamine/ElleKit compatibility was tested in this run. This candidate reaches the indispensable live transition gate described above. No executable change was made after this successful source build.
