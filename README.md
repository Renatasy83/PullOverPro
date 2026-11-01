# PullOver Pro port development

This is an incomplete GPL-3.0 port of c1d3rdev/Will Smillie’s PullOver Pro. Main preserves Alpha4, with earlier operation-specific stable sources retained separately.

Current isolated work is0.16.0~dev.programmatic1 on debug/app-client-configuration. Metadata policyv2 adds one explicit true multiscene manifest shape without static configurations. UIKit/app code chooses the actual configuration; PPO adds no private runtime dispatch, guessed configuration override or firmware-baseline bypass. Calendar/Preview are candidates, not runtime-confirmed clients. Explicit single-scene and complex policy shapes remain excluded.

Sourceac825acfe64f4d740a9158417d9b7b6fb4817006 passed all25 suites, iOS analysis, pinned Theos rootless arm64/arm64e build and downloaded package/hash inspection. Actual new-client admission/rendering/input/cleanup still requires the phone. Linux/macOS Intel CI are not iOS runtime substitutes; no compatible physical Apple Silicon Mac is accessible for vphone-cli.

Actual prior observations include Safari hosted/navigation/size/Keep/lock/minimize/restore/underlying-input/expiry operations on their stated versions, Reminders/Contacts window reuse, and0.15.0 own-store read plus long-press visibility for one unspecified favorite. Separate favorite selection/removal, complete keyboard/focus, all app clients, original parity, prolonged global cleanup and general Dopamine/ElleKit compatibility remain unconfirmed.

[Current status](AUTONOMOUS_PORT_STATUS.md) · [0.16.0 validation/package](VALIDATION_0.16.0.md) · [Programmatic scene evidence](PROGRAMMATIC_SCENES_23A355.md) · [Single-scene broker limits](SINGLE_SCENE_BROKER_AUDIT_23A355.md) · [Actual device evidence](DEVICE_VALIDATION.md) · [Original feature coverage](ORIGINAL_FEATURE_PARITY.md).

Nothing installs/resprings the phone, edits personal records or modifies other tweaks automatically. The versioned report contains the minimal changed-client test, recovery and preserved fallback sources. Older guides describe their historical versions.
