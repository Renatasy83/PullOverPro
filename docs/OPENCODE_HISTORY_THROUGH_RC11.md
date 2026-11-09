# Historical RC11 implementation checkpoint

Read root OPENCODE_HANDOFF.md for the completed source/archive and current device gate. Pending statuses below are historical.

# RC11 public Messenger move/resize — implementation/CI pending

User confirmed existing RC10 over-NewTerm/manualX/laterforeground procedure works. New report's second kept/manual session has originalbg0layers vs ownedactive/nonbg2layers and schema4phase3flags47(deferred32), clean own cleanup/replacementAllowed. User supplies input/NewTerm/no-focus-steal/laternormalappearance observations; frozen flag32 is not a failed return. See RC10_MESSENGER_BACKGROUND_RESULT.md. No redo of that gate. Exact RC10 recovery remains fd8e3b24/archive50b1390a373052f90622b47376a59aaa92c56898/DEBSHAfd4a6aba30a603e5dcbb33efa9c6ee4b19a1aa6fa589e8727597fc685a9c72cf.

New1.0.10~rc11 removes only four Messenger UI restrictions: title pan interaction, pan early return, disabled size button, resize early return. Existing public panel/viewport/wrapper geometry handles movement/scaling; native child dimensions/private scene remain unchanged. Minimize/restore guards and bounded-Keep-only menu, Standard initial size, cold block,120s root/125s agent/v4, profile/firmware/owner/root/cleanup/quarantine/render/lock guards stay. Agent/transport code unchanged; currently loaded v4 companion remains compatible, no protocol-driven app termination needed.

Local13 portable suites/owner Clang/source wiring policy passed. Reuse existing geometry108812/presentation403376/aspect-fit tests; no redundant new geometry fixture. Full39 native suites/analysis/pinned rootless build, exact artifact/ABI/hash/v4/move-resize marker checks and immutable archive still required before giving one DEB. Do not claim transformed app input from pure geometry.

NEXT autonomous work: finish CI, fix failures, verify exact artifact, archive onecandidate, update current handoff. Then ONLY necessary phone gate: install/respring, normalMessenger->PPOKeep->NewTerm; drag by title and cycle3 sizes, check app content/tap/scroll and outside NewTerm input, X then manualMessengernormalforeground. host-1.0.10.json. Stop onblack/refusal/auto close with exactmessage/interface. No other-app or repeated2minute test. No automatic phone actions. Read RC11_MESSENGER_MOVE_RESIZE.md.

Previous checkpoint below is historical; RC10 foreground/background bounded use is now scoped user-confirmed.

---

# PullOver Pro — current OpenCode/ChatGPT handoff (2026-11-05)

## RC10 bounded Keep and normal return confirmed by user

