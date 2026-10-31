# Autonomous port status — 2026-10-31

Current isolated work:0.14.0~dev.minimize1 on debug/minimize-owned-window. Public ••• actions add explicit same-window minimize/restore while retaining the positive expanded viewport and original owner/native frame/lifetime. New mode geometry has403376 local sanitizer/assertion checks. Current-source CI/build/artifact inspection is pending. See MINIMIZED_OWNED_WINDOW.md.

## Preserved actual device evidence

Safari0.13.0 executablec86083b77575af887973c195e73b0beff28ccfef is stable/verified-safari-window-geometry. Actions41246925116/artifact13060155969 passed21 suites, iOS analysis, rootless arm64/arm64e build and downloaded package/hash inspection. The subsequent two-session Safari report/user confirmation covers11 resizes,5 moves, kept37.014s/manual close, then timed9.378s/manual close after2.908s reuse. Native presentation frames stay414x896 and captured insets are{44,0,34,0}. Both invalidations return without quarantine. This does not add a0.13.0 default-timeout or lock observation.

Contacts0.12.0 executable6d176ad4bec086cad6a99c72e360d136efa79cff is stable/verified-contacts-installed-metadata. Its report exercises fresh installed-info admission, X/reopen/default timeout and clean teardown. Reminders0.11.0 source0bb57241e7aeb54a35b434e59f7b24bf844cc7c5 remains stable/verified-reminders-window-reuse. Safari0.10.0 sourceffe808f00174ac2bca2c3f9ffb64a7ae209e2cef remains stable/verified-safari-keep-lock-reuse. Earlier picker/launch/rendering/Safari baselines and GPL attribution remain preserved.

Main remains Alpha4 at af336d84a6b4812e6b6406af87803fb15bf29c3b. Target evidence:iPhone12,5 iOS26.0.1 build23A355 and ElleKit1.2; Dopamine rootless is user-reported and its exact version remains unknown. Runtime observations are operation/version-specific. Raw phone reports/app contents are not published. Historical watchdog causes remain unconfirmed because original IPS files were not supplied.

## Current boundary

Private owner/admission/lock/lifetime/helper and package lifecycle implementations remain unchanged. Presentation mode uses a separate44-point bar path and terminal stop. Menu actions are weak/deferred; minimize/restore do not create, detach, reactivate or reauthorize a scene and never reset deadline/heartbeat or imply Keep. A scene that becomes inactive still closes. Native geometry tests cannot prove compositor clipping, retained activation, remote input routing or public menu integration.

All prior native suites plus the new presentation suite, applicable sanitizers, iOS Clang analysis, pinned Theos rootless arm64/arm64e compilation and downloaded payload/hash/license checks are required before delivery. No compatible physical Apple Silicon Mac is accessible for vphone-cli; Linux/macOS Intel CI are not replacements. Original feature coverage remains explicit in ORIGINAL_FEATURE_PARITY.md.

## Next indispensable live gate

After successful automation, only the changed public menu/minimize/restore behavior needs testing. Use one already working app, explicit Keep then minimize, move the bar and wait beyond15seconds; confirm the app underneath responds outside it. Restore/check content, minimize and X. Reopen default mode, minimize without Keep and confirm original timed expiry. Provide host-0.14.0.json. Ordinary app discovery and already confirmed size/navigation tests do not need repeating.

Recovery:X/default15-second expiry; /var/mobile/.ppo_disable; manual respring for quarantine. Kept mode has no timer expiry. If injection prevents startup, start Dopamine without injection and remove only this package. No phone installation/respring, personal data deletion or other-tweak modification is performed automatically. Complete original functionality and full Dopamine/ElleKit compatibility remain unconfirmed.
