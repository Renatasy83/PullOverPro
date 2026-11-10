# PullOver Pro — OpenCode / ChatGPT handoff (2026-11-10)

## Current gate: RC12 package ready; Messenger 586 needs one device test

Version **1.0.11~rc12**, tested executable source `6928d998ea54583faf8a6e79ab6a897da72419b7`. [Download exact DEB](https://raw.githubusercontent.com/Renatasy83/PullOverPro/c08bc044455f6a6d359626891ede89915c75a34c/release-candidates/1.0.11-rc12/com.renatasy83.pulloverpro.diagnostic_1.0.11~rc12_iphoneos-arm64.deb). Permanent archive `release-candidates/1.0.11-rc12`, commit `c08bc044455f6a6d359626891ede89915c75a34c`. DEB322794 bytes; SHA256 `5b1860200f514cbc4ddb971898837ce2a54672d6a5f240c17db4753ea0e37c1a`; Git blob `ca96490efd103eedbf9f6fe4a111baffb467dda1`. Uploaded blob and immutable raw download independently match the artifact. Previous packages remain accessible.

[macOS Actions42753494551](https://github.com/Renatasy83/PullOverPro/actions/runs/42753494551), job129622358785/artifact13734852405: **39 native suites passed**, Clang analysis, pinned Theos/SDK16.5/rootless arm64+modern arm64e build and payload checks. Artifact1381996 bytes/SHA2568e72fdf127f2a8d111a3ec487548ddbdba1ac4c87fe42bce0403ca3303b18004. Profile296/state1805/client74/warm-owner859/cold-owner204 checks. Second independent source/artifact review found no blockers; six actual fat binaries and bounded code signatures checked. All12 analysis logs have no diagnostics; whole job shows12 obsolete -multiply_defined linker warnings only. Signature trust and real UIKit behavior are untested.

Linux Actions42753494965/job129622362298/artifact13734831109 passed13 portable suites plus source/lifecycle46/static analysis. ZIP5876/SHA256aade7ede39700fca238421481977101f8e34c3cbb9b3f5c825dbceeaf249f060 independently verified. Its ABI probe0x2 is unsupported and correctly prevented packaging; this is evidence only, not the DEB build. Local13 portable suites/source/lifecycle/Python syntax also passed. Read VALIDATION_1.0.11_RC12.md and RC12_MESSENGER_586_PROFILE.md.

## What changed and why

User's current Info.zip contains raw Messenger586.0.0/build1105932679,22533 bytes/77keys/SHA354b8abc3acd00ae3a16f48e3b0156f1497be49742f6dc1db3753c13bbc89b9f. It differs from recorded585.0.0/build1101076820/SHA741517f9808a10ac225c6490d2af5bd835ff56b112464c5d53ce670d7ff92e30, consistently explaining the old exact-profile refusal before hosting. Historical raw585/full keylist unavailable; equal77count does not establish keyset/code/lifecycle equivalence. Update timing and what every old service loaded are unproved. Raw plist is not committed. Six supplied reports and current metadata are already reviewed; don't ask for them again.

RC12 preserves585 and adds a separately reviewed exact586 hash+version+build+structure tuple with distinct reserved reason. Both remain unknown/eligible=false, experimental warm-only. No generic scene-support bypass, cold fallback, new private selector or root-controller assignment. New schema5/channels return.v5 and return.prepare.v5 reject the old585-only v4 companion/state; **Messenger must be manually closed/reopened after installation** to load the new code.

Keep foreground/source-layer/capture/current-root/window/scene/framework/owner/cleanup/quarantine/render/lock checks, initialStandard, default15seconds, manual120second root Keep/125second companion. Existing public header drag and three size presets remain enabled. Messenger minimize/restore and unlimited Keep remain blocked. Agent observer now has an explicit scene!=nil guard, eliminating the previous analyzer warning without widening runtime permission.

## Only necessary next phone action

1. Manually install/respring RC12. Close Messenger from the app switcher and reopen normally to load the v5 companion.
2. Open Messenger in PPO and choose bounded Keep before15seconds. Switch to NewTerm, drag the title and cycleLarge/Compact/Standard, checking content/simple tap/scroll and outside NewTerm input.
3. Close X, manually foreground Messenger, check normal full-screen UI. Send `/var/mobile/Library/Logs/PullOverPro/host-1.0.11.json`. If admission is refused or content goes black, stop repeating; retain exactmessage and capability-1.0.11.json/interface-1.0.11.json.

No message sending, app Data, other-app, repeated2minute, cold or minimize test needed. Actual586 warm hosting/input/return and transformed input remain **unconfirmed** until this gate. Do not call this a general Dopamine/ElleKit compatibility result or final stable release.

## Preserved device baseline / recovery

User reports iPhone12,5 / iOS26.0.1 build23A355 / Dopamine rootless / ElleKit1.2. RC10 bounded120second Keep/full-screen return plus Messenger-overNewTerm/manualX/later normal foreground were user-confirmed on the prior585 profile. Reports show originalbg0layers versus ownednonbg2layers, schema4/phase3/flags47 deferred visibility, clean owned cleanup. RC11 was refused before hosting, so it supplied no transformed Messenger test. Other earlier apps' results are separately scoped.

RC10 recovery: sourcefd8e3b24305624ccb984c9063ac0667e52f925af, archive50b1390a373052f90622b47376a59aaa92c56898, DEBSHAfd4a6aba30a603e5dcbb33efa9c6ee4b19a1aa6fa589e8727597fc685a9c72cf. RC11 archivefe48837528401c61e81372d1ebc1e012ad4cfbd1, DEBSHA4e55e325704f8fe12bb78c0971ab7142864ea65973d0afa353a43d2efdb77e16. Both preserved; older585-only builds need not admit586. Mainaf336d84a6b4812e6b6406af87803fb15bf29c3b and scopedstablee5c6e53f659109d77d78a5a99f7139899a978991 unchanged.

Recovery: create `/var/mobile/.ppo_disable` and manually respring; if unusable use known Dopamine without injection and uninstall only PPO. No automatic install/respring/kill, personal-data deletion or other-tweak change was performed. Preserve GPL-3.0/c1d3r attribution. Earlier watchdog cause remains unconfirmed.

## Tandem workflow

Active `debug/two-stage-handle-messages`. Fresh-fetch remote head/handoff before edits; use explicit Git tree delta and CAS, preserve OpenCode changes; no broad index reset/push. This documentation-only checkpoint does not change the executable source `6928d998ea54583faf8a6e79ab6a897da72419b7` or require another build. Keep this root handoff current at meaningful checkpoints. Work autonomously until indispensable real-device gates. No compatible physical device/Apple Silicon Mac/vphone environment is accessible; hosted Intel CI cannot substitute.

Earlier pending statuses in docs/OPENCODE_HISTORY_THROUGH_RC12_PROFILE_INPUT.md are superseded here.
