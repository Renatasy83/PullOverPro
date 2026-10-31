# Validation — 0.14.0~dev.minimize1

Executable:020017780f099a4b1a6335797a0d54ded91449c0 on debug/minimize-owned-window.

[Successful Actions run41251070344](https://github.com/Renatasy83/PullOverPro/actions/runs/41251070344) · [artifact13061840118](https://github.com/Renatasy83/PullOverPro/actions/runs/41251070344/artifacts/13061840118).

The downloaded artifact contains exactly one verified DEB and the generated human/machine validation reports, test/analysis/build/dependency/UUID logs, checksums and symbols. It is a controlled real-device-gate candidate. Complete original functionality and full Dopamine/ElleKit compatibility remain unconfirmed.

## Concrete behavior

The public ••• menu offers explicit Păstrează and Minimizează. Minimize collapses the same UIWindow/root to a44-point bar with title/drag, ▢ Restore and X. It preserves the positive expanded viewport, wrapper transform, native child frame, containment, visibility flags and owned scene. The window's existing clipping conceals the application content. Restore uses saved dimensions/preset at the bar's current origin, clamped within the captured usable scene. A separate bar geometry path avoids the320-point minimum of normal expanded layout. No private operation or logical scene geometry setter is added.

Actions require healthy existing lifetime/state; minimize also requires observed activation. Minimize/restore do not create a scene, reauthorize old metadata, detach a view, call Keep implicitly or restart the timer/heartbeat. The original15-second deadline applies until explicit Keep. Existing inactivity, lock, data, host and size-change closure remain. If clipping inactivates the scene, the policy closes. No input-blocking guarantee follows from a UIView flag; actual clipping and input outside the bar must be observed.

Only public UI/header/menu, the new pure mode policy, version/description and associated tests/docs change. Private owner/admission/lock/lifetime/helper implementations and package lifecycle scripts are unchanged. More/menu actions capture weakly and defer outside the UIAction callback stack; confirmed cleanup clears all own controls. See MINIMIZED_OWNED_WINDOW.md.

## Automated evidence

Executed and passed for the exact source above:

- All22 automated suites. New presentation policy403376 checks passed in CI and locally with C++17, -Wall/-Wextra/-Werror and ASan/UBSan; local -pedantic and libstdc++ assertions also passed. They cover44-point bars, malformed/current-width/finite bounds, atomic rejected/duplicate transitions, all presets,12000 mixed cycles, terminal stop, positive viewport/native fit, unchanged exact15-second expiry and kept lock/inactivity closure.
- Existing floating geometry108812, native aspect-fit geometry1027, lifetime410, ownership825, lock175, metadata655, bundle reader175, admission80, presenter342, visibility613, layers229, session-slot229, IO365, subprocess71, lifecycle46 and app-data/launch/protocol/service/scene-selection suites passed. Applicable native sanitizer fixtures passed.
- iOS Clang static analysis, including the public menu/minimized presentation adapter, tweak, helpers, owner/admission/metadata, lock and session modules.
- Pinned Theos rootless arm64/arm64e build with SDK16.5/deployment15.0; binary architecture/dependency/UUID inspection, payload/service/lifecycle/dependency/GPL attribution/license checks and absence of test mailbox overrides in release binaries.
- Local source policy, Python lifecycle46, Python/Bash syntax checks and independent downloaded actual DEB rootless/lifecycle/license inspection.
- Artifact ZIP digest matches GitHub metadata; the single DEB digest matches diagnostics/SHA256SUMS. VALIDATION.json identifies this exact source,22 successful logs, final_candidate=false and dopamine_ellekit_compatibility_confirmed=false.
- Fresh remote refs preserve main at af336d84a6b4812e6b6406af87803fb15bf29c3b, Safari geometry stablec86083b77575af887973c195e73b0beff28ccfef and Contacts installed metadata stable6d176ad4bec086cad6a99c72e360d136efa79cff. Explicit-tree comparison preserved private owner/admission/lock/lifetime/helper source and package lifecycle scripts/modes.

Existing obsolete -multiply_defined linker-option warnings did not prevent success. Native private-class/workspace fixtures do not execute real iOS clients or UIKit context menus.

Package:packages/com.renatasy83.pulloverpro.diagnostic_0.14.0~dev.minimize1_iphoneos-arm64.deb

DEB SHA256:0b83def3259bdcde0caa10cabecd0d766110d117f939d5d267dbecd177e72000

Artifact ZIP SHA256:a4b21ec93d2f2905857ca1aff24900d69c0df0b6823a8a8f1ca1a3c4f4df226d

Independent design and implementation review found no concrete UIKit/lifecycle/retain blocker. Public UIAction/UIMenu APIs support deployment15.0. Native fixtures cannot exercise actual UIKit context-menu presentation, occlusion/activation, compositor clipping, remote input or resource teardown.

## Preserved actual phone baseline

0.13.0 sourcec86083b77575af887973c195e73b0beff28ccfef is stable/verified-safari-window-geometry. [Artifact13060155969](https://github.com/Renatasy83/PullOverPro/actions/runs/41246925116/artifacts/13060155969) remains the fallback. The user's two-session report confirms requested function with11 resizes,5 moves, kept37.014s/manual closure then timed9.378s/manual closure after2.908s reuse, matching four framework UUIDs, unchanged414x896 native frames, clean owned teardown and no quarantine. It does not include a0.13.0 timeout/lock observation. Contacts0.12.0, Reminders0.11.0 and Safari0.10.0 baselines remain preserved separately. See DEVICE_VALIDATION.md.

## Not executed here

- Actual0.14.0 package installation and public menu presentation inside SpringBoard.
- Real compositor clipping of app content below the44-point bar, retained scene activity while minimized, input delivery to the app underneath and restoration of visible/interactable content without client recreation.
- Actual minimized Keep beyond15seconds, default expiry, bar X, repeat/reopen and private scene/workspace cleanup for this exact executable.
- New-version lock/orientation/process-death/watchdog integration, zero lock-transition exposure and prolonged global client/session/resource cleanup.
- Nonbaseline dynamic clients, complex/single-scene apps, favorites/quick-switch, auto-nub/edge-drawer parity, full keyboard adaptation or simultaneous windows.
- Full Dopamine/ElleKit compatibility. Prior phone observations are version/operation-specific; exact Dopamine version is unknown.
- vphone-cli: no compatible physical Apple Silicon Mac is accessible; Linux/macOS Intel CI cannot substitute for iOS runtime.

## Minimal combined actual-phone gate after successful automation

Install the verified single DEB manually and respring. Use one already working app, preferably Safari. Open its PPO window, choose ••• > Păstrează then ••• > Minimizează. Move the bar, wait20seconds and confirm the underlying app responds outside the bar. Restore with ▢ and check the same content/scrolling. Minimize again and close with X.

Reopen in default mode, minimize without choosing Păstrează and confirm automatic close by the original15-second deadline from opening. Provide /var/mobile/Library/Logs/PullOverPro/host-0.14.0.json and whether content/underlying input behaved correctly. The report checks mode transitions, counters, saved frame, actual positive viewport/native/wrapper geometry, same owner/proxy and terminal cleanup. savedExpandedFrame is historical:zero before first minimize, then last successful min/restore snapshot; it does not track every expanded move/resize or prove post-close state.

Recovery:X/default15-second expiry; /var/mobile/.ppo_disable; manual respring for pinned quarantine. Kept mode intentionally has no timed expiry. If injection prevents startup, start Dopamine without injection and remove only this package. Tested0.13.0 remains available. Main/all tested branches remain untouched. No automatic phone install/respring, personal-record edit/deletion or other-tweak modification is performed. Raw phone reports/content are not published.
