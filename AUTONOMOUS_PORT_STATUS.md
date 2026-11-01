# Autonomous port status — 2026-11-01

Current isolated work:0.15.0~dev.favorites1 on debug/favorite-app-picker. It adds up to16 persistent favorite IDs, All/Favorites filtering and long-press quick selection. Production Foundation tickets own asynchronous generations; rows carry exact copied IDs and render generations. Executablec23360fc032479ff1052d50a216eca79d50eda35 passed all25 suites, iOS analysis, pinned Theos rootless arm64/arm64e build and downloaded artifact/package/hash inspection. Delivered candidate:Actions41256552751/artifact13063642671. See VALIDATION_0.15.0.md for evidence, exact digests and actual-device limits. See FAVORITE_APP_PICKER.md.

## Actual preserved baselines

Safari0.14.0 executable020017780f099a4b1a6335797a0d54ded91449c0 is stable/verified-safari-minimize-restore. Actions41251070344/artifact13061840118 passed22 suites and downloaded artifact inspection. The supplied report and explicit user answers cover kept minimization for about39s, same-owner restore with visible/scrollable content, underlying NewTerm input, bar X, reuse and default minimized expiry near15s. Both displayed sessions release their owner/workspace without quarantine. Initial no-source refusal is safe; cached final samples are not post-close readings. This is the0.15.0 fallback.

Safari0.13.0 sourcec86083b77575af887973c195e73b0beff28ccfef remains stable/verified-safari-window-geometry; its actual report covers11 resizes/5 moves/manual reuse. Contacts0.12.0 source6d176ad4bec086cad6a99c72e360d136efa79cff remains stable/verified-contacts-installed-metadata. Reminders0.11.0 source0bb57241e7aeb54a35b434e59f7b24bf844cc7c5 and Safari0.10.0 sourceffe808f00174ac2bca2c3f9ffb64a7ae209e2cef retain their operation-specific stable references. Main remains Alpha4 at af336d84a6b4812e6b6406af87803fb15bf29c3b; earlier baselines/GPL attribution remain unchanged.

Target evidence:iPhone12,5, iOS26.0.1 build23A355, ElleKit1.2; Dopamine rootless is user-reported, exact version unknown. Raw phone reports/app contents are not published. Historical watchdog causes remain unconfirmed because original IPS files were not supplied. Full platform compatibility, nonbaseline clients, complete keyboard/focus behavior and prolonged global cleanup remain unconfirmed.

## Current boundary and next live gate

The private owner/admission/lock/lifetime/helper and package lifecycle implementations are unchanged. Public host UI behavior changes only version/report names. Favorite data is ordered IDs only, separately stored in its own bounded private directory; missing apps remain unavailable/removable and are never automatically pruned. Inventory/favorites never grant application permission. All file work stays off main; no new keyboard/key-window request or automatic launch is introduced.

Automation has passed; test only new star/filter/disk reload/long-press selection with an already working app, then its existing open action. If it fails provide picker-0.15.0.json or the exact UI outcome; host report is host-0.15.0.json. No repeat of the completed0.14.0 min/restore gate is needed. Original feature coverage is in ORIGINAL_FEATURE_PARITY.md. No compatible physical Apple Silicon Mac is accessible for vphone-cli; Linux/macOS Intel CI are not iOS runtime replacements.

Recovery:X/default15-second expiry; /var/mobile/.ppo_disable; manual respring for quarantine. Kept mode intentionally has no timer expiry. If injection prevents startup, start Dopamine without injection and remove only this package. No automatic phone install/respring, personal-record deletion or other-tweak change is performed.
