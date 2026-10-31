# Validation — 0.9.1~dev.componentproxy1

Executable commit:025cf5d835d4454c60c771fea19e17e60c126add on debug/owned-safari-scene.

[Successful GitHub Actions run41165469987](https://github.com/Renatasy83/PullOverPro/actions/runs/41165469987) and [artifact13028552395](https://github.com/Renatasy83/PullOverPro/actions/runs/41165469987/artifacts/13028552395).

This is an incomplete Safari-only independent-scene development build. It is not the requested final all-application release. Dopamine/ElleKit compatibility, pixels and private scene lifecycle are not established by this build.

## Executed

- Exact23A355 firmware analysis of FBSComponentScene construction, class forwarding, weak target getter and hostScene return semantics. No live private API was invoked during this analysis; no Apple binary is distributed.
- All15 automated suites completed. The new ownership suite passed702 checks, including100 normal cycles, NSProxy masquerading identity, raw identity, missing/wrong component, nil/source/foreign targets, unknown proxy classes, bad getter ABI, getter exceptions, snapshot purity, quarantined failures and owned cleanup. Native suites use controlled fixtures, not iOS scene objects.
- ASan/UBSan for the ownership and relevant existing native suites; Clang iOS analysis of tweak, helpers, scene selection, probe, adapters and session gate passed.
- Theos rootless build with pinned toolchain/SDK16.5, deployment15.0, and arm64/arm64e architecture checks passed. Payload, dependency, lifecycle script, service and GPL attribution/license checks passed.
- Local Linux source policy and Python lifecycle tests passed; G++ ASan/UBSan geometry1027 and IO365 checks passed. The downloaded DEB passed local rootless payload inspection.
- Downloaded artifact ZIP digest matched GitHub metadata; DEB hash matched the CI SHA256SUMS file. Exactly one DEB was present.

The first0.9.1 run41165049197 passed production Clang analysis but failed native test compilation on a conditional expression between a fixture scene pointer and an unrelated NSProxy pointer. An explicit id cast fixed the test. The complete rerun above passed; no production guard was bypassed to obtain that result. Theos emitted obsolete -multiply_defined linker-option warnings. GitHub reported Node20 action deprecation; neither prevented the successful run.

The artifact includes diagnostics/VALIDATION.md, diagnostics/VALIDATION.json, all test/analysis/build logs, binary dependency/UUID evidence, SHA256SUMS and symbols.

## Not executed here

- Real iOS launchd bootstrap/removal, mailbox permissions and launching from this exact new package; earlier phone observations remain version-specific.
- Actual Safari scene admission/connection, visible rendering over another app, touch, keyboard, and controller/client/session teardown.
- Lock/unlock, orientation, process death, repeated live sessions, watchdog integration and recovery behavior.
- Dopamine and ElleKit runtime compatibility for this candidate.
- vphone-cli: no compatible physical Apple Silicon Mac is accessible. Linux and the macOS Intel Actions runner are not substitutes for its required hardware.

Main remains af336d84a6b4812e6b6406af87803fb15bf29c3b. The preserved verified-safari-over-newterm source remains411cd127fa18005989d05f2aefff59b697ee1029. No phone installation/respring, personal-data deletion or other-tweak modification was performed.

## Package identity and necessary live gate

File:packages/com.renatasy83.pulloverpro.diagnostic_0.9.1~dev.componentproxy1_iphoneos-arm64.deb

DEB SHA256:181c597c751c5bf2818d82c5eaf4c5e3d456162666bc866fb649244760672e2d

Artifact ZIP SHA256:fac0600ebbe70301df2304bbceda056d0344ef2ba203e8a7ad901e40ba8ac4e3

Install manually only if proceeding with the essential device gate, then perform one manual respring to load the new code and discard0.9.0's pinned uncertain resources. Open Safari normally once, return to NewTerm, select Safari in PPO and request its15-second separate-scene trial. Record whether content appears and the automatic close occurs; provide /var/mobile/Library/Logs/PullOverPro/host-0.9.1.json. Do not repeat0.9.0 or begin with all-app/input stress.

Recovery: X/timeout, /var/mobile/.ppo_disable to block new attempts, manual respring for quarantine; if injection prevents normal startup, use Dopamine without injection and remove only this package. The raw uploaded phone JSON is not committed.
