# Source-independent owned-scene inputs — exact23A355

Read-only static audit for iPhone12,5 / iOS26.0.1 build23A355. No private method was executed, no phone was contacted and no production file was edited. Existing local cache/evidence was used. UIKitCore UUID C98EAB32-B273-3430-B0C5-46522C904CBB; FrontBoardServices CB9A7EAD-B91A-3F19-86F1-461027284416; FrontBoard ED43ADA7-7107-3242-928F-09708F2FD9F3. Runtime cold launch remains unconfirmed.

## Exact factories

| Receiver / method | Implementation | Encoding / ownership |
| --- | --- | --- |
| FBSSceneClientIdentity +identityForBundleID: |0x1a28c7278|@24@0:8@16; normal autoreleased factory (+0)|
| FBSSceneSpecification +specification, inherited by UIApplicationSceneSpecification |0x1a2865c9c|@16@0:8; objc_alloc_init(receiver), then objc_autoreleaseReturnValue (+0)|

The first selector is **identityForBundleID:**, not identityForApplicationIdentifier:. Exact method type bytes are at0x1a29355ed. FBSSceneClientIdentity metaclass is0x1ed6b61c8, its RO data0x1f1807c58 and class-method list0x1a2905fa8; the identityForBundleID entry's IMP resolves0x1a28c7278. The inherited specification class-method list0x1a2906338 resolves type bytes0x1a2935540 and IMP0x1a2865c9c. The normal UIApplicationSceneSpecification declares no class-method override for this factory.

The specification factory preserves its receiver, so sending it to the exact UIApplicationSceneSpecification class constructs that class, rather than the private hosting-spec subclass. Its body0x1a2865ca8 calls stub0x1a5347d00, which jumps to libobjc _objc_alloc_init0x180097b64. Its tail0x1a2865cc0 jumps through0x1a5347d40 to _objc_autoreleaseReturnValue0x180097814. Those symbol addresses were independently read from libobjc's own image symbol table, without whole-cache annotation.

UIApplicationSceneSpecification's inherited FBSSceneSpecification init0x1a28660fc calls NSObject init, then registers/obtains class metadata through helper0x1a2866158. No app/process identity is an input to this specification creation. Previously inspected exact-class methods still resolve normal application role at0x1889f4e90, UIWindowScene minimum at0x188a316f4, UIKit-managed true0x188a31648 and internal false0x188a31650. This does not authorize arbitrary specification subclasses.

## Identity does not require an already running app

identityForBundleID: retains/validates its argument and calls:

1. RBSProcessIdentity +identityForEmbeddedApplicationIdentifier: via stub0x1a293de40 at0x1a28c72ac.
2. FBSSceneClientIdentity +identityForProcessIdentity: via stub0x1a293df00 at0x1a28c72c8.

The first factory is0x18e63fcb8 in RunningBoardServices. It forwards to the auid variant0x18e63fcc0 with0, then to the existing embedded-app factory; RBSEmbeddedAppProcessIdentity _initEmbeddedAppWithBundleID:0x18e654fa4 forwards to _initEmbeddedApp:personaString:0x18e655030. That initializer explicitly writes PID0 at0x18e655094, copies bundle/persona strings, and builds the identity description/hash. No lookup of an existing FBScene or running app process occurs in the inspected constructor chain, and it does not itself launch the app.

FBSSceneClientIdentity +identityForProcessIdentity:0x1a28c731c compares with identityOfCurrentProcess. The current-process case uses localIdentity; otherwise defaultIdentityForProcessIdentity:0x1a28c73c8 forwards to identityForManagedEndpointOfProcessIdentity:0x1a28c7454. That allocates FBSSceneClientIdentity and initializes local=0, direct=1, the RBS process identity and nil description through _initWithLocal:direct:identity:description:0x1a28c74d4. The object copies/retains immutable identity data. isValid0x1a28641ac is local || processIdentity!=nil; it is not a running-process check. bundleIdentifier0x1a2871ef8 derives the identifier from the stored process identity.

These inputs are therefore structurally available without borrowing an existing scene's definition. They do not prove that a given installed client accepts the new scene or supplies rendered content.

