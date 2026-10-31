# Owned-scene component binding — 0.9.1

This changes only the ownership check after construction of the isolated Safari scene. It does not add foreground, security, process assertion or event-routing operations. The fresh workspace, source inequality, Safari client/role checks, inactive-before-attachment guard, 15-second trial and quarantined cleanup policy remain in force.

## Device evidence

The supplied host-0.9.0.json has one Safari trial and matching FrontBoard, FrontBoardServices and UIKitCore UUIDs. The new workspace and child identity/client/role checks passed. Preparation then stopped at unverified-controller-scene about25ms after the request. No PPO hosting window or view was attached, and no controller/workspace invalidation was attempted. The uncertain controller remains pinned and another trial is refused. The report does not distinguish a missing component, an unexpected component class or a different hostScene pointer; it cannot by itself prove which operand failed.

Do not repeat0.9.0. A manually initiated respring is required to discard its quarantined resources before a corrected trial. No respring or installation is performed automatically.

## Exact firmware finding

Static inspection uses the same iPhone12,5 iOS26.0.1 build23A355 cache and framework UUIDs documented in FIRMWARE_23A355.md. No Apple binary is included in the package or repository.

The controller stores a raw FBScene, but FrontBoard supplies a different object to its host components:

| Implementation | Address | Relevant behavior |
| --- | --- | --- |
| FBScene extension application | 0x1a842d3a0 | Allocates FBSComponentScene:NSProxy for the scene/extension |
| Proxy construction call | 0x1a842d4c8 | Passes the raw FBScene and extension to initWithScene:extension: |
| Host component construction call | 0x1a842d568 | Passes that proxy to initWithScene: |
| FBSSceneComponent.hostScene | 0x1a286b67c | Tests the stored object as FBScene and returns it without unwrapping |
| FBSComponentScene.isKindOfClass: | 0x1a2875bcc | Delegates the class test to its weak target |
| FBSComponentScene.class | 0x1a2871c80 | Presents its target's class |
| FBSComponentScene.scene | 0x1a2875a6c | Explicit getter loads and returns the weak underlying scene |

The hostScene class-name constant is exactly FBScene. Its imported calls were followed to NSClassFromString, objc_opt_isKindOfClass and retain helpers; misleading cross-image stub labels were not treated as evidence. Proxy initialization uses weak storage and the scene getter uses objc_loadWeakRetained followed by objc_autoreleaseReturnValue. FBScene.addExtension: applies its host-component changes synchronously through updateSettings:; an arbitrary delay is not a justified repair.

The old fixture returned the raw child from hostScene. Actual firmware can return the proxy, so the old pointer comparison rejects a correctly bound component. This is a concrete defect in the ownership model, although the0.9.0 report lacks the fields needed to confirm it was the observed operand.

## Corrected proof and diagnostics

Accept hostScene directly only if it is the already verified child pointer. Otherwise require object_getClass(result) to equal the validated FBSComponentScene class, verify that exact runtime method table declares scene with object return and only self/_cmd arguments, and require its returned target to equal the owned child. The getter is read-only in this exact firmware. Do not detect the proxy with class or isKindOfClass:, which it forwards. Unknown proxies, missing targets, source aliases, foreign targets and unsupported encodings fail closed without private cleanup on uncertain objects.

sceneHost.componentBinding captures a bounded status and nullable booleans during preparation. An unknown value remains null. Snapshots do not invoke private getters, publish addresses, serialize scene objects, or include page contents. Stages before each getter preserve useful evidence if it throws.

Native NSProxy fixtures reproduce the actual forwarded identity rather than only mirroring the adapter. They cover successful unwrapping, source/foreign/nil targets, unknown proxies, missing/wrong components, getter exceptions, unsupported ABI, pure snapshots, cleanup and100 normal cycles. These fixtures establish the adapter decision under controlled inputs; they do not execute FrontBoard, SpringBoard, Safari, Dopamine or ElleKit.

## Remaining device gate

Automation completed for executable source025cf5d835d4454c60c771fea19e17e60c126add in [Actions run41165469987](https://github.com/Renatasy83/PullOverPro/actions/runs/41165469987):702 native ownership checks with ASan/UBSan, all15 suites, iOS Clang analysis, Theos arm64/arm64e rootless packaging and payload/license/lifecycle inspection passed. The downloaded artifact and DEB hashes were checked and local package inspection passed. See VALIDATION_0.9.1.md. These results do not change the device-validation limits below.

After successful CI, one corrected separate Safari trial over NewTerm plus its visual outcome and /var/mobile/Library/Logs/PullOverPro/host-0.9.1.json is indispensable. Safari scene connection, actual pixels, input, client session persistence and private teardown cannot be established by native mocks or a successful DEB build. This remains an incomplete Safari-only development build, not the requested final all-app floating-window release.

Recovery: X or15-second timeout, /var/mobile/.ppo_disable to prevent new attempts, and manual respring for quarantined resources. If injection prevents normal startup, use Dopamine without injection and remove only this package. No personal data or other tweaks are modified.
