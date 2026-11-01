# Validation — 0.15.0~dev.favorites1

Executable:c23360fc032479ff1052d50a216eca79d50eda35 on debug/favorite-app-picker.

[Successful Actions run41256552751](https://github.com/Renatasy83/PullOverPro/actions/runs/41256552751) · [artifact13063642671](https://github.com/Renatasy83/PullOverPro/actions/runs/41256552751/artifacts/13063642671).

The artifact contains exactly one verified DEB plus machine/human validation reports, test/analysis/build/dependency/UUID logs, checksums and symbols. This is a controlled changed-feature candidate. Real iOS favorites sandbox/UI behavior, complete original functionality and general Dopamine/ElleKit compatibility remain unconfirmed.

## Concrete behavior

Up to16 ordered favorites can be added/removed with a separate44-point star target, viewed in Toate/★ Preferate, and selected through a long press on the PPO handle. Every app row carries copied exact identity and a render generation. Selection and launching remain separate explicit actions; a favorite never grants private permission or replaces an active window. Names resolve from current inventory; unavailable favorites remain visible/removable and are never silently pruned by failed/partial/empty inventory.

The production Foundation coordinator owns immutable operation tickets, coalesced loads, latest requested filter/visibility and target/favorite generations. Stale or foreign completions cannot roll back a newer choice. Pending selection writes also prevent a load from restoring an older disk target after that write completes. Uncertain opener outcomes continue to block further normal launches for the process, as in the preceding implementation; selection changes do not retry unknown OS requests.

A separate own schema1 plist stores only exact IDs, at most16KiB, under /var/mobile/Library/Preferences/com.renatasy83.pulloverpro.diagnostic.favorites/. Worker-only I/O uses same-UID0700/0600 modes, no-follow/nonblocking regular-file reads, inode/version bounds, nonblocking directory locking, expected-state comparison and atomic own-temp replacement. Corruption/errors preserve data and disable writes until a valid reload. Noncooperating external editors can still race the final compare/rename; this is not authenticated CAS. Other preferences/tweaks are untouched.

Private owner/admission/lock/lifetime/helper and package lifecycle source is unchanged. The host UI implementation differs from0.14.0 only in version/report strings, verified by exact source comparison after normalizing those strings. No keyboard/key-window request or private API is added. The local build helper now reads the actual control Version instead of searching for obsolete0.7.0 artifacts. See FAVORITE_APP_PICKER.md.

## Executed and passed

- All25 automated suites. New favorites codec/projection268, isolated filesystem store264 and production picker state94 checks passed with applicable ASan/UBSan native fixtures.
- Favorites cases include exact keys/genuine numeric schema,16/17 IDs and16KiB bounds, copy independence, current names, exact identities and unavailable non-pruned entries. Store cases cover worker-only zero-main-I/O, mode/owner/link/size restrictions, corrupt data preservation, symlink/FIFO/hardlink failures, immutable reopened snapshots, expected conflicts, nonblocking lock contention, concurrent writers and own-temp cleanup. Coordinator cases cover stale/replayed/foreign tickets, latest selection, old failures, pending-save/load races, coalesced close/reopen, missing/corrupt favorites, full-limit removal and mutable input independence.
- Existing floating presentation403376, floating geometry108812, aspect-fit1027, ownership825, lock175, lifetime410, metadata655, bundle reader175, admission80, presenter342, visibility613, layers229, session slot229, IO365, subprocess71, lifecycle46 and app-data/launch/protocol/service/scene-selection suites passed. Fixtures do not execute real iOS clients.
- iOS Clang analysis of the tweak, new data/store/coordinator, existing helpers/owner/UI/metadata/lock/session modules. Pinned Theos rootless arm64/arm64e build with SDK16.5/deployment15.0.
- Binary architecture/dependency/UUID and rootless payload/service/lifecycle/dependency/GPL attribution/license inspection. Packaged binaries contain no test mailbox overrides. Local source policy, lifecycle46, Python/Bash syntax checks and downloaded actual DEB rootless/lifecycle/license checks passed.
- Artifact ZIP digest matches GitHub metadata. Exactly one DEB is present and its digest matches diagnostics/SHA256SUMS. VALIDATION.json identifies this source and25 successful logs, final_candidate=false and dopamine_ellekit_compatibility_confirmed=false.
- Remote refs preserve main at af336d84a6b4812e6b6406af87803fb15bf29c3b, Safari minimize stable020017780f099a4b1a6335797a0d54ded91449c0 and Safari geometry stablec86083b77575af887973c195e73b0beff28ccfef. Explicit base-tree comparison preserves existing source and executable script modes outside the selected change set.

Two intermediate CI runs rejected new fixtures:an Apple Boolean typedef collision, then reliance on concrete Foundation mutable-class tests. They were corrected before this delivered source passed. The final native trace establishes independent=yes while immutable __NSCFString also reports mutable-class-test=yes; tests now check preserved values after caller mutation and later file replacement instead of class-cluster internals. No private behavior was changed to pass those fixtures. Existing obsolete -multiply_defined linker-option warnings did not prevent success.

Package:packages/com.renatasy83.pulloverpro.diagnostic_0.15.0~dev.favorites1_iphoneos-arm64.deb

DEB SHA256:a535f26d0a48898901ab2c192529e848bf7ab0daabe1b3fb757900b657c728cc

Artifact ZIP SHA256:9d04af81de0f8c4a77ec6e82c84d6b5e045f541e99a1cee5bc859eaf84b3f0ab

## Preserved actual device baseline

0.14.0 Safari gate is complete. Its report has a safe no-source refusal, then a kept86.291s session with2 minimizes/1 restore/manual bar X, followed by a timed session expiring at15.076s. Viewport300x436/native414x896 and verified owner remain across transitions; cleanup returns without quarantine. The user explicitly confirms restored content/scrolling and underlying NewTerm input outside the bar. Stable source020017780f099a4b1a6335797a0d54ded91449c0 and [artifact13061840118](https://github.com/Renatasy83/PullOverPro/actions/runs/41251070344/artifacts/13061840118) are the fallback. Other operation-specific Safari/Contacts/Reminders baselines remain preserved. See DEVICE_VALIDATION.md for cached-sample and untested-client limits.

## Not executed in this environment

- Actual0.15.0 installation and SpringBoard sandbox access to the new own favorites directory.
- Real UIKit star/filter/long-press/tap-vs-drag behavior, disk reload through the visible picker, theme/scroll layout and end-to-end selected favorite opening on iOS.
- Actual phone compilation with the local helper; only its shell syntax/version selection logic was inspected here.
- New-version lock/orientation/process death/watchdog stress, indefinite/global process/client/session cleanup or complete keyboard/focus adaptation.
- Nonbaseline/complex/single-scene apps, drag/drop/exact edge-drawer/auto-nub parity, complete preferences and simultaneous windows.
- General Dopamine/ElleKit compatibility. Exact Dopamine version remains unknown; prior observations are operation/version-specific.
- vphone-cli:no compatible physical Apple Silicon Mac is accessible. Linux/macOS Intel CI cannot replace iOS runtime.

## Minimal indispensable phone gate

Install the verified single DEB manually and respring. Star Safari or another already working app in Toate, switch to ★ Preferate, then close the picker and long-press the PPO handle. Confirm the stored favorite reappears after the fresh disk load. Select it and use the existing Deschide în fereastră action, then close with X. Remove the star from Favorites and confirm that this only removes that favorite. No extra respring, keyboard, new-app compatibility or repeat of min/restore tests is required.

Provide the outcome and, if needed, /var/mobile/Library/Logs/PullOverPro/picker-0.15.0.json. It contains only operation/count/readability/error category/code, no favorite IDs/names; no raw favorites plist is requested. If the separate window-opening path fails, host-0.15.0.json remains the lifecycle report.

Recovery:X/default15-second expiry; /var/mobile/.ppo_disable; manual respring for uncertain pinned cleanup. Keep intentionally has no timer expiry. If injection prevents startup, start Dopamine without injection and remove only this package. The tested0.14.0 fallback remains available. No automatic installation/respring, personal-record deletion or other-tweak change is performed. Raw phone reports/app contents are not published.
