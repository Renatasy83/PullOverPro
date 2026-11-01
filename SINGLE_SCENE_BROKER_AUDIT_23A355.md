# Exact 23A355 existing-scene ownership / host-view audit

Read-only investigation against `/workspace/firmware-research/dyld/dyld_shared_cache_arm64e` and its original extracted subcaches. No source, firmware, phone, or GitHub mutation. No new firmware download. Temporary text/helper outputs only under `/tmp`. This note records static contracts, not runtime compatibility.

## Conclusion

There is a distinct, per-view presentation object with releasable presenter ownership. It does not establish live hosting for an ordinary application whose background scene has stopped producing content. The actual device view factory also changes the original scene's snapshotting UI settings, and the inspected release path does not establish restoring differing previous IDs. Therefore neither manager transfer nor the normal device host-view factory is ready to enable single-scene applications.

## Manager transfer: explicit global state migration, no lease

`SBSceneManager -transferOwnershipOfSceneWithIdentity:toSceneManager:` = 0x21d6d2f2c. Exact declared binary method encoding `v32@0:8@16@24`.

Live-scene normal path:

1. Source `existingSceneHandleForSceneIdentity:` -> handle; handle `sceneIfExists` -> existing FBScene.
2. Source observers receive `sceneManager:willMoveScene:toSceneManager:` through block 0x21d6d340c.
3. Source `_prepareToRemoveScene:withReason:` with reason 1 at 0x21d6d30a8; implementation 0x21d6d843c invalidates pending snapshots and notifies external-foreground removal observers.
4. Source `_removeScene:withReason:1` at 0x21d6d30b8; implementation 0x21d6d85fc removes scene from all/daemon/workspace/pending sets, removes the handle, calls scene-reference `releaseForScene:`, removes bound scene, and calls presentation binder `removeScene:`.
5. Handle removal 0x21d6d86cc removes external/foreground tracking. Reason 1 removes both persistent and transient identity-map entries (0x21d6d8784-0x21d6d8798), unlike reason 0's transient retention/destroy callback path.
6. Destination `_addScene:` at 0x21d6d30c4. Implementation 0x21d6d8104 retains active/legacy scene references, can add to presentation binder, resolves/creates an application handle from an existing-scene request, installs identity-map entries, updates state/icon style and tracked scene sets. It may add an extension on an entitlement-dependent path; this is not simply moving an owned view.
7. Transfer compares destination display's current configuration to scene settings and calls existing scene `updateSettingsWithBlock:`. Block 0x21d6d3470 clears, or block 0x21d6d347c sets, `sb_setDisplayConfigurationForSceneManagers:`. Setter 0x21d8c2f20 writes transient-local setting 0x16a4.
8. Destination handle `setSceneManager:` then original handle `_noteReplacedWithSceneHandle:`. Base setter 0x21cf54d5c updates weak manager, clears cached display identity, and calls `_noteDidMoveFromSceneManager:`. Base replacement 0x21cf558fc notifies observers; device override 0x21da8fe08 also updates capturing-content state on the replacement.

No per-request token is returned, no saved original-state snapshot exists in this method, and no cancellation/rollback path is established by the inspected normal body. Reverse-transfer behavior and exception/disconnect restoration are not proved. It is not a safe acquisition primitive for PPO.

Evidence: `/tmp/ppo-transfer-annotated.asm`, `ppo-transfer-{prepare,remove,preparehandle,removehandle,addscene,replaced,moved,setdisplay}-annotated.asm`.

## Host-view factory and actual receiver class

- Base `SBApplicationSceneHandle` (0x28122bcc8) factory 0x21dcc4220 allocates `SBApplicationSceneView` (0x28122bc28).
- Actual device override `SBDeviceApplicationSceneHandle` (0x281229310), factory 0x21da90428, allocates `SBDeviceApplicationSceneView` (0x2812291d0).
- Both factory encodings: `@56@0:8{CGSize=dd}16q32q40@48`. This returns an object in the `new` retained method family.
- Base/application/device initializer encoding: `@64@0:8@16{CGSize=dd}24q40q48@56`. Initializers are 0x21cf51434 / 0x21dea0e38 / 0x21db53c80 respectively. Device initializer requires `isDeviceApplicationSceneHandle`.
- Requester protocol `SBSceneViewPresentationConfiguring` requires identifier/priority methods. Constructor sends `sceneViewPresentationPriority:self` at 0x21cf515ac and `sceneViewPresentationIdentifier:self` at 0x21cf515cc; nil requester yields priority 0.
- Identifier includes requester/view addresses and increasing counter; nil requester still gets a unique identifier. Constructor reads `sceneIfExists` at 0x21cf51668, not the potentially lifecycle-affecting `scene` getter.
- `sceneHandle:didCreateScene:` 0x21cf52878 obtains existing scene `uiPresentationManager`, creates a fresh `_UIScenePresenter` for that generated identifier/priority, and stores it in its own `_presenter`. Manager factory 0x1897b7a40 creates fresh presenter class 0x1ee656c88 and registers it inactive. No transferOwnership call in this path.

