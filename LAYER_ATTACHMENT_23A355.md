# Layer attachment investigation —23A355

## Observed0.8.1 result

Safari and Settings still show black content. The supplied JSON has valid visible geometry and current active/hosting/noninvalidated samples through750ms. The wrapper uses actual native geometry without a fallback. Both successful sessions close cleanly; the initial no-scene Safari attempt is a separate, safely refused lookup.

The recorded full descendant tree has only _UIScenePresentationView, _UISceneLayerHostContainerView and an empty _UITouchPassthroughView. There is no recorded context-host view. The8-node capture limit is not hiding a larger reported tree here: only3 nodes are recorded, with child counts1,1,0 and the leaf's layer-child count0.

This is evidence about the captured tree, not proof that the application has no render contexts. The source scene's layers and presentation filters are not in the runtime report. Missing source layers, filter selection, background/client state and other attachment causes must remain unconfirmed.

## Static path inspected

Inspected the same digest-verified23A355 dyld cache and pinned FrontBoard/UIKitCore UUIDs.

- _UISceneLayerHostContainerView::_filteredLayersToPresent at0x1889cd348 obtains the scene's layer manager through objc_msgSend$layerManager (stub0x18ac66f80), then its layers through objc_msgSend$layers (stub0x18ac67160). The method also reads _exclusiveLayerTargetsToInclude (stub0x18ab70ee0) and performs target/filter work.
- FBScene::layerManager at0x1a83da764 and FBSceneLayerManager::layers at0x1a83da774 are cached object-field getters in the inspected implementation. The latter is declared NSOrderedSet.
- FBSceneLayer declares type(long long), contextID(unsigned int) and renderID(unsigned long long). Their presence does not establish current values.
- UIScenePresentationContext::presentedLayerTypes at0x1889d9eb4 reads settings/default-context state. It is declared unsigned long long. Do not invent a mask or use all bits without establishing the actual layer/filter contract.
- _UISceneLayerHostContainerView::hostedLayers at0x18979f908 has a delegated/own-container path. Its returned set must not be inferred solely from presenter.isHosting.

No new runtime getter, setter, priority change, scene-foreground update, security setting or event-deferral operation was enabled for this investigation.

## Next discriminating observation, existing build

Keep Safari full-screen and open its small PPO window without switching to NewTerm first.0.8.1 supports explicit reopening after confirmed cleanup, so no reinstall/respring is required just for this observation.

If the small window renders there but not over NewTerm, the failure is conditional on the background arrangement; that still does not identify the exact process/layer/filter policy. If it remains black over foreground Safari as well, the issue is not restricted to that arrangement. Record the result before choosing an additional private inspection or a functional mutation.

A compatible live target is required for this observation. Native geometry/ownership tests and binary disassembly cannot reproduce actual WindowServer/client rendering state in the current execution environment.


## Follow-up:0.8.1 renders over foreground Safari

On the same installed0.8.1 build, the user explicitly answered that the small PPO window displays content when Safari stays full-screen underneath, without switching to NewTerm. This contrasts with the earlier black-content observations over the other-app arrangement. It establishes rendering in this foreground-Safari condition, not a general rendering fix or independent background execution.

The earlier host-0.8.1.json was captured for the black sessions and must not be presented as instrumentation of this later successful observation. Obtain the report generated after this successful operation to compare the same build's descendant tree and sampled presenter state. No package installation or respring is needed for this comparison.

The source comparison against the user-confirmed0.7.2 baseline shows the presenter creation/activation and unique-scene selection paths unchanged;0.8.1 adds read-only presenter state sampling, while wrapper geometry, session lifecycle, UI and reporting changed. None of those differences alone proves the cause. In particular, foreground rendering does not demonstrate that a specific background assertion, foreground flag, layer mask or priority mutation is required or safe.

Main and every stable branch remain unchanged. No new private runtime call or executable change was made for this observation.


## Paired runtime report received: context-host views differ on the same build

