# Read-only scene layer diagnostic — 0.8.2

This is an instrumented development build, not a background-hosting repair or final candidate. The user observed that 0.8.1 renders over foreground Safari, then the small window remains open but becomes black when switching to NewTerm. Paired reports show two CALayerHost-backed context-host views in the later Safari sessions, versus none in the black sessions, with equal geometry and active/hosting flags.

## Scope and evidence

The source reader is called only after the existing exact23A355 framework UUID gate and unique app scene selection. It holds the selected scene only for the owned trial's lifetime; it never activates, invalidates or modifies that scene. Only newly created PPO presenters are invalidated by the existing teardown path. The selected scene reference is released on confirmed cleanup.

Exact inspected FrontBoard accessors: FBScene.layerManager at0x1a83da764, FBScene.settings at0x1a83d7904, FBScene.isActive at0x1a83d9e6c, FBSceneLayerManager.layers at0x1a83da774 and FBSceneLayer.type at0x1a83da77c. In the pinned FrontBoardServices image, FBSSceneSettings.isBackgrounded at0x1a288faa4 calls a getter then inverts its Boolean result. These static observations do not establish device call success. Runtime checks require the expected receiver classes and declared object/Boolean/signed-long-long method encodings before typed dispatch, including actual receiver overrides. Missing methods do not trigger dynamic resolution.

Reports contain source layer count (maximum32 iterated), integer layer types, scene active state and settings backgrounded state. They do not contain context/render IDs, process IDs, URLs, page content or screenshots. Unsupported classes, ABI mismatches, oversize sets and Objective-C exceptions produce explicit status values; a failed source probe is not retried in the same session. Those failures do not force scene settings or attempt recovery through another API.

## Sampling and limits

Existing post-layout,100ms and750ms observations include source state. Six additional state-only samples at2,4,6,8,10,12 seconds cover the transition within the unchanged15-second trial. They do not call layoutIfNeeded, reactivate the presenter or extend the timeout. All reads occur on the main thread. Existing disable/closed/running guards prevent later reads after cleanup. Each source/presenter observation carries its own sampleUptime; copied last samples after close remain historical. View geometry is captured at the event's time, not necessarily the source sample's exact time. Reads are bounded by object count/call count, not a preemptive timeout; a private getter is not guaranteed to return promptly merely because its ABI matches.

Report: /var/mobile/Library/Logs/PullOverPro/host-0.8.2.json, schema5, up to8 session summaries and16 events per session, with no recursive history. lastSourceSample and lastLiveSample are separate. Unsupported status is not evidence of an empty source. A count of zero is not by itself proof of process suspension. A source with layers but no hosted context view points to a different stage from a source that has lost its layers; neither outcome proves that arbitrary foreground flags or priority changes are appropriate.

## Validation and remaining device gate

Native fixtures cover source transitions, zero/two/32/33 layers, class mismatch, wrong scalar ABI, missing method without resolution, exceptions, wrong-thread rejection and repeated samples. CI includes iOS static analysis, native ASan/UBSan fixtures, the existing suites, rootless Theos build and DEB inspection. Results must be read from the actual workflow run; this document does not assert those checks have passed before they run.

Linux/native macOS fixtures cannot recreate the target's live SpringBoard/client/WindowServer state. After automated checks pass, an actual device transition report is indispensable: start the small window over foreground Safari, switch to NewTerm before timeout, then retrieve the report after automatic close. No automatic install/respring is added. Existing recovery remains: close with X or wait15 seconds; use /var/mobile/.ppo_disable to prevent new trials and overlay startup, and if necessary boot Dopamine without injection and remove only this package. No other tweak or personal data is modified. No remote input blocking, independent keyboard focus or complete Dopamine/ElleKit compatibility is claimed.


## Executed CI evidence

Source commit59773b51c37578c33e062d0a1d55439ce51a1c7a completed Actions run40970033364 successfully. New probe fixtures:229 checks, native ASan/UBSan. Existing geometry1027, presenter342 and session-slot229 checks passed, together with scene preflight, lifecycle24, bridge IO365, actual fake-workspace subprocess52 and the existing inventory/launcher/protocol/service suites. iOS Clang analysis, rootless Theos compilation, arm64/arm64e binary checks, payload/lifecycle/license inspection and validation-report generation passed. The only recorded linker warnings were the existing obsolete -multiply_defined flag.

Artifact12939308526 contains the0.8.2~dev.layers1 DEB plus logs and VALIDATION.md/VALIDATION.json. This documents an actual successful automated run, not a device installation, private getter invocation, background-rendering repair or Dopamine/ElleKit compatibility confirmation. The next device gate described above remains outstanding. No install or respring was performed by the agent; main and stable branches remain unchanged.
