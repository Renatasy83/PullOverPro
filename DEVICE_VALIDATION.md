# Device validation

## User-confirmed 0.10.0 — Keep, lock notification and reuse

The user supplied host-0.10.0.json and answered Funcționează after the requested default-lock and Keep/manual-close/reopen sequence. Executableffe808f00174ac2bca2c3f9ffb64a7ae209e2cef is preserved as stable/verified-safari-keep-lock-reuse.

The report contains five attempts, of which four displayed a window. The initial attempt safely refused selection:not-found,5 scenes inspected and0 matched, no owner/window created, replacement allowed. This is not a crash or cleanup failure. Later source selection succeeds after Safari exists; no automatic launch or source fabrication was performed.

Displayed sessions:default timed mode6.119s closes by device-lock-notification; kept mode77.776s closes by that notification; kept mode39.534s closes manually; kept mode7.033s closes by that notification. Keep is explicitly requested at roughly2.045,2.578 and3.693 seconds. The long session has heartbeats near32.056/62.306s and the39.534s session near32.809s. Actual operation beyond the15-second deadline is established, while an actual default timeout is not exercised in this particular report.

All four displayed sessions match all four framework UUIDs, verify the proxy target as the owned child, and finish with returned controller/workspace invalidations, closed=true, pinned=false, poisoned=false and replacementAllowed=true. The final reopening begins about1.387s after manual closure. No exception or quarantine event is present. New render layers are present while the original Safari scene remains logically backgrounded without layers.

Final locked=false/data-available/active samples are cached pre-close readings. Lock samples precede closure by about0.24–0.51s; they do not contradict notification-driven closure or measure the state after locking. Accept the user's confirmation of the requested visual test; the report does not quantify zero-frame exposure during lock transitions, indefinite stability, global leak freedom, explicit keyboard routing or full Dopamine/ElleKit compatibility. The longest event list reaches16 but does not exercise ring overflow.

The requested Keep/lock/manual-reuse gate is complete for these observations. The next isolated stage tests additional eligible apps under the same owned-scene proof; see DECLARED_SCENE_TARGETS.md. The raw phone report and web data are not committed.

## User-confirmed 0.9.1 follow-up — input, manual close and reuse

The latest host-0.9.1.json contains five sessions total, including the exact timeout session from the prior report. It adds four trials, not five: one timeout and three manual closes. All five have matching framework UUIDs, verified-proxy binding to the owned child, returned controller/workspace invalidations, closed=true, pinned=false, poisoned=false and replacementAllowed=true. There are no preparation failures or exception events.

Visible durations are approximately15.044,15.030,11.680,1.991 and3.365 seconds, respectively. Session intervals do not overlap. The smallest close-to-next-prepare gap is about1.999 seconds, providing actual live reuse evidence beyond the native fixtures. The original remains uniquely selected and logically backgrounded with zero layers in every paired sample. Newly hosted layers vary across sessions; a type3 layer does not prove keyboard use. Inspected scene counts7/8/8/8/9 do not by themselves establish a leak.

The user explicitly confirms manual X, reopening, rendering over another foreground application, actual interaction and web navigation. This completes the requested same-build input/manual-close/reuse gate. It does not independently identify the other app, confirm explicit keyboard routing, lock/unlock, rotation, prolonged lifetime, other hosted applications or full Dopamine/ElleKit compatibility. JSON is not an input event trace; accept the user's direct observation alongside it. Historical final samples remain pre-close observations.

Preserved executable reference:stable/verified-safari-ownscene-input-reuse points to025cf5d835d4454c60c771fea19e17e60c126add. The earlier ownscene-timeout baseline remains unchanged. The next isolated stage is explicit Keep, described in KEPT_SAFARI_WINDOW.md, with its own automation and necessary lifetime/lock device gates. No repeat of ordinary0.9.1 input/navigation testing is required. The raw report, URLs and page contents are not committed.

## User-confirmed 0.9.1~dev.componentproxy1 — independent Safari rendering and timeout

Executable source025cf5d835d4454c60c771fea19e17e60c126add passed Actions run41165469987 and was installed manually by the user. The user then supplied host-0.9.1.json and confirmed visible content and automatic closure. Preserved source reference:stable/verified-safari-ownscene-timeout. This reference describes this specific verified operation, not full compatibility or all-application support.

