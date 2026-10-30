# Independent Safari scene trial — 0.9.0

This is an incomplete development candidate, not a final release or confirmed background hosting. The0.8.3 device report shows visibility propagation already enabled in two sessions and a successful disabled-to-enabled context operation in a third; source layers still disappear or remain absent while Safari is backgrounded. The borrowed-scene approach is not used by this candidate.

## Verified firmware declarations

The exact iPhone12,5 iOS26.0.1 build23A355 main OS member043-93327-010.dmg.aea was selectively downloaded from Apple's IPSW, checked against ZIP CRC32, decrypted locally and checked against BuildManifest SHA384:
1c72d887772982c4243da5f5d975f604f4a28a08b0b76b94e76eabf3e9e6ffa4b6366f19c16d9f76bc15a22987046cb9.
The selected actual MobileSafari Info.plist fields declare UIApplicationSupportsMultipleScenes=true, device families1/2 and UIWindowSceneSessionRoleApplication with BrowserWindowScene and BrowserSceneDelegateRouter. MobileSafariUI metadata confirms BrowserWindowScene:UIWindowScene. Preferences declares multiple scenes=false. Accordingly this trial is Safari-only; it must not be generalized to Settings or all installed apps.

These are firmware declarations, not actual device admission. No Apple binary or complete app plist is included in the repository or DEB. No phone file or personal data was modified during extraction.

## Constructor and ownership contract

The existing exact loaded FrontBoard/UIKitCore/FrontBoardServices UUID gate remains before private operations. The adapter validates declared methods and actual receiver/return classes; missing methods do not cause dynamic resolution. ARC alloc/init family rules are preserved through typed private protocols with verified signatures.

The original Safari FBScene supplies only immutable definition/client identity/specification inputs after unique selection. The adapter allocates a fresh FBSceneWorkspace with a random PPO namespace, verifies it empty, and assigns a different random scene identifier to a new advanced hosting configuration. Configuration identity/workspace/specification readback must match before constructing _UISceneHostingController. No shared-workspace factory or borrowed-scene extension mutation is used.

The controller creates a new FBScene during initialization. It structurally accepts an ordinary UIApplicationSceneSpecification and adds its activation extension only to that new scene if needed. Before exposing a child controller, the adapter verifies exactly one scene in its namespace, a different pointer/identifier from the original, matching workspace and Safari identity/application role, and activation component.hostScene binding. The new scene must be valid and inactive.

Both allocated and returned initializer receivers are retained before uncertain construction can release them. This matters because _UISceneHostingController.dealloc automatically invalidates its stored scene, and FBSceneWorkspace.dealloc requires prior invalidation. A global main-thread owner pin protects active or uncertain resources even if a caller drops its adapter reference. Unknown constructor/namespace results remain quarantined with no automatic retry or destructor-driven cleanup.

## Geometry and activation

Static tracing confirms normal construction starts inactive: fresh FBScene active/updateShouldActivate flags are zero; updateSettings: uses a nonactivating join; fresh workspace has no delegate/observers to activate; UIScenePresenter activation only updates presentation on this normal path. Runtime inactive-state checks enforce that precondition rather than relying on binary analysis alone.

PPO loads the new UIKit child view, assigns its public frame to native nonzero screen dimensions before addChild/addSubview, rechecks inactive/valid state, then completes normal public containment and shows its own window. UIKit's sceneWillActivate path invokes its geometry providers before activation; the provider applies this own view's geometry to the new scene. PPO does not call private geometry setters, a foreground setter, or a manual scene activation selector. It does not change shared security, app protection, layer masks, event deferral or process assertion modes.

Only UI demonstrably parented by PPO's own root/wrapper may be detached during cleanup. A rejected/preparented child is not removed from another hierarchy. UIKit attachment/appearance participates in the new scene's lifecycle; actual client connection and render availability still need the live target.

## Bounded trial and teardown

The UI closes manually, on disable/host-inactive/protected-data conditions, or after15 seconds. Closure invalidates only the verified owned controller. Workspace invalidation is forbidden until the own FBScene is invalid and its allScenes array is empty; otherwise the workspace would assert. Up to8 quarter-second cleanup waits allow asynchronous removal, then retain/quarantine uncertain resources and refuse another trial. Normal controller destruction may invoke its own idempotent invalidation again; an 'invalidate returned' field describes PPO's explicit call, not the total internal destructor call count.

Confirmed cleanup means own scene invalid, own workspace empty and explicit invalidations returned. It does not prove synchronous OS grant revocation or Safari session/process persistence cleanup. Constructor/cleanup uncertainty is retained rather than forcibly released; in that case a manual respring is the recovery boundary. No automatic respring/install or manipulation of other tweaks is added.

Report: /var/mobile/Library/Logs/PullOverPro/host-0.9.0.json, schema7. sceneHost ownership fields replace the older presenter fields. lastHostedSourceSample and lastOriginalSourceSample are separate, each with its own timestamp; historical samples after close are not new reads. Reports are bounded by8 session summaries,16 events and8 view nodes, exclude recursive history and contain no URLs/page contents/screenshots.

## Automated checks and remaining gate

Native fixtures exercise namespace/identity validation, distinct source/new scenes, ARC initializer failures retained before cleanup, class/ABI rejection, unexpected early activation, delayed/failed cleanup, reentrancy, thread rejection and100 lifecycle cycles. CI must also execute Clang analysis, existing suites, Theos rootless compilation and package/architecture/license checks. Source inspection and native mocks do not execute iOS UIKit/Safari connection.

After successful automation the indispensable device gate is a single explicit separate Safari trial over NewTerm, its visual outcome and host-0.9.0.json. Open Safari normally once so the original input scene exists, return to NewTerm, select Safari and press the window action. No foreground-Safari underlay is required by the intended design, but success is not assumed. Keep the existing15-second bound; do not start by stress-testing keyboard or all apps. Recovery is X/timeout, then /var/mobile/.ppo_disable to block new sessions/overlay startup. If startup/injection fails, boot Dopamine without injection and remove only this package. Main/stable sources remain preserved. Full Dopamine/ElleKit compatibility remains unconfirmed.


## Executed automated result

Sourcea51c7cdfbb5515cff23f0ec29fc60dd29184f9a0 completed Actions run41116185796 successfully. The new owned-scene suite passed573 native ASan/UBSan checks, including100 lifecycle cycles with fake receivers. Existing visibility613, presenter342, geometry1027, session-slot229 and source-layer229 checks passed, alongside lifecycle24, mailbox IO365, real fake-workspace subprocess52 and the inventory/launcher/protocol/service suites. iOS Clang analysis, Theos rootless build, arm64/arm64e checks, payload/lifecycle/license inspection and validation-report generation passed. Only the existing obsolete -multiply_defined linker warnings were recorded.

Artifact13005358295 contains the0.9.0~dev.ownedscene1 DEB, test logs and VALIDATION.md/VALIDATION.json. No actual Safari additional-scene connection, UIKit appearance-driven activation, pixels, input or complete device teardown was executed by this CI. The live target gate above remains indispensable. No executable change followed this successful source build.
