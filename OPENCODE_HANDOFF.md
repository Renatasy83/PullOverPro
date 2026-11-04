## RC7 ready — necessary Messenger return-after-close gate

User requirement persists: continue autonomously through implementation/automation and stop only at an indispensable installation/device test. Candidate1.0.6~rc7 is ready. Tested executable source a0de352dd11bae4a15ea127e5ddc049fa42d9a2f/tree870f1d39d470a9129548b52f2a560b055518e4ba. Actions41827194632/job126564838943 succeeded: all37 suites,168 return-state/transport checks, existing92 profile/854 owner/201 cold cases, sanitizer-configured fixtures, Clang analysis of both new components, pinned Theos rootless arm64/arm64e build and exact two-filter/two-dylib payload/architecture inspection. Artifact13320571598. No app-side/runtime restoration test has yet occurred.

Permanent archive release-candidates/1.0.6-rc7 commit e8051501867124258cff5d5eaea4524edea97f46. DEB317234bytes SHA256aba19add31eded4375892cf9053988dcfaea83d9a911c9c39000b6d3150efdc8. ZIP1361014bytes SHA25649e994ebe6b6f1085b47fd4debe417c853284e8343fe3ea61033c54b2453f5ca. Git blob a45e0d552797169c685846ee0fc4f7f8a9cf834f and raw permanent download size/SHA256 independently matched. Download: https://raw.githubusercontent.com/Renatasy83/PullOverPro/e8051501867124258cff5d5eaea4524edea97f46/release-candidates/1.0.6-rc7/com.renatasy83.pulloverpro.diagnostic_1.0.6~rc7_iphoneos-arm64.deb
Independent checks bound source/report/37 logs/hashes, four fat binaries, separate exact SB/Messenger filters, and both companion slices' SHA256/profile/public windowScene return/notify producer markers with no key-window/focus/snapshot selectors. See RC7_MESSENGER_WINDOW_RETURN.md and VALIDATION_1.0.6_RC7.md.

RC6 actual result: user confirms Messenger small-window content/touch/scroll, but original full-screen UI was black during and after closure, requiring manual app exit. Uploaded host report: distinct child/proxy not original, own layer0→1, original samples2layers/active/not-backgrounded, timeout15.034s, own controller/workspace closed/unpinned/unpoisoned/replacementAllowed=true. Last original sample is before close, so it does not establish post-close rendering. User observation is the evidence of black UI after cleanup. This proves scoped content/input/own cleanup, not original-window recovery or a confirmed exact migration mechanism. Read RC6_MESSENGER_DEVICE_RESULT.md.

RC7 adds separate hookless PPOMessengerReturnAgent with com.facebook.Messenger-only filter; original SB filter stays unchanged. Same exact installed585.0.0/build1101076820 Info.plist SHA256 and UIKit UUID gate. Public UIKit only inside Messenger. Tracks one ordinary original UIWindow/root/scene, freezes identity when an exact com.renatasy83.ppo.scene.UUID public session appears, and only after its disconnect defers one queue turn then revalidates/rebinds the SAME window/root to the still-connected original same-screen normal scene. Readback checked; visibility is protected/deferred when inactive/locked. Unknown session/window/root/target pattern refuses. No screenshot, app-data write, key-window/focus request, arbitrary root/view reparent or direct FBScene mutation. Public session prefix mapping and actual same-window migration are explicitly unproven; UIKit can prefer another persistence identifier, so no forced mapping fallback.

Only bounded libnotify phase/flags/time telemetry crosses to host report messengerReturnHelper; no pointers/content/sessionIDs. Fresh unconsumed captured readiness required before trial. Idle notification observers plus at most20s read-only polling while an identified owned session is active; no permanent timer. One process does not silently rearm completed/refused migration. Existing RC6 warm-source/ownership/lock/15s/8s/no-cold/no-Keep safeguards remain; after-close helper telemetry is sampled3times. Original private owner/admission/bridge remain unchanged. borrowedSourceMutationRequested=false still describes the server adapter; intentional app-side public UIWindow reassociation is separately reported by helper state, not hidden by that older field.

