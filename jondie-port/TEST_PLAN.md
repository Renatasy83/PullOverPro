# PullOver Pro movable-window candidate3.0.2~rc3

Independent c1d3r/Jond_ie GPL-3.0 derivative. User reports RC2 resizing works and requests practical free movement. RC2 remains archived and unchanged for recovery.

## Controls

Shrink with the lower diagonal-arrow grip, then grab the top bar to move the whole window. The full bar/app/grip stays within the safe screen area. X closes. A physical double tap on the top bar resets this app's position; double tap on the lower grip resets its maximum size. Position and size are saved per app when each valid gesture ends. VoiceOver has directional movement/reset and size-adjustment actions.

The new bar reserves30points plus the existing20point bottom grip area. Maximum iPhone11ProMax pane is354.857x768points; native aspect ratio is preserved. Moving/resizing uses owned UIKit transforms, without relaunching or requesting new private scene APIs. The original edge drawer and outside-tap-close behavior remain.

## Automated verification

Ten mandatory suites: prior eight plus actual floating geometry (bounds, normalization, movement, anchored resize, invalid inputs) and actual Foundation position store (independent apps, preserved size/global/unknown metadata, malformed data, reset/reopen/concurrent saves). ASan/UBSan where applicable. Production Clang analysis, rootless Theos release, complete payload/filter/preferences/GPL resources, modern-arm64e ABI and embedded CodeDirectory/page/special-slot hashes remain mandatory. macOS codesign is recorded separately; internal hash consistency is not Apple/device trust. Failed inspections remain quarantined and never become candidate uploads.

## Single grouped real-device gate

1. From another app such as NewTerm, open a favorite, shrink it and drag the top bar horizontally/vertically to several corners. Check the drawer does not page instead and the complete controls remain reachable; repeat once with the opposite edge setting. Verify a button/link, scrolling and typing after moving/resizing.
2. Give two apps distinct positions/sizes, close/reopen each and check independent restoration. Double tap the bar to reset position; double tap the lower grip to reset size. X must close; reopen and verify normal content.
3. With a chosen moved position/size, perform one manual respring and confirm persistence. No exhaustive per-app tests or induced crashes are required.

## Installation and recovery

Install manually via Filza/Sileo, then respring after success. Same package ID upgrades RC2; preserve preferences. If the old diagnostic package is still present, remove that package manually before installing; do not run both.

Keep RC2 from archive dd5e7e3ec5dd73231d65dd9e7fae18614ee8b865, SHA25659bf2fc4426c4ed78b28654af622574fc385d50c219d61d96998f9e3582fd5e4. Revert by manual downgrade. If SpringBoard stalls: reboot, Dopamine without injection, then remove/downgrade only the candidate. No automatic phone action, process termination or personal-data deletion is performed. RC2 ignores windowPositionsV1.
