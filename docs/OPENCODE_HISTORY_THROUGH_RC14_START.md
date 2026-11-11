## RC13 device gate passed (2026-11-11)

User confirms Funcționează with host-1.0.12.json. ExactMessenger586/schema5 hosted session has4minimizes/3restores/6moves/2resizes, positive260×376viewport/native414×896, manualclose whileminimized, cleanownedteardown/replacementAllowed. Budgetelapsed58.187716s is not exactvisibleinterval; initialshown/Keep discarded. Helper5/phase3/flags47deferred32/readyfalse expectedpostclose. Firstattempt refusedbeforeownedprepare atforeground/source readiness, notminimizeregression. User suppliesactualpixels/outsideinput/normalreturn; telemetryflagsremainfalse. See RC13_MESSENGER_DEVICE_RESULT.md; don'taskcompletedprobeagain.

RC13 recovery source3b3e320bca7ccf15c3cbf7c1a349d5e8c4705079/archive7f77890d4229375c83050683eb0ef6718b90b9ef/DEBSHAb07cab134c6ce7ff27006e508fef14d203b9e3eb74c66592895a1e61a1ea28f5 preserved. Main/scopedstable/RC12/olderarchives unchanged. No genericcompatibility/cold/headerless/120expiry claim.

Nextwork RC14: honorMessenger requestedwindowSize3 Sertar whilekeepingotherinitialpresetsStandard andautomaticKeepoff; exposeexistingweak/liveguarded UIMenu onlongpress existinghandleX, withtapstillclose andparentgestureexclusion preserved. No newprivateAPI/scenecreation/nativeframe/rootassignment/clockreset; samev5Agent/profile/120root125agent. Do notguesscontextmenuhit-routingorbroadenUIKitprivatehit classes. Full39native/13portable/static/Theosbuild/artifactinspection beforenewDEB; onlynextphonegate afterchecks headerlesscontent/menuKeepactualselection/edgeretract+reopen/menuMinimize+restore/tapX/normalMessenger. ExistingRC13probeneednotrepeat. Earlierpendingstatusesbelow superseded.

---

# PullOver Pro — OpenCode / ChatGPT handoff (2026-11-11)

## Current candidate: RC13 Messenger minimize and restore

Version `1.0.12~rc13`, executable source `3b3e320bca7ccf15c3cbf7c1a349d5e8c4705079`, on `debug/two-stage-handle-messages`. RC13 changes exactly three presentation decisions in `PPOOwnedSafariTrial.mm`: expose the existing Keep/Minimize menu for Messenger and remove the two Messenger-specific early returns from minimize and restore.

The existing action guards, positive expanded viewport, wrapper and native child containment remain. The minimized panel clips to a 44-point bar; restoration uses the existing public layout path. Agent, profile, transport/schema 5, scene owner, geometry, presentation and lifetime policies are unchanged. No new private API, scene recreation, root assignment or deadline reset is introduced. Preserve exact 585/586 profiles, foreground warm admission, initial Standard size, the 15-second default, 120-second root cap and 125-second companion cap, plus all ownership, render, lock, cleanup and quarantine checks. Cold Messenger, unlimited Keep and headerless Messenger are outside this stage.

Read [RC13 design](RC13_MESSENGER_MINIMIZE_RESTORE.md) and [validation report](VALIDATION_1.0.12_RC13.md). The existing presentation, lifetime and Keep fixtures are reused; no redundant implementation-mirroring tests were added. They cannot establish actual Messenger clipping or remote touch routing.

## Automated evidence and package

**Automated validation passed; the candidate is ready for the single physical test below. Minimized Messenger input/rendering and close-from-bar return remain untested.**