NECESSARY NEXT PHONE GATE: manually install RC7 and respring once, then manually close Messenger from the app switcher and reopen it normally to load the NEW app-filtered component (respring may leave its old process alive). Open one timed PPO Messenger window promptly, let it close, wait2seconds and observe whether original full-screen Messenger content/touch return. Send /var/mobile/Library/Logs/PullOverPro/host-1.0.6.json and that visual result. Background DURING the active small window may remain black; this candidate tests AFTER-close return, not duplicate app UI. If helper readiness refuses, stop and send host report; earlier verification failure -> capability-1.0.6.json. No repeated install/respring/service restart or unrelated-app tests. No general compatibility/restoration success claim until actual report.

No automatic phone install/respring/kill, app bundle/personal Data/other-tweak modifications were performed. Recovery: /var/mobile/.ppo_disable plus manual respring or known reboot/Dopamine without injection/uninstall-only-PPO; disabling injection disables the app component too. Prior RC6 archive5fc08ae00d461d33bf4fc1bea5f7096e7500ba72 remains with black-original-UI defect documented; RC5/RC4/stable/main/recovery preserved. No compatible physical Apple Silicon Mac available for vphone-cli. Native fixtures do not simulate the third-party app, notify sandbox permissions, session mapping, notification ordering, visible return or input. Persistent slowdown/battery attribution remains unconfirmed.

Tandem: fetch current head/read this file, preserve OpenCode changes and use CAS/non-forced updates. Keep handoff current and continue authorized implementation/tests autonomously until the next indispensable real-device gate.

---

# RC6 ready — necessary bounded Messenger window test

User explicitly requires autonomous progress until an installation/device gate, not intermediate research summaries. Candidate1.0.5~rc6 is now built and independently inspected. Executable source d9cf526d189caf5a46301e7a288ed031e07a9a58/tree1810009cd0b828318bb1bf1b7f20caf206c4428b. Actions41738869428/job126275019452 succeeded: all36 suites,92 Messenger profile/digest/wire checks,854 owner checks,201 cold checks, sanitizer-configured native fixtures, Clang analysis, pinned Theos rootless arm64/arm64e build and payload/binary inspection. Artifact13280547508.

Permanent archive release-candidates/1.0.5-rc6, commit5fc08ae00d461d33bf4fc1bea5f7096e7500ba72. DEB298602bytes, SHA2569d5499345c2a2f9bcf0c5d004366f5c980be275e2869a7a648eff7a3766c9c48. ZIP1269393bytes, SHA2563d8ed2b4d48773d3c7ee198408b6fadb27b5c593e78b9ee270c730157478c594. Git blob e78fc4b27c5f810ac0ec6a362c0666a91328207c and raw download size/hash matched. Download: https://raw.githubusercontent.com/Renatasy83/PullOverPro/5fc08ae00d461d33bf4fc1bea5f7096e7500ba72/release-candidates/1.0.5-rc6/com.renatasy83.pulloverpro.diagnostic_1.0.5~rc6_iphoneos-arm64.deb
Independent inspection verified36 logs, source/report binding, payload, architectures/production markers in both dylib slices, and public CC_SHA256 import/exact profile digest in both bridge slices. Rootless payload verification passed again locally. See RC6_MESSENGER_WARM_TRIAL.md and VALIDATION_1.0.5_RC6.md.

Only the previously supplied exact installed Messenger585.0.0/build1101076820 plist SHA256 plus scalar checks can mint unknown/eligible=false reviewed-messenger585-warm-trial. Admission freezes explicit experimental warm provenance. The caller revalidates a unique normal existing active foreground source with layers; core owner rejects missing source before cold factories/workspace allocation. No global absent-manifest allowance, new private selector/signature, foreign-source mutation or layer copying. Same exact source/child/normal role/workspace/proxy/ABI/lock/cleanup/quarantine guarantees remain. Runtime trial forces nonpersistent standard-size/timed preferences, blocks Keep/resize/minimize/restore/pan, retains closeX;15second maximum,8second child-render deadline, existing2second activation grace. Other app routes/preferences remain unchanged. No automatic launch retry or source-free fallback.