The report contains one session and13 events. All three framework UUIDs match; the original Safari selection is unique among7 scenes. The component binding is verified-proxy, matchesCreatedScene=true and matchesBorrowedSource=false. Preparation completes about21ms after the request and the window is shown at36.7ms.

The first two layer observations have no layers. At the750ms scheduled observation, about811ms after the request, the new scene has2 type1 layers and the hosting hierarchy contains2 _UIContextLayerHostView instances. Those remain present in every later observation through12.062s. This bounds the observed arrival time; it does not measure the exact first frame.

Across every paired sample, the original scene has settingsBackgrounded=true and0 layers, while the independently hosted scene has settingsBackgrounded=false, active=true and valid=true. Thus the new scene retains render sources while the original is logically backgrounded. The user's separate observation establishes visible content. The JSON does not identify the app underneath the window or record actual page contents, screenshots or input events.

closeReason=timeout and close-returned occur15.080s after the preparation request, about15.044s after showing the window. Final sceneHost.state=closed, controllerInvalidateReturned=true, workspaceInvalidateReturned=true, pinned=false and poisoned=false show completed owned cleanup; replacementAllowed=true also requires confirmed UI cleanup. In the implementation this state requires the owned scene to be invalid and its workspace empty before workspace invalidation returns. It is not a proof of Safari client session database cleanup or long-term process behavior.

The final live/layer sample values are historical readings taken around12.062s, roughly3.018s before close. Their active=true/layerCount=2 values are not post-close observations. The final geometry is empty and windowHidden=true. No source mutation was requested by this adapter.

This confirms one independent Safari rendering/timeout/owned-cleanup operation on the stated device. It does not confirm touch, scrolling, keyboard/focus, manual X, reopening, lock, rotation, process death, repeated stress, other applications or full Dopamine/ElleKit compatibility. The report's conservative runtimeCompatibilityConfirmed=false remains appropriate.

The then-requested same-build input/manual-close/reuse gate is now complete, as recorded in the follow-up above. UIView interaction flags do not establish remote-event blocking; the user's direct observation establishes actual interaction for the tested0.9.1 operations. No speculative input flag/private focus change was made. No phone operation is performed automatically; the raw phone report is not committed.

## Device report: 0.9.0~dev.ownedscene1 — preparation rejected

The actual host-0.9.0.json contains one Safari session. All three expected framework UUIDs match; original selection is unique among7 inspected scenes. workspaceVerified=true and the code path reaching unverified-controller-scene establish that the isolated child namespace, pointer inequality, validity, Safari client identity and application role checks passed. The combined activation-component/hostScene guard then rejected preparation in about25ms.

No hosting window was attached: geometry is empty, windowHidden=true and no live/source samples were taken. controllerVerified=false, pinned=true, poisoned=true, closed=false and replacementAllowed=false show intentional quarantine. Both controller and workspace invalidation attempt/return flags are false. This is not a report of rendering failure after successful attachment, and it does not establish a watchdog or Objective-C crash.

The combined guard did not record individual operands. Exact23A355 firmware inspection independently proves that a normal hostScene result can be FBSComponentScene:NSProxy, which forwards FBScene class tests but differs from the raw workspace child. This reveals a false-rejection defect, without proving that this exact operand caused the uploaded rejection.0.9.1 adds exact-runtime-class unwrapping with an ABI-checked read-only getter, strict owned-target equality and scalar componentBinding evidence. Native proxy fixtures and CI cannot establish the phone outcome.

Do not repeat0.9.0. Manual respring is needed to discard its pinned uncertain resources before a corrected trial. No device operation is performed automatically. New build's Safari rendering, input and owned-scene/private cleanup remain unverified; full Dopamine/ElleKit compatibility is not confirmed. Historical successful tests below apply only to their stated versions and operations.

## User-confirmed 0.6.1~dev.bridgefix1

Target: iPhone12,5, iOS26.0.1 build23A355. Dopamine rootless is user-reported; ElleKit1.2 and OS/device identifiers were shown in earlier device screenshots. The exact Dopamine version is not recorded.

Evidence supplied by the user:

- `command -v launchctl` returns `/var/jb/usr/bin/launchctl`.
- Installing0.6.1~dev.bridgefix1 over0.6.0~dev.bridge1 completed package configuration without the earlier missing-launchctl error.
- After respring, pressing the Safari launch action inside PPO actually opened Safari. This is visual user confirmation, beyond the helper's accepted-request return value.

