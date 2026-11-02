# Classic interface and source-independent favorites — RC2

Version1.0.1~rc2 follows the user-confirmed Safari baseline in1.0.0~rc1. It is a test candidate; complete Dopamine/ElleKit compatibility and all-app support remain unconfirmed.

The original reference is c1d3rdev/PullOver-Pro commit4a227b75668929894d7faa5a83ea4bf2ba81edc0, GPL-3.0. The uploaded PullOverPro-main.zip (SHA25644ba7b3ec1fd9b49069aad2c2b2996093bcb1d8c3f6cd7eb8b52fb23ec99e147) matches the seven Alpha4 files on this repository's main ataf336d84a6b4812e6b6406af87803fb15bf29c3b; it is not the original upstream implementation. The upstream source was obtained independently.

Default windowSize3 now uses the original aspect-preserving screen-minus50pt edge panel, without the RC1 toolbar/header/margin. It keeps public wrapper scaling and the existing private child's one-time native frame. The80pt capsule has a50pt edge touch strip and follows the open drawer to the opposite edge. Its X closes the owned window. Tap outside retracts the drawer. Other window-size presets preserve the toolbar, resize/move/minimize/restore features.

Hold the handle for a narrow34pt-row icon column of recent applications or favorites, according to Settings. Rows reverse above the handle when needed; clipped lists can scroll. Slide across an icon and release for an owned window, or drag it to the central target for normal full-screen launch. Double-tap the handle for the full application browser and favorites editor. Cached inventory/selection/favorites restore on a worker after UI creation; cached rows never authorize scene construction. Unknown app icons use a public fallback glyph/initial, rather than an unverified private icon API. Exact original animation/assets/haptics parity is not claimed.

When a scene is cleanly absent, fresh positive installed metadata permits the two firmware-audited +0 class factories described in OWNED_COLD_DEFINITION_AUDIT.md. The existing owner still creates and verifies its own isolated workspace, child definition and proxy binding. Ambiguous/unsupported source results are refused. No extra launcher, foreign-scene mutation, security flag, input injection or foreground workaround was added. Framework identity/ABI, eligibility/freshness, immutable selected ID, lock/data checks, cleanup and quarantine remain enforced. Source-based warm construction remains available.

Cold activation has an8s initial activation/layer deadline; Keep is admitted only after activity and an initial owned-layer observation. A layer observation does not establish visible pixels or input. The grace is a bounded candidate policy, not measured device readiness. The existing15s timed mode and warm2s activation guard remain.

Reports: /var/mobile/Library/Logs/PullOverPro/host-1.0.1.json, capability-1.0.1.json and picker-1.0.1.json. A genuine source-absent run must report preparationMode=fresh-application-identity and sourceSceneProvided=false; a warm success is not cold-start proof.

## Automation and real-device gate

CI runs Clang analysis,30 synthetic/native/pure/subprocess suites, Theos rootless dual-architecture compilation, lifecycle/payload/license checks, and records hashes. These do not run SpringBoard, Apple private frameworks or a real app process. No compatible physical Apple Silicon Mac is accessible for vphone-cli.

Essential device test after a successful candidate build: close PPO's owned window, remove Safari from the app switcher, remain in NewTerm, and open the Safari favorite directly from PPO without opening Safari normally. Check first content, web input/keyboard, then X/reopen and send host-1.0.1.json. The report determines whether the absent-source path actually ran. Confirm the classic handle/column/headerless drawer in the same session. Do not repeat a per-app test matrix. No automatic install/respring/process kill occurs.

Recovery is preserved at stable/verified-rc1-safari-kept-resize-manual (executablef3653171e59fd04cb2ae0c7b70ba28acf4c20fef), permanent release-candidates/1.0.0-rc1, and recovery/0.17.0. Main is untouched. The existing ppo_disable marker and Dopamine launch without tweak injection remain the emergency routes; no new recovery action modifies other tweaks.
