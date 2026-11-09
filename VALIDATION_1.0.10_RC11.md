# PullOver Pro 1.0.10~rc11 validation

[Exact DEB](https://raw.githubusercontent.com/Renatasy83/PullOverPro/fe48837528401c61e81372d1ebc1e012ad4cfbd1/release-candidates/1.0.10-rc11/com.renatasy83.pulloverpro.diagnostic_1.0.10~rc11_iphoneos-arm64.deb)
Source `192758bb746b3dcd3d4b4113fa11bcb652c10d67`; DEB321262bytes/SHA256`4e55e325704f8fe12bb78c0971ab7142864ea65973d0afa353a43d2efdb77e16`; Git blob`dd0ab6a56bc9f7da4f986fdaf202c7afed1f5e3c`.
Archive release-candidates/1.0.10-rc11/commit`fe48837528401c61e81372d1ebc1e012ad4cfbd1`.

## Executed evidence

- [macOS Actions42061254065](https://github.com/Renatasy83/PullOverPro/actions/runs/42061254065), job127363278114, artifact13432397857: success. Standard macos-15-intel; pinned Theos304e079/SDK0222fd54/iPhoneOS16.5/deployment15/rootless, Apple clang17.0.0/Xcode16.4/GNU Make4.4.1.
- All39 exact success markers and workflow/report log inventories match source and extracted logs. Existing geometry108812/presentation403376/aspect-fit fixtures cover public movement/resize/clamping/lifetime policy. Keep598/state1804/client68 plus existing persistence/bridge/ownership/lock/other native fixtures passed. Generic geometry does not verify real remote app input.
- ZIP1377416bytes/SHA256398470ab7502ac5efb879a669d817069ca6a9babed33c2ffa4afd522b82f0563 matched GitHub metadata; ZIP CRC passed106 entries. DEB byte equality/hash/version/source-build record matched. These already completed results were recovered/reverified after environment replacement; no new compilation is being claimed.
- Source/payload/filter/lifecycle/license checks passed. All six actual fat Mach-O binaries contain arm64 and modern arm64e0x80000002; command/code-signature bounds and v4/forbidden companion selectors checked. This does not establish signature trust or actual device compatibility.
- Independent second reviews corroborated39 logs, ZIP/DEB hashes/sizes, actual binary bounds and v4 markers. Prior review found both Agent slices' __TEXT byte-identical to RC10; complete binary bytes differ, so no binary-identity claim. Git diff independently shows Agent, state, Keep-policy, consumer and filters unchanged, supporting loaded-v4 protocol compatibility.
- Uploaded Git blob matched expected SHA; immutable raw archive download was fetched and matched byte count/SHA256.
- [Linux42061253895](https://github.com/Renatasy83/PullOverPro/actions/runs/42061253895) succeeded with13 portable/source/lifecycle/static checks. Evidence13431567911 ZIP5876bytes/SHA2560bdcddf97c134e2fc196452cee02b39979580c94de9cc582a2f4d56ca1408bbd independently matched current source,13 passed suites and no DEB. Unsupported Linux arm64e correctly skips packaging; this is not the delivered macOS package.
- Earlier local13 portable suites/source checks and changed owner Clang analysis passed. Native fixtures use stubs/isolated files where documented, not private iOS framework execution.

## Warnings and historical report text

Analysis was not warning-free. messenger-return-analysis.log contains one Clang nullability warning at PPOMessengerReturnAgent.mm219 for containsObject:scene. Owned(scene) rejects nil/non-UIWindowScene first, so its false result short-circuits before that call; independent source review classifies this as a likely false positive. No runtime code was changed solely to suppress it. Existing obsolete -multiply_defined linker warnings remain. Do not describe the build as having no warnings.

The immutable generated VALIDATION.md retains a historical RC6 opening, and original JSON rc6_scope is historical. They do not describe current RC11 controls. Current scope here, the archive README/validation wrapper and source diff supersede that paragraph. The future report writer is corrected in the final documentation/metadata commit, without changing the delivered executable/source attribution.

## Change and confirmed baseline

Only four Messenger UI restrictions are removed: title interaction override, pan early return, size-button disable, resize early return. Existing public panel/viewport/wrapper geometry is reused; PPO explicitly assigns the native child frame once before containment, then reads it. No private scene/frame setter or new private method is added.

InitialStandard, minimize/restore guards, Keep-only menu, warm admission, Root120/Agent125/v4/profile/firmware/root/ownership/cleanup/quarantine/lifetime/render/lock protections remain. Cold/unlimited Keep/headerless drawer behavior is not enabled.

User confirmed RC10 bounded120second Keep/full-screen return and later background hosting overNewTerm, outside input, manualX/no-focus-steal/laternormalforeground. Background metadata shows originalbg0layers versus ownedactive/nonbg2layers and schema4phase3flags47/deferred32 with clean own cleanup. Read RC10_MESSENGER_BACKGROUND_RESULT.md; do not ask to reconfirm it. Scope relies on user observation for pixels/input/app identity, not authenticated frontmost/PID telemetry.

## Necessary phone gate

RC11 move/resize real Messenger rendering/input conversion and cleanup after transform remain untested. Manually install/respring, open normal Messenger/PPO and choose bounded Keep. Switch toNewTerm; drag by title and cycle Large/Compact/Standard with the size button, checking visible content and simple tap/scroll after changes plus NewTerm touches outside. CloseX, then manually open Messenger to check normal full-screen UI. Send host-1.0.10.json; on black/refusal/unexpected early closure retain exact observation/interface-1.0.10.json and stop loops. The known120second cap still applies. Existing compatible v4 Agent is sufficient; no protocol-driven app termination or other-app/repeated2minute test is required.

No accessible compatible physical iOS/Mac/vphone environment exists here. General app/Dopamine/ElleKit compatibility, signature trust, cold/minimize/unlimited modes are unconfirmed. Main/stable/RC10/earlier archives retained; no automatic phone install/respring/kill, personal-data deletion or other-tweak modification. GPL-3.0/original attribution preserved. Recovery remains /var/mobile/.ppo_disable+manual respring or known Dopamine without injection/uninstall only PPO if unusable.
