# RC5 validation — completed automated checks

Executable source: ca1c56ba1937a815f8762552685ceb0c18b83c7b. Candidate1.0.4~rc5.
Actions: https://github.com/Renatasy83/PullOverPro/actions/runs/41578881921
Job125728758066; artifact13204834146. All35 suites passed, including63 new scene-observation checks and3191 capability checks. Native suites use sanitizers where configured. Clang analysis, pinned Theos/SDK16.5 rootless arm64/arm64e build, architecture/dependency/lifecycle/license/payload checks all passed.

Independent Linux inspection verified artifact ZIP size/digest, exact source in VALIDATION.json,35 distinct successful test logs, DEB checksum, package payload and production markers in both dylib slices. No test-only bridge path or old policy marker was found. Source comparison confirmed the existing owner/admission/lock/bridge implementations were untouched and owned-trial code matches after version/report-label normalization. Explicit refusal trigger, lock/intent guards,4-observation bound,2s cooldown and2-entry retention were checked in source. Source policy and Python syntax checks passed. No repeat native run was needed for subsequent documentation-only commits.

New tests exercise observed foreground/background fixtures; missing/ambiguous source with no deeper reads; wrong specification/role/layer object; invalid/other-app/other-reason/stale proof; disable, firmware, class and thread gates; JSON serialization and omission of a private scene token. These are actual implementation fixtures with synthetic scenes, not an execution of Messenger or private iOS frameworks.

DEB294756 bytes; SHA2569346849e94861872ecfd7eed27bf0f379b8f86b3bc84dc83356b37bf5e1612a2.
ZIP1257906 bytes; SHA256e177b33e17e5d8bcef04f87bb4f7d9e7a0a178e094cc2186d583533247f8bff7.
Permanent archive commit bfd53b813bef2801dc5d1b7f09061945fe29331e; Git blob9603070dbcce73e2851757962107b5fd0e53fa9a. Raw archived download size/SHA256 matched independently.

Download: https://raw.githubusercontent.com/Renatasy83/PullOverPro/bfd53b813bef2801dc5d1b7f09061945fe29331e/release-candidates/1.0.4-rc5/com.renatasy83.pulloverpro.diagnostic_1.0.4~rc5_iphoneos-arm64.deb

Not executed: RC5 actual phone install/respring/service upgrade, SpringBoard mailbox/report writing, private getter latency, Messenger source specification/role/layers/foreground-background state, rendering/input or independent-window admission. Native success does not confirm target runtime safety or Dopamine/ElleKit compatibility. No compatible physical Apple Silicon Mac was available for vphone-cli; Linux and the Actions Intel Mac do not replace the phone. The phone slowdown cause is unconfirmed.

This DEB does not fix Messenger. No Messenger launch, scene creation/activation/presentation/mutation or eligibility exception was added. The only indispensable next test is documented in RC5_MESSENGER_OBSERVATION.md. Previous RC4, stable/recovery builds and main remain available. Preserve original GPL-3.0 attribution and license.
