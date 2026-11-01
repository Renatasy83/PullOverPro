# Original-style interface —1.0.0 RC1

Version `1.0.0~rc1` on `debug/original-interface-rc` brings the main PullOver Pro edge-drawer flow and Settings controls to the existing owned-scene port. It is the closest implemented candidate, not a claim of complete original parity or general Dopamine/ElleKit compatibility. Exact source/build/package evidence belongs in [VALIDATION_1.0.0_RC1.md](VALIDATION_1.0.0_RC1.md). The new interface, full-scene remote input and Settings integration still require actual device validation after automation.

## Edge drawer and application choice

The handle is an80-point blurred capsule clipped by a50-point edge strip, with default34-point height. Choose Stânga or Dreapta in Settings. Drag the handle vertically to reposition it; tap or drag inward to reveal the selected application's owned panel, and drag outward to hide that panel. Sliding changes only PPO's public panel transform: the private native app view retains its frame and the owned scene is not recreated on every gesture. X closes the owned window through the existing cleanup path.

Hold the handle for0.3 seconds to open the configured Recente or Favorite chooser. Drag over a row for enlargement/haptic feedback and release to select, or tap a row normally. The Toate view exposes the installed inventory. A row's long-press menu can request normal full-screen launch through the existing mobile bridge. To use the original-style drop action, hold a choice, pull it out of the list (or at least44 points horizontally), then release the badge over the central100x100 dashed target. Releasing elsewhere or cancelling does not launch it. Stars manage favorites in PPO; the same ordered store is editable from Settings.

Recente contains only applications selected in PPO, persisted with a maximum of16 identifiers. It does not read SpringBoard's OS-wide app switcher. Public system symbols represent app categories or a generic app; original private icon generation is not used. The central drag/drop action is implemented with public UIKit and the existing launch bridge; exact original iconography and every old transition detail are not reproduced.

## Settings page and preference timing

The package adds **Configurări → PullOver Pro** through PreferenceLoader. Its bundle is named `PullOverProPortPreferences`, distinct from the upstream bundle, and uses the exact23A355-audited `PSViewController` superclass with an own public UIKit table. PreferenceLoader is a package dependency; use Sileo to resolve it if it is not already installed.

Sixteen editable controls are grouped as follows:

| Group | Controls |
| --- | --- |
| General | Activează PullOver Pro; Marginea ecranului; Aspect; Ascunde în modul peisaj; Feedback haptic |
| Comutator de aplicații | Recente/Favorite mode; recent count1–16; enlargement1–3; drag instructions; favorite add/remove/reorder editor |
| Mâner lateral | Remember position; automatic nub; delay1–30s; height32–72pt; opacity20–100% |
| Ferestre | Sertar/Mică/Standard/Mare initial preset; keep window open |

Automatic nubbing starts after the drawer closes and stays inactive during a gesture; turning it off reveals the full handle. With position remembering off, the initial position is centered and later temporary movement stays in memory without changing the stored position. The handle updates without a respring. Disabling PPO hides its interface and closes the own window; changing edge closes the active window so the handle and host cannot disagree about the side. Appearance, initial size and persistence are frozen for an active window and take effect on its next opening. X/reopen is sufficient; turning Keep off does not retroactively restart an already kept window's timer.

The default **Sertar** preset preserves native content aspect beneath a44-point header within safe margins, using space close to the original50-point edge strip. The three prior bounded presets remain available. In the pure geometry fixture for414x896 with insets{44,0,34,0}, the panel is approximately350.24x802; this is an expected calculation, not an RC phone measurement. The default window stays open until closed or stopped by an existing lifecycle guard. Turn **Păstrează fereastra deschisă** off for the approximate15-second timed mode on the next opening. Keep never removes lock/protected-data/scene/disable checks.

The dedicated settings domain is `com.renatasy83.pulloverpro.settings`:17 presentation settings plus the internal bounded recent-ID cache. Vertical position and recent IDs have no direct editor. Writes update only validated changed keys. Existing selected-app and favorites data remain in their own locations; the original `com.c1d3r.PullOverPro` domain is not migrated or cleared.

## Favorites editor

The Settings editor reads the existing bounded inventory cache and favorite store on a worker queue. Add/remove/reorder is limited to16 favorite IDs and uses the same expected-state CAS commit/readback as the picker. Missing apps remain visible/removable; read errors never prune favorites. Editing is disabled while storage state is unknown or a save is pending.

