# RC15 — copy-safe binding for the Messenger X menu

## Failure and documented contract

RC14 user reports flickering/unselectable Keep followed by automatic closure. The supplied report has two exact586/schema5 headerless sessions, both timed/timeout at about15seconds, positive hosted layers/cleanowncleanup, no acceptedKeep. It does not identify menu object identities or prove a callback path; actualUIKitcopy/dismiss behavior remains unmeasured. Read RC14_MENU_DEVICE_FAILURE.md. RC14 is not a verified stable; preserve RC13 recovery.

Pinned SDK16.5 UIButton.menu is copy. UIMenu.h documents immutable copies taken by UIKit sinceiOS14. RC14 compared the copied destinationX.menu pointer with a different button's menu pointer every1second. That identity is not a supported invariant; it can cause repeated setter calls and is consistent with flicker. Some immutable copies may returnself, so do not call this independently proven device causality.

## Production change

The owner retains its original UIMenu model strongly, exposes that original through the existing live Messenger-classic getter, assigns a UIKit copy to its own actions button, and clears the model with confirmed UI teardown. Only initialization or acceptedKeep rebuilds semantic menu state.

PPOMenuBinding is Foundation-only and shared by production/UI fixtures. It caches the originalsource strongly and owner/destination weakly, never reads destination.menu and never retains a setter. Only a changed source/owner/target or a real canonicalclear invokes the ephemeral setter. It is main-thread-only, suppresses setter/dealloc reentry until next normal refresh, invalidates on missingdestination, invalidates before an accepted setter attempt, commits only after success and propagates exceptions. Missing source/owner clears exactlyonce on a live destination. Caller actions remain weak/exacttrial and independently check lifecycle/expiry.

The root binds through this adapter rather than comparing UIKit copies, avoids no-op handle/X frame/hidden assignments, and records bounded actual-assignment count plus bound/cleared events in the existing interface report. It does not stop safety polling, freeze layout under a menu, inspect private UIKit classes, broaden hitTest or alter callbacks/clock/admission.

## Meaningful regression

A40th native Foundation suite exercises the actual production adapter against a real copy-property fixture whose copies are distinct-but-equal. The old cross-property pointerguard invokes setter100times; unchanged adapter refreshes invoke it once across128requests. Additional source/owner/target identity, weaklifetime, canonicalclear, niltarget/setter, exception/partialsetter, thread/reentry and ephemeral capture/deallocation cases are covered. This tests a public copy contract boundary, not a simulated UIKit menu implementation. Actual UIKit presentation/routing still needs the phone.

Forty native suites/analysis/pinned Theos rootless build and13 portable/Linux suites, followed by independent artifact/6binary checks, are required before delivery. Source/static checks cover stable originalmodel, production adapter linkage and absence of copied-property comparison.

## Preserved behavior and remaining test

No profile/Agent/schema5/scene owner/geometry/presentation/lifetime/Keep-policy changes. Keep exact585/586 warm foreground/currentroot/window/scene/framework/proxy/owner/render/lock/cleanup/quarantine checks,15second default/120second root/125second companion, automaticKeepoff. No guessed private selector, cold Messenger, automatic foreground launch, capextension or personal-data/other-tweak mutation. Native child frame/containment and RC14 minimized-control ordering remain.

After automated success, manually install/respring. Keep Dimensiune inițială->Sertar. Open Messenger normally then PPO, longpresshandleX and actually select Păstrează within15seconds. Check menu stays selectable and session remains beyond15seconds. If successful in the same session, switchNewTerm, retract/reveal and check simplecontent/input; XmenuMinimize/barRestore/content, then tapX and manually foreground normal Messenger. Sendhost-1.0.14.json andinterface-1.0.14.json; the latter records actual menu assignments, allowing residual routing/refresh behavior to be distinguished. On flicker/black/refusal stop repeated attempts and identify the step. No other-app/priorresize/cold/repeated2minute/personalappData test or protocol-driven forcequit.

Actualflickerfix/menuselection/remainingheaderlessgates are unconfirmed until thatprocedure. Do not claim a successful build proves Dopamine/ElleKit/signaturetrust. Recovery is verifiedRC13 archive7f77890d4229375c83050683eb0ef6718b90b9ef/stablec87589dc45eb4d5039081eff7015f48ad1ff4a7e, /var/mobile/.ppo_disable/manualrespring or known Dopamine without injection/uninstall only PPO if unusable. Preserve main/stables/archives/GPL-3.0/c1d3r attribution.
