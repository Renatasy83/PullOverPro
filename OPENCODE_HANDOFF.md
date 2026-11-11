# PullOver Pro — OpenCode / ChatGPT handoff (2026-11-11)

## Current candidate: RC14 Messenger edge drawer

Version `1.0.13~rc14`, executable source `586608c13cff2557fffbb3c04233a361ab593890`, on `debug/two-stage-handle-messages`. RC14 honors requested Messenger `windowSize == 3` (**Sertar**). Other initial presets retain Standard, and automatic Keep remains off.

The existing headerless drawer uses public panel/wrapper geometry. A main-thread-only getter returns the existing actions menu only for a live reviewed Messenger classic session; it performs no private sampling. Long-press the handle **X** for its weak, exact-trial Keep/Minimize actions. Tap-X still closes. Parent pan/long-press recognizers exclude X descendants. Binding changes only when menu identity changes and clears when X is hidden or inactive; closed/expired action callbacks cannot control a replacement.

Headerless content starts at y=0 and was added after the chrome. A 44-point clip alone would leave it above minimized controls. RC14 validates panel/control ownership and brings only title, restore and X to front, preserving the positive viewport, wrapper, native frame, visibility and containment. Classic restoration uses the existing edge geometry and re-anchors the panel.

Agent, exact 585/586 profiles, schema 5 transport, scene owner, geometry and lifetime/Keep policies are unchanged. Preserve warm foreground admission, current root/window/scene/framework/owner/proxy, render/lock/cleanup/quarantine gates, the 15-second default, 120-second absolute root cap and 125-second companion cap. No private API, scene recreation, root reassignment, deadline reset, cold Messenger, automatic foreground launch or unlimited Keep is introduced.

Read [RC14 design](RC14_MESSENGER_CLASSIC_DRAWER.md) and [validation](VALIDATION_1.0.13_RC14.md). Existing fixtures and source guards are reused; no algorithm warrants mirror tests.

## Automated evidence and archive

**Automated validation passed. The candidate is ready for the single physical gate below; actual headerless menu/input/retract behavior remains unconfirmed.**

