# Stability candidate test plan

Version3.0.2~rc1; upstream source076da8f07e707453bc58ed9baadeefb40f0e93e4. Independent GPL derivative preserving c1d3r/Jond_ie attribution and original edge interface. No new window-sizing or multiple-window feature is included.

## Automated checks

- Three C fixtures compiled with AddressSanitizer/UndefinedBehaviorSanitizer: startup generation/deadline/one-launch policy; keyboard overlap/clamping; QuickSwitch viewport/row validity/autoscroll.
- Native Foundation fixtures compile the actual ContextHostManager implementation against fake scene/presenter/service responses: nil presenter/view, exceptions, rollback, reuse, stale/repeated cleanup, unavailable services, launch error propagation, duplicate callbacks and main-thread completion. These fakes do not validate actual private API behavior.
- Actual in-memory preference sanitizer tests invalid types, finite/clamped numeric values, IDs, duplicates and preserved defaults.
- Clang analysis of production translation units and generated Logos code; release Theos rootless package build.
- Embedded-signature fixture: thirteen Python unittest methods plus malformed-structure subcases reject altered code pages, alternate CodeDirectories, Requirements, unsupported hash/bounds/coverage and empty placeholders.
- Package inspection: SpringBoard-only injection, preference bundle/loader resources, GPL/provenance, no maintainer scripts/personal-data paths, arm64 plus modern arm64e ABI, every embedded CodeDirectory/page/special-slot digest and SHA256 of the whole DEB. macOS codesign diagnostics are recorded separately: the upstream ldid fakesign format is not accepted as Apple signing trust, and this check does not establish phone trust.

No UIKit touch/lifecycle test, real SpringBoard hosting, on-phone signature trust, Dopamine/ElleKit compatibility or battery measurement is automated here.

## Installation boundary

Keep the original upstream Jond_ie3.0.1 recovery DEB available before replacing it. Its operation on this exact phone has not been confirmed in the conversation. The candidate upgrades the same package ID; returning to3.0.1 requires an explicit downgrade using the saved DEB or Sileo. Do not run the old custom `com.renatasy83.pulloverpro.diagnostic` alongside it; remove that package manually if still installed. The candidate declares the conflict but does not execute removals. Keep preferences; there is no need to delete them. Install manually with Sileo/Filza, and perform a manual respring only after successful installation.

If SpringBoard stalls: use the already-established Dopamine recovery path (reboot, enable jailbreak without tweak injection), remove/downgrade only this candidate, then restore normal injection. No automatic recovery action is performed by this package.

## One grouped real-device session

1. Open a normally cold/background app from the original handle; close and reopen, switch favorite, and immediately close once after selection. Confirm live content/touch and that the drawer does not reopen by itself. Leave a working window open beyond20seconds: the startup deadline must not close it. Observe normal app recovery after closing.
2. With a keyboard visible, check the handle on both edges. Hide/show keyboard, move handle deliberately once, then hide it: the deliberate position should be retained, no jump across the screen. Confirm the background and hosted app still receive touches normally.
3. With enough favorites to fill the screen, hold/drag near either end to reach the rest; choose an app, cancel a gesture outside the list, and try the full-screen drop target. Check both edge settings. Changing a preference while a launch is pending must not leave an old drawer or timer.
4. If an application cannot supply a window, confirm startup stops within20seconds and shows Try again; closing must remain responsive. There is no need to manufacture an invalid installed-app state to force this case: automated fakes cover the failure paths.

Report only the failing step and visible behavior. No per-app exhaustive test is required. A passing session establishes only the observed apps/device/version scope.