NEXT indispensable phone gate: manually install RC6 and respring once. Open Messenger normally, keep it full-screen and open Messenger from PPO once. Observe actual content and harmless scrolling INSIDE the new small window; do not send messages. Let it close automatically within15seconds (possibly earlier if readiness fails). Send /var/mobile/Library/Logs/PullOverPro/host-1.0.5.json plus the visual/input result. If verification/refusal prevents a window, send capability-1.0.5.json instead; no repeated opening/reinstall/service restart to conceal failure. Existing RC5 read-only foreground/background tests need no repeat. Actual second-window content/input/cleanup and general Dopamine/ElleKit compatibility remain UNCONFIRMED.

No phone installation/respring/process kill was performed by the assistant. Recovery is the known /var/mobile/.ppo_disable marker plus manual respring, or reboot/Dopamine without injection/uninstall only PPO. Do not modify personal Data/Messenger bundle/other tweaks. Private calls already entered cannot be interrupted by the main-thread deadline. Persistent phone slowdown remains user-reported with unverified battery attribution. Previous RC5 archive bfd53b813bef2801dc5d1b7f09061945fe29331e, RC4, main af336d84a6b4812e6b6406af87803fb15bf29c3b and scoped stable e5c6e53f659109d77d78a5a99f7139899a978991 remain unchanged.

The old Info.zip is no longer mounted this turn; expected hash/version come from earlier computed local evidence/published derived audit, not a newly recomputed raw-file claim. Actual installed reader recomputes bytes before permitting trial; synthetic digest fixtures test the decision boundary, not preimage equality. No raw app plist is published. No compatible physical Apple Silicon Mac is accessible for vphone-cli; native CI/fixtures do not substitute for phone runtime.

Tandem: always fetch current development head/read this file, preserve OpenCode changes, use CAS/non-forced updates and keep this handoff current. Continue implementation/automated correction autonomously after the next actual report; no approval needed for authorized tests/fixes.

---

# RC5 foreground gate completed — no repeated phone test needed

The newly supplied messenger-1.0.4.json reports one foreground-marked Messenger source: observed, inspected10/matched1, normal specification/role=true, expected framework UUIDs all match, sampled3layers of type[1,1,1], settingsBackgrounded=false, sceneActive=true. Hosting/mutation requested=false. Prior separate report showed backgrounded=true and0layers. See RC5_MESSENGER_DEVICE_RESULT.md. Each file has one retained observation; do not assume one continuous scene/process/boot session or that3layers means3windows.

The required read-only source comparison is now complete; do not request another foreground retry, installation/respring or unrelated app tests. A later diagnostic completed, but the previous timeout cause is still unresolved and must not be declared fixed. Messenger's normal source/foreground layers are established at the observation instants; its delegate adoption, second-scene content/admission/input and general Dopamine/ElleKit compatibility remain unproven.

Next autonomous development: review a constrained explicit warm-source Messenger trial, grounded in the owned-scene lifecycle/cleanup audit; the owner reuses verified identity/specification to create its own namespace/child, not existing source render layers. No identifier-only/global missing-manifest exception, cold fallback, foreign-source mutation or permanent keep-mode authorization follows from this report. Any trial must be narrowly identity/version bound, runtime source revalidated, time bounded and fail closed with existing owner/proxy/cleanup/quarantine guarantees before a next device candidate. No new private signature may be guessed. This is a pending design/implementation gate, not a delivered Messenger fix.

No code or package change in this documentation checkpoint. RC5 executable source ca1c56ba1937a815f8762552685ceb0c18b83c7b, Actions41578881921/35 suites/Clang/Theos/rootless inspection, and permanent archives remain as recorded. Preserve main/stable/recovery refs and update this file for OpenCode on every meaningful checkpoint.

---

## RC5 launchd screenshots — registered/running; one fresh foreground observation next

