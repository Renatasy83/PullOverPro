# PullOver Pro 1.0.12~rc13 — Messenger minimize and restore candidate

Tested source `3b3e320bca7ccf15c3cbf7c1a349d5e8c4705079`. [macOS Actions42956204214](https://github.com/Renatasy83/PullOverPro/actions/runs/42956204214) passed all39 native suites, Clang analysis, pinned Theos/SDK16.5 rootless arm64+modern arm64e build and package checks. Linux42956204227 passed13 portable suites/source/lifecycle/static analysis; unsupported ABI0x2 correctly skipped packaging.

DEB `com.renatasy83.pulloverpro.diagnostic_1.0.12~rc13_iphoneos-arm64.deb`: 323518 bytes; SHA256 `b07cab134c6ce7ff27006e508fef14d203b9e3eb74c66592895a1e61a1ea28f5`. ZIP/39-marker/source/payload/filter/lifecycle/license/six-binary and code-signature bounds checked.12 analysis logs have no diagnostics; full job has12 obsolete linker-option warnings. Actual UIKit behavior and signature trust are untested.

RC13 enables only the existing public Minimize menu/action and Restore action for Messenger. The44point bar clips PPO's own panel; positive expanded viewport, wrapper and native child stay attached. Agent/profile/schema5/scene owner and geometry/lifetime/Keep policies are unchanged. No new private API or clock reset. Keep exact585/586 warm profiles, initialStandard,15seconddefault/120secondroot/125secondAgent and all ownership/render/lock/cleanup guards. Cold Messenger, unlimitedKeep and headerless mode remain outside this stage.

## One necessary physical test

Manually install/respring. Open Messenger normally, open its PPO window and choose bounded Keep. Switch to NewTerm, menu->Minimizează, check outside-bar input/scrolling, move the bar, restore with▢ and check content/simpletap/scroll. Minimize again and close the bar withX, then manually foreground Messenger and check normal full-screen UI. Send `/var/mobile/Library/Logs/PullOverPro/host-1.0.12.json`. Stop on refusal/black/unexpectedclosure; retain exactmessage/interface-1.0.12.json. No protocol-driven forced Messenger restart or repeated other-app/cold/priorresize/two-minute test needed.

RC12's reported working Messenger586 geometry and clean manual return are preserved at stable/verified-rc12-messenger586-geometry (8f0c64f5ce82913b8cb99ef7bcecf0de6b307fa2), DEB archivec08bc044455f6a6d359626891ede89915c75a34c. Prior archives/main/scopedstable/GPL-3.0/c1d3r attribution retained. No automatic phone action, personal-data deletion or other-tweak change. Recovery: /var/mobile/.ppo_disable plus manualrespring, orknownDopamine withoutinjection anduninstallonlyPPO ifunusable.
