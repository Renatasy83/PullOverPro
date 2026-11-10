# PullOver Pro 1.0.11~rc12 — Messenger 586 warm-trial candidate

Tested source `6928d998ea54583faf8a6e79ab6a897da72419b7`. [macOS Actions42753494551](https://github.com/Renatasy83/PullOverPro/actions/runs/42753494551) passed all39 native suites, Clang analysis and pinned Theos/SDK16.5 rootless arm64+modern arm64e build. Linux42753494965 passed13 portable suites/source/lifecycle/cross-target analysis; its unsupported0x2 ABI correctly skipped packaging.

DEB `com.renatasy83.pulloverpro.diagnostic_1.0.11~rc12_iphoneos-arm64.deb`: 322794 bytes; SHA256 `5b1860200f514cbc4ddb971898837ce2a54672d6a5f240c17db4753ea0e37c1a`. Independent ZIP/39-log/source/DEB/payload/license/filter/six-fat-binary and bounded code-signature checks passed. Analysis logs show no warnings/errors;12 obsolete linker-option warnings remain. Signature trust and actual UIKit/ElleKit behavior are untested.

Exact586.0.0/build1105932679 metadata was separately reviewed alongside preserved585, each bound to its own hash and structural tuple. Both are unknown/eligiblefalse, warm-only. Metadata matches do not establish application code or lifecycle equivalence. New schema5/channelv5 rejects old585-only companion state. No new private selector, cold fallback, minimize/restore or unlimited Keep. Existing Standard/drag/resize/120secondroot/125secondcompanion/ownership/cleanup guards remain.

## One necessary physical test

Manually install/respring. Close Messenger from the switcher and reopen normally to load newv5. Open its PPO window and choose boundedKeep before15seconds. Switch to NewTerm, move by title and cycleLarge/Compact/Standard, checking content/simple tap/scroll and NewTerm touches outside. Close X, manually foreground Messenger and check normal fullscreen UI. Send `/var/mobile/Library/Logs/PullOverPro/host-1.0.11.json`. On refusal or black, stop repeating and retain exactmessage plus capability-1.0.11.json/interface-1.0.11.json. No other-app/repeated2minute/cold/minimize probe.

RC10 archive50b1390a373052f90622b47376a59aaa92c56898 and RC11fe48837528401c61e81372d1ebc1e012ad4cfbd1 preserved. Main/scopedstable/GPL-3.0/c1d3r attribution retained. No automaticphoneaction, personaldata deletion orother-tweak change. Recovery: /var/mobile/.ppo_disable with manualrespring, orknownDopamine withoutinjection anduninstallonlyPPO ifunusable.