The user supplied launchctl print screenshots. Rootless launchctl redirects system/com.renatasy83.ppo.bridge to user/501/com.renatasy83.ppo.bridge, warning to use user/foreground/com.renatasy83.ppo.bridge. The shown job has state=running, pid523, runs1, execs1, last exit code=(never exited), mobile UID/group, --serve arguments, and the expected rootless daemon plist/program. This establishes registered/running state at capture, not responsiveness or previous-boot continuity. The warning is domain translation, not a proven failed bootstrap. Do not move domains or change the launch plist based on it.

The screenshots also show6MB jetsam limits, but there is no shown termination/jetsam event. Do not diagnose memory pressure or raise limits from that configuration alone. There is no evidence of an alarm/restart in the shown job lifetime; do not claim one. Mailbox response nonce still differs from the old request, and boot/session continuity remains unresolved.

NEXT indispensable phone action: a single NEW explicit Messenger inspection while Messenger is visibly full-screen, using already installed RC5. No reinstall/respring/service restart. Open Messenger normally, invoke the selected Messenger opening action in PPO once and allow at least2seconds for the existing observation cooldown. A new window is not expected; look for the diagnostic message and collect messenger-1.0.4.json. If the verification-unavailable message recurs, stop repeats and collect capability-1.0.4.json from that new attempt instead. This is a user-initiated new nonce-bound read-only request, not an automatic replay of the timed-out request. Running-state evidence justifies this one fresh inspection; it does not guarantee it will respond.

No code/package changes or new automated test/build. Existing source ca1c56ba1937a815f8762552685ceb0c18b83c7b,35-suite CI and permanent RC5/RC4 archives remain unchanged. No Messenger hosting fix or general compatibility claim. Preserve main/stable/recovery and update this OpenCode handoff on subsequent evidence.

---

## RC5 mailbox evidence — mismatched reply; service state required

Uploaded request.json is inspect-scene/com.facebook.Messenger at createdUptime238.09916733333336. Uploaded response.json is an inspected/missing-manifest Messenger reply with a DIFFERENT nonce, uptime269064.2314720417 and capability observation269064.15757050004. It cannot validate this request. Uploaded heartbeat.json is ready/service-ready at uptime267.1975894166667 and is only startup evidence. No raw nonce/file contents are committed.

The capability error at246.19693858333335 is8.09777125seconds after the supplied request, consistent with the client's8second deadline. If request/error/heartbeat share one boot, heartbeat is29.09842208seconds after request and21.00065083seconds after timeout. But these files persist across restarts and carry no boot/service-instance ID, so do not assert a common boot or that the heartbeat proves current liveness. The much larger unrelated-response uptime is consistent with a different session, but not proof of one. Distinguish evidence from hypotheses.

Current source correctly ignores a different-nonce response. The service ignores preexisting requests at startup intentionally, uses alarm20 around private operations and launchd KeepAlive; absence/delay/restart/blocked private work remain possibilities, not diagnosed causes. Do not remove replay/nonce protections, extend waits, retry automatically, or launch a second --serve process. Next indispensable read-only phone input: /var/jb/usr/bin/launchctl print system/com.renatasy83.ppo.bridge. Inspect state/pid/runs/last exit/termination signal before any restart/respring/new app test; this may distinguish an absent job from a running or repeatedly terminated service. No new code/build/phone action was performed by the assistant.

Foreground Messenger comparison remains absent. Prior RC5 snapshot establishes only a background-marked unique normal-specification/role scene with0layers. Runtime, DEB/archive and35-suite evidence remain unchanged. Keep main/stable/recovery refs and this OpenCode handoff current.

---

## RC5 capability result — timeout60 before scene observation

The new capability-1.0.4.json contains one latest-per-app Messenger record: responseStatus=unavailable, capabilityIssue=response-unavailable, sceneCapability=null, errorCode60, observedUptime246.19693858333335, version1.0.4~rc5. On the target Darwin platform60 is ETIMEDOUT. PPOBridgeClient uses NSPOSIXErrorDomain and an8second matching-nonce response deadline; invalid/wrong-nonce or absent replies can also end in this timeout. Do not decode this target code with Linux errno values. This report does not establish which service-side condition caused the timeout or that SpringBoard crashed/hung.

