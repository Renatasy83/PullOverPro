# Device validation

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
