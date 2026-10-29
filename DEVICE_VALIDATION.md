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