If the inventory cache cannot be read, open PPO's application list once and reload the editor. Its access from the actual Settings sandbox has not been established by desktop fixtures. Failures preserve stored data and display a message; they do not justify bypassing permissions or overwriting the store. No AppList dependency, new private app API or personal-document edit is added.

## Preserved runtime and safety boundaries

The core private owner, admission, helper protocol, lock reader and lifetime implementations retain their existing guards. Nonbaseline clients still require fresh eligible installed metadata, exact source/child specification and role, independent identity/proxy/namespace proof and explicit owned cleanup. One session can be replaced only after cleanup is confirmed. Explicit no-multiple-scene and unreviewed complex clients remain excluded; Files working on0.17.0 is not proof that every app works.

The new public windows do not request key-window ownership or introduce private input/focus calls. Passthrough and animation behavior, remote touch/keyboard delivery, Settings discovery and Settings storage access are actual OS outcomes. Pure fixtures cannot establish them. Cached telemetry also cannot prove zero-frame lock exposure, post-teardown resource release or indefinite leak freedom.

In RC diagnostics, `geometry.windowFrame` describes the full-scene transparent window. `panelBaseFrame` is the untransformed app panel; `panelTransform` and `drawerProgress` describe its slide. A window that remains visible with progress0 does not mean the app panel is onscreen. The sampled native frame remains a separate field; these new field meanings must not be compared directly with older small-window `windowFrame` values.

No automatic phone installation/respring, personal-record edit/deletion or other-tweak change is performed. The emergency `/var/mobile/.ppo_disable` marker has priority; the old `.ppo_enable_overlay` opt-in is no longer required for this enabled-by-default candidate.

## One combined new-interface device gate

After the exact-source automated build and downloaded-DEB verification pass, manually install the single RC package and respring. In one session:

1. Verify Configurări → PullOver Pro appears, select the preferred edge, and confirm the handle follows it. Check the favorite editor can show the preserved favorites; make only an intended own-favorite change if needed.
2. Use a previously working app such as Safari or Files. Open it normally once, return to NewTerm, select it through PPO and check visible content/scrolling in the edge drawer. Slide out/in and verify the other app can still receive touches where PPO does not handle them.
3. Close with X and reopen once. With default persistent mode, check it remains past15 seconds, then lock/unlock and confirm the owned window closes. Turning PPO off in Settings should hide it without a respring.
4. Supply `host-1.0.0.json` from `/var/mobile/Library/Logs/PullOverPro`, plus the exact displayed error if Settings or the drawer cannot work. If admission refuses before hosting, use `capability-1.0.0.json` instead.

This gate concerns the new interface/integration, not every installed application or a repeat of ordinary0.17.0 tests. Avoid opening, editing or deleting personal records/documents merely to test the interface.

## Permanent fallback and recovery

The user-confirmed0.17.0 source is preserved at `stable/verified-files-named-config-reuse`, source `ad6ece8c6cbde196cc4be1ee0b2910cd9c832134`. The previous package is archived independently of Actions retention on `recovery/0.17.0`, commit `a5c6ac9bcd6d188b9fb2b5d6032ff84cd0911920`.

[Download the preserved0.17.0 DEB](https://raw.githubusercontent.com/Renatasy83/PullOverPro/a5c6ac9bcd6d188b9fb2b5d6032ff84cd0911920/recovery/0.17.0/com.renatasy83.pulloverpro.diagnostic_0.17.0~dev.namedconfigs1_iphoneos-arm64.deb)

SHA256: `0e2d6a5792167e29d3eec58f843b3fc121efb93b51c20a0bf70703c530010bda`.

Use X or Settings Off first. The RC default is persistent, so waiting15 seconds is not a recovery method unless timed mode was selected before opening. If needed, create `/var/mobile/.ppo_disable` and respring manually. For pinned uncertain resources a manual respring remains the recovery path. If injection prevents startup, start Dopamine without tweak injection and remove only PPO or manually return to the archived PPO package. Existing favorite/selection files are not deleted by the package's lifecycle scripts.

The port retains GPL-3.0 attribution and full license. Original UI source reference: `c1d3rdev/PullOver-Pro` at `4a227b75668929894d7faa5a83ea4bf2ba81edc0`. No original unsafe KVC foreground writes, guessed Home/orientation hooks, private system recents or iOS13-only external-keyboard scene-stack code is enabled to imitate parity.
