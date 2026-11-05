# PullOver Pro1.0.9~rc10 — bounded Messenger Keep candidate

Source `fd8e3b24305624ccb984c9063ac0667e52f925af`; macOS Actions41946753360 passed39 suites, including598 budget/composed lifetime checks and1804 return checks. Pinned Theos/SDK16.5 rootless arm64+modern arm64e build, Clang analysis and independent source/report/ZIP/DEB/payload/six-binary signature-bounds checks passed. Signature trust/device behavior is not established by static checks.

DEB `com.renatasy83.pulloverpro.diagnostic_1.0.9~rc10_iphoneos-arm64.deb`, 321086bytes; SHA256`fd4a6aba30a603e5dcbb33efa9c6ee4b19a1aa6fa589e8727597fc685a9c72cf`.

Adds only explicit Messenger Keep up to120seconds from pre-prepare start, ordinary15second default unchanged. Companion125second cap is coordinated through v4 isolation. Global Messenger Keep preference, cold start, resize/minimize remain disabled. No new private API. User-confirmed RC9 repeated timed restoration is retained as recovery; bounded long Keep is untested on a phone.

One necessary device gate: install/respring manually, close/reopen Messenger once to load v4, open one PPO window, select "Păstrează (max. 2 min)" before15seconds, verify usable beyond20seconds and let the cap close near2minutes; observe normal full-screen Messenger return. Send host-1.0.9.json, or exact refusal text/interface-1.0.9.json. No personal Data or other-app retests.

Prior RC9 recovery archive3a1eecdbffba0c576ea7790af541bb2db68b192c and main/stable/older archives remain. /var/mobile/.ppo_disable plus manual respring, or known Dopamine without injection/uninstall only PPO if unusable. No automatic phone actions or personal-data/other-tweak changes. GPL-3.0/original attribution retained.
