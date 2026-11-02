# Classic interface and direct favorites — RC2

Version **1.0.1~rc2** follows the user-confirmed Safari baseline in **1.0.0~rc1**. It is a test candidate. Complete Dopamine/ElleKit compatibility and support for every application remain unconfirmed.

The original reference is GPL-3.0 `c1d3rdev/PullOver-Pro` at `4a227b75668929894d7faa5a83ea4bf2ba81edc0`. The uploaded `PullOverPro-main.zip` matches the seven Alpha 4 files on this repository's `main` at `af336d84a6b4812e6b6406af87803fb15bf29c3b`; it is not the upstream implementation. The upstream source was obtained independently. Uploaded ZIP SHA256: `44ba7b3ec1fd9b49069aad2c2b2996093bcb1d8c3f6cd7eb8b52fb23ec99e147`.

## Interface

Default `windowSize=3` now uses the original aspect-preserving screen-minus-50-point edge panel, without RC1's toolbar, header or additional margin. The public wrapper scales the child; its native frame is still assigned once before containment. The 80-point capsule has a 50-point edge touch strip and follows the open drawer to the opposite edge. Its X closes the owned window. Tapping outside retracts the drawer. Other window-size presets preserve toolbar, resize, move, minimize and restore.

Hold the handle for a narrow column of recent applications or favorites, according to Settings. Rows have a 34-point pitch and reverse above the handle when necessary; clipped lists scroll. Slide across a row and release for an owned window, or drag it into the central target for normal full-screen launch. Double-tap the handle for the complete browser/favorites editor. A refresh cannot replace a row under a held finger: a changed projection cancels selection.

Cached inventory, selection and favorites restore on a worker after UI creation. Cached rows never authorize scene construction. Known applications use public system symbols; other rows use initials. Recent history contains PPO selections, not the system-wide switcher history. Exact original app-icon assets, animations, external-keyboard handling and multiple simultaneous windows are not included.

## Source-independent construction

When a source scene is cleanly absent, fresh positive installed metadata permits the two audited +0 class factories in [OWNED_COLD_DEFINITION_AUDIT.md](OWNED_COLD_DEFINITION_AUDIT.md). Existing owned activation handles the internal process-launch path documented in [COLD_ACTIVATION_TRACE.md](COLD_ACTIVATION_TRACE.md). These static traces do not establish runtime admission or rendering.

The owner still verifies its fresh isolated workspace, child definition, normal specification, selected ID and proxy binding. Ambiguous or unsupported source results are refused. Framework identity/ABI, short-lived eligibility, immutable selection, lock/data checks, cleanup and quarantine remain enforced. No extra launcher, foreign-scene mutation, guessed security/focus flag or input injection was added. Warm construction remains available.

Cold activation has an 8-second initial activity/layer deadline. Layer inspection waits for sampled owned-scene activity; unsupported active objects stop the probe. Keep is admitted only after activity and an initial owned-layer observation. A layer observation does not prove pixels or input. This bounded grace is candidate policy, not measured device readiness. Timed mode remains 15 seconds; warm activation grace remains 2 seconds. These main-queue deadlines cannot interrupt a blocked private call and do not rule out a watchdog failure.

Reports are in `/var/mobile/Library/Logs/PullOverPro/`: `host-1.0.1.json`, `capability-1.0.1.json` and `picker-1.0.1.json`. A genuine absent-source run must record `preparationMode=fresh-application-identity` and `sourceSceneProvided=false`. Warm success is not cold-start proof.

## Automation and necessary device check

CI runs Clang analysis, 30 automated suites, pinned Theos rootless compilation for arm64/arm64e, lifecycle/payload/license checks and hashing. These use synthetic Foundation classes, pure policies and an actual subprocess with a fake workspace. They do not run SpringBoard or Apple private iOS frameworks. No compatible physical Apple Silicon Mac is accessible for vphone-cli.

After a successful candidate build, manually close PPO's owned window, remove Safari from the iOS app switcher, stay in NewTerm, and open the Safari favorite from PPO without opening Safari normally. Check content, web input/keyboard, then X/reopen; send `host-1.0.1.json`. Confirm the classic handle, compact column and headerless drawer in the same session. This requires no per-application test matrix. No automatic phone install, respring or process kill occurs.

RC1 recovery is preserved at `stable/verified-rc1-safari-kept-resize-manual` (executable `f3653171e59fd04cb2ae0c7b70ba28acf4c20fef`) and permanent archive `release-candidates/1.0.0-rc1`. The older `recovery/0.17.0` package also remains. Main is untouched. The existing `/var/mobile/.ppo_disable` marker plus manual respring, or Dopamine startup without tweak injection followed by uninstalling only PPO, remain recovery routes. No other tweak or personal data is modified.