[macOS Actions 42956204214](https://github.com/Renatasy83/PullOverPro/actions/runs/42956204214), job `130311804545`, passed all 39 native suites, Clang analysis, the pinned Theos/SDK 16.5 rootless build and package inspection. Artifact: `13827159319`; ZIP: `1382838` bytes, SHA256 `8c2e8015e8b3d6b87dc9efe3f0f6324d72730af0af72140000ed4835a3d3bc53`. Exact source, all 39 successful markers, ZIP CRC/hash, payload/filter/lifecycle/license and all six actual arm64/modern arm64e binaries were independently checked, including a second source/artifact review. Twelve recorded analysis logs have no diagnostics; the full job has exactly 12 obsolete -multiply_defined linker-option warnings. Profile296/state1805/client74/warm-owner859/cold-owner204/Keep598/geometry108812/presentation403376 assertions passed. The Agent __TEXT,__text section matches RC12 in both slices; whole images differ, so do not claim whole-binary identity.

[Linux Actions 42956204227](https://github.com/Renatasy83/PullOverPro/actions/runs/42956204227), job `130311804538`, artifact `13827556315`, passed 13 portable suites, source policy, 46 lifecycle checks and cross-target static analysis. ZIP: 5,876 bytes, SHA256 `dcd7aaf793df528fd32561f850d7362c0688eb41519b0a8ed10d002578eab080`; digest and CRC independently checked. Unsupported ABI subtype `0x2` correctly prevented Linux packaging. This is evidence only; the deliverable comes from the verified macOS build. Local portable, source, lifecycle and Python syntax checks also passed.

[Exact candidate DEB](https://raw.githubusercontent.com/Renatasy83/PullOverPro/7f77890d4229375c83050683eb0ef6718b90b9ef/release-candidates/1.0.12-rc13/com.renatasy83.pulloverpro.diagnostic_1.0.12~rc13_iphoneos-arm64.deb): `323518` bytes, SHA256 `b07cab134c6ce7ff27006e508fef14d203b9e3eb74c66592895a1e61a1ea28f5`, Git blob `9a3421432e5517e96b6e064efed025c68c890d4f`. Permanent archive `release-candidates/1.0.12-rc13`, commit `7f77890d4229375c83050683eb0ef6718b90b9ef`. The immutable raw download was verified against the built DEB hash and length. A build or bounded code-signature command inspection does not establish signature trust or device compatibility.

## Only next physical test

Manually install/respring RC13. Open Messenger normally, open its PPO window and select bounded Keep. Switch to NewTerm, choose **Minimizează** from the menu, check NewTerm input/scrolling outside the bar, and move the bar. Restore with **▢**, check Messenger content and a simple tap/scroll, then minimize again and close the bar with **X**. Manually foreground Messenger and check its normal full-screen interface.

Send `/var/mobile/Library/Logs/PullOverPro/host-1.0.12.json`. On refusal, black content or unexpected closure, stop repeating and retain the exact message plus `interface-1.0.12.json`. No messages or personal app Data are needed. Do not repeat other-app, cold-start, prior resize or two-minute expiry tests. The companion/protocol is unchanged, so no forced app restart is required just to reload the protocol.

Actual minimized-bar passthrough, restored content/input and close-from-bar return remain unconfirmed until this test. No general Dopamine/ElleKit or application compatibility claim is justified.

## Confirmed RC12 recovery baseline

The user said “Funcționează” and supplied `host-1.0.11.json` after the requested RC12 probe. The report confirms the exact Messenger 586 trial, schema 5, three completed moves and five resizes across all three presets, with native geometry retained at 414×896. The kept session closed manually; owned controller/workspace invalidations returned, the owner was closed, unpinned and unpoisoned, and replacement was allowed.

The root budget consumed 66.125255 seconds. This is **not** an exact visible interval: bounded retention discarded `window-shown` and the Keep-entry event. Retained hosted active/nonbackground 1–2-layer samples span 53.749623 seconds while the original scene is backgrounded with no layers. Helper schema 5/phase 3/flags 47 includes deferred visibility; post-close `ready=false` is expected. Actual pixels, input and later normal appearance are user observations, not independent proof from these metadata. Telemetry verification flags appropriately remain false. See [RC12 device result](RC12_MESSENGER_DEVICE_RESULT.md); do not request that completed probe again.

Preserve `stable/verified-rc12-messenger586-geometry` at evidence commit `8f0c64f5ce82913b8cb99ef7bcecf0de6b307fa2`. Its executable source is `6928d998ea54583faf8a6e79ab6a897da72419b7`; archive `c08bc044455f6a6d359626891ede89915c75a34c`; DEB SHA256 `5b1860200f514cbc4ddb971898837ce2a54672d6a5f240c17db4753ea0e37c1a`. Keep RC11 archive `fe48837528401c61e81372d1ebc1e012ad4cfbd1` and RC10 archive `50b1390a373052f90622b47376a59aaa92c56898` accessible.

## Tandem workflow and recovery

Fresh-fetch the remote head and this handoff before editing. Preserve OpenCode changes through explicit Git tree deltas and CAS updates; never use a broad index reset or push. Update this root handoff at meaningful checkpoints and work autonomously until a necessary physical gate. Keep `main` at `af336d84a6b4812e6b6406af87803fb15bf29c3b` and the earlier scoped stable branch at `e5c6e53f659109d77d78a5a99f7139899a978991` unchanged. Preserve GPL-3.0 and c1d3r attribution, all recovery archives, personal data and other tweaks. No automatic install, respring or process termination.

Recovery: create `/var/mobile/.ppo_disable` and manually respring; if the phone is unusable, use the known Dopamine procedure without tweak injection and uninstall only PPO. The earlier watchdog cause remains unconfirmed.

Device scope is the user's reported iPhone12,5 / iOS 26.0.1 build 23A355 / Dopamine rootless / ElleKit 1.2. No physical device or compatible physical Apple Silicon Mac/vphone environment is accessible here. Hosted Intel macOS CI runs native fixtures and builds; it does not test UIKit scene hosting, entitlements, signature trust or overall runtime compatibility.

Earlier pending statuses in `docs/OPENCODE_HISTORY_THROUGH_RC13_START.md` are superseded by the scoped RC12 result above.

This final checkpoint changes documentation only; the exact tested executable source remains `3b3e320bca7ccf15c3cbf7c1a349d5e8c4705079`. No further executable build was needed for the handoff update.
