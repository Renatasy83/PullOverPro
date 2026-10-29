# Safari input investigation — exact23A355

## Preserved evidence

0.7.1 displayed live Safari and closed with X on the user's iPhone12,5/iOS26.0.1. The actual JSON completed owned presenter invalidation, and the user confirmed normal visual restoration. This is one operation, not general runtime compatibility.

## Static hit-testing evidence

Inspected the same manifest-digest-verified 23A355 dyld cache documented in FIRMWARE_23A355.md (UIKitCore UUID C98EAB32-B273-3430-B0C5-46522C904CBB):

- _UIScenePresentationView::_hitTest:withEvent:windowServerHitTestWindow: at0x1897a2dec and _UISceneLayerHostContainerView's implementation at0x18979ff1c compare their window to the supplied window-server hit-test window, return nil when it differs, otherwise delegate to super and apply transparency filtering.
- Selector stub0x18ad19280 resolves to objc_msgSend$window, corroborated by its selector reference0x1e73b3268. Stub0x18acea440 resolves to objc_msgSend$shouldPassthroughHitTestEventsIfTransparent (selector reference0x1e73a76d8).
- _UISceneLayerHostView::hitTest:withEvent: at0x18979f47c delegates to super and returns nil for a self-only hit. It does not demonstrate that a remote Safari process will accept a user's touch.

These implementation details support leaving routing/coordinate conversion to UIKit, but cannot prove cross-process input delivery. None of these private hit-test methods are called, overridden or hooked by PPO.

## 0.7.2 implementation boundary

The explicit Safari trial still creates/activates/invalidates the same owned presenter, behind UUID and receiver ABI checks. Content starts with userInteractionEnabled=NO. Only an explicit header button toggles that public UIKit property after successful activation, while the scene is active, the disable marker is absent and the original 15-second deadline has not elapsed. The toggle does not create/reactivate presenters or extend the deadline.

There are no additional private calls, event synthesis, HID APIs, key-window changes, first-responder forcing, scene-setting changes or event-deferral tokens. The header's own drag/close buttons remain separate. Closing disables input before detachment. Reports identify manual/timeout/disabled/host-inactive/protected-data/opening failures, record opt-in events and conservative touchDeliveryVerified=false/keyboardRoutingVerified=false.

## Focus boundary

LiveContainer's current AppSceneViewController.m source discusses iOS26 keyboard problems and uses sceneViewController.view plus scene-hosting/event-deferring configuration. It hosts its own extension processes and creates scenes. That is not proof that the same ownership/focus arrangement can be applied to a borrowed Safari scene. Its source was reviewed, not copied.

Exact23A355 includes _UISceneHostingEventDeferringExtension and _UISceneHostingEventDeferringHostComponent (declarations in UIKitCore). Presence/ABI alone does not establish token ownership, correct parent scene, arbitration behavior or cleanup. No such APIs are enabled in PPO.

Public UIKit touch acceptance can now be tested on the actual phone without introducing an unverified private focus mechanism. Native CI does not reproduce UIKit/WindowServer/Safari cross-process routing; its success cannot confirm touch or keyboard. If touches fail, collect the report and observed behavior before introducing new APIs.