The panel-to-service launch path is therefore confirmed for this operation on this device. The earlier0.5.10/0.5.11 SpringBoard posix_spawn EPERM no longer prevents this launch path. Its precise enforcement cause remains unproven; the architecture avoids that process creation rather than changing sandbox or injection settings.

Not established by this test: launching other apps, repeated/restart/lock/orientation stress, emergency-disable behavior on the phone, full Dopamine/ElleKit compatibility, or application content hosted in floating windows. Floating application hosting was not implemented in that version. main and stable/verified-app-picker remain unchanged; this single operation does not promote the development branch to a fully validated release.

## Device report: scene-0.7.0.json

The user supplied the actual JSON report. FrontBoard, FrontBoardServices and UIKitCore observed UUIDs all equal the exact23A355 expected UUIDs. Selection inspected5 scenes, matched1 and returned state unique for a Safari scene identifier. Both top-level and selection hostingRequested are false. The read-only selection path therefore completed on the device; no presenter creation, activation or hosting was tested.

Runtime metadata also reports FBScene.uiPresentationManager as @16@0:8, UIScenePresentationManager.createPresenterWithIdentifier: as @24@0:8@16, _UIScenePresenter.presentationView as @16@0:8, and activate/invalidate as v16@0:8. These entries establish method presence/type encodings, not successful invocation, ownership, input routing or correct teardown. Do not promote them to confirmed hosting support.

## User-confirmed 0.7.1~dev.hosttrial1 — 2026-10-29

The user supplied host-0.7.1.json and confirmed that live Safari content appeared in the PPO window, that they closed it with X, and that Safari and the phone interface returned to normal.

The report observed the exact expected three framework UUIDs, 9 inspected scenes and one Safari match. Its owned presenter reached prepared then activate-returned, with activeAfterActivation=true and hostingAfterActivation=true. Roughly 10 seconds later it reached close-returned/state=closed, invalidateReturned=true, owned=false, poisoned=false. The user explained the early close as manual; the 15-second automatic timeout was not exercised by this test.

The activeAfterActivation/hostingAfterActivation flags are historical observations, not a claim that hosting continued after close. The report's visiblePixelsVerified/systemPresentationRestoredVerified=false values are conservative constants; visual confirmation comes separately from the user's observation.

This validates one manual Safari render/close operation on this particular device. It does not establish touch/keyboard routing, automatic timeout, repeated cycles, lock/orientation/process death or complete Dopamine/ElleKit compatibility.

Preserved branch: stable/verified-safari-rendering at 3c7d3f0265e4a9b938ec45dd5ea7ad99ad06fa1e. Previous launch-only baseline and main remain intact.

## Device report and observation: 0.7.2~dev.touchtrial1

The supplied host-0.7.2.json matches all three framework UUIDs and selects one Safari scene among5 inspected scenes. The owned presenter activates with activeAfterActivation=true and hostingAfterActivation=true. About15.03 seconds later closeReason=timeout, state=closed, invalidateReturned=true, owned=false and poisoned=false establish completion of the automatic-close code path.

The report has inputEverEnabled=false, all inputEnabled fields false and no input-enabled event. The user nevertheless explicitly observed scrolling inside the small Safari window while the header read "Atingeri: oprite".

Consequently the0.7.2 switch and the old report field names do not reliably describe remote-scene input blocking. The observation is accepted as scrolling seen in the hosted content, but direct hosted-surface routing versus events reaching Safari underneath is not distinguished by this report. Do not reject the user's observation based on the UIView flag or promote it to proof of isolated input routing. No keyboard entry was confirmed.

The0.7.3 correction removes the misleading switch, keeps the same container flag used in the observed trial, and reports schema2 fields containerUserInteractionEnabled/presentationViewUserInteractionEnabled, inputBlockingGuaranteed=false and inputRoutingMechanism=unconfirmed. It does not add a private input API or claim a blocking fix.

Preserved timeout-tested source: stable/verified-safari-timeout at411cd127fa18005989d05f2aefff59b697ee1029. main and previous stable branches are unchanged. This is not confirmation of full Dopamine/ElleKit compatibility.

## Follow-up: Safari Tab button responds in the small window

The user explicitly confirmed that pressing Safari's Tab button inside the small hosted window opens the tab overview. This supplements the observed scrolling while the0.7.2 switch said off: Safari controls visibly respond at the locations presented in the small window.

