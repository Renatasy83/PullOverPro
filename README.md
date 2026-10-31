# PullOver Pro port development

This is an incomplete GPL-3.0 port of c1d3rdev/Will Smillie’s PullOver Pro. Main preserves Alpha4; the earlier tested picker/launch/rendering and Safari/Reminders source branches remain preserved.

Current isolated work is0.13.0~dev.geometry1 on debug/floating-window-geometry, adding bounded title dragging and three public viewport size presets. It includes the UIKit overlay/app picker, mobile launch service and separately owned floating application scenes with guarded identity, lifecycle, lock and cleanup. Fresh selected-app installed metadata can conservatively admit simple iPhone multiscene apps; being listed or launchable does not establish eligibility or runtime compatibility. No bundle file IO or helper-process creation occurs on SpringBoard's main thread.

Actual device observations confirm the stated Safari0.9.1/0.10.0 window/input/Keep/lock/reuse operations and Reminders0.11.0 window/manual-close/timeout/reuse. These are version-specific observations. Contacts0.12.0 installed-info/window/X/reopen/timeout is now also confirmed for the requested operations. Nonbaseline dynamic clients remain untested. Complete original functionality and full Dopamine/ElleKit compatibility are unconfirmed; development artifacts are not final releases.

[Current status](AUTONOMOUS_PORT_STATUS.md) · [0.12.0 verified baseline](VALIDATION_0.12.0.md) · [Window geometry stage](FLOATING_WINDOW_GEOMETRY.md) · [0.13.0 validation/package](VALIDATION_0.13.0.md) · [Original feature coverage](ORIGINAL_FEATURE_PARITY.md) · [Selected-app metadata contract](SELECTED_APP_CAPABILITIES.md) · [Actual device evidence](DEVICE_VALIDATION.md).

The0.12.0 executable passed all20 automated suites, iOS static analysis, pinned Theos rootless arm64/arm64e build and package/hash inspection. Current0.13.0 passed all21 suites, iOS analysis, rootless arm64/arm64e build and downloaded package/hash checks; the new geometry policy passed108812 native checks. Linux/macOS Intel fixtures do not execute iOS clients, and no compatible physical Apple Silicon Mac is accessible for vphone-cli. The changed size/drag/remote-input behavior requires the actual phone after successful automation. Older diagnostic guides describe their historical versions.

Nothing installs/resprings the phone, edits personal records or modifies other tweaks automatically. See the versioned validation report for the minimal manual test, recovery procedure and tested0.11.0 fallback.