Source inspection confirms the request must obtain a validated inspect-scene response before the new Messenger observer can run. No foreground Messenger snapshot was collected by this failed verification. The earlier one background-marked snapshot remains the only Messenger scene evidence. A stopped/busy/restarted service, unmatched/invalid reply or other transport issue cannot be distinguished from the capability file alone. Do not increase timeouts or repeat launch/inspection automatically to hide this error.

NEXT read-only evidence, without another phone test/install/respring/service restart: in Filza obtain request.json, response.json and heartbeat.json from /var/mobile/Library/Logs/PullOverPro/Bridge/ (zip those existing files; note any missing file). Compare schema/operation/nonce/request-created and response/heartbeat uptimes to the capability timestamp. Heartbeat is written only at service startup and is not proof of present liveness. A service restart intentionally suppresses preexisting requests; preserve that no-replay protection. Do not infer a startup race or blocked private getter as the cause without mailbox evidence. No personal Data-container files are needed. Raw reports stay outside GitHub.

No runtime/package changes or new build/test in this documentation checkpoint. RC5 source ca1c56ba1937a815f8762552685ceb0c18b83c7b, archived DEB and35-suite/Clang/Theos inspection evidence remain unchanged. Preserve main/stable/recovery refs and update this handoff in tandem with OpenCode.

---

## RC5 foreground attempt — verification unavailable; inspect existing capability error first

The user reports the approximate UI message «Verificarea ferestrei nu e disponibilă» during the requested foreground comparison. Current source has «Verificarea ferestrei nu este disponibilă» in inspectSelectedForIntent when response is nil, before the Messenger read-only observer. This can follow a bridge transport/validation failure or a caught exception; it is not the missing-manifest refusal and does not prove that Messenger hosting failed, that the service stopped or that the app lacks support.

The existing code normally calls PPOWriteCapabilityObservation immediately after PPOBridgeSend, retaining bounded response status/issue/errorCode in /var/mobile/Library/Logs/PullOverPro/capability-1.0.4.json. Request that current file from this attempt first. No repeat action, install, respring or service restart until its evidence is read. If absent/stale, investigate the exception/write path rather than assuming the recorded error belongs to this attempt. The previous messenger-1.0.4.json has one background-marked sample only; the foreground comparison remains missing.

No runtime/package changes or new tests in this documentation checkpoint. Keep RC5 source/archive and35-suite evidence below; preserve main/stable/recovery refs and update this handoff for OpenCode.

---

## RC5 first Messenger phone observation received — foreground comparison missing

Uploaded messenger-1.0.4.json contains exactly ONE observation, version1.0.4~rc5: state=observed, inspected6, matched1, normalApplicationSpecification=true, normalApplicationRole=true. All four observed framework UUIDs match their expected23A355 values. Existing layer probe status=sampled, layerCount0, layerTypes empty, settingsBackgrounded=true, sceneActive=true. hostingRequested=false and sceneMutationRequested=false at both report and observation levels.

This establishes execution of the read-only diagnostic/report-writing path and a uniquely identity-bound normal-specification/role Messenger source at that instant. It does not establish foreground content, app-delegate adoption, second-scene admission/rendering/input or general compatibility. FBScene.isActive and settings.isBackgrounded represent different properties; do not relabel the active flag as app foreground. Zero published layers in this background-marked sample is not proof that Messenger can never render. The prior missing-handle cause and whether a disable marker was removed remain unconfirmed; the new report only proves this diagnostic was executed.

NEXT indispensable gate: no reinstall/respring/new DEB. Open Messenger normally and keep it visibly full-screen; invoke its PPO opening action once, wait2seconds if needed for the existing cooldown, then send the same messenger-1.0.4.json again. The existing candidate retains the latest2 samples, so the additional observation can be compared to this background-marked one. Do not ask to repeat unrelated app tests or interpret this single sample as evidence to relax admission. A refusal/no new window remains expected. Raw uploaded report stays outside the repository. See RC5_MESSENGER_DEVICE_RESULT.md.