## Readiness, activation, and cleanup

- `_enableHostingIfPossible` 0x21cf4d814 -> `_recheckLiveContentDependencies` 0x21cf4d86c checks requested/effective display mode and handle `isContentReady`.
- Base handle readiness 0x21cf4cf64 is exactly `contentState == 2`. Handle contentState 0x21cf4ce24 forwards existing scene.contentState or returns 0 if absent.
- Readiness block 0x21cf537f8 -> `_configureLiveHostView` 0x21cf4ce7c rechecks readiness, obtains own presenter.presentationView, configures view, activates that presenter at 0x21cf4cf08. No direct FBScene activation or foreground setter appears in these concrete paths. The numeric display-mode predicates were observed, not promoted to a guessed named enum.
- Base view invalidate 0x21cf52230 is idempotent, removes own presenter/resources/views/observer; dealloc 0x21cf516e8 unregisters observer and invalidates only its presenter.
- Presenter invalidate 0x188d43cd8 -> owner `_invalidatePresenter:` 0x1897a59cc removes only that presenter. `_updateActivePrioritizedPresenterIfNecessary` 0x188ad54f8 picks remaining active array.lastObject and swaps presentation containers. This is live arbitration, conditional on other presenters remaining active; it is not historical-state restoration. No original FBScene invalidation in this path.

This is a bounded presentation-ownership contract, not proof of background client execution, render contexts, keyboard/event focus, or ordinary single-scene client admission.

## Actual device subclass: snapshot-settings release gap

Device initializer adds own status/placeholder/background objects, inspectors, handle-block observer and settings/notification observers. Device invalidate 0x21db5512c clears/invalidate its own observer/inspectors/classic accessory then calls superclass.

Device `_configureSceneLiveHostView:` 0x21db56a04 additionally acquires `_sceneHostingInfoForSnapshottingAssertionWithView:` 0x21da90094. Exact token factory encoding `@24@0:8@16`. Its token captures host window context ID and layer render ID. Add 0x21da902ac makes it the current assertion and updates with force YES.

Updater 0x21da8ff28 calls existing scene `updateUISettingsWithBlock:`. Block 0x21da90038 calls `setHostContextIdentifierForSnapshotting:` and `setScenePresenterRenderIdentifierForSnapshotting:` on scene mutable UI settings. These are changes to the original scene.

Device `_invalidateSceneLiveHostView:` 0x21db56ad8 invalidates only its own snapshot token. Invalidation callback 0x21da90250 removes only its token through `_removeSnapshottingInfoAssertion:` 0x21da90354. If current, removal selects remaining array.lastObject and passes that replacement token to updater with force NO at 0x21da903f8.

Important exact release condition: force NO path 0x21da8fff4 checks current scene snapshot context equals the passed replacement token's context; then 0x21da90008 checks render ID equality. Only equality of both returns to the writing block. When prior/replacement IDs differ from the currently installed own IDs, this inspected path skips. Therefore token-list restoration does not establish restoration of differing previous scene snapshot IDs. No guessed compensating setters are justified.

Evidence: `/tmp/ppo-device-snapshot-{update,remove}.asm`, `/tmp/ppo-devscene-{factory,init,invalidate,hostconfigure,hostinvalidate,snapshotassert}.asm`, `/tmp/ppo-uipresenter-invalidate.asm`, `/tmp/ppo-uiowner-{invalidateone,updateactive}.asm`.

## Remaining exact boundary

A single-scene implementation needs a verified system contract that keeps the existing application scene supplying live content while its owned external presentation is active, with abort/disconnect/close restoration. The examined factory only waits for ready content. Manager transfer migrates foreign global state; the device host factory changes snapshot settings. Neither establishes that missing rendering/admission lease. Existing `render-retention-audit.md` also found no rendering guarantee from focal activity alone. No static eligibility widening or new phone beta follows from these findings.

Read-only helper `/tmp/ppo_cache_read.py` maps existing dyld subcache headers and resolves ObjC selector stubs. Modern relative selector names require the runtime selector base; matching IMP addresses and relative type pointers was used for encodings. Full ipsw symbol annotation is unsuitable here (memory exhaustion); bounded `--quiet` disassembly succeeded.


This route is not enabled in the port. The separate0.16.0 programmatic candidate requires explicit multiple-scene support; it does not use manager transfer or these device host views.
