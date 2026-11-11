# RC14 — reviewed Messenger headerless edge drawer

## Baseline

RC13 was user-confirmed after minimize/restore/bar-X. The report contains one safe readiness refusal before owned preparation, then exact586/v5 success with4minimizes/3restores/6moves/2resizes, positive viewport/native414×896 and clean manual close while minimized. Read RC13_MESSENGER_DEVICE_RESULT.md for timing/telemetry limits. Preserve its DEB/archive7f77890d4229375c83050683eb0ef6718b90b9ef and stable/verified-rc13-messenger586-minimize.

## Public presentation changes

1. Honor requested windowSize3 (Sertar) for Messenger; retain Standard for other initial presets. Automatic Keep is still disabled. Existing classic geometry hides floating toolbar and scales only the owned wrapper; native child frame stays supplied once before containment.
2. A main-thread, running/not-opening/not-closing/not-closed getter returns only the existing reviewed Messenger classic menu. It never probes lifetime/private state or builds a scene. Long-press the existing handle X to choose Keep/Minimize; showsMenuAsPrimaryAction=NO preserves tap-X. Existing parent recognizers exclude X descendants. Bind only if menu identity changes and clear when X is hidden. Exact-trial weak action captures and existing action lifecycle guards prevent stale menu callbacks from controlling a replacement.
3. Correct the newly reachable headerless-minimized stacking defect: content begins at y=0 and was added after chrome. A44point panel clip alone leaves it above bar controls. Validate title/restore/X belong to the own panel and bring just those controls to front. Preserve positive content frame/bounds, wrapper/native containment and visibility; restore refits the public wrapper and re-anchors classic edge geometry.
4. Settings explains the long-press-X actions. Existing handle chooser-first/second-selection semantics and all unrelated app layouts stay unchanged; the extra X menu is Messenger-classic only.

No Agent/profile/schema5/scene owner/geometry/lifetime/Keep-policy changes. Preserve exact585/586/warm foreground/current-root/window/scene/framework/proxy/owner/render/lock/cleanup/quarantine checks,15second default, explicit120second root and125second companion. No cold Messenger, unlimited Keep, automatic foreground launch, private selector or native/root reassignment is added.

## Verification

Existing classic/edge/handle/intent/geometry/presentation/lifetime/Keep/return/profile/owner fixtures are reused; no new algorithm justifies mirror tests. Static checks require requested-size restriction, automaticKeepoff, live read-only menu, tap/gesture exclusions, binding identity/clearing, owned chrome ordering and no native mutation in minimize. Full39 native,13 portable/Linux, Clang analysis, pinned Theos rootless and independent ZIP/DEB/six-binary checks are required before delivery. Validation status is in OPENCODE_HANDOFF.md.

Two real runtime boundaries remain: UIKit may host the X context menu outside accepted overlay hit descendants, and a fully retracted Messenger panel may change remote layer visibility differently from a44point bar. Do not guess private UIKit view classes or relax the existing render gate to preempt these. Build/geometry cannot establish actual menu selection or app input.

## One physical procedure after automated validation

Manually install/respring. In PPO Settings choose Dimensiune inițială->Sertar if not already selected. Open Messenger normally, then its PPO drawer. Within15seconds long-press handle X and select Păstrează (max.2min); verify actual selection, no accidental close/favorites. Switch NewTerm, retract/reveal with handle, check visible content/simpletap/scroll. Long-press X->Minimizează; restore▢ and check content. Tap handle X, then manually foreground Messenger and check normal UI.

Send /var/mobile/Library/Logs/PullOverPro/host-1.0.13.json and interface-1.0.13.json. On refusal/black/unexpectedclosure stop repetitions and describe which step. No other-app, prior resize, repeated2minute or cold probe, no messages/personal appData. No protocol-driven force quit needed. Recovery marker /var/mobile/.ppo_disable/manualrespring or known Dopamine without injection/uninstall only PPO if unusable. No automatic phone action/data/other-tweak change. Preserve main/stables/archives/GPL attribution; general Dopamine/ElleKit/signaturetrust remains unconfirmed.