[macOS Actions 42981254906](https://github.com/Renatasy83/PullOverPro/actions/runs/42981254906), job `130391958183`, passed all 39 native suites, Clang analysis, pinned Theos/SDK 16.5 rootless arm64/modern arm64e build and package inspection. Artifact `13837724141`; ZIP `1384170` bytes, SHA256 `bd43276370710a54c5ca2b4e827b7e427867759ce6497d2f91dbb230f0ec795b`. Exact source, all39 successful markers, ZIP CRC/hash, DEB bytes, payload/filter/lifecycle/license and all six actual binaries were independently verified, including a second source/artifact review. Twelve analysis logs contain no diagnostics; the full job has exactly12 obsolete -multiply_defined linker warnings and no errors. Profile296/state1805/client74/warm-owner859/cold-owner204/Keep598/geometry108812/presentation403376 assertions passed. Both root slices contain the new menu, own-chrome ordering and report markers. Agent __TEXT,__text matches RC13 in both slices; whole images differ, so do not claim binary identity.

[Linux Actions 42981254926](https://github.com/Renatasy83/PullOverPro/actions/runs/42981254926), job `130391958010`, passed 13 portable suites, source policy,46 lifecycle checks and cross-target analysis. Artifact `13838155985`; ZIP `5878` bytes, SHA256 `1ffddc1fa58157137a1da0b7f5eb5f4f142a4e07131a49af0fece0f29cb3596b`. ZIP digest/CRC verified. Observed unsupported ABI `0x2` correctly prevented Linux packaging; the deliverable is the verified macOS build. Local 13 portable suites, source policy, 46 lifecycle checks and changed Python syntax checks passed.

[Exact DEB](https://raw.githubusercontent.com/Renatasy83/PullOverPro/b111008864ba8545ff8f1b92398bb0d1e6a30873/release-candidates/1.0.13-rc14/com.renatasy83.pulloverpro.diagnostic_1.0.13~rc14_iphoneos-arm64.deb): `323782` bytes; SHA256 `2d8c9105b3e13c9bba0539008928a1b1124435dd6c6b49faaf2f6b6fa8260d05`; Git blob `cf92af8e98a7e8c2580209a5046341f582391a89`. Permanent archive `release-candidates/1.0.13-rc14`, commit `b111008864ba8545ff8f1b92398bb0d1e6a30873`. The immutable raw download matches the built artifact hash and length. Bounded code-signature inspection is not signature-trust or device-runtime validation.

## Only next physical test

Manually install/respring. In PPO Settings select **Dimensiune inițială → Sertar** if needed. Open Messenger normally, then its PPO drawer. Within 15 seconds, long-press handle **X** and actually select **Păstrează (max. 2 min)**; check that neither tap-close nor the favorites chooser fired.

Switch to NewTerm, retract/reveal through the handle, then verify content and a simple tap/scroll in the same owned session. Long-press X → **Minimizează**, restore with **▢**, check content/input, then tap handle X. Manually foreground Messenger and check normal full-screen UI.

Send `/var/mobile/Library/Logs/PullOverPro/host-1.0.13.json` and `interface-1.0.13.json`. On refusal, black content or unexpected closure, stop repeating and identify the step. No other-app, prior resize, repeated two-minute, cold-start or personal app-data probe is needed. The protocol is unchanged; no forced Messenger restart is needed solely to reload it.

Actual menu selection routing and Messenger retract/reveal rendering remain unproven. UIKit may host its menu outside accepted overlay hit descendants. Do not broaden hit testing using guessed private classes or relax the render gate. Geometry/builds do not establish remote input or general Dopamine/ElleKit compatibility.

## Confirmed RC13 recovery point

User said “Funcționează” with `host-1.0.12.json`. One foreground/source-readiness refusal occurred before preparation; no retained sample identifies its constituent cause. One subsequent Messenger586/schema5 hosted session completed four minimizes, three restores, six moves and two resizes. The 260×376 viewport/native414×896 remained positive/unchanged; manual close occurred while minimized, with clean owned invalidations, unpinned/unpoisoned state and replacement allowed.

Budget elapsed was 58.187716 seconds, not an exact visible interval: bounded history discarded initial shown/Keep events. Helper5/phase3/flags47 includes deferred visibility32; post-close ready=false is expected. Real pixels, outside input and normal appearance are user observations; telemetry verification flags remain false. See [RC13 device result](RC13_MESSENGER_DEVICE_RESULT.md); do not repeat that completed gate.

Preserve `stable/verified-rc13-messenger586-minimize` at `c87589dc45eb4d5039081eff7015f48ad1ff4a7e`, executable `3b3e320bca7ccf15c3cbf7c1a349d5e8c4705079`, archive `7f77890d4229375c83050683eb0ef6718b90b9ef`, DEB SHA256 `b07cab134c6ce7ff27006e508fef14d203b9e3eb74c66592895a1e61a1ea28f5`. RC12 stable `8f0c64f5ce82913b8cb99ef7bcecf0de6b307fa2` and archive `c08bc044455f6a6d359626891ede89915c75a34c`, plus older archives, remain recovery points.

## Tandem workflow and recovery

Fresh-fetch remote head/handoff before editing; preserve OpenCode changes through explicit Git tree deltas and CAS. No broad reset/push. Update this root file at meaningful checkpoints and continue autonomously until a necessary physical gate. Keep main `af336d84a6b4812e6b6406af87803fb15bf29c3b`, earlier scoped stable `e5c6e53f659109d77d78a5a99f7139899a978991`, GPL-3.0/c1d3r attribution, personal data and other tweaks intact. No automatic install/respring/process termination.

Recovery: `/var/mobile/.ppo_disable` plus manual respring, or known Dopamine without injection/uninstall only PPO if unusable. Earlier watchdog cause remains unconfirmed. Reported device: iPhone12,5/iOS26.0.1 build23A355/Dopamine rootless/ElleKit1.2. No physical device or compatible Apple Silicon Mac/vphone environment is accessible; Intel CI cannot establish UIKit hosting, entitlements, signature trust or global compatibility. Historical pending RC13 statuses are superseded by the device result.

This final checkpoint changes documentation only. The tested executable remains `586608c13cff2557fffbb3c04233a361ab593890`; no additional executable build is needed for these records.
