# Autonomous port status — 2026-10-31

Current isolated development:0.12.0~dev.selectedcap1 on debug/selected-app-capabilities. It adds conservative per-selected-app installed metadata inspection through PPO's existing mobile service. No bulk manifest collection or SpringBoard bundle IO is introduced. Eligible new clients use the existing owned-scene architecture with additional exact specification-class guards. Metadata is advisory, not an entitlement or compatibility claim. See SELECTED_APP_CAPABILITIES.md. CI/build results must be recorded before recommending installation.

## Preserved actual device baselines

Reminders0.11.0 executable0bb57241e7aeb54a35b434e59f7b24bf844cc7c5 is preserved as stable/verified-reminders-window-reuse. Actions41214886266/artifact13047815553 passed17 suites, iOS analysis, rootless build and downloaded artifact inspection. The subsequent supplied report contains two cleanly released Reminders windows, manual X then15-second timeout after reopening; the user confirms the requested function works. Contacts remains untested. See DEVICE_VALIDATION.md and VALIDATION_0.11.0.md.

Safari0.10.0 executableffe808f00174ac2bca2c3f9ffb64a7ae209e2cef remains stable/verified-safari-keep-lock-reuse, Actions41192308078/artifact13039207175. Its report/user confirmation covers the requested Keep/lock/manual-reuse operations. Cached pre-close lock/layer values do not measure post-lock exposure or cleanup. Earlier Safari0.9.1 source025cf5d835d4454c60c771fea19e17e60c126add remains preserved as stable/verified-safari-ownscene-input-reuse and stable/verified-safari-ownscene-timeout.

Main remains Alpha4 at af336d84a6b4812e6b6406af87803fb15bf29c3b. Earlier picker/launch/rendering stable references and original GPL attribution remain untouched. Raw phone reports and application contents are not published.

## Current change and validation boundary

The new seven-field capability is nonce-bound, normalized and expires after5s. Only the selected app Info.plist is bounded-read by the mobile helper after exact23A355 cached getter owner/ABI/CoreServices UUID checks. A positive requires a simple explicit iPhone multiple-application-scene declaration. Negative metadata overrides the three-app firmware baseline. Valid unknown metadata or an explicit nonce-validated unsupported response preserves only that baseline; missing/malformed/mismatched/stale replies grant nothing. Each original/child identity and the frozen admission must match independently. The own service is restarted on upgrade using its exact launchd label, with fixture tests for lifecycle errors. Existing inventory, normal launch, lock/Keep and owned cleanup policies remain.

New native suites cover pure capability policy, bundle reader and immutable admission, alongside expanded bridge/owner/subprocess/lifecycle tests. Applicable ASan/UBSan, iOS Clang analysis, Theos arm64/arm64e build and package/license inspection are required. Linux and macOS Intel fixtures do not run iOS clients. No compatible physical Apple Silicon Mac is accessible for vphone-cli.

Target evidence:iPhone12,5 iOS26.0.1 build23A355, user-reported Dopamine rootless, screenshot-confirmed ElleKit1.2; exact Dopamine version unknown. Actual metadata access, service upgrade restart, new-app client admission/rendering/input and full platform compatibility remain unconfirmed for0.12.0. Historical watchdog causes remain unconfirmed because the original IPS files were not supplied.

## Next indispensable live gate

After successful automation, test the installed selected-app inspection and one window operation; Contacts is a previously untested simple baseline client. The host report must be interpreted together with capability-0.12.0.json:firmware-baseline fallback alone does not prove the new installed-info path. Open the app normally once, return to NewTerm, select it in PPO, observe its small window and try scrolling/navigation without editing records or initiating calls; X/reopen once. A conservative refusal requires the capability diagnostic, not blind policy relaxation. Do not repeat already confirmed ordinary Safari/Reminders gates merely to acknowledge their results.

Recovery:X/default15-second timeout; /var/mobile/.ppo_disable; manual respring for quarantine. Keep deliberately has no timer expiry. If injection prevents startup, start Dopamine without injection and remove only this package. No phone installation/respring, personal data deletion or other-tweak modification is performed automatically. Complete original functionality and full Dopamine/ElleKit compatibility remain unconfirmed.
