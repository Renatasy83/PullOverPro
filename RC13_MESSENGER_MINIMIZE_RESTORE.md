# RC13 — Messenger public minimize and restore

## Baseline

User confirmed RC12 Messenger586 works after the requested warm/Keep/NewTerm/move/resize/X/full-screen procedure. Report has3moves/5resizes/3presets withnative414x896 preserved, exact586/schema5, cleanownedcleanup. Scope and missing retainedevents in RC12_MESSENGER_DEVICE_RESULT.md. Preserve RC12 archivec08bc044455f6a6d359626891ede89915c75a34c and stable/verified-rc12-messenger586-geometry.

## Small production delta

PPOOwnedSafariTrial.mm changes only the menu fromMessengerKeep-only tokeep+minimize and removes Messenger-specific earlyreturns fromminimizeFromButton:/restoreFromButton:. Existing generic actionguards/checkLifetime/observedactive remain. No new private selector, delegate/root/frame assignment, workspacecreation or scene activation. Agent/transport/schema5/profile unchanged; no apprestart needed just for protocol.

Minimize uses existing PPOFloatingWindowPresentation: save expanded geometry, clip PPO's ownpanel to44pointbar, retainpositive expanded viewport/wrapper/native containment. applyWindowFrame/captureLayout skip fitting belowthebar whileminimized. Restore clamps savedexpandedframe and refitspublicwrapper. Closingfrombar followsnormalownteardown. Normal passthrough hitTest checks transformedinteractivePanel; actualremoteapptouch exclusion is a devicegate.

Keep initialStandard/foregroundwarm/exact585+586/v5/currentroot/owner/cleanup/quarantine/render/lock guards,15seconddefault, manual120secondroot/125secondagent cap. Minimize/restore neverstart/keep/reprepare/resetclock. ColdMessenger/unlimitedKeep/headerlessmode remainoutside.

## Automated verification

Existing403376presentation assertions include12000mixedresize/minimize/move/restore cycles, finiteclamping/positiveviewport/nativeimmutability/terminalstop/independentlifetime. ExistingKeep598 andreturnstate/client/profile/ownerfixtures retained. Staticguards now requirepublicmenu/actionpaths and forbidmessengerbudgetstart/timerstart/lifetimestart/keep/prepare inminimize/restore. No redundant mirror test added. Full39native/static/pinnedTheosrootlessbuild and13portable/Linux plusartifactinspection requiredbeforeinstall recommendation. Currentstatus recorded inroot handoff.

## Only next physical procedure after automated success

Manuallyinstall/respring. OpenMessenger normally, openitsPPOwindow andchooseboundedKeep; switchNewTerm. Menu…->Minimizează, verifyNewTermtap/scrolloutside44pointbar, dragbar, restore▢andcheckMessengercontent/simpletap/scroll. MinimizeagainandclosebarX; manuallyforegroundMessengerandchecknormalfull-screenUI. Send /var/mobile/Library/Logs/PullOverPro/host-1.0.12.json. Onrefusal/black/unexpectedclosurestoprepetitions andretainexactmessage/interface-1.0.12.json. No repeated2minute/otherapp/coldprobe, no messagesorpersonalappData.

Builds/geometry do not confirmremoteMessengerclipping/input/normalreturn or generalDopamine/ElleKit/signaturetrust. Recoverymarker /var/mobile/.ppo_disable/manualrespring orknownDopaminewithoutinjection/uninstallonlyPPO ifunusable. No automaticphoneaction/other-tweak/personaldata change. GPLattribution andmain/scopedstable/archives retained.
