# Messages scene audit — exact23A355

Read-only inspection of the existing decrypted iPhone12,5 iOS26.0.1 build23A355 main OS image, without mounting, downloading more firmware, executing iOS code or changing production code. The supplied current device reports contain Safari/Files/Calendar, not a failed Messages or Messenger session. The reported generic verification refusal is consistent with policy exclusion but does not by itself identify its reason on the installed phone.

## Exact staged Messages declarations

Staged path `/private/var/staged_system_apps/MobileSMS.app/Info.plist`,8405bytes, SHA256 `562948d94bc6609c54510caeab33008abdc370de076ddf084c87d664e294033a`.

`com.apple.MobileSMS` is an APPL application for families `[1,2]`, executable `MobileSMS`, principal class `SMSApplication`, short version `26.0`, bundle version `1448.100.1.2.102`, DTPlatformVersion `26.0`, DTPlatformBuild/DTSDKBuild `23A345`, DTSDKName `iphoneos26.0.internal`, and DTPlatformName `iphoneos`. It declares **UIApplicationSupportsMultipleScenes=true**. It is not an explicit-single-scene case.

Its manifest has three keys: `UIApplicationSupportsMultipleScenes=true`, `UIApplicationSupportsSceneItemProviders=true`, and `UISceneConfigurations`. The configuration map contains exactly three auxiliary roles and no normal application role:

- `CPTemplateApplicationSceneSessionRoleApplication`: Messages-Car / CPTemplateApplicationScene / CKStarkManager.
- `UIWindowSceneSessionRoleAssistiveAccessApplication`: Messages-ClarityUI / CKClarityUISceneDelegate.
- `com.apple.PosterBoardUIServices.editor-overlay`: Messages-EditorOverlayConfiguration / ChatKit.PosterEditorOverlaySceneDelegate.

Current policyv3 rejects this as unknown/manifest-complex: it requires at most two manifest keys and a configuration dictionary containing only the normal application role. This is deterministic for this staged plist. It is not proof the phone's installed bundle matches these bytes or a proven app failure after scene activation.

## App-defined normal configuration

Staged Messages executable UUID `EA050F24-AEEF-3F8F-B2E3-95E4CAB5E68A`, SHA256 `aa1bf2d8cfd5088b80dc53c61f24b818d98e133022f4e3bf2cb3552624191709`.

`SMSApplicationDelegate -application:configurationForConnectingSceneSession:options:` at `0x100018fc8` handles special roles separately. ExternalDisplayNonInteractive, CarPlay, AssistiveAccess and PosterBoard editor-overlay branches return the existing session configuration. All other roles enter a dynamic-default branch at `0x1000191e4`, selecting `CKMessagesSceneDelegate` initially. URL overlay options can select CKChatSceneDelegate; state-restoration/user activities can select a container/debug delegate. An ordinary owned request should not fabricate these options.

At `0x100019520` the app allocates UISceneConfiguration. It calls `initWithName:sessionRole:` at `0x100019554` with the existing configuration's name/role, sets its selected delegate at `0x10001956c`, then copies the existing sceneClass at `0x100019580` and returns the new configuration. Thus the absent normal-role plist entry is intentional; normal configuration can be supplied by the app delegate, rather than by PPO choosing an auxiliary role.

ChatKit UUID `C51C4E7C-7F10-3647-B3D8-40720E5F8C53`. Its CKMessagesSceneDelegate subclasses CKSceneDelegate, which conforms to UIWindowSceneDelegate and owns a UIWindow. Presence/shape alone is not runtime hosting permission.

## UIKit connection evidence — missing-normal-role lookup completed

The earlier exact-firmware programmatic-scene audit establishes unnamed new sessions, app-delegate configuration override, and the normal UIApplicationSceneSpecification's UIWindowScene minimum/application role. `UISceneConfiguration -_initWithName:sessionRole:includingPlist:` at `0x18a0f42f0` is additionally inspected for a nonempty auxiliary-role map with missing requested role: the key lookup result is held inx23 at `0x18a0f4430`. An unnamed request branches at `0x18a0f4468` to `0x18a0f4560`, takes the first object of the selected role's array, and if nil branches through `0x18a0f499c` to normal return without setting plist override classes. The selector stubs were decoded by reading their selector-reference pointers from the cache: `0x18ab7e9e0` is `_infoPlistSceneConfigurations`, `0x18ac77320` is `objectForKey:`, and `0x18ac34ea0` is `firstObject`. Thus `0x18a0f4428` performs `[configurationMap objectForKey:requestedRole]`; for the audited normal application role it returns nil, and `[nil firstObject]` at `0x18a0f4564` is nil. The initializer skips the plist override-writing block at `0x18a0f45c0` and takes its nil-result return path via `0x18a0f499c`. This is not merely an inference from role-name presence. The preceding normal UIApplicationSceneSpecification role/minimum and allowed app-delegate connection path remain as documented in PROGRAMMATIC_SCENES_23A355.md.

The apparent alternate-key lookup at `0x18a0f4448` does not select an auxiliary role for a normal request: the comparison at `0x18a0f4418` is against the decoded `UIWindowSceneSessionRoleExternalDisplayNonInteractive` constant (`0x1e7320de8`→`0x1efe1fe38`, characters at `0x18a620f32`). Only that role can use fallback CFString `0x1efe29278`, whose decoded value is `UIWindowSceneSessionRoleExternalDisplay` (characters at `0x18a62db30`). The ordinary application role skips this alias path. The nil role-array branch at `0x18a0f4578` reaches `0x18a0f499c`, releases temporaries and returns configuration objectx21 at `0x18a0f49c8` without writing a delegate/scene override or resolution error in the intervening plist-writing block.

This completes the previously unresolved missing-normal-role lookup point. Together with the app's normal delegate path, it supports a narrowly bounded metadata candidate on this exact build. It does not establish actual FrontBoard/client admission or pixels/input on the phone.

## Narrow candidate boundary

A candidate can be limited to exact MobileSMS executable/principal/version/platform/SDK/family and the complete audited auxiliary-role manifest, including genuine Boolean scene/item-provider flags. The descriptor remains advisory and fresh; exact normal source/child specification/role, own namespace/identity/proxy, inactive preparation, framework gates, cleanup/quarantine and all hard negatives must remain. Do not select CarPlay/AssistiveAccess/editor-overlay configuration, invoke the delegate manually, bypass false multiple-scene declarations, mutate original scenes or authorize other complex apps.

This is a scoped installed-info profile candidate, not a firmware-baseline bypass. It still requires an actual on-device Messages admission/rendering/input/cleanup gate after automation. Installed app version differences must refuse/reinspect rather than silently match another build. Process/scene absence, privacy/account/entitlement behavior and actual client admission are not established by this static audit.

Messenger is a separate third-party app; neither its version nor manifest appears in the current supplied capability report, which only describes Safari. Its installed metadata/refusal reason must be captured independently. No Messages conclusion authorizes Messenger or a global policy relaxation.

Only derived facts should be committed. Raw Apple plist/binary/assembly inputs remain local under `/workspace/firmware-research/evidence/`.
