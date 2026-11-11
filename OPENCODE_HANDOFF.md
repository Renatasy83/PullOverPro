# PullOver Pro — OpenCode / ChatGPT handoff (2026-11-11)

## Current work: RC14 Messenger edge drawer; validation pending

RC13 device gate passed. User said “Funcționează” with host-1.0.12.json: one safe foreground/source-readiness refusal before preparation, then one successful Messenger586/v5 session. Four minimizes, three restores, six moves, two resizes; positive260×376 viewport/native414×896 retained; manual close while minimized, clean owned cleanup and replacement allowed. Budget58.187716s is not an exact visible interval because initial shown/Keep events were discarded. Helper5/phase3/flags47/deferred32/readyfalse is expected postclose. Actual outside-NewTerm input, restored content and later normal appearance are user observations; telemetry flags remainfalse. Read RC13_MESSENGER_DEVICE_RESULT.md. Do not request completed RC13 probes again.

RC13 recovery: stable/verified-rc13-messenger586-minimize at evidence commitc87589dc45eb4d5039081eff7015f48ad1ff4a7e, executable3b3e320bca7ccf15c3cbf7c1a349d5e8c4705079, archive7f77890d4229375c83050683eb0ef6718b90b9ef, DEBSHAb07cab134c6ce7ff27006e508fef14d203b9e3eb74c66592895a1e61a1ea28f5. RC12 and older archives/stable/main remain intact.

## Narrow RC14 implementation

Version1.0.13~rc14 honors requested Messenger windowSize3 (Sertar); other initial presets retain Standard. Automatic Keep remains off:15second default, explicit bounded120second root/125second companion. Existing read-only public menu getter exposes only a live reviewed Messenger classic drawer; no private sampling. Long-press existing handle X offers its existing weak guarded Keep/Minimize actions. Tap X still closes; existing parent pan/longpress delegates exclude X descendants. Only change the menu binding when identity changes, and clear it when hidden/inactive. Do not broaden hit testing to guessed UIKit menu classes.

Headerless content begins at y=0 and is added after chrome; simple44point clipping would cover minimized controls. The minimized branch now validates own control parents and brings only title/restore/X above the preserved positive viewport. No native content frame/visibility/containment or scene setting is changed. Classic restoration re-anchors through the existing edge geometry.

Agent/profile/schema5/scene owner/geometry/lifetime/Keep policy files unchanged. Keep exact585/586 warm admission, foreground source/current root/window/scene/framework/ownership/lock/render/cleanup/quarantine and all caps. No cold Messenger, unlimited Keep, auto foreground launch or new private API. Full39 native/static/Theos rootless build,13 portable/Linux and artifact checks are pending; do not recommend install yet.

## Only next phone gate after automated success

Manually install/respring; Settings->PPO->Dimensiune inițială->Sertar if needed. Open Messenger normally, then PPO. Within15seconds, long-press the handle X and actually select Păstrează (max.2min), ensuring no tap-close/favorites chooser. Switch to NewTerm, retract/reveal through the handle, check content/simpletap/scroll and same owned session. Long-press X->Minimizează, restore▢ frombar and check content, then tap X and manually foreground normal Messenger. Save host-1.0.13.json and interface-1.0.13.json. Stop on refusal/black/unexpectedclosure; exact observation matters. No other-app/prior resize/repeated2minute/cold test or personal appData. Agent/protocol unchanged, so no forced app restart just to reload it.

Actual overlay menu selection routing and Messenger edge retract/reveal are untested; the restricted hitTest may depend on where UIKit hosts its menu. Existing geometry/builds cannot prove these behaviors. Read RC14_MESSENGER_CLASSIC_DRAWER.md.

## Tandem workflow / limits

Active debug/two-stage-handle-messages; fresh-fetch remotehead/handoff, preserve OpenCode changes via explicit Git tree/CAS, no broadreset/push. Keep root handoff updated. Preserve mainaf336d84a6b4812e6b6406af87803fb15bf29c3b, earlier scopedstablee5c6e53f659109d77d78a5a99f7139899a978991, RC12stable8f0c64f5ce82913b8cb99ef7bcecf0de6b307fa2 and all archives/GPL-3.0/c1d3r attribution. No automatic install/respring/kill, personal-data deletion or other-tweak change.

Reported device iPhone12,5/iOS26.0.1 build23A355/Dopamine rootless/ElleKit1.2. No compatible physical device/Apple Silicon Mac/vphone environment is accessible; Intel hosted CI is native fixtures/build only. Do not claim general runtime/signaturetrust/entitlement compatibility. Earlier watchdog cause remains unconfirmed. Recovery /var/mobile/.ppo_disable+manualrespring, or known Dopamine without injection/uninstall only PPO if unusable. Work autonomously until the necessary phone gate.

Prior checkpoint in docs/OPENCODE_HISTORY_THROUGH_RC14_START.md; its pending RC13 statuses are superseded by the device result.
