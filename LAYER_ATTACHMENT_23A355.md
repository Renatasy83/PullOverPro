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
