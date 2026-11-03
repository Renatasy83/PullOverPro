# PullOver Pro1.0.4~rc5: Messenger observation candidate

Source: ca1c56ba1937a815f8762552685ceb0c18b83c7b.
Actions: https://github.com/Renatasy83/PullOverPro/actions/runs/41578881921
All35 suites passed, including63 new read-only observation fixture checks, Clang analysis, pinned Theos rootless arm64/arm64e build and package inspection. ZIP/DEB checksums,35 logs, fat binaries and compiled observation markers were independently checked. See VALIDATION.json.

This candidate collects a bounded read-only snapshot after an explicit Messenger missing-manifest refusal. It does not launch Messenger, create/activate/present/mutate a scene or fix Messenger hosting. Existing floating windows and admission/owner/cleanup stay unchanged. No automatic install/respring; exact firmware/ABI and identity gates remain. No new phone runtime test was performed; general Dopamine/ElleKit compatibility remains unconfirmed. Preserve GPL-3.0 and original c1d3r / Will Smillie attribution; the package includes the license.

DEB SHA256:9346849e94861872ecfd7eed27bf0f379b8f86b3bc84dc83356b37bf5e1612a2 (294756 bytes).

After manual installation and one manual respring, open Messenger normally; try opening it from PPO once with Messenger full-screen. Switch to NewTerm, wait at least2seconds and repeat the PPO attempt once. No new Messenger window is expected. Send /var/mobile/Library/Logs/PullOverPro/messenger-1.0.4.json (zip if necessary). Last2 snapshots are retained; maximum4 per SpringBoard process. Do not kill the app, modify its bundle, collect its Data container or repeat tests on other apps.

The user reports a slow phone and attributes it to the battery; this work establishes no cause. Recovery: create /var/mobile/.ppo_disable and manually respring; if SpringBoard is unusable, reboot and enable Dopamine without injection, then uninstall only PPO. Personal data/other tweaks are not to be changed.

Previous permanent RC4 remains:
https://raw.githubusercontent.com/Renatasy83/PullOverPro/689d179ae4a722e67aca33cf74b318a5a5ee8a2a/release-candidates/1.0.3-rc4/com.renatasy83.pulloverpro.diagnostic_1.0.3~rc4_iphoneos-arm64.deb
SHA256345d6121198c50ea6030988bfee78c24b88a7bb0a12306b7223e8f4d14f4b297.

Development details: RC5_MESSENGER_OBSERVATION.md and OPENCODE_HANDOFF.md on debug/two-stage-handle-messages. Main/stable/recovery references remain preserved.
