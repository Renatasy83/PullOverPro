# RC6 Messenger content/input success with original-UI return defect

User confirms the small Messenger window displays content and supports touch/scroll/other interaction. The surface behind it was black and remained black after automatic close; the user manually exited the app. No claim of complete Messenger compatibility follows.

The supplied host-1.0.5.json contains one reviewed warm trial. Its child/proxy binding is verified and distinct from the original. Window shown27757.982221541668; close-returned27773.016360041667, approximately15.034seconds, reason timeout. Own layer samples progress0→1; original samples report2layers/active/not-backgrounded. Controller/workspace invalidation returned, owner closed/unpinned/unpoisoned and replacementAllowed=true. These are own-adapter cleanup checks, not original-app UI restoration. The final original sample27773.006008583336 precedes close-returned and cannot prove post-close original rendering. The user's visual report establishes the after-close defect.

Automatic touchDeliveryVerified=false flags are not a denial of the user's physical confirmation; the software did not independently verify gestures. Likewise layer counts do not prove original pixels. A migrated single UIWindow/root is a hypothesis requiring app-process evidence, not a conclusion from server-side layer counts alone. Raw device report is not published.

RC7 introduces the narrowly scoped public UIKit original-window return companion documented in RC7_MESSENGER_WINDOW_RETURN.md. It must recognize exact same-window/root/PPO-session/target identity and refuses unknown patterns. Actual mapping/return remains a device gate. Existing own-scene and whole-platform compatibility claims remain scoped, and prior RC6/RC5/stable/recovery remain available.