This supports functional touch interaction with the presented Safari UI on this device. It is a visual user observation, not a trace of WindowServer/event-target ownership, and does not establish an input-blocking guarantee or interaction while a different underlying app is active. Keyboard entry/focus has not been tested or confirmed. No private keyboard/focus calls are enabled on the basis of this observation.

Next indispensable device observation can use the already installed0.7.2 build: tap the address field in the small Safari window, enter about:blank and verify that input reaches that field and that closing the window restores normal operation. No new package is needed for this observation.

## Follow-up: keyboard entry and navigation

After being asked to test the address field, keyboard entry and navigation using the already installed0.7.2 build, the user confirmed that the keyboard and navigation both work. This adds a positive visual device observation for Safari input; no private key-window, first-responder or event-deferral calls were added.

The underlying foreground application during this test has not yet been recorded. Therefore this confirms the tested Safari interaction, but does not yet establish independent focus while another app is underneath, background execution, app switching or cross-app routing. The report's conservative keyboardRoutingVerified=false constant is not a rejection of the user's separately supplied observation; JSON alone does not instrument actual text delivery.

Do not introduce speculative keyboard/focus APIs to solve an unobserved problem. The next gate is the existing presentation's behavior with a different foreground app; first obtain the context of the completed test to avoid asking the user to repeat it unnecessarily. Other-app hosting, lock/orientation/process death and complete platform compatibility remain unverified.

## Foreground context clarified by the user

The user clarified that full-screen Safari was behind the small PPO Safari window during the successful scrolling, Tab button, keyboard and navigation observations. Those observations therefore establish behavior in that foreground-Safari arrangement. They do not yet demonstrate independent Safari interaction over NewTerm/another foreground app or Safari background execution.

The current source review confirms that selecting Safari in PPO's picker only persists the selection; the separate launch action brings Safari forward. A discriminating device test can use the already installed0.7.2 build: after a manual respring/new attempt, open Safari normally so it has a scene, switch to NewTerm, select Safari in the PPO picker without pressing the separate app-launch action, then press the floating Safari trial. Observe whether NewTerm stays behind the small window and Safari's Tab/address/keyboard/navigation controls respond there; allow timeout cleanup and provide the existing host-0.7.2.json report. If the trial refuses or Safari becomes full-screen, record that result rather than adding guessed foreground/focus calls.

No executable code was changed for this clarification. This runtime configuration cannot be established by the current Linux/macOS native fixture environment. Main and all stable source branches remain unchanged.

## User-confirmed Safari window over NewTerm

After the specified existing-build test (Safari scene first, switch to NewTerm, select Safari without the foreground-launch action, then open the floating trial), the user confirmed that it works as described: NewTerm remains visible and the Safari window closes automatically. This is an actual user observation of the requested background-app arrangement on0.7.2, supplementing the previously confirmed Safari scrolling/Tab/keyboard/navigation observations.

No additional JSON report was supplied for this particular background test; the earlier report's timeout trace must not be misrepresented as a trace of the newly clarified foreground context. Repeated presenter creation, Settings hosting, lock/orientation/process death and complete Dopamine/ElleKit compatibility remain unverified.

The code exercised on the phone is preserved at411cd127fa18005989d05f2aefff59b697ee1029, also on stable/verified-safari-over-newterm. Main and all previous stable branches remain untouched.

##0.8.0 device regression: black hosted content

The user found Settings in the picker, resolving the earlier list-discovery issue without a code change. In0.8.0 they observed a black small window for Settings and Safari. The X button/manual close works and reopening after manual close works. No visible application content or scroll behavior can be verified from the black window. No crash was reported in this observation.

Treat this as a rendering regression against the user-confirmed0.7.2 Safari behavior, not a successful Settings-hosting test. The new native/sanitizer/build checks did not establish real UIKit rendering.

The supplied0.8.0 runtime JSON has been offered by the user but is not yet attached in the current message. Analyze it before attributing a cause or selecting another device build. The GitHub comparison411cd127...3651ec9 confirms PPOScenePresenter.mm and PPOScenePreflight.mm are unchanged; ownership, wrapper/UI and reporting changes still require review and are not ruled out by that fact.

Main and the working0.7.2 stable branches remain preserved. Do not infer an ElleKit/Dopamine defect, an Objective-C exception, presenter priority failure, or a geometry/lifetime cause from a black window alone.

## Received host-0.8.0.json: four complete sessions

