# PullOver Pro window-size candidate3.0.2~rc2

Independent GPL-3.0 derivative of c1d3r/Jond_ie, preserving original attribution and drawer interface. RC1 is retained unchanged as the user-reported working recovery package.

## Automated checks

The full macOS workflow must pass all eight fixture runners: previous startup/keyboard/QuickSwitch/preferences/real-manager-fakes/embedded-signature fixtures, plus actual window geometry and actual Foundation size-store fixtures. New fixtures cover aspect/safe-area/grip bounds, exact baseline size, clamped total-delta pan projection, invalid values, independent applications, non-destructive reads, reset, reopened defaults and concurrent sibling updates. Fixtures do not execute UIKit gestures or prove iOS respring persistence.

Production Clang analysis, rootless Theos release build, exact package/filter/preferences/GPL paths, both arm64/modern-arm64e ABI and every embedded CodeDirectory/page/special-slot hash remain mandatory. macOS codesign diagnostics are retained separately and do not establish Apple or device trust. Failed package inspections retain quarantine evidence and never publish a candidate artifact.

## User controls

Drag the small diagonal-arrow grip below the app to resize between55percent and100percent of its largest pane, keeping proportions. A physical double tap restores only this app's size. With VoiceOver, use increment/decrement and the Restore original size action. The default app size on iPhone11ProMax is unchanged. App touches remain inside the native hosted canvas; resizing adjusts the owned wrapper only and keeps its scene active.

## One grouped phone gate

1. From another app such as NewTerm, open appA in PPO. Drag its grip smaller/larger; verify scrolling and a button/link still respond at smaller size. Check the grip does not page/close the drawer. Repeat the grip once with the opposite edge setting.
2. Give appA a small size and appB a different size; return to each and confirm independent restoration. Double tap appA's grip: only appA should return to original size. Cancel an unfinished resize by closing: reopening should restore the last completed size.
3. After choosing a non-default size, perform one manual respring and reopen that app; confirm the size persists. No exhaustive per-app checks or extra crash simulations are required.

## Installation and recovery

Install manually using Sileo/Filza and respring after successful installation. Same package ID upgrades RC1 and keeps preferences. Do not run the old `com.renatasy83.pulloverpro.diagnostic` simultaneously; remove that package manually only if present, keeping preferences.

Keep the saved RC1 DEB available: SHA256 b3f8fc9a946ea4d87a7c0a8bd5649ab8deef54b6fe05c026f6e2ab2b3bb9b50d, archive6c3fdc2fe19b09d1fa5d11a5be9f0aec095fb463. Return by manual downgrade if needed. If SpringBoard stalls: reboot, Dopamine without tweak injection, then remove/downgrade only this candidate. No installer scripts, automatic phone actions or personal-data deletion are performed.
