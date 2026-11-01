# PullOver Pro port development

This is an incomplete GPL-3.0 port of c1d3rdev/Will Smillie’s PullOver Pro. Main preserves Alpha4; operation-specific stable sources are retained separately.

Current isolated work is0.17.0~dev.namedconfigs1 on debug/named-application-configurations. Advisory policyv3 adds bounded lists of2–8 named normal application configurations. UIKit/app code selects the configuration. PPO adds no private dispatch, configuration override or baseline bypass. Explicit single-scene clients and other unreviewed shapes remain excluded.

Calendar0.16.0 is now device-confirmed through the programmatic admission reason, with kept/minimize/restore/resize/manual/default-timeout operations and clean recorded ownership teardown. Sourceac825acfe64f4d740a9158417d9b7b6fb4817006 is preserved as stable/verified-calendar-programmatic-reuse. Safari, Reminders, Contacts and favorite read/long-press observations retain their stated version/operation limits.

The0.17 executable is ad6ece8c6cbde196cc4be1ee0b2910cd9c832134. It passed all25 automated suites, iOS analysis, the pinned Theos rootless build and downloaded package/hash inspection; exact evidence is recorded in the versioned validation report. Multiple-named clients still require one representative real-device gate, preferably Files. This is not a request to test every app. Linux/macOS Intel CI cannot run actual iOS clients; no compatible physical Apple Silicon Mac is accessible for vphone-cli. Complete original parity and general Dopamine/ElleKit compatibility remain unconfirmed.

[Current status](AUTONOMOUS_PORT_STATUS.md) · [0.17.0 validation/package](VALIDATION_0.17.0.md) · [Named configuration audit](NAMED_APP_CONFIGURATIONS_23A355.md) · [0.16.0 actual evidence](VALIDATION_0.16.0.md) · [Single-scene broker limits](SINGLE_SCENE_BROKER_AUDIT_23A355.md) · [Device evidence](DEVICE_VALIDATION.md) · [Original feature coverage](ORIGINAL_FEATURE_PARITY.md).

Nothing installs/resprings the phone, edits personal records or modifies other tweaks automatically. The versioned report gives the minimal changed-client gate and recovery. Older guides describe historical versions.
