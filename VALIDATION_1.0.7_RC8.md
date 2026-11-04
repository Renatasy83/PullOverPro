# PullOver Pro 1.0.7~rc8 validation

Validated executable source: `e92284e6e2679cfc11235273da367b5a32dc50a1`.
Delivered DEB: `com.renatasy83.pulloverpro.diagnostic_1.0.7~rc8_iphoneos-arm64.deb`, 316630bytes.
SHA256: `6a2784f8a3194220669a96a68e2cfdbec10ea42799c957d73477f48f70632c69`.
Permanent archive commit: `ad0a2b4703d22e7a29588cbdbb8f15374126c58f`.
[Download the exact DEB](https://raw.githubusercontent.com/Renatasy83/PullOverPro/ad0a2b4703d22e7a29588cbdbb8f15374126c58f/release-candidates/1.0.7-rc8/com.renatasy83.pulloverpro.diagnostic_1.0.7~rc8_iphoneos-arm64.deb)

## Executed evidence

- GitHub Actions [41903532726](https://github.com/Renatasy83/PullOverPro/actions/runs/41903532726), job126831969127: success on standard macos-15-intel. Artifact13358429186, ZIP1361868bytes/SHA256`28bcb30cfde51e83bf482e4a1f2774eab30df157acc53d3f1dd3e38b86545fbc`.
- All37 required test logs independently checked against the report and successful markers. New Messenger return/transport policy:171 checks. Existing profile92, owned-scene854 and cold-owner201 fixtures passed. Native Foundation/CoreFoundation, actual service subprocess/mailbox/kqueue/replay/timeout fixtures and sanitizer-configured policy suites passed; these are host fixtures, not private API execution on iOS.
- Clang static analysis and pinned Theos304e0799973e8145f32e4ca2de6c747a84b758ce, SDK0222fd5413cf4b9af096f37b4621afa2688572f7/iPhoneOS16.5, deployment15.0/rootless build passed. Delivered compiler Apple clang17.0.0/clang-1700.0.13.5 from Xcode16.4; GNU Make4.4.1.
- Independent ZIP size/digest, exact report source,37-log inventory, DEB checksum, rootless payload/filter/lifecycle/license policy and production markers passed. All six fat binaries have arm64 and modern arm64e subtype0x80000002; Mach-O command/signature bounds checked. No claim of signature trust or actual injection execution follows from those static checks.
- Companion and SpringBoard consumer both contain v2 channel/notify markers. Companion slices include the exact Messenger profile digest/public windowScene return selector and exclude root setter/key-window/focus selectors checked by the validator. Companion dependencies are Foundation/UIKit/CoreFoundation and ordinary system/Objective-C/C++ libraries, with no new private framework dependency.
- Git blobSHA1`1ff2d9873af94685a61411f381463e4f496dbe4c` matched uploaded bytes. Immutable raw download was fetched again and independently matched size/SHA256.
- Same-runtime secondary macOS26Intel run41902948991/source102c08da8a4b625d1aed5acb51912a1575a0b340 also succeeded. Delivered package is only the macOS15Intel/e92284e build above.
- Ubuntu22.04 run41903532989/job126831969913 succeeded for source/lifecycle,12 C++ ASan/UBSan suites and cross-target Clang analysis. Evidence artifact13359213314 ZIP5571bytes/SHA256`05972cbf653a820be070151b379e06d60a35e5760343209dd1eccce97e1ff9f4` was independently checked and contains no DEB. Its ABI probe correctly reports subtype0x2 unsupported and skips packaging. Compiler version alone did not establish ABI compatibility; rejected Linux output is not the delivered package.
- Local Linux independently ran12 portable suites/4,843,140 assertions,46 lifecycle checks, source policy and32 cross-analyzed files. These corroborate policy/tooling only.

Theos's existing linker option emits `-multiply_defined is obsolete` warnings in the delivered build. No compile error or incompatible-arm64e warning appears in that build. No framework/signature change was made merely to suppress these warnings.

## Actual runtime evidence and limits

RC6 user-confirmed Messenger content/touch/scroll is retained; its original full-screen surface was black during and after closure. Supplied RC7 report shows schema1 phase4/flags147: injection/transport/PPO session recognition and refusal when its old weak root was absent/different. It does not include a new visual outcome. See RC7_MESSENGER_DEVICE_RESULT.md.

RC8 preserves the exact original UIWindow, requires its current root/view to belong to that window, and uses bounded public windowScene reassociation only after identified scene disconnect. It never reassigns an old root or reparents another controller/view. Transport is schema2/channelv2; old loaded v1 state cannot authorize a trial. Existing exact profile/firmware, warm source, no-cold/no-Keep/15second/8second/owned-cleanup/quarantine guards remain.

Not executed for RC8: actual current-root attachment, UIKit disconnect ordering/window lifetime, original full-screen pixels/input after closure, lock/protected-data transitions and actual loaded companion on the phone. During-trial original background may still be black. No compatible physical Mac/device environment was available for vphone-cli; hosted runners are not that environment. Global app/Dopamine/ElleKit compatibility and full Messenger restoration are NOT confirmed.

The generated CI report retains a conservative historical `not_executed` label about RC7 migration identification. The newer supplied RC7 telemetry provides the scoped identification/refusal evidence explained above, but no visual restoration evidence. RC8 visual return remains untested; this document and the handoff make that distinction explicit.

## Single necessary device gate

Manually install this exact DEB and respring once. Then manually close Messenger from the app switcher and reopen it normally so the new v2 companion loads (respring alone may leave the previous app process alive). Promptly open one timed PPO Messenger window. Let it close automatically, wait about2seconds and observe whether original full-screen Messenger returns and responds.

Send the observed result with `/var/mobile/Library/Logs/PullOverPro/host-1.0.7.json`. If helper readiness refuses, stop repeated attempts and send that host report; an earlier verification failure needs capability-1.0.7.json instead. No conversations/Data or another app's data are needed.

Recovery: `/var/mobile/.ppo_disable` plus manual respring; if unusable, known reboot/Dopamine without injection and uninstall only PPO. The prior RC7/RC6/stable/main archives are retained. No automatic install/respring/app termination, personal-data deletion or other-tweak modification was performed. GPL-3.0/original attribution preserved.
