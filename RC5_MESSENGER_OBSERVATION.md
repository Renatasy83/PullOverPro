# RC5: existing Messenger scene observation

Version1.0.4~rc5. Executable source ca1c56ba1937a815f8762552685ceb0c18b83c7b, development branch debug/two-stage-handle-messages. CI results and permanent DEB are recorded in OPENCODE_HANDOFF.md after validation. This candidate does not fix or enable Messenger floating windows.

## Why a phone observation is necessary

The installed Messenger585.0.0/build1101076820 plist is missing UIApplicationSceneManifest. Current metadata admission refuses it. Offline23A355 UIKit analysis found that lifecycle adoption also depends on actual delegate callbacks; a wrapper can be created without proving app content. The supplied plist and native fixtures cannot establish the existing Messenger scene's real specification, role, active/background state or layer counts. See MESSENGER_LEGACY_AUDIT_23A355.md. Messages already works with com.apple.MobileSMS and requires no repeat test.

## Scope and safeguards

Only a fresh, normalized unknown/scene-manifest-missing result for com.facebook.Messenger, following an explicit user app-opening action, may request this diagnostic. Existing overlay/lock, selection epoch, intent cancellation and no-active-host guards still apply. Four observations maximum per SpringBoard process, at least two seconds apart; only the latest two are retained. No timer or automatic retry. Original missing-manifest admission remains a refusal.

PPOSceneObservation checks the disable marker and exact existing framework UUIDs, then reuses bounded same-app unique scene enumeration (256 scenes/100ms cooperative limit). Missing/ambiguous results do not read further source facts. For a unique source, it reads the existing definition/specification/normal application role through already audited getters and ABI checks, then reuses the existing layer-state probe. Only normal specification/role Boolean results, selection counts/status, layer types/count and active/background flags are reported. No raw scene identifier, layer/context identifier, app pixels/content, app delegate class, paths or pointers are retained. This does not inspect the Messenger process's delegate.

No Messenger launch, new-scene allocation, activation, presenter, resize, settings change, teardown or source mutation is requested. Existing owner/admission/cleanup production files are unchanged; PPOOwnedSafariTrial differs only in version/report labels. Settings version text, package version and report filenames move to1.0.4. General Dopamine/ElleKit compatibility and Messenger hosting are not established by CI.

The cooperative enumeration deadline cannot interrupt a private getter already executing; exact firmware/ABI and read-only constraints reduce scope but do not prove runtime safety. Existing recovery and the permanent RC4 DEB remain available. The user reports a slow phone and attributes it to the battery; no cause is established by this work. No automatic installation/respring is performed.

## Automated evidence

Source-policy and Python syntax checks passed locally. Independent source comparison verified that owner/admission/lock/bridge implementations were not changed and the existing owned-trial implementation matches after version/report-label normalization. The new native fixture suite covers foreground/background reads, missing/ambiguous scenes without deeper reads, wrong specification/role/layer objects, wrong app/reason/stale capability, disable/framework/class/thread gates, JSON serialization and omission of the private scene token. Actions runs all35 suites with ASan/UBSan where configured, Clang analysis, pinned Theos rootless arm64/arm64e compilation and payload/binary inspection. Consult the handoff for actual completed run/hash, not this description of configured checks.

## Only necessary phone gate

After manual installation and one manual respring:

1. Open Messenger normally from its app icon. While Messenger stays full-screen, try opening Messenger from PPO once. Expect a diagnostic message and no new window.
2. Switch to NewTerm. Wait at least two seconds, then try opening Messenger from PPO once more, keeping Messenger selected.
3. Share only /var/mobile/Library/Logs/PullOverPro/messenger-1.0.4.json (zip it if the upload rejects JSON).

Do not close/kill Messenger between these observations, force-launch it repeatedly, alter its bundle or collect its Data container. A not-found or ambiguous report is useful evidence; do not try to make it succeed by disabling guards. More than four attempts require a new process; no extra respring is requested merely to repeat the test. If PPO is hidden by the existing disable marker, keep it disabled until deliberately ready for the test; do not interpret absence as a new rendering failure.

This gate cannot prove a second Messenger window or the cause of phone slowdown. Decide the next route from the actual report before changing admission or hosting.

## Recovery

To disable PPO only: create /var/mobile/.ppo_disable and manually respring. If SpringBoard is unusable, use the previously successful recovery of rebooting and enabling Dopamine without injection, then uninstall only PPO. No personal data or other tweak is to be modified.

Permanent previous RC4:
https://raw.githubusercontent.com/Renatasy83/PullOverPro/689d179ae4a722e67aca33cf74b318a5a5ee8a2a/release-candidates/1.0.3-rc4/com.renatasy83.pulloverpro.diagnostic_1.0.3~rc4_iphoneos-arm64.deb
SHA256345d6121198c50ea6030988bfee78c24b88a7bb0a12306b7223e8f4d14f4b297.
