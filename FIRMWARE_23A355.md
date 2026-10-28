# Exact firmware research: iPhone12,5 / 23A355

Public Apple BuildManifest identifies iOS26.0.1 build23A355 and iPhone12,5 (d431ap). Only SystemOS member043-93952-010.dmg.aea was range-downloaded; the whole IPSW was not downloaded.

- Encrypted member size:1,879,048,192 bytes; ZIP CRC32:2246500967, verified.
- AEA decryption succeeded using ipsw3.1.739 on Linux.
- Decrypted image size:4,863,295,488 bytes.
- Decrypted SHA384:1535b620015aa6d1ad28787a286c710aba1fdcd6674fb63067ec25370466c5bf040d0959b0e9a0a9c3af6406494ac014, matching Apple's BuildManifest Digest. The manifest digest applies to the decrypted image, not the encrypted archive member.
- APFS volume:Luck23A355.D421D431SystemCryptex.

Apple source: https://updates.cdn-apple.com/2025FallFCS/fullrestores/093-44804/921E3C8D-1CE1-4C74-899F-2829E5C29E9D/iPhone12,3,iPhone12,5_26.0.1_23A355_Restore.ipsw

## Extraction

The Go APFS reader rejected the sealed/headerless root B-tree. Built sgan81/apfs-fuse ApfsLib at66b86bd525e8cb90f9012543be89b1f092b75cf3, plus a small local read-only extraction wrapper, without FUSE mounting or global installation. Compressed files require com.apple.decmpfs decoding; four linkedit/symbol files have an empty data stream but nonempty compressed content. All cache files were extracted from /System/Library/Caches/com.apple.dyld. No Apple binaries are included in this repository or tweak package.

## Binary evidence

- FrontBoard version1000.0.1.0.0, UUID ED43ADA7-7107-3242-928F-09708F2FD9F3.
- UIKitCore version9088.1.114.0.0, UUID C98EAB32-B273-3430-B0C5-46522C904CBB.
- FBSceneManager has enumerateScenesWithBlock: at unslid address0x1a8419a94 and scenesPassingTest: at0x1a8419bb8. Its method list does not expose a general workspace getter; _workspace is an ivar.
- Disassembly of enumerateScenesWithBlock: shows the callback invoked with the current collection element in x1 and a stack-byte pointer in x2. The byte is cleared before invocation and bit0 checked afterward to stop enumeration. This supports the candidate callback shape void (^)(id scene, BOOL *stop), rather than guessing a single-argument callback from the erased header. This is static evidence, not runtime validation.
- UIKitCore contains _UISceneLayerHostContainerView, UIScenePresentationManager and _UIScenePresenter in this exact firmware.

## Limits

These results establish firmware provenance and inspectable implementation details. They do not establish the actual device's loaded UUIDs, scene adoption ownership, presenter side effects, input routing or correct teardown. No new private scene calls were enabled and floating application hosting remains unimplemented. Dopamine/ElleKit compatibility remains unconfirmed. Next analysis should correlate exact getter/initializer encodings and presenter lifecycle implementations before deciding whether a hosting adapter can be safely implemented.

## Reproducible scene audit

`scripts/audit-firmware-scenes.py` extracts declarations from an existing cache using ipsw and checks the exact FrontBoard/UIKitCore UUIDs before producing its report. Executed on the extracted23A355 cache:334 declarations recorded, all explicitly not runtime-validated. Apple binaries and declaration dumps are not included in this repository.

Usage:

```sh
python3 scripts/audit-firmware-scenes.py --ipsw-tool /path/to/ipsw --cache /path/to/dyld_shared_cache_arm64e --output /path/to/audit-output
```

The UIKitCore dump exposes `uiPresentationManager` at0x1889e6d08 under a category reported as NSObject. Disassembly shows a guarded lookup and lazy retained association. Its valid concrete receiver still needs correlation; the category name alone does not prove FBScene or arbitrary NSObject is acceptable.

`_UIScenePresenter activate` at0x188ad5494 delegates to its owner through `_activatePresenter:`. `invalidate` at0x188d43cd8 sets its invalidated flag, calls `updateHostingStateIfNecessary`, updates its view and delegates `_invalidatePresenter:`. The owner maintains a separate active-prioritized-presenter state. These are not passive view-only operations. Restoration of SpringBoard's existing presentation, focus and foreground policy remains unverified.

No private hosting calls were activated. Remaining work: concrete receiver verification, presenter priority/teardown semantics and input/foreground lifecycle, followed by target runtime validation.

## Presentation-manager receiver correlation

Additional exact-cache correlation: uiPresentationManager's guard loads the class reference at0x1e6b9fca0. `ipsw dyld dump ... --addr --count1` resolves that reference to0x1ed81f6c0, the FBScene class address in the FrontBoard verbose metadata. This resolves the earlier uncertainty about the class constant used in the receiver guard; it supports FBScene as the intended receiver rather than arbitrary NSObject. It does not by itself validate invoking the getter on the live device, presenter creation, activation side effects or teardown. The scene-0.7.0 device report now independently confirms a unique Safari FBScene and matching loaded framework UUIDs; it did not invoke this presentation-manager getter.