The actual schema3 report was supplied and parsed. It contains two Settings sessions followed by two Safari sessions. Every lookup inspected10 scenes and selected one exact match. All three observed framework UUIDs match the pinned23A355 values.

Each session reaches prepared then activate-returned with activeAfterActivation=true/hostingAfterActivation=true, then closed with invalidateReturned=true, owned=false, poisoned=false and replacementAllowed=true. Settings closes manually after roughly5.59s, then by timeout after15.02s; Safari closes by timeout after15.03s, then manually after2.12s. This supplies actual runtime evidence for multiple explicit reopen/cleanup cycles while the user reports black content. It is not evidence of visible application rendering.

The report only stores the activation flags sampled immediately after activate. It does not sample current active/hosting state later, nor does it record runtime view frames/bounds/transforms. Its top-level presentationViewUserInteractionEnabled=false and hostWindowIsKey=false were captured after close cleared those objects; they do not establish either property's in-window value. No geometry, priority, process-background, injection or ownership root cause is established by this JSON.

0.8.1 adds an owned scaling wrapper and bounded post-layout/live-state observations. Exact UIKitCore implementation evidence shows that the private presentation view itself can write its frame/transform, so direct scaling of that view is a fragile integration. This also existed in0.7.2 and is therefore not a demonstrated explanation of the regression. Recovery of visible pixels must be observed on the phone. See RENDER_LAYOUT_23A355.md.

## Received host-0.8.1.json: geometry valid, recorded host tree has no context-host view

The schema4 report contains three attempts. The first Safari lookup found no scene among4 and refused without creating a presenter. The next Safari lookup matched one scene among5, and Settings matched one among6. Both successful attempts closed manually and completed invalidation without poison.

At post-layout,100ms and750ms in both apps: the private presentation view is attached to PPO's window, hidden=false, alpha=1, frame/bounds414x896, identity transform; PPO's wrapper scales by0.486607142857, producing201.455x436 inside a300x436 viewport. The visible window is300x480 at57,60, the host scene is foreground-active and usedFallbackFrame=false. Current sampled presenter flags remain active=true, hosting=true, invalidated=false at both delayed observations.

The complete recorded three-view descendant chain is _UIScenePresentationView -> _UISceneLayerHostContainerView -> _UITouchPassthroughView. The last view has no subviews or layer children; no _UIContextLayerHostView or _UIExternalSceneLayerHostView appears. This narrows the investigation to availability/selection/attachment of the scene's render layers rather than supporting zero-size, off-window or initially hidden geometry. It does not establish why a context-host view is absent, or rule out every possible rendering issue.

Exact23A355 filtering code reads FBScene.layerManager.layers and applies presentation-context target filters. No runtime layer-manager counts or filter values have yet been recorded, so absent source layers, filtering and other attachment-state causes remain hypotheses. No priority/foreground/security flags were changed. See LAYER_ATTACHMENT_23A355.md.

Before another diagnostic installation, the existing0.8.1 can distinguish whether the failure is restricted to the NewTerm/background arrangement: keep Safari full-screen and open its PPO window there. The visual result of that observation is pending.


## Follow-up:0.8.1 renders over foreground Safari

On the same installed0.8.1 build, the user explicitly answered that the small PPO window displays content when Safari stays full-screen underneath, without switching to NewTerm. This contrasts with the earlier black-content observations over the other-app arrangement. It establishes rendering in this foreground-Safari condition, not a general rendering fix or independent background execution.

The earlier host-0.8.1.json was captured for the black sessions and must not be presented as instrumentation of this later successful observation. Obtain the report generated after this successful operation to compare the same build's descendant tree and sampled presenter state. No package installation or respring is needed for this comparison.

The source comparison against the user-confirmed0.7.2 baseline shows the presenter creation/activation and unique-scene selection paths unchanged;0.8.1 adds read-only presenter state sampling, while wrapper geometry, session lifecycle, UI and reporting changed. None of those differences alone proves the cause. In particular, foreground rendering does not demonstrate that a specific background assertion, foreground flag, layer mask or priority mutation is required or safe.

Main and every stable branch remain unchanged. No new private runtime call or executable change was made for this observation.


## Paired runtime report received: context-host views differ on the same build

The later supplied host-0.8.1.json contains five sessions. Its first three session dictionaries are exactly equal to those in the earlier black-window report; they are retained history, not three additional tests. The two new Safari sessions select the same Safari scene identifier as the earlier black Safari session, with matching framework UUIDs. Their close reasons are timeout (approximately15.049 seconds from prepare-requested) and manual (approximately14.471 seconds). Both end closed, invalidateReturned=true, owned=false and poisoned=false.

