## Current tandem checkpoint — user-confirmed Messages

The user explicitly confirms that the real Messages application now works on RC4 after selecting the correct identifier, com.apple.MobileSMS. The earlier failed attempt targeted com.apple.mobilesms.compose. This is human functional confirmation, not a new host trace; exact input/cleanup operations beyond the user's statement are not inferred. Do not request another ordinary Messages test or installation just to repeat it.

Messenger has a single observed identifier, com.facebook.Messenger, and still does not work. The earlier RC4 capability report records unknown/manifest-unknown before host creation. This is NOT proof of explicit multiple-scenes=false, a black rendering failure or an exception. Its installed scene-manifest structure/version remain missing. Investigate that bounded metadata before any eligibility relaxation or alternative host route.

Runtime/package unchanged: RC4 executable8bd812121489f896f4e38d578da10ba0ce284039; existing34-suite/Clang/Theos evidence and permanent DEB remain applicable. No new runtime change/build was needed to record this confirmation. Do not claim every-app or general Dopamine/ElleKit compatibility.

## Required ChatGPT / OpenCode tandem workflow

The user requests that OPENCODE_HANDOFF.md ALWAYS be updated at each meaningful checkpoint, including completed work, exact branch/source/package/build/test references, new device evidence, unresolved issues and the next concrete action.

At the start of either tool's resumed session:
1. Fetch the current remote branch head and read this file before editing. Do not assume the previous chat or local checkout is current.
2. Inspect intervening commits and the working tree; preserve the other tool's changes. Never force-push, reset away work or overwrite an unexpected remote head.
3. Work on the active development branch or a documented new branch; main and existing stable/recovery refs remain preserved.
4. Commit scoped changes and update this handoff with the resulting checkpoint. Use a fresh ref/CAS or ordinary non-forced push. If branch, source or artifacts change, record them explicitly.
5. Separate runtime modifications, automated results and actual phone confirmations. Never present pending builds/tests as successful.

Current active branch: debug/two-stage-handle-messages. Remaining priority: Messenger's real installed metadata and safe hosting route; improve picker identity visibility so compose/helper entries cannot be confused with the main app. No automatic phone install/respring, personal-data deletion or other-tweak modification.

---

# OpenCode handoff

Continue on `debug/two-stage-handle-messages`. Main remains the Alpha4 reference; do not overwrite it.

## Current deliverable

Version: 1.0.3~rc4.
Tested executable source: `8bd812121489f896f4e38d578da10ba0ce284039`.
Actions: https://github.com/Renatasy83/PullOverPro/actions/runs/41477013922
Artifact:13157684936. All34 suites, Clang analysis and rootless arm64/arm64e packaging passed.
DEB SHA256: `345d6121198c50ea6030988bfee78c24b88a7bb0a12306b7223e8f4d14f4b297`.

Permanent download:
https://raw.githubusercontent.com/Renatasy83/PullOverPro/689d179ae4a722e67aca33cf74b318a5a5ee8a2a/release-candidates/1.0.3-rc4/com.renatasy83.pulloverpro.diagnostic_1.0.3~rc4_iphoneos-arm64.deb

See VALIDATION_1.0.3_RC4.md, TWO_STAGE_HANDLE_MESSAGES_RC4.md and MESSAGES_SCENE_AUDIT_23A355.md for complete evidence and limits.

## Implemented

First handle tap/inward pull reveals choices only; separate second tap or row selection opens an app. Reserved handle hit band and separate grid button replace the conflicting double-tap shortcut. Pan code contains no app inspection/window creation call.

Policy v4 adds only an exact firmware-matching MobileSMS metadata profile: normal application configuration is supplied dynamically by its delegate despite auxiliary-only plist roles. All existing owner/normal-role/identity/workspace/proxy/ABI/lock/lifetime/cleanup checks remain. No new private hosting method was introduced. Old v1/v2/v3 descriptors refuse normalization.

Capability diagnostics retain the latest result for eight apps so a subsequent Safari success does not overwrite Messages/Messenger refusals. Interface diagnostics retain a separate interaction history and reveal/inspection/window-attempt counters.

## Actual device evidence and next step

Target: iPhone12,5, reported iOS26.0.1 build23A355, Dopamine rootless, ElleKit1.2. Framework UUIDs in prior reports match. Exact Dopamine version is unknown.

RC2 Safari source-independent scenes, visible content/navigation/keyboard/X were user-confirmed. Scoped stable branch: `stable/verified-rc2-safari-source-free-classic-reuse`.

RC3 supplied reports contain four clean source-free sessions (Safari118.584s, Files10.077s, Calendar282.295s, Safari7.937s).47 public keyboard notifications were received, but retained observations were hidden/unadjusted; keyboard movement/restoration is not established. One manual nub commit was recorded.

User corrected RC3's immediate app opening and reported Messages/Messenger showed “Suportul pentru fereastra nu poate fi verificat”. Uploaded capability contained Safari only; no failed Messages/Messenger host was present.

RC4 has NOT yet received a phone result. Necessary next gate: verify first gesture reveals without opening, separate action opens; attempt Messages and Messenger once each. Collect interface-1.0.3.json, host-1.0.3.json and capability-1.0.3.json from /var/mobile/Library/Logs/PullOverPro/. A pre-host refusal may update capability only.

Messenger remains unresolved: do not infer its installed manifest or apply the Messages exception to it. Do not declare actual Messages rendering, every-app support or general Dopamine/ElleKit compatibility based on compilation.

## Recovery and constraints

Permanent RC3 archive: `release-candidates/1.0.2-rc3`, commit87d5d1ef8ddf122edc255c54250694861f6de15d.
Permanent RC2 archive: `release-candidates/1.0.1-rc2`, commit8d360d8ded7df9e8e857b29088c5642769679172.
Earlier RC1 and recovery/0.17.0 remain available.

No automatic phone install/respring/process kill; no personal-data deletion or other-tweak modification. Existing recovery: /var/mobile/.ppo_disable plus manual respring, or Dopamine without injection then uninstall only PPO. Preserve GPL-3.0 attribution/license. Original watchdog causes remain unconfirmed.

Use GitHub Actions' pinned Theos/SDK16.5 workflow. Linux pure tests cannot validate UIKit or private iOS runtime. No compatible physical Apple Silicon Mac was available for vphone-cli. Private icons and keyboard alternatives remain unenabled; read the derived audit documents before changes.

Raw phone reports and Apple firmware bytes were kept outside the repository and may not be available in a new environment. Do not assume prior ChatGPT context or access to those local files. Repository source, derived audits, reports and permanent DEBs are published.


## Subsequent RC4 messaging reports

Read [RC4_MESSAGING_DEVICE_RESULT.md](RC4_MESSAGING_DEVICE_RESULT.md) before changing messaging support. The attempted Messages identifier was com.apple.mobilesms.compose; the audited com.apple.MobileSMS profile has not yet been exercised in these reports. Messenger is unknown/manifest-unknown before host creation.