Latest validated executable source`fd8e3b24305624ccb984c9063ac0667e52f925af`, version1.0.9~rc10. [macOS run41946753360](https://github.com/Renatasy83/PullOverPro/actions/runs/41946753360)/job126980755950/artifact13379542626 succeeded on standard macos-15-intel:39 suites,598 budget checks,1804 state checks,68 native async client checks, Clang analysis, pinned Theos/SDK16.5 rootless arm64+modern arm64e build. Actual Apple clang17.0.0/Xcode16.4. Source/report/39 logs/ZIP/DEB/rootless/filter/license/lifecycle/six-fat-binary/signature-bounds/v4/budget markers independently verified, including a second artifact review. This does not prove signature trust or long UIKit behavior.

[Download exact DEB](https://raw.githubusercontent.com/Renatasy83/PullOverPro/50b1390a373052f90622b47376a59aaa92c56898/release-candidates/1.0.9-rc10/com.renatasy83.pulloverpro.diagnostic_1.0.9~rc10_iphoneos-arm64.deb)
321086bytes; SHA256`fd4a6aba30a603e5dcbb33efa9c6ee4b19a1aa6fa589e8727597fc685a9c72cf`; Git blob`31cae78d10c47d151d1b0709e1372771f26d718a`. Archive branch release-candidates/1.0.9-rc10/commit`50b1390a373052f90622b47376a59aaa92c56898`. Uploaded blob and raw permanent download independently matched. ZIP1377319bytes/SHA2563628a3bb94f9d43966c500b6ea414342717eab3f8025e0b71a53536115792397.

Ubuntu41946753305/job126980756038 succeeded for13 portable/source/lifecycle/cross-analysis suites. Evidence13379376474 independently verified, including598/1804 markers and no DEB. Unsupported Linux arm64e correctly skips packaging; do not call that evidence-only green run the delivered package or weaken its gate.

## Newly confirmed device evidence

User confirmed RC9 works under the requested two consecutive timed-window procedure. Supplied host-1.0.8 has two clean15.025650/15.024213s Messenger sessions, schema3 phase3 flags31/15, distinct owned proxies, controller/workspace invalidations returned, closed/unpinned/unpoisoned/replacementAllowed=true. First bit16 means weak baseline absent OR current root differed, not which case; current-root ownership passed. Same-process interpretation is procedural user context; no independent PID/boot/generation echo exists. Read [RC9 device result](RC9_MESSENGER_DEVICE_RESULT.md). Do not ask to redo RC9 merely to reconfirm it.

User's reported iPhone12,5/iOS26.0.1 build23A355/Dopamine rootless/ElleKit1.2 remains scope. Earlier RC8 normal full-screen Messenger return was explicitly confirmed. Other app/edge UI/favorites/preferences results have prior scoped reports; Messages worked with com.apple.MobileSMS. Do not retest unrelated apps.

Preserve exact RC9 recovery source d183e1b28caa7c4e1f380decab96608b74ff6cbf/archive3a1eecdbffba0c576ea7790af541bb2db68b192c/DEBSHAfd50b7bcf8671903733f574a5103d5dc4786d8eab25e9b96121cdea32fe0a502. RC8 and older remain accessible.

## RC10 implementation boundaries

Explicit Messenger-only "Păstrează (max. 2 min)" action; ordinary15s default unchanged. New PPOMessengerKeepPolicy starts once BEFORE owned allocation/prepare, absolute120s includes startup, cannot reset on Keep. Fresh positive rendering and refreshed lifetime/time after the probe reject late requests. Normal scene/lock/disable/protected/activation/render checks still win. Agent observation cap125s starts at later owned scope, giving nominal5s cleanup margin, not a guarantee under frozen/private callbacks.

Manual Keep only for Messenger; global Keep preference ignored, cold/resize/minimize/pan blocked. No new private method, app launch/kill, focus/key-window request, root assignment or arbitrary reparenting. Schema4/channelsv4 isolate still-loaded v3/20s helpers. Existing exact585 Info SHA/UIKitUUID, explicit rearm generation/scene/timer/lifecycle guards and own-proxy/cleanup/quarantine remain. Root reports messengerMaximumSeconds120/messengerAbsoluteDeadline; lifetimeMode "kept" remains compatible and is bounded by those fields.

Read [design](RC10_BOUNDED_MESSENGER_KEEP.md) and [actual test report](VALIDATION_1.0.9_RC10.md).

## Latest device result: no repeat of this gate is needed

User supplied host-1.0.9.json and explicitly confirmed it works, closes after two minutes and returns to normal full-screen Messenger. One session is kept, reason messenger-session-limit, root maximum120. Budget start77289.589860875 precedes prepare; explicit Keep at+5.595212s, heartbeats at~35.822/65.821/96.071s, close-returned+120.087649s (deadline overshoot~0.087649s). Window-shown is no longer retained in the bounded history, so this is budget duration, not exact visible-window timing.

Schema4 phase3/flags31, clean distinct-owned proxy/controller/workspace invalidations, closed/unpinned/unpoisoned/replacementAllowed=true. Bit16 means absent/different weak baseline, not a proven literal replacement. Late2-layer/active/valid samples precede close; user confirmation establishes visible normal full-screen return. Automatic touch/keyboard flags remain false; no independent routing/continuous-pixel proof is claimed. Read [RC10 device result](RC10_MESSENGER_DEVICE_RESULT.md).

This confirms the requested bounded Keep outcome as reported for this exact device/profile, not unlimited Keep, long repeated cycles, manual-X/resize/minimize/cold/background/lock transitions or global app/Dopamine/ElleKit compatibility. Do not request the same2minute test again, treat its visible answer as missing, or publish another DEB merely to reconfirm it. Current candidate/archive above is the latest scoped recovery point; RC9/RC8 remain intact.

## Current next gate: background hosting on existing RC10

Read-only audits of runtime checks/notifications/agent visibility plus prior evidence show existing1.0.9 can be tried over NewTerm without any code change or reinstall. Foreground admission is startup-only; lifetime checks use the SpringBoard host and owned child, not an ongoing original-app foreground requirement. Rendering/activity loss still closes through existing guards. Background original-window return can legitimately defer visibility (flag32) until manually foregrounded; no app activation/focus is requested. Real background retention/input/later unhide cannot be established statically. RC10/RC9 reports do not establish this Messenger case; old pre-hosting RC5 and Safari success must not be substituted.

Only indispensable next phone input: use currently installed1.0.9; start over normal visible Messenger, create PPO window and select bounded Keep; switch to NewTerm without app termination; check small Messenger content/input and NewTerm touches outside for~10seconds; close PPO with X while NewTerm stays foreground; manually open Messenger normally and check full-screen UI. Send new host-1.0.9.json+observations. If black/automatic closure/refusal occurs, stop and send report rather than loops. No respring/reinstall, new DEB, shell commands, personal Data or repeated2minute gate. See [background gate audit](RC10_MESSENGER_BACKGROUND_GATE.md).

Saved helper flag32 may be correct while NewTerm is foreground, and root's2second post-close samples may precede later manual foreground/unhide. Do not claim failed return from that frozen state alone. No compatible physical device/Mac/vphone environment is available; unchanged host tests cannot substitute for this gate.

Broader lifetime work still requires coordinated design: removing120s would outlive the125s helper. Do not silently remove limits or claim unlimited/general compatibility. No runtime/package modification or new automated tests/CI were needed for this read-only audit and necessary existing-version gate.

## Workflow/recovery

Continue implementation/build/static/native validation autonomously until a necessary real-device gate. Never request automatable intermediate tests or routine permission, install/respring/kill automatically, delete personal data or alter other tweaks. Preserve GPL-3.0/c1d3r attribution. Keep this root file current for OpenCode; fresh-fetch active head and preserve intervening changes with explicit tree delta/CAS, never broad local-index push/reset.

Active debug/two-stage-handle-messages. Mainaf336d84a6b4812e6b6406af87803fb15bf29c3b, stable/verified-rc2-safari-source-free-classic-reuse=e5c6e53f659109d77d78a5a99f7139899a978991 and old archives untouched. Recovery /var/mobile/.ppo_disable+manual respring or known Dopamine without injection/uninstall only PPO if unusable. No automatic phone action performed.

[Historical RC10 implementation checkpoint](docs/OPENCODE_HISTORY_THROUGH_RC10.md) and [earlier history](docs/OPENCODE_HISTORY_THROUGH_RC9.md) are historical; old pending statuses/questions may be superseded. Earlier SpringBoard watchdog causes remain unconfirmed; do not blame Dopamine/ElleKit or infer exceptions without logs.