## Preconditions and failure behavior

identityForBundleID: has asserting failure paths for nil input and nil RBS identity. The nil-result path reaches diagnostic helper0x1a28f9e78 and terminates through0x1a28f9f50..f58; it must not be presented as a catchable NSError-style factory. Use only a copied nonempty normalized app identifier, an explicitly fresh eligible installed-info descriptor and the existing critical-ID exclusions. A malformed/missing/stale/negative descriptor must refuse before either factory. No baseline-only or missing-helper fallback should authorize this new cold path.

Runtime method-table checks must still validate the actual class factory encodings, exact resulting identity/specification classes, bundleIdentifier readback and normal application role. The exact class factory has no original scene pointer or process handle parameter; it cannot be used to transfer an original scene. Factory absence/wrong encoding/wrong class/wrong identifier/role should refuse without a workspace/controller attempt.

The factories do not add an explicit main-thread assertion in the inspected code. That is not threading permission; keep all private construction on the existing main-thread owner path. NSObject/data-object allocation is not a proof of resource or process admission.

## Relation to the existing owner

_UISceneHostingControllerAdvancedConfiguration initWithClientIdentity:0x189905da8 stores the supplied identity and initializes defaults. Existing code can then assign its own newly allocated, initially empty FBSceneWorkspace, UUID scene identifier and the exact normal specification. It need not fabricate a definition object or call an app delegate itself.

_UISceneHostingController initWithAdvancedConfiguration:0x189b61a34 creates its own view and view controller, then invokes createSceneWithConfiguration:. The previously audited configuration block0x189b61e88 copies the configured identifier/specification/clientIdentity into the newly created definition. The existing child/workspace namespace, independent identity, proxy-to-created-child, inactive-before-public-attachment, own invalidation and quarantine guards remain essential.

For a source-independent request, telemetry should identify the fresh-factory mode and record that no original source was supplied. A nil source cannot provide evidence of a borrowed-source inequality check; ownership instead rests on the fresh empty workspace, exact UUID namespace, verified child definition and activation binding. The warm-source path can remain separate. Do not silently reinterpret an ambiguous/unsupported warm-source result as permission to bypass its guards.

## Cold activation follow-up

An independent narrow trace is examining the existing FBScene activateWithTransitionContext:completion: path0x1a84290c4 and helper0x1a842945c. Initial finding: when no clientProcessHandle/remnant exists, that helper derives definition.clientIdentity.processIdentity and calls the workspace process manager's _createProcessFutureWithExecutionContext:error: at0x1a8429840. This is framework-managed activation work, not an additional method PPO needs to call. Detailed launch/bootstrap trace is in /workspace/COLD_ACTIVATION_TRACE.md when completed.

Even with that structural path established, native fixtures cannot establish target entitlements, actual cold client connection, app-delegate selection, pixels/input, current activation grace timing or complete cold cleanup. A single actual cold-source-none device session, with the new preparation mode in its report, remains indispensable. Do not add guessed foreground/security/focus flags, manual Home transitions, suspended-launch retries or foreign settings mutations to make a cold test pass.

Local bounded disassembly files are /workspace/cold-identity-bundle.asm, cold-identity-init.asm, cold-specification-factory.asm, cold-specification-init.asm, cold-advancedcfg-init.asm, cold-controller-process-init.asm, cold-rbs-bundle-factory.asm, cold-rbs-embedded-factory.asm, cold-rbs-embedded-init.asm, cold-rbs-embedded-app-init.asm and cold-identity-failure.asm. Raw Apple bytes/dumps remain local and should not be committed with the port.

## Direct-launch condition independently completed

The exact RBSEmbeddedAppProcessIdentity override supportsLaunchingDirectly at0x18e6282b8 is `mov w0,#1; ret` in the cached RunningBoardServices image. The embedded identity created by the audited factory therefore satisfies the internal direct-launch gate traced in COLD_ACTIVATION_TRACE.md. PPO does not call this getter, bootstrap method or launch request itself. This remains static call-path evidence; cold on-device rendering/input still require a real gate.