Runtime/archive/automated evidence unchanged: source ca1c56ba1937a815f8762552685ceb0c18b83c7b, Actions41578881921,35 suites/Clang/Theos/rootless inspection passed; permanent RC5 archive bfd53b813bef2801dc5d1b7f09061945fe29331e. Docs-only checkpoint; no new build or Messenger hosting fix is claimed. Preserve main/stable/recovery refs and update this handoff in tandem with OpenCode.

---

## RC5 phone follow-up — handle not visible; cause not confirmed

The user reports that the PPO handle is not visible after receiving RC5. Exact installed version, completion of respring, the disable marker and Settings enabled state have not yet been checked. Earlier the assistant recommended creating /var/mobile/.ppo_disable while the phone was slow; the user never confirmed whether that command was executed. Check that marker first rather than inferring a loader failure or asking for repeated installations. Remove only that PPO disable marker if the user deliberately wants to re-enable PPO, then one manual respring. If it is absent, verify installed package version and preferences/injection status before changing code. No crash or RC5 Messenger observation has been supplied. Runtime/package/archive/test evidence below remains unchanged; no compatibility or fix claim.

---

## RC5 ready — indispensable Messenger observation gate

Package1.0.4~rc5; tested executable source ca1c56ba1937a815f8762552685ceb0c18b83c7b/tree9a060bb4da8f2bb11f2d7cff6121909e9370ed99. Actions41578881921/job125728758066 succeeded: all35 suites, including63 new read-only scene-observation checks, ASan/UBSan fixtures, Clang analysis, pinned Theos rootless arm64/arm64e compilation and payload/binary inspection. Artifact13204834146. Independent ZIP/DEB hashes,35 logs, fat-binary architecture/production policy and new observation markers in both dylib slices were checked. Rootless payload verification passed again locally.

Permanent archive: release-candidates/1.0.4-rc5, commit bfd53b813bef2801dc5d1b7f09061945fe29331e.
DEB294756bytes, SHA2569346849e94861872ecfd7eed27bf0f379b8f86b3bc84dc83356b37bf5e1612a2.
ZIP SHA256e177b33e17e5d8bcef04f87bb4f7d9e7a0a178e094cc2186d583533247f8bff7.
Download: https://raw.githubusercontent.com/Renatasy83/PullOverPro/bfd53b813bef2801dc5d1b7f09061945fe29331e/release-candidates/1.0.4-rc5/com.renatasy83.pulloverpro.diagnostic_1.0.4~rc5_iphoneos-arm64.deb
Archived Git blob SHA1 and raw download size/SHA256 independently matched. See RC5_MESSENGER_OBSERVATION.md and VALIDATION_1.0.4_RC5.md. The previous RC4 archive and main/stable/recovery refs remain preserved.

Change: only fresh explicit com.facebook.Messenger unknown/scene-manifest-missing refusals can collect a read-only existing-scene snapshot. Exact firmware/ABI/class/identity and normal specification/role checks; reuse bounded unique enumeration and layer reads. Max4 explicit observations per SpringBoard process,2s cooldown,last2 retained; no polling. Atomic worker-only messenger-1.0.4.json output omits raw scene tokens, pointers, paths and content. No Messenger launch/create/activate/present/mutation or admission relaxation. Existing private owner/admission/bridge/lock files are unchanged; owned-trial code differs only in version/report labels. Runtime diagnostics now use1.0.4 filenames; preferences/data are preserved.

NECESSARY NEXT PHONE GATE ONLY: manually install RC5 and respring once; open Messenger normally from its icon, try Messenger from PPO once while Messenger remains full-screen. Switch to NewTerm, wait2seconds, try Messenger from PPO once more. A diagnostic/refusal and no new Messenger window are expected. Share /var/mobile/Library/Logs/PullOverPro/messenger-1.0.4.json (zip if needed). Do not kill the app or change its bundle/Data container. Messages already works and requires no repeat test. Snapshot topology does not establish the remote app delegate, independent content or Messenger hosting; do not authorize unknown apps from these observations alone.

