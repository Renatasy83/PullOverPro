# PullOver Pro 1.0.7~rc8 — scoped Messenger return candidate

Source `e92284e6e2679cfc11235273da367b5a32dc50a1`. macOS Actions run41903532726 succeeded with37 suites, Clang analysis, pinned Theos/SDK16.5 rootless arm64+arm64e packaging. This exact DEB was independently checked for source/report/ZIP/DEB hashes, payload, six signed Mach-O binaries, modern arm64e ABI and v2 companion/consumer markers. Signature bounds are checked; device trust/execution is not.

DEB `com.renatasy83.pulloverpro.diagnostic_1.0.7~rc8_iphoneos-arm64.deb`: 316630bytes, SHA256 `6a2784f8a3194220669a96a68e2cfdbec10ea42799c957d73477f48f70632c69`.

RC8 retains the exact original Messenger UIWindow and accepts its current root only when public UIKit verifies that root/view belong to this same window. It never reinstalls an old root or reparents another controller/view. RC7 telemetry identified refusal on its previous root condition; no new visual RC7 outcome was supplied. RC8 return remains untested on a phone.

The separate Ubuntu workflow passed12 portable suites/source/lifecycle/static checks but demonstrated unsupported Linux arm64e ABI and correctly produced no DEB. It is not the package build. Full macOS evidence above is separate.

One indispensable test: manually install/respring, manually close/reopen Messenger so v2 loads, immediately open one timed PPO Messenger window, let it close, wait2seconds and observe whether original full-screen UI/touch return. Collect `/var/mobile/Library/Logs/PullOverPro/host-1.0.7.json`. During-trial black original background may remain. Earlier verification refusal needs capability-1.0.7.json instead. No general compatibility claim.

Recovery remains `/var/mobile/.ppo_disable` plus manual respring, or Dopamine without injection and uninstall only PPO if SpringBoard is unusable. Previous RC7 and older stable archives remain. No automated phone actions were performed. GPL-3.0 and original PullOver Pro attribution preserved.
