# Autonomous port status — 2026-10-31

Current isolated development:0.13.0~dev.geometry1 on debug/floating-window-geometry. It adds bounded title dragging and three public viewport size presets; no new private dispatch or scene/native-frame/lifetime change. See FLOATING_WINDOW_GEOMETRY.md. Current-source CI is pending.

Previous selected metadata stage:0.12.0~dev.selectedcap1 on debug/selected-app-capabilities. It adds conservative per-selected-app installed metadata inspection through PPO's existing mobile service. No bulk manifest collection or SpringBoard bundle IO is introduced. Eligible new clients use the existing owned-scene architecture with additional exact specification-class guards. Metadata is advisory, not an entitlement or compatibility claim. See SELECTED_APP_CAPABILITIES.md. Executable6d176ad4bec086cad6a99c72e360d136efa79cff passed all20 suites, iOS Clang analysis, Theos rootless arm64/arm64e packaging and downloaded ZIP/DEB inspection. Actions41241693750/artifact13057987055 is the delivered package. See VALIDATION_0.12.0.md for evidence, hashes and unexecuted device tests.

## Preserved actual device baselines

Reminders0.11.0 executable0bb57241e7aeb54a35b434e59f7b24bf844cc7c5 is preserved as stable/verified-reminders-window-reuse. Actions41214886266/artifact13047815553 passed17 suites, iOS analysis, rootless build and downloaded artifact inspection. The subsequent supplied report contains two cleanly released Reminders windows, manual X then15-second timeout after reopening; the user confirms the requested function works. Contacts remains untested. See DEVICE_VALIDATION.md and VALIDATION_0.11.0.md.

Safari0.10.0 executableffe808f00174ac2bca2c3f9ffb64a7ae209e2cef remains stable/verified-safari-keep-lock-reuse, Actions41192308078/artifact13039207175. Its report/user confirmation covers the requested Keep/lock/manual-reuse operations. Cached pre-close lock/layer values do not measure post-lock exposure or cleanup. Earlier Safari0.9.1 source025cf5d835d4454c60c771fea19e17e60c126add remains preserved as stable/verified-safari-ownscene-input-reuse and stable/verified-safari-ownscene-timeout.

Main remains Alpha4 at af336d84a6b4812e6b6406af87803fb15bf29c3b. Earlier picker/launch/rendering stable references and original GPL attribution remain untouched. Raw phone reports and application contents are not published.

## Current change and validation boundary

The new seven-field capability is nonce-bound, normalized and expires after5s. Only the selected app Info.plist is bounded-read by the mobile helper after exact23A355 cached getter owner/ABI/CoreServices UUID checks. A positive requires a simple explicit iPhone multiple-application-scene declaration. Negative metadata overrides the three-app firmware baseline. Valid unknown metadata or an explicit nonce-validated unsupported response preserves only that baseline; missing/malformed/mismatched/stale replies grant nothing. Each original/child identity and the frozen admission must match independently. The own service is restarted on upgrade using its exact launchd label, with fixture tests for lifecycle errors. Existing inventory, normal launch, lock/Keep and owned cleanup policies remain.

New native suites cover pure capability policy, bundle reader and immutable admission, alongside expanded bridge/owner/subprocess/lifecycle tests. Applicable ASan/UBSan, iOS Clang analysis, Theos arm64/arm64e build and package/license inspection are required. Linux and macOS Intel fixtures do not run iOS clients. No compatible physical Apple Silicon Mac is accessible for vphone-cli.

Target evidence:iPhone12,5 iOS26.0.1 build23A355, user-reported Dopamine rootless, screenshot-confirmed ElleKit1.2; exact Dopamine version unknown. The subsequent0.12.0 Contacts report/user confirmation exercises fresh installed-info admission, visible requested function, X/reopen/timeout and clean owned teardown. Exact postinst restart branch, nonbaseline clients and full platform compatibility remain unconfirmed. Current0.13.0 size/drag/input behavior requires device validation after automation. Historical watchdog causes remain unconfirmed because the original IPS files were not supplied.

## Next indispensable live gate

The0.12.0 selected metadata/Contacts gate is complete and preserved as stable/verified-contacts-installed-metadata at6d176ad4bec086cad6a99c72e360d136efa79cff. After successful0.13.0 automation, only the changed public-window behavior needs a live gate:use one already working app, cycle the size button, drag near edges, check reachable X/content/scrolling and close/reopen once. Keep remains off by default and no app metadata policy is broadened. Provide host-0.13.0.json.

Recovery:X/default15-second timeout; /var/mobile/.ppo_disable; manual respring for quarantine. Keep deliberately has no timer expiry. If injection prevents startup, start Dopamine without injection and remove only this package. No phone installation/respring, personal data deletion or other-tweak modification is performed automatically. Complete original functionality and full Dopamine/ElleKit compatibility remain unconfirmed.
