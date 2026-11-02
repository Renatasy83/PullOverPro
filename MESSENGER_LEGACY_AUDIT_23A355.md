# Messenger without a scene manifest: 23A355 lifecycle audit

## Conclusion

Messenger585.0.0/build1101076820's supplied plist is missing UIApplicationSceneManifest. This explains PPO's current metadata refusal; it does not establish that Messenger cannot use UIScene or that an independently created scene will render the app. A missing manifest must not become a blanket authorization. No runtime policy or private method was changed by this audit.

The next missing evidence concerns the running Messenger application's lifecycle/default scene and actual delegate behavior. Its Info.plist contains no NSPrincipalClass, UIApplicationDelegateClassName, UIMainStoryboardFile or NSMainNibFile. UILaunchStoryboardName=LaunchScreen is a launch screen, not a declaration of the app's interactive interface. The app executable, decrypted code and running delegate have not been inspected. Do not infer a class name or absence of a delegate method from the plist.

## Inputs and method

Target firmware: previously staged iPhone12,5 build23A355 dyld cache, UIKitCore UUID C98EAB32-B273-3430-B0C5-46522C904CBB. Messenger metadata SHA256741517f9808a10ac225c6490d2af5bd835ff56b112464c5d53ce670d7ff92e30 (22483 bytes,77 keys). No Apple binaries, disassembly or raw user plist are published with this document.

Read-only Objective-C method metadata and ARM64 disassembly were inspected offline. Selector stubs were decoded directly from their ADRP/LDR instructions and independently checked against ipsw's disassembly:75 selector resolutions agreed across four extracts. A local evidence check verified32 anchors across10 extracts. These are static-audit checks, not additional native test suites or an execution of iOS/Messenger. Framework addresses below are unslid and apply only to the audited image.

## Lifecycle adoption is broader than manifest presence

UIApplication -_appAdoptsUISceneLifecycle is at0x1889b50b4. After its once initialization,0x1889b5130–0x1889b5148 tests mask0x30 in application-flags byte7 and ORs the result with the cached byte at0x1eab73b3d. The declaration metadata associates those application flags with support for configuration-for-connecting and discarded-session delegate callbacks. This is an implementation observation, not permission to change those flags or invoke those callbacks from PPO.

The once block0x188a1dab0 obtains sceneConfigurations and enumerates its values; its block0x188a75ae8 sets the cached adoption byte when an enumerated collection has nonzero count (0x188a75b00–0x188a75b14). Therefore lack of declared configurations alone does not prove a false lifecycle-adoption result: the delegate flags are another input. Messenger's actual delegate flags are unknown. Conversely, a method encoding or existing UIScene does not prove that this app can populate an additional independent scene.

UIApplication -_appSupportsMultipleScenes at0x189cefb90 reads a separate bit (byte13,bit4). Do not conflate lifecycle adoption with multi-scene capability. This audit does not establish where Messenger's value is initialized or a permissible override.

## UIKit can construct a scene wrapper without establishing content

UIApplication -workspace:didCreateScene:withTransitionContext:completion: at0x189cf4604 calls -_connectUISceneFromFBSScene:transitionContext: at0x189cf4734. That connection routine begins at0x189cf3ef8 and handles the specification/role, session, configuration and connection options.

At0x189cf40ac it checks -_appAdoptsUISceneLifecycle. A false result branches at0x189cf40b4 to0x189cf412c, where the connection-options value is nil. Both paths still continue toward +[UIScene _sceneForFBSScene:create:withSession:connectionOptions:] at0x189cf4384. This establishes that the false-adoption branch is not simply an unconditional failure to allocate a UIScene wrapper. It does NOT prove FrontBoard admission, a visible window, per-app launch behavior, independent content or input.

The UIScene factory0x18916cef8 checks the specification's minimum class, configured class compatibility and an existing scene mapping. In the new-object path it calls initWithSession:connectionOptions: at0x18916d060, initializes components, readies the scene at0x18916d270 and conditionally delivers scene:willConnectToSession:options: to a scene delegate. These existing compatibility/ownership checks cannot be replaced by a Messenger identifier exception.

## Main-interface initialization is a distinct path

UIApplication -_runWithMainScene:transitionContext:completion: begins0x189cf5500. At0x189cf5770 it checks lifecycle adoption; a true result skips the call to -_loadMainInterfaceFile at0x189cf577c. The non-adopting branch can load the application-level main interface during main-scene initialization. The inspected -_loadMainInterfaceFile implementation0x188b1f608 checks main storyboard/nib names and invokes their corresponding loaders. Messenger declares neither; any programmatic interface construction remains app-code behavior, not proven by this framework branch.

UIApplication -_defaultSceneIfExists0x188994c78 consults the application initialization context's defaultSceneToken (0x188994cdc–0x188994cf0), rather than demonstrating that an arbitrary newly created PPO scene becomes the default. A new scene and an app's pre-existing/default scene must remain distinct unless binding is established.

UIWindowScene -_readySceneForConnection0x188a28dec reads the session configuration's storyboard and calls _loadWindowWithStoryboardIfNeeded: at0x188a28e54. -_performDeferredInitialWindowUpdateForConnection0x188a63b9c consults its window-scene delegate/window and existing visible windows. None of these observations establishes that a legacy app's existing UI is duplicated into an independently owned scene. Do not guess a storyboard, relocate existing windows, call app initialization a second time or present an existing foreign scene as PPO-owned.

## Development decision and next gate

Keep current refusal for missing manifests. Do not borrow the MobileSMS profile, treat launch-screen metadata as interactive UI, set private multi-scene flags, add synthetic input, invoke the app delegate manually or change the Messenger bundle. Cold-first-scene and warm-additional-scene behavior are different unknowns, not one successful test to assume in advance.

Before a Messenger hosting candidate, establish an audited route connecting the app's actual lifecycle/content source to PPO's ownership and teardown guarantees. A read-only existing-scene observation may narrow topology but cannot inspect a delegate in another process or prove a second window's content. No further package/test is requested by this checkpoint. The user reported device slowdown; its current recovery status must be known before any phone experiment. There is no evidence assigning that slowdown to PPO, Dopamine or ElleKit.

No new DEB was delivered. Runtime source remains d0303bd039aefe08817702fb737c85eae90336eb (34-suite/Clang/Theos/package success in Actions41521971944); the permanent delivered RC4 package remains source8bd812121489f896f4e38d578da10ba0ce284039. Current source-policy verification passed again; documentation-only changes do not require recompiling that unchanged runtime. main, stable and recovery refs remain preserved.