Actual RC5 phone behavior, launchd upgrade/write permissions, private getter behavior and Messenger source topology have not been tested. General Dopamine/ElleKit compatibility remains unconfirmed. The user reports persistent slowdown and attributes it to the battery; this is not a diagnostic conclusion. No automatic phone installation/respring/process kill was performed. Recovery remains marker /var/mobile/.ppo_disable plus manual respring, or the known Dopamine-without-injection recovery/uninstall only PPO.

Tandem: fetch the current development head and read this handoff on resume, preserve OpenCode changes, use CAS/non-forced updates and keep this file current. No further automated work can substitute for the above target-phone source observation.

---

# Messenger legacy lifecycle audit completed — no new runtime experiment

Read MESSENGER_LEGACY_AUDIT_23A355.md. Offline23A355 UIKit inspection shows that lifecycle adoption depends on declared scene configurations OR delegate callback-support flags. Missing UIApplicationSceneManifest alone does not establish that Messenger's runtime lifecycle is legacy. The false-adoption branch can still construct a UIScene wrapper; it does not establish independent app content. Application-level main-interface initialization and defaultSceneToken are distinct from an arbitrary PPO-owned scene. Messenger declares neither a main storyboard/nib nor its actual delegate class. LaunchScreen is not interactive app content.

Completed: read-only metadata/disassembly review; independent agreement for75 selector-stub resolutions;32 evidence anchors across10 extracts; exact declaration bit-offset check; local source-policy pass. These audit checks are not native suites or runtime tests. No new private call, admission relaxation, app modification, DEB or phone test. Original34-suite/Clang/Theos/package evidence remains run41521971944/source d0303bd039aefe08817702fb737c85eae90336eb; delivered RC4 source8bd812121489f896f4e38d578da10ba0ce284039 remains available. Main and stable/recovery refs preserved.

Next: Messenger's running delegate/content/default-scene behavior and a route respecting independent ownership/cleanup remain unproven. Do not permit missing manifests globally or add an identifier-only Messenger exception. An existing-scene read cannot prove second-window content or another process's delegate. The user has been asked whether the reported phone slowdown persists; await health status before proposing any necessary device observation. Do not infer recovery, perform a respring/install or attribute slowdown without evidence. Continue from the current remote head and preserve intervening OpenCode work.

---

## Installed Messenger metadata received — no phone test requested

The user supplied Info.zip after reporting that the phone was slow. The extracted application plist identifies com.facebook.Messenger, version585.0.0/build1101076820, executable Messenger, APPL, device families[1,2]. It has77 keys and22483 bytes; SHA256741517f9808a10ac225c6490d2af5bd835ff56b112464c5d53ce670d7ff92e30. UIApplicationSceneManifest is absent; no other top-level scene/window keys or background-only/extension declarations were found. Raw plist/archive are not published.

Bounded offline plist parsing checked the earlier parser prerequisites (dictionary/key counts/types, identifier, package type, device families and background/extension absence). Therefore this supplied plist reaches RC4's missing-manifest branch: unknown/manifest-unknown; investigation source d0303bd039aefe08817702fb737c85eae90336eb refines it to unknown/scene-manifest-missing. This explains the current metadata refusal for these supplied bytes. No explicit false multiple-scene declaration exists. It does not prove a compatible legacy hosting path, current phone runtime behavior or a cause for the phone slowdown.

Next autonomous work: audit the exact23A355 UIKit/FrontBoard legacy/no-manifest application lifecycle and normal-scene admission path before proposing a narrowly justified Messenger route. Do not apply the MobileSMS exception or simply authorize missing manifests. Existing exact ABI/identity/ownership/cleanup guards remain mandatory. No new app file, diagnostic installation, respring or real-device test is requested now. Messages remains user-confirmed working.

Runtime unchanged; previous CI run41521971944 passed34 suites, Clang analysis, Theos rootless arm64/arm64e build and package inspection. This checkpoint changes documentation only; no new runtime build/test is claimed. Main, stable/recovery refs and the permanent RC4 DEB remain unchanged. Phone slowdown remains uninvestigated; do not attribute it to PPO, Dopamine or ElleKit without evidence. Ask about recovery only if needed before any future phone test.