In each new session, from activate-returned through the750ms sample, the recorded descendant tree contains five nodes: _UIScenePresentationView, _UISceneLayerHostContainerView, _UITouchPassthroughView, then two _UIContextLayerHostView children backed by CALayerHost. The earlier successful-activation black sessions contain only the first three nodes, with no context-host children. No capture-limit truncation explains this difference.

The recorded ancestor geometry is equal between the black Safari session and both new Safari sessions: private view414x896, wrapper scale0.48660714285714285, own window300x480 at57,60. Current active=true/hosting=true/invalidated=false samples occur in both outcomes. These values therefore cannot discriminate rendered content. The report itself does not record the target application's foreground state; association of the later successful observations with foreground Safari comes from the user's separate explicit answer. No visual outcome is assigned to the second new session solely from its JSON.

This establishes an attachment-tree difference and repeatable owned-presenter cleanup in this sample, not the upstream reason for missing context-host layers. Source FBScene layer counts, layer filters, process state and policy remain uninstrumented. The same selected scene identifier and retained earlier session history argue against needing a different build/respring just to attach layers in the foreground condition, but do not establish app-process identity or guaranteed background operation.

The original project's ContextHostManager.mm was rechecked: its iOS13 hosting path calls forceApplicationForegroundForBundleId before reading scene layers; that method uses KVC _mutableSettings, setForeground:YES and updateSettings:withTransitionContext:completion:. Close unconditionally writes foreground=false. This is historical design evidence, not a verified iOS26 lifecycle contract. No original KVC/foreground mutation, presumed layer mask, priority or process assertion was copied into the port.

Next live discriminator can use the installed build: create the visible small Safari window while full-screen Safari is underneath, then switch to NewTerm before the15-second timeout. Distinguish retained content, black content and automatic close rather than treating those outcomes as equivalent. This is a real UIKit/client lifecycle observation and cannot be simulated by the present native fixture tests. No new package is required. No executable change or new build was made for this evidence update.


## Observed transition: visible Safari becomes black over NewTerm

The user performed the existing-build transition on0.8.1: open the small window over full-screen Safari, then switch to NewTerm before timeout. The small PPO window remains open but becomes black. This is a within-session visual observation of content loss on the app switch, not a failure to create PPO's window. No transition JSON was supplied, so the earlier750ms samples must not be represented as samples of this switch or as proof that source layers were removed at that instant.

Combined with the paired reports, this prioritizes the target scene/client foreground-to-background lifecycle and layer availability/attachment path. It does not establish process suspension, a particular assertion requirement, security/injection policy or filter mask. The cause remains unconfirmed. Existing0.7.2 cross-app success is retained as a historical user observation; its earlier report did not instrument that background arrangement, and it cannot establish which state differed.

No additional installation or blind foreground/priority mutation is justified by this observation. Before a functional change, the next instrumentation must distinguish source scene/layer state from hosted-view state across the same transition, use verified encodings and declared method-table checks, remain bounded/main-thread, and add native rejection/exception fixtures. A run-time dependency or full compatibility claim must not be derived from a successful build.

Static follow-up inspected FBScene updateSettings:withTransitionContext:completion: at0x1a842b00c in the pinned23A355 FrontBoard image. The method performs nontrivial work, including a settings getter and diffFromSettings:toSettings: dispatch (stubs0x1a849bbe0 and0x1a8496300). Presence of this method and the original project's usage do not establish reversible ownership of scene settings or a safe background-hosting contract. No settings setter or update callback was invoked or enabled in the port.

This update changes documentation only. Main/stable source and the installed executable remain unchanged; no new CI runtime-validation claim is made.


## Device evidence:0.8.2 source layers disappear on the foreground-to-background transition

The actual schema5 host-0.8.2.json contains one Safari session and13 events, with all pinned framework UUIDs matching and unique source selection. The guarded source reader succeeds on the device: layerManager/settings/isActive, layers, type and isBackgrounded reads complete without reported ABI/class failure or exception. This validates those bounded reads for this sample, not arbitrary scene mutations or full runtime compatibility.

Observed timeline, relative to prepare-requested:

