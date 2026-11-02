# PullOver Pro 1.0.3 RC4 validation

[Download the single RC4 DEB](https://raw.githubusercontent.com/Renatasy83/PullOverPro/689d179ae4a722e67aca33cf74b318a5a5ee8a2a/release-candidates/1.0.3-rc4/com.renatasy83.pulloverpro.diagnostic_1.0.3~rc4_iphoneos-arm64.deb) · [Preserved RC3 DEB](https://raw.githubusercontent.com/Renatasy83/PullOverPro/87d5d1ef8ddf122edc255c54250694861f6de15d/release-candidates/1.0.2-rc3/com.renatasy83.pulloverpro.diagnostic_1.0.2~rc3_iphoneos-arm64.deb) · [Scoped stable RC2 DEB](https://raw.githubusercontent.com/Renatasy83/PullOverPro/8d360d8ded7df9e8e857b29088c5642769679172/release-candidates/1.0.1-rc2/com.renatasy83.pulloverpro.diagnostic_1.0.1~rc2_iphoneos-arm64.deb) · [Controls and remaining test](TWO_STAGE_HANDLE_MESSAGES_RC4.md)

**The two-stage UI correction and narrow Messages admission profile are implemented, compiled and automatically checked, but require actual device confirmation. Messenger is not declared fixed.** No general Dopamine/ElleKit compatibility, every-app support or exact original parity is claimed.

| Item | Evidence |
| --- | --- |
| Version | `1.0.3~rc4` |
| Tested executable source | `8bd812121489f896f4e38d578da10ba0ce284039` |
| Development branch | `debug/two-stage-handle-messages` |
| Successful Actions run | [41477013922](https://github.com/Renatasy83/PullOverPro/actions/runs/41477013922) |
| Successful job / artifact | `125385156493` / `13157684936` |
| ZIP size / SHA256 | 1,247,464 bytes / `e11955367b6d25c84afd15844f6cb5a84b84940f026d648570b2985bcb071b67` |
| DEB SHA256 | `345d6121198c50ea6030988bfee78c24b88a7bb0a12306b7223e8f4d14f4b297` |
| Permanent archive commit | `689d179ae4a722e67aca33cf74b318a5a5ee8a2a` on `release-candidates/1.0.3-rc4` |
| Build | Pinned Theos, SDK16.5, deployment15.0, rootless arm64+arm64e, macOS15 Intel Actions |

## Concrete behavior change

Tapping or inward-pulling the closed handle previously requested the selected app's window immediately. It now reveals only the full handle and choices. Opening requires a separate second tap on the selected handle or an explicit immutable row choice. Already-open owned windows can retract; a retained retracted window also uses the reveal step before reopening. The pan implementation contains no selected-app inspection/window creation call. Existing metadata freshness, selected identity/generation and owned-session admission remain independent gates after an explicit open action.

The selected handle stays visible and has its complete44–72pt touch band reserved. List rows and expanded hit targets are outside that band. A separate grid button opens all applications; the conflicting double-tap recognizer is removed. Cancel/reset/stale pan tickets cannot authorize opening. Preference presentation resets preserve an already explicit app intent, including own recent-history writes, while keeping visible picker readiness consistent.

## Messages profile and unresolved Messenger

The exact23A355 Messages app declares multiple-scenes support and auxiliary roles, with no static normal-role entry. The previous generic v3 policy would classify that shape as unknown/manifest-complex. The supplied phone capability file contains only Safari, so the actual installed rejection reason is not inferred from it.

[The firmware audit](MESSAGES_SCENE_AUDIT_23A355.md) verifies normal-role lookup yields nil without selecting an auxiliary role, UIKit permits the ordinary unnamed configuration/delegate override, and SMSApplicationDelegate builds the normal configuration dynamically with CKMessagesSceneDelegate. RC4 admits only the exact reviewed MobileSMS executable/principal/version/build/families and whole manifest profile after existing hard negatives. It does not enable other complex manifests. Policy v4 rejects old v1/v2/v3 descriptors; its new reason is valid only for the Messages identifier.

This is advisory installed metadata, not an entitlement, runtime app admission or pixel/input proof. The owner still requires the exact normal application specification, selected-ID binding, framework/ABI checks, independent namespace/workspace/child/proxy, activation/lifetime guards and explicit verified cleanup. No private scene method/constructor/foreground flag, delegate invocation or foreign-scene mutation was added. The owned trial changes only version/report strings; owner/admission/bridge/lock production sources are preserved.

Messenger has no installed manifest evidence in the supplied files, receives no guessed exception and remains unresolved pending its actual retained diagnostic. The new capability log stores the latest outcome for eight distinct apps; testing Safari afterward cannot overwrite another app's retained refusal. It strips mismatched capability identities, raw responses/error descriptions and plist/bundle-path content. Diagnostics never grant scene admission.

## Executed verification

Clang analyzed the generated root UI, public views/monitor, capability/diagnostic code, existing adapters/helpers and preferences/Settings. All **34** required suite logs passed and were independently checked after artifact download. Selected C++/Foundation suites use ASan/UBSan. Theos packaged both architectures; CI verified all five executable payloads plus rootless filter, dependencies, lifecycle scripts/modes, Settings bundle/entry, license and allowed paths.

Independent inspection matched report commit, ZIP digest, DEB checksum and each suite marker. It inspected the root dylib, bridge and Settings fat binaries and production policy v4; both dylib slices contain the reveal/counter/profile markers. Test-only paths and obsolete policy markers are absent. The permanent Git blob SHA and raw archived DEB download were checked. Unrelated repository blobs/modes and the private owner/admission/bridge/lock production sources were compared against the RC3 base; only owned-trial report strings changed.

| Selected final suite | Checks |
| --- | ---: |
| `handle-interaction-tests.log` | 614708 |
| `classic-geometry-tests.log` | 1679714 |
| `capability-diagnostics-tests.log` | 202 |
| `scene-capability-tests.log` | 3050 |
| `bridge-protocol-tests.log` | 198 |
| `owned-admission-tests.log` | 94 |
| `owned-scene-tests.log` | 849 |
| `owned-cold-scene-tests.log` | 198 |

All successful logs:

- `handle-interaction-tests.log`
- `capability-diagnostics-tests.log`
- `keyboard-avoidance-tests.log`
- `handle-nub-tests.log`
- `classic-geometry-tests.log`
- `owned-cold-scene-tests.log`
- `edge-drawer-tests.log`
- `interaction-intent-tests.log`
- `user-preferences-tests.log`
- `favorite-apps-tests.log`
- `favorites-store-tests.log`
- `picker-state-tests.log`
- `floating-presentation-tests.log`
- `floating-geometry-tests.log`
- `scene-capability-tests.log`
- `bundle-reader-tests.log`
- `owned-admission-tests.log`
- `lock-state-tests.log`
- `window-lifetime-tests.log`
- `owned-scene-tests.log`
- `visibility-tests.log`
- `layer-probe-tests.log`
- `geometry-tests.log`
- `host-slot-tests.log`
- `presenter-tests.log`
- `scene-tests.log`
- `lifecycle-tests.log`
- `appdata-tests.log`
- `launcher-tests.log`
- `process-tests.log`
- `bridge-io-tests.log`
- `bridge-protocol-tests.log`
- `bridge-service-tests.log`
- `bridge-integration-tests.log`

Build warning inspection: 10 existing linker warnings about obsolete `-multiply_defined`; no missing shell or locale failure.

## Actual supplied RC3 evidence

The four distinct source-free sessions are Safari118.583783s, Files10.076879s, Calendar282.295437s and Safari7.937405s, all in Keep with layers and clean unpinned/unpoisoned owner teardown/replacement. The interface records47 public keyboard notifications and one manual nub commit, but only hidden/unadjusted retained keyboard snapshots; it does not prove movement/restoration or absence of an earlier visible sample. The last capability describes Safari only. The user's first-open behavior correction is accepted; RC3 is not promoted as a verified two-stage interface. Raw reports stay local; no messages/calendar/file/web contents are published.

## Not executed and the necessary next phone gate

Native fixtures do not run real UIKit gesture delivery, Apple private scene callbacks, Messages/Messenger rendering/input or actual SpringBoard teardown. The narrow Messages profile and UI second-tap separation require the target phone. Messenger's actual unknown/refusal reason is still missing. No compatible physical Apple Silicon Mac is accessible for vphone-cli. Build success does not eliminate runtime hangs; existing main-queue deadlines cannot interrupt a blocked private call. Lock/orientation/process-death/long-term stress, all apps and complete original parity are unconfirmed.

After manual installation/respring, confirm the first tap/inward pull shows the handle/choices without opening an app, and only the second tap or row choice opens it. Try Messages and Messenger once each. Send `/var/mobile/Library/Logs/PullOverPro/interface-1.0.3.json`, `host-1.0.3.json` and `capability-1.0.3.json`. A refusal before host creation may update only capability; its eight-app history now preserves it. No per-app matrix or replay of the old keyboard test is needed.

Main remains Alpha4. The scoped stable RC2 source and the RC3/RC2/RC1/0.17 permanent packages remain available. Existing recovery is `/var/mobile/.ppo_disable` plus manual respring, or Dopamine startup without injection followed by uninstalling only PPO. No automatic phone operation, personal-data deletion or other-tweak modification occurs. Original watchdog causes remain unconfirmed.