---

## Messenger diagnostic refinement — CI passed; installed metadata required

Active branch: debug/two-stage-handle-messages. Based on 4f9c082ce257bcf757cc3db8e3c2d3469664ad48; no intervening OpenCode changes were found on resume.

A scoped metadata-only change distinguishes missing versus malformed UIApplicationSceneManifest, and absent versus non-Boolean UIApplicationSupportsMultipleScenes. All four results remain unknown/eligible=false. Explicit false remains multiple-scenes-disabled. No application gains eligibility, no private call or host/owner/launcher/lifecycle path changes, and no raw plist or new personal information enters reports. Existing wire shape/policy stay unchanged; old clients reject unfamiliar negative reasons safely. Existing synthetic negative cases and JSON/status-forgery tests cover the distinctions.

Source d0303bd039aefe08817702fb737c85eae90336eb passed GitHub Actions run41521971944/job125540017169: all34 suites, native Foundation fixtures with AddressSanitizer/UndefinedBehaviorSanitizer, Clang analysis, pinned Theos rootless arm64/arm64e build and payload/binary inspection. Scene capability tests:3191 checks. Local source-policy and independent scoped-diff verification also passed. CI artifact13179350959 is investigation evidence, not a new release or an installation recommendation. No actual Messenger/iOS runtime test was performed. Package version is deliberately unchanged because this is an investigation checkpoint, not a new delivered release. The permanent RC4 DEB and stable/recovery refs remain the supported recovery choices.

Messenger's installed manifest and app version remain unavailable. The old manifest-unknown report cannot be retroactively assigned a more specific cause. Next indispensable phone input: only the installed Messenger Info.plist from its .app bundle via Filza (not its Data container). No new diagnostic installation/respring is needed for this collection. See MESSENGER_METADATA_DIAGNOSTICS.md. Continue static investigation from that exact version/manifest before proposing a runtime path. Do not bypass admission or apply the Messages exception to Messenger. Messages already works per user confirmation.

---

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

RC4 received phone reports and subsequent user confirmation that Messages works with com.apple.MobileSMS. See the current tandem checkpoint and RC4_MESSAGING_DEVICE_RESULT.md. Do not repeat ordinary Messages testing.

Messenger remains unresolved: do not infer its installed manifest or apply the Messages exception to it. Messages functionality is user-confirmed; do not declare every-app support or general Dopamine/ElleKit compatibility based on compilation.

## Recovery and constraints

Permanent RC3 archive: `release-candidates/1.0.2-rc3`, commit87d5d1ef8ddf122edc255c54250694861f6de15d.
Permanent RC2 archive: `release-candidates/1.0.1-rc2`, commit8d360d8ded7df9e8e857b29088c5642769679172.
Earlier RC1 and recovery/0.17.0 remain available.

No automatic phone install/respring/process kill; no personal-data deletion or other-tweak modification. Existing recovery: /var/mobile/.ppo_disable plus manual respring, or Dopamine without injection then uninstall only PPO. Preserve GPL-3.0 attribution/license. Original watchdog causes remain unconfirmed.

Use GitHub Actions' pinned Theos/SDK16.5 workflow. Linux pure tests cannot validate UIKit or private iOS runtime. No compatible physical Apple Silicon Mac was available for vphone-cli. Private icons and keyboard alternatives remain unenabled; read the derived audit documents before changes.

Raw phone reports and Apple firmware bytes were kept outside the repository and may not be available in a new environment. Do not assume prior ChatGPT context or access to those local files. Repository source, derived audits, reports and permanent DEBs are published.


## Subsequent RC4 messaging reports

Read [RC4_MESSAGING_DEVICE_RESULT.md](RC4_MESSAGING_DEVICE_RESULT.md) before changing messaging support. The attempted Messages identifier was com.apple.mobilesms.compose; the audited com.apple.MobileSMS profile has not yet been exercised in these reports. Messenger is unknown/manifest-unknown before host creation.

