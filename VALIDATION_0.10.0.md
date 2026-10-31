# Validation — 0.10.0~dev.keep1

Executable source:ffe808f00174ac2bca2c3f9ffb64a7ae209e2cef on debug/kept-safari-window.

[Successful Actions run41192308078](https://github.com/Renatasy83/PullOverPro/actions/runs/41192308078) · [final artifact13039207175](https://github.com/Renatasy83/PullOverPro/actions/runs/41192308078/artifacts/13039207175).

This is an incomplete Safari-only development candidate with explicit Keep. Default sessions retain their15-second timeout; kept sessions have no timed expiry. New lifetime/lock behavior and full Dopamine/ElleKit compatibility remain unconfirmed on the device. Earlier0.9.1 user observations establish the baseline operations only.

## Executed and passed

- All17 automated suites, including410 lifetime-policy checks,175 read-only lock/ABI checks and702 owned-scene checks. Applicable native suites use ASan/UBSan and controlled fixtures rather than real SpringBoard/UIKit scene objects.
- Existing app data, launch ABI, process runner, bridge IO/protocol/service/subprocess, scene selection/layer probe, geometry, presenter/visibility, session gate and package lifecycle regressions passed.
- Clang iOS static analysis of tweak/helpers/adapters and the new read-only lock reader passed.
- Theos rootless arm64/arm64e build using pinned Theos/SDK16.5 and deployment15.0 passed. Package payload, dependencies, scripts, service, architecture and GPL attribution/license inspection passed.
- Local Linux source policy, lifecycle24 and G++ lifetime410 ASan/UBSan checks passed. The actual downloaded DEB also passed local rootless payload inspection.
- Artifact ZIP SHA256 matched GitHub metadata. Exactly one DEB was found and its SHA256 matched diagnostics/SHA256SUMS. The generated VALIDATION.json identifies the executable source above,17 suites, final_candidate=false and dopamine_ellekit_compatibility_confirmed=false.
- Read-only exact23A355 firmware audit established existing-manager lookup without construction, pure lock/pending-lock getters and the actual Foundation lock-notification literal. Runtime method-table validation remains mandatory; no ivar reads or private lock mutations were added.
- Independent source review checked explicit Keep, activation grace, failure latching, deferred notification cleanup, pending/opening reentry, weak capture, bounded history and preservation of tested owned cleanup. Notification-driven explicit controller/workspace invalidation now runs after the poster unwinds; public UIKit hiding may itself perform normal framework work.

The initial implementation274a7b3ac8229d952d46eaf91dc5c258f5fdd174 also passed run41191853947. Subsequent review separated explicit private teardown from synchronous notification delivery; the final revision above passed the full workflow again. Only the final artifact linked here is delivered for the new gate. Obsolete -multiply_defined linker-option and action-runtime deprecation warnings did not prevent success.

## Not executed here

- Actual0.10.0 installation, iOS launchd/mailbox permissions and helper launching on the phone.
- Real lock/unlock, absence of lock-transition frames, delayed notifications and current protected-data behavior in SpringBoard.
- Keep beyond15 seconds, prolonged resource behavior, Safari client/session persistence and new lifecycle closures during actual process death/orientation.
- Actual touch/keyboard routing for this changed build; no new private input/focus operations were introduced. Earlier0.9.1 interaction/navigation/reuse evidence remains specific to that version.
- Wider apps, simultaneous windows, resizing and full Dopamine/ElleKit runtime compatibility.
- vphone-cli: no compatible physical Apple Silicon Mac is accessible; Linux and macOS Intel CI are not substitutes.

The artifact contains diagnostics/VALIDATION.md, VALIDATION.json, individual test/analysis/build logs, dependency/UUID evidence, SHA256SUMS and symbols. Main and all previously verified source references remain preserved. No phone installation/respring, personal-data deletion or other-tweak modification was performed. Raw uploaded phone reports and web contents are not committed.

## Package identity and indispensable device gate

File:packages/com.renatasy83.pulloverpro.diagnostic_0.10.0~dev.keep1_iphoneos-arm64.deb

DEB SHA256:1ce059f8690d4e191f014bc703e38d7cba639cb15c37c2217d34da6b5db16aae

Artifact ZIP SHA256:9f5a7634ed64f0ae742dd4721770231a3d6efb1dc29cc9b5161cca5e9bf1c732

After manual installation and respring, first open the default15-second Safari window and lock/unlock: it should close and must not remain visible on the lock screen. If that passes, reopen, press Păstrează within15 seconds, keep it for at least30 seconds, close with X and reopen once. Provide the visual outcome and /var/mobile/Library/Logs/PullOverPro/host-0.10.0.json. Ordinary0.9.1 input/navigation observations need not be repeated.

Recovery:X;15-second timeout in default mode; /var/mobile/.ppo_disable to prevent new openings and request closure; manual respring for quarantine. Kept mode has no timed expiry. If injection prevents startup, use Dopamine without injection and remove only this package. Tested0.9.1 source025cf5d835d4454c60c771fea19e17e60c126add and [artifact13028552395](https://github.com/Renatasy83/PullOverPro/actions/runs/41165469987/artifacts/13028552395) remain available as a fallback.