The later supplied host-0.8.1.json contains five sessions. Its first three session dictionaries are exactly equal to those in the earlier black-window report; they are retained history, not three additional tests. The two new Safari sessions select the same Safari scene identifier as the earlier black Safari session, with matching framework UUIDs. Their close reasons are timeout (approximately15.049 seconds from prepare-requested) and manual (approximately14.471 seconds). Both end closed, invalidateReturned=true, owned=false and poisoned=false.

In each new session, from activate-returned through the750ms sample, the recorded descendant tree contains five nodes: _UIScenePresentationView, _UISceneLayerHostContainerView, _UITouchPassthroughView, then two _UIContextLayerHostView children backed by CALayerHost. The earlier successful-activation black sessions contain only the first three nodes, with no context-host children. No capture-limit truncation explains this difference.

The recorded ancestor geometry is equal between the black Safari session and both new Safari sessions: private view414x896, wrapper scale0.48660714285714285, own window300x480 at57,60. Current active=true/hosting=true/invalidated=false samples occur in both outcomes. These values therefore cannot discriminate rendered content. The report itself does not record the target application's foreground state; association of the later successful observations with foreground Safari comes from the user's separate explicit answer. No visual outcome is assigned to the second new session solely from its JSON.

This establishes an attachment-tree difference and repeatable owned-presenter cleanup in this sample, not the upstream reason for missing context-host layers. Source FBScene layer counts, layer filters, process state and policy remain uninstrumented. The same selected scene identifier and retained earlier session history argue against needing a different build/respring just to attach layers in the foreground condition, but do not establish app-process identity or guaranteed background operation.

The original project's ContextHostManager.mm was rechecked: its iOS13 hosting path calls forceApplicationForegroundForBundleId before reading scene layers; that method uses KVC _mutableSettings, setForeground:YES and updateSettings:withTransitionContext:completion:. Close unconditionally writes foreground=false. This is historical design evidence, not a verified iOS26 lifecycle contract. No original KVC/foreground mutation, presumed layer mask, priority or process assertion was copied into the port.

Next live discriminator can use the installed build: create the visible small Safari window while full-screen Safari is underneath, then switch to NewTerm before the15-second timeout. Distinguish retained content, black content and automatic close rather than treating those outcomes as equivalent. This is a real UIKit/client lifecycle observation and cannot be simulated by the present native fixture tests. No new package is required. No executable change or new build was made for this evidence update.


## Observed transition: visible Safari becomes black over NewTerm

The user performed the existing-build transition on0.8.1: open the small window over full-screen Safari, then switch to NewTerm before timeout. The small PPO window remains open but becomes black. This is a within-session visual observation of content loss on the app switch, not a failure to create PPO's window. No transition JSON was supplied, so the earlier750ms samples must not be represented as samples of this switch or as proof that source layers were removed at that instant.

Combined with the paired reports, this prioritizes the target scene/client foreground-to-background lifecycle and layer availability/attachment path. It does not establish process suspension, a particular assertion requirement, security/injection policy or filter mask. The cause remains unconfirmed. Existing0.7.2 cross-app success is retained as a historical user observation; its earlier report did not instrument that background arrangement, and it cannot establish which state differed.

No additional installation or blind foreground/priority mutation is justified by this observation. Before a functional change, the next instrumentation must distinguish source scene/layer state from hosted-view state across the same transition, use verified encodings and declared method-table checks, remain bounded/main-thread, and add native rejection/exception fixtures. A run-time dependency or full compatibility claim must not be derived from a successful build.

Static follow-up inspected FBScene updateSettings:withTransitionContext:completion: at0x1a842b00c in the pinned23A355 FrontBoard image. The method performs nontrivial work, including a settings getter and diffFromSettings:toSettings: dispatch (stubs0x1a849bbe0 and0x1a8496300). Presence of this method and the original project's usage do not establish reversible ownership of scene settings or a safe background-hosting contract. No settings setter or update callback was invoked or enabled in the port.

This update changes documentation only. Main/stable source and the installed executable remain unchanged; no new CI runtime-validation claim is made.
