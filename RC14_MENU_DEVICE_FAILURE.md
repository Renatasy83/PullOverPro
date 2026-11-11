# RC14 phone result — headerless rendering, unusable Keep menu

User reports long-press-X menu flickers, Keep cannot be selected, then automatic closure. Supplied host-1.0.13.json is311018 bytes, SHA256cd00db127170797d1043032daf7b765080b7f772cd588101d26b101dc7529cfc. Exact executable586608c13cff2557fffbb3c04233a361ab593890/version1.0.13~rc14/archiveb111008864ba8545ff8f1b92398bb0d1e6a30873/DEBSHA2d8c9105b3e13c9bba0539008928a1b1124435dd6c6b49faaf2f6b6fa8260d05. No raw report or personal data is committed.

## What the report establishes

Two distinct hosted Messenger586/schema5 sessions, both timed/timeout. First window-shown57681.10093566667 toclose57696.170920958335 =15.069985s; budgetelapsed15.113985. Second budget57724.15016979167 toclose57739.216642583335 =15.066473s (window-shown discarded byboundedhistory). Both retain over104s before the independent120s cap. Neither acceptedKeep nor messenger-keep-refused event appears. No minimize/restore/move/resize; second records drawer-closed shortlybeforetimeout.

Retained open layouts areclassic/header0, panel+viewport364×787.7874, native414×896 attached. Hostedlayersremainpositive/active. Original scene also remains nonbackground in retained samples, so NewTerm/background/reopen probes are not established. Both own controller/workspace cleanups returned, closed/unpinned/unpoisoned/replacementAllowed. Helper final5/phase3/flags31 then15/readyfalse is expected restored state. This is normal15second closure without acceptedKeep, not a120cap/render/cleanup/watchdog failure.

User evidence establishes the menu is unusable. The report has no menu presentation/selection/object-identity telemetry and cannot independently distinguish an uninvoked callback from an early guard return or prove a particular flicker mechanism. Do not repeat phone attempts just to confirm the same timeout. RC14 is not promoted; retain RC13 verified recovery.

## Concrete source-contract defect

Pinned SDK16.5 UIButton.h declares menu as copy. UIMenu.h documents that sinceiOS14 UIKit takes immutable copies of menus it receives. RC14 compares destinationX.menu pointer with sourceowner.actionsButton.menu pointer on every1second overlay refresh. Cross-button identity is not guaranteed by that contract. Repeated reassignments can interrupt a context menu and are consistent with the reported cadence, but actualiOS26 copy/dismiss frequency is not proven by this log.

Source updateActionsMenu is not called eachtick forMessenger; onlyinitialization/explicitKeep changes it. The fix must retain the original menu model and track source/owner/destination binding separately from UIKit's copied destination property. Add a real Foundation regression fixture whose copyproperty returns distinct objects, then prove repeated refreshes do not reassign. Bounded assignment counters can distinguish a residual UIKit hit-routing issue in the nextreport. Keep current hitTest bounds and alltimers/admission/Agent/ownership/render/cleanup gates. No guessed UIKitprivate classes, autoKeep, clockextension or unsupportedprivatecall.

Public SDK evidence: https://github.com/theos/sdks/blob/0222fd5413cf4b9af096f37b4621afa2688572f7/iPhoneOS16.5.sdk/System/Library/Frameworks/UIKit.framework/Headers/UIButton.h and UIMenu.h in the same directory. Fullheaders are not copied into the project.
