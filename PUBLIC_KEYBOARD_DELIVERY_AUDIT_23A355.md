# Public keyboard notification delivery — bounded 23A355 audit

Read-only followup during the RC3 public UI work. No production source, private observer or runtime operation was changed. Sources are the existing local arm64e 23A355 dyld cache, UIKitCore UUID `C98EAB32-B273-3430-B0C5-46522C904CBB`, and SpringBoard UUID `8676BE2A-9484-3492-888E-7DE10333250F`.

**Conclusion:** static evidence neither rules out nor confirms the RC3 public-notification monitor for keyboards belonging to NewTerm or hosted Safari. An actual SpringBoard delivery observation remains necessary. Default-off, public-only behavior is appropriate until that observation; this audit does not justify introducing private keyboard notification names.

## SpringBoard has global keyboard awareness, but uses private variants in the inspected system controller

`SBPIPController -initWithIdleTimerCoordinator:windowLevel:interactionSettings:adapter:` is at `0x21de54818`. Its inspected initialization obtains the default NSNotificationCenter and calls `addObserver:selector:name:object:` with nil object filters. Registration at the following sites resolves to these **private** constant values:

| Registration call | Selector | Name |
| --- | --- | --- |
| `0x21de54968` | `_keyboardWillShowOrHide:` | `UIKeyboardPrivateWillShowNotification` |
| `0x21de54988` | `_keyboardWillShowOrHide:` | `UIKeyboardPrivateWillHideNotification` |
| `0x21de549ac` | `_keyboardWillChangeFrame:` | `UIKeyboardPrivateWillChangeFrameNotification` |
| `0x21de549d0` | `_keyboardWillRotate:` | `_UIKeyboardInternalWillRotateNotification` |

For example, the indirect imported pointer at `0x278043ac8` resolves to `0x1e731a490`, whose NSString value is `UIKeyboardPrivateWillChangeFrameNotification`. This was decoded through the imported constant, rather than inferred from the handler's name.

The frame handler at `0x21de5ca70` reads `notification.userInfo`, checks `UIKeyboardOriginatedFromRotationUserInfoKey`, then updates controller state. The class also stores `_keyboardFrameInMainScreenFromNotifications` and participates in system picture-in-picture layout. This is credible system keyboard awareness, but the receiver's private constant does not establish that the public variant is or is not posted alongside it. These private observer calls are evidence only and must not be copied into RC3.

## UIKit still contains a public frame-notification posting path

`UIPeripheralHost -postKeyboardFrameChangeNotification:withInfo:` is at `0x189b033b0`. Its bounded body provides positive evidence that public frame notification posting remains implemented on this firmware:

- When the supplied name equals `UIKeyboardWillChangeFrameNotification` (`0x1e731a4f0`), it selects `UIKeyboardPrivateWillChangeFrameNotification` (`0x1e731a490`). The DidChange pair uses globals `0x1e731a500` and `0x1e731a498`.
- It obtains `NSNotificationCenter.defaultCenter`.
- At `0x189b03490`, it posts the selected private equivalent with a screen object and the provided userInfo.
- At `0x189b034a8`, it also posts the original supplied name with **object=nil** and that userInfo.
- If the host's `_isTranslating` flag is1 and the name contains `ChangeFrameNotification`, an earlier guard skips the frame posting. Therefore not every internal geometry activity necessarily yields a public frame event through this method.

This code is a local process posting path. It is **not** a cross-process notification broadcast and does not prove that another application's keyboard is routed through the SpringBoard process's UIPeripheralHost. It also does not establish scene filtering, screen conversion accuracy for the injected overlay, public DidHide delivery or the timing/shape of every modern keyboard notification.

Other current UIKit metadata includes `UIWTInputViewSetPlacementController -_postNotificationsForType:from:to:forStart:` (`0x1895fb4d0`) and its onScreenFrame variant (`0x1895fb5f8`). That confirms more than one keyboard placement path exists; their entire routing and notification-selection logic was not traced in this deliberately bounded followup.

## Consequence for the current candidate

A public NSNotificationCenter observer is a valid best-effort receiver, but cannot be presented as globally effective for all foreground application keyboards based on method metadata or source compilation. Conversely, the inspected use of private variants by SBPIPController is not sufficient to declare the public path nonfunctional.

Keep RC3 public-only and default-off. The necessary real-device check is narrowly scoped: with avoidance enabled and the handle positioned where it actually overlaps the keyboard, show/change/hide a keyboard in NewTerm and/or the already supported Safari window and observe whether a valid public end-frame event reaches the injected SpringBoard monitor. A bounded receive/apply counter and frame/status diagnostic can separate missing delivery from correct rejection of no-overlap/invalid/different-screen geometry. Do not infer absence of delivery solely because an already non-overlapping handle stays still. This can share the planned RC3 UI test; no separate new installation or private API experiment follows from this audit.

If public events do not arrive for the required app context, keep the optional feature disabled or explicitly limited to observed delivery. Do not compensate by guessing a private notification/keyboard service signature or manipulating focus/remote input. Evidence for a later alternative would need a separate audited contract and device gate.

Local raw evidence remains outside the repository: `/workspace/public-keyboard-sbpip-init.asm`, `/workspace/public-keyboard-sbpip-frame.asm`, `/workspace/public-keyboard-uikit-post-frame.asm`, its annotated version, and the pre-existing verbose declarations. Only this derived audit is suitable for a source commit.
