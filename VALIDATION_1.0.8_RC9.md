# PullOver Pro1.0.8~rc9 validation

Source `d183e1b28caa7c4e1f380decab96608b74ff6cbf`. [Exact candidate DEB](https://raw.githubusercontent.com/Renatasy83/PullOverPro/3a1eecdbffba0c576ea7790af541bb2db68b192c/release-candidates/1.0.8-rc9/com.renatasy83.pulloverpro.diagnostic_1.0.8~rc9_iphoneos-arm64.deb).
DEB321808bytes; SHA256`fd50b7bcf8671903733f574a5103d5dc4786d8eab25e9b96121cdea32fe0a502`; Git blob`df2362d68980e6d767d0962ca2fef97854c7df6c`.
Permanent archive `3a1eecdbffba0c576ea7790af541bb2db68b192c`, branch release-candidates/1.0.8-rc9.

## Executed checks

- [macOS Actions41942732626](https://github.com/Renatasy83/PullOverPro/actions/runs/41942732626), job126967316222, artifact13378540672: success on standard macos-15-intel. Pinned Theos304e0799973e8145f32e4ca2de6c747a84b758ce and SDK0222fd5413cf4b9af096f37b4621afa2688572f7/iPhoneOS16.5, deployment15.0/rootless. Apple clang17.0.0/clang-1700.0.13.5 from Xcode16.4, GNU Make4.4.1.
- All38 test logs independently matched report/source and passed markers. New return policy:1803 assertions, including all8 rearm gates,100 synthetic cycles, generation exhaustion and stale disconnect/timer/lifecycle rejection. New prepare-client fixture:68 checks, actual main-queue scheduling around stubbed notify boundaries, delayed readiness, timeout, unavailable/refused/active state, stale capture and post failure. It does not establish real daemon authorization or UIKit execution.
- Existing native Foundation/CoreFoundation persistence, picker/intents, ABI, actual subprocess/mailbox/kqueue/replay/restart/timeout, scene/admission/layer/ownership, lock/lifetime and geometry fixtures passed. Owner854/cold201/profile92 retained. Clang source analysis and full rootless compile/package/payload inspection passed. Sanitizers are configured for state/policy fixtures; do not describe every native fixture as sanitized.
- ZIP1375284bytes/SHA256`49e900c5a39498b886186ae7c5eb3fbec737a9820383d34df72443a403a605f3` independently verified against GitHub artifact metadata. Exact report source,38-log inventory, package filename/version and checksum matched.
- Rootless filters, lifecycle scripts, license and payload policy passed. All six fat binaries have arm64 subtype0 and modern arm64e subtype0x80000002; command/code-signature bounds passed. This is not signature-trust or on-device injection validation.
- Both companion slices contain v3 return/explicit-prepare channels, public return selector, profile digest, dispatch registration and prepare handler. Both main tweak slices contain v3 consumer/post and requested/ready/refused UI markers. Old v2 channel markers are absent; checked companion slices have no root setter/key-window/focus selectors. No new private scene/framework method was introduced.
- Uploaded Git blob SHA and immutable raw download byte count/SHA256 independently matched the delivered artifact.
- [Ubuntu Actions41942732683](https://github.com/Renatasy83/PullOverPro/actions/runs/41942732683), job126967316762: success for12 portable suites/source/lifecycle/static checks. Evidence artifact13375869759 ZIP5582bytes/SHA256`fdca3a01d7951943bc581ab338b885f35b63ef9000b0d5ef9bb228160078c549` independently matched, including1803 return assertions and no DEB. Unsupported Linux arm64e subtype0x2 correctly skips packaging; this is not the delivered build.
- Local state tests1803 and changed Agent/client/Logos tweak cross-target analysis passed. Native client fixture also passed local cross-target syntax checking; its execution proof is macOS CI above.

Theos's existing linker option emits `-multiply_defined is obsolete` warnings. No incompatible-arm64e ABI or compile error appears in the delivered macOS build. Intermediate internal builds are not the delivered package.

## Confirmed baseline and remaining device gate

RC8 host-1.0.7 schema2 phase3/flags15 and clean teardown are accompanied by the user's explicit confirmation that original full-screen Messenger displayed normal content and worked after automatic closure. That scoped result is confirmed and must not be requested again under RC8. See RC8_MESSENGER_DEVICE_RESULT.md.

RC9 adds a different behavior: another timed Messenger PPO window in the SAME app process. A new explicit UI intent may prepare readiness only on the exact original connected normal scene/window/current-root ownership, active visible/key UI, protected data, no owned scene and settled timer/handoff/visibility. Completed verified state or still-unconsumed capture only; refused/active/uncertain state cannot reset. Generation/scene association, timer identity/deadline and connected lifecycle checks isolate old callbacks. One asynchronous metadata request/poll budget of1second does not open anything on cancellation. All warm-only/15second/no-Keep/no-cold/8second render/strict owner cleanup/quarantine guards remain.

NOT EXECUTED for RC9: actual repeated UIKit scene migration/return, original key-window state after return, new notify request delivery in Messenger sandbox, repeated real input/rendering, manual-X/Keep/minimize/resize or all lock/background/protected transitions. During-trial original-background duplication is not promised. No compatible physical Mac/vphone environment is accessible; hosted CI is not that environment. General app/Dopamine/ElleKit or repeated Messenger compatibility is unconfirmed.

Necessary single phone test: manually install/respring once, manually close/reopen Messenger to load v3, then open two consecutive timed PPO Messenger windows without terminating the app between them. Let each expire and observe whether full-screen Messenger content/input return. Send host-1.0.8.json; on readiness refusal send exact UI message plus interface-1.0.8.json and stop repeating. No other-app or personal Data test is requested.

RC8 recovery archivead0a2b4703d22e7a29588cbdbb8f15374126c58f remains accessible. Main/stable/older archives are preserved. Recovery /var/mobile/.ppo_disable plus manual respring, or known Dopamine without injection/uninstall only PPO if unusable. No automatic install/respring/app termination, personal-data deletion or other-tweak modification was performed. GPL-3.0/original attribution preserved.