| Sample time | settingsBackgrounded | sceneActive | Source layer count/types | Context-host views | PPO presenter active/hosting |
| --- | --- | --- | --- | --- | --- |
|0.019s to2.038s|false|true|2 / [1,1]|2|true / true|
|4.032s to12.039s|true|true|0 / []|0|true / true|

The first background/empty observation occurs at4.032s; the transition is bracketed between the2.038s and4.032s samples, not timed exactly to4 seconds. Across those five later samples, the PPO window remains visible and its host UIWindowScene remains foreground-active. The private source FBScene.isActive flag also remains true: it is not equivalent to application foreground state or available render content. The layer type values are observed integers, not an inferred layer-type enum definition.

The automatic-close path completes at approximately15.043s: closed, invalidateReturned=true, owned=false, poisoned=false, replacementAllowed=true. The close record carries the historical last source/presenter samples from12 seconds; it is not a new source-state read after teardown.

This is direct runtime evidence that source-layer loss accompanies backgrounding in the reproduced failure. A geometry-only correction, presenter.isHosting or an invented presentedLayerTypes mask cannot be treated as a demonstrated remedy for an observed empty source set. This does not establish why the client stops supplying layers, actual process suspension/death, missing entitlements, injection failure, or the precise lifecycle operation needed to keep rendering. No crash/watchdog cause is inferred.

No repeat of the same device test or another diagnostic-only installation is requested for these already successful reads. The next functional work must address source scene/client lifecycle with a separately owned, releasable request and verified semantics, instead of silently changing foreign scene settings. Restoring an old full settings snapshot could overwrite newer system state, while blindly setting foreground=false at close could background an application the user has since opened. Neither is accepted as a recovery strategy.

### Static lifecycle follow-up

The exact23A355 SpringBoard framework in the already verified dyld cache was inspected locally; no Apple binary is distributed with the project. SBSceneManager.assertBackgroundedStatusForScenes: at0x21d6d38d4 returns a SBSceneBackgroundedStatusAssertion, and the inspected paths track an NSCountedSet named _assertedBackgroundScenes and invoke manager state-update work. The method name alone does not establish a foreground-rendering lease; it was not invoked. SBDeviceApplicationSceneHandle also declares activity/jetsam/resource assertions whose signed-char modes are not defined by their ABI. No guessed modes are used. The application-protection visibility assertion found on a separate assistant is not an app-rendering lease and is outside this port's scope.

FBScene.isMutable at0x1a83debfc consults internal transaction/update/deactivation/invalidation state; this is evidence of lifecycle constraints, not permission to mutate scene state whenever a Boolean is true. The original port's KVC _mutableSettings/setForeground/updateSettings sequence does not supply a verified current ownership/rollback contract. Static method presence is insufficient to bypass those constraints.

No new private runtime operation, source mutation, DEB version, install or respring was introduced by this evidence update. Main and all stable branches remain untouched. The existing successful Actions result for executable source59773b51c37578c33e062d0a1d55439ce51a1c7a remains the automated baseline; documentation-only evidence does not require or claim another runtime validation run.


## Received0.8.3 report: scoped visibility is insufficient

Three Safari sessions were recorded. The first two had visibilityPropagationInitiallyEnabled=true, so no visibility-context mutation was needed. In session1 the source changed from2 layers at2.040s to0 layers/backgrounded at4.036s; by12.041s it again had2 source layers/not-backgrounded, but PPO hosting=false and no recorded context-host children. This separates source availability from presenter arbitration; the report does not identify the user's exact app-switch actions at those timestamps. Manual owned cleanup completed at14.319s.

Session2 remained not-backgrounded with2 layers through all recorded samples and closed by timeout at15.045s. It does not instrument an observed background transition. Session3 started with visibilityPropagationInitiallyEnabled=false and configuration readback succeeded; it nevertheless remained backgrounded with0 source layers through12 seconds and closed by timeout at15.041s. Thus the scoped mutable-copy operation is device-confirmed for that operation, but it did not produce background render layers in this sample. It is not evidence of delivered RBS grants or a general compatibility result. All three sessions ended with invalidateReturned=true, owned=false, poisoned=false and replacementAllowed=true.

No separate visual outcome was supplied with this file. No new claim of pixels or touch routing is inferred from JSON. There is no need to repeat this same visibility test. Independent scene ownership is being implemented on debug/owned-safari-scene; the exact firmware Safari manifest declares multiple scenes supported, while Settings does not. See OWNED_SAFARI_SCENE_23A355.md for the new bounded architecture and remaining live gate.

