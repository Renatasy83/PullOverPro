# PullOver Pro — current OpenCode/ChatGPT handoff (2026-11-05)

## Current checkpoint: RC9 ready for one indispensable device gate

Latest validated executable source `d183e1b28caa7c4e1f380decab96608b74ff6cbf`, version1.0.8~rc9. macOS15Intel [Actions41942732626](https://github.com/Renatasy83/PullOverPro/actions/runs/41942732626)/job126967316222/artifact13378540672 succeeded with38 suites,1803 state checks,68 native async client checks, Clang analysis and pinned Theos/SDK16.5 rootless arm64+arm64e build. Apple clang17.0.0/Xcode16.4. All38 logs/source/report/hash/payload/filter/license/lifecycle/six-fat-binary/modern arm64e/signature-bounds/v3 handler+consumer markers independently verified. Signature trust/device execution is not proven by static inspection.

[Download exact DEB](https://raw.githubusercontent.com/Renatasy83/PullOverPro/3a1eecdbffba0c576ea7790af541bb2db68b192c/release-candidates/1.0.8-rc9/com.renatasy83.pulloverpro.diagnostic_1.0.8~rc9_iphoneos-arm64.deb)
321808bytes, SHA256`fd50b7bcf8671903733f574a5103d5dc4786d8eab25e9b96121cdea32fe0a502`, Git blob`df2362d68980e6d767d0962ca2fef97854c7df6c`. Permanent branch release-candidates/1.0.8-rc9, archivecommit`3a1eecdbffba0c576ea7790af541bb2db68b192c`. Uploaded blob and immutable raw download independently matched. ZIP1375284bytes/SHA25649e900c5a39498b886186ae7c5eb3fbec737a9820383d34df72443a403a605f3.

Ubuntu run41942732683/job126967316762 succeeded for12 portable/source/lifecycle/cross-analysis checks, including1803 return assertions. Evidence artifact13375869759 independently verified; unsupported ABI subtype0x2 correctly skips packaging and contains no DEB. Do not present that evidence-only green run as the package build or weaken its ABI gate. Intermediate internal sources82e7215/1b4882a were superseded; only d183e1b artifact above is delivered.

## What is actually confirmed on the phone

User's iPhone12,5, reported iOS26.0.1/build23A355, Dopamine rootless/ElleKit1.2. Existing app/window/favorites/preferences/edge UI functionality has prior scoped reports. Messages worked after selecting correct com.apple.MobileSMS identifier; do not retest unrelated apps.

RC8 Messenger: host-1.0.7 has one15.033808second warm trial, schema2 phase3/flags15, distinct owned proxy/child, controller/workspace invalidations returned, closed/unpinned/unpoisoned/replacementAllowed=true. User EXPLICITLY confirmed normal visible/working full-screen Messenger after automatic closure, with no black screen. That one-cycle return is confirmed; do not ask to repeat the RC8 question. No root replacement was observed at its accepted migration check (no16). See [RC8 device result](RC8_MESSENGER_DEVICE_RESULT.md).

Recovery exact RC8 sourcee92284e6e2679cfc11235273da367b5a32dc50a1/archivead0a2b4703d22e7a29588cbdbb8f15374126c58f/DEBSHA2566a2784f8a3194220669a96a68e2cfdbec10ea42799c957d73477f48f70632c69 stays intact.

## RC9 change and retained safety boundaries

RC8 readiness was intentionally one-shot. RC9 allows a new explicit opening intent to request public-notify preparation. Only exact original window/connected normal scene/current root ownership, active visible/key normal-level UI, protected data, no connected owned scope and no timer/handoff/deferred visibility can prepare. Successfully completed state or unconsumed capture only. Refused/active migration/uncertain state cannot rearm.

Nonwrapping generation+exact scene association isolate disconnect callbacks. Timer callbacks require captured generation and current timer/deadline; old cancelled callbacks cannot expire a new cycle. Disconnected old lifecycle events cannot consume fresh readiness. SpringBoard issues at most one request per explicit UI intent, polls metadata asynchronously50ms/max1second, and rechecks cancellation/selection/overlay/admission before consuming intent/private creation. Notify is a readiness hint, not authenticated identity/entitlement proof.

Schema3/channelsv3 isolate old loaded v2 libraries. No new private API, app launch/kill, root setter/arbitrary view reparenting or foreground/key-window/focus request. Existing exact Messenger585 Info SHA/UIKitUUID, warm-only/15s/no Keep/no cold/resize/minimize/8s render/strict owned child-proxy-workspace cleanup/quarantine guards remain. Main injection filter remains SpringBoard-only; separate exact Messenger filter unchanged.

Read [RC9 design](RC9_REPEATED_MESSENGER_WINDOWS.md) and [full validation](VALIDATION_1.0.8_RC9.md).

## Necessary next action: phone only

Manually install RC9/respring once, manually close/reopen Messenger initially to load v3. Then open TWO timed PPO Messenger windows consecutively in the SAME app process, letting each expire and checking full-screen content/input after each. Do NOT terminate Messenger between cycles. Send /var/mobile/Library/Logs/PullOverPro/host-1.0.8.json. If readiness refuses, retain exact message and interface-1.0.8.json rather than repeated attempts. No other-app or personal Data test is required.

RC9 repeated UIKit behavior/new request IPC/original key status after return remain untested. Do not claim all app/platform/Dopamine/ElleKit compatibility, manual-X/Keep or all lock/background cases. No physical compatible Mac/vphone environment is accessible; hosted runners do not establish one. During-trial original-background duplication is not promised. Do not enable all experimental functions together.

## Workflow and recovery rules

User wants autonomous implementation/build/static/native testing until an indispensable real-device gate. Never stop for routine permission, ask for automatable intermediate tests, install/respring/kill automatically, delete personal data or alter other tweaks. Preserve GPL-3.0/original c1d3r attribution. Keep this file updated for OpenCode handoffs. Fresh-fetch active branch/head before edits; preserve intervening edits via explicit Git tree delta/CAS, never broad local-index push/reset.

Active branch debug/two-stage-handle-messages. Mainaf336d84a6b4812e6b6406af87803fb15bf29c3b and stable/verified-rc2-safari-source-free-classic-reuse=e5c6e53f659109d77d78a5a99f7139899a978991 unchanged; RC8/RC7/older archives retained. Recovery /var/mobile/.ppo_disable plus manual respring, or known reboot/Dopamine without injection/uninstall only PPO if unusable. No automatic phone actions were performed.

Current source/report scope is authoritative above. Older full handoff preserved in [historical checkpoints](docs/OPENCODE_HISTORY_THROUGH_RC9.md); its pending questions/build statuses are historical, not current. Earlier SpringBoard watchdog causes remain unconfirmed; do not blame Dopamine/ElleKit or infer Objective-C exceptions without logs.
