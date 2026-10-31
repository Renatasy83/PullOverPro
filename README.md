# PullOver Pro port development

This is an incomplete GPL-3.0 port of c1d3rdev/Will Smillie’s PullOver Pro. Main preserves Alpha4; the earlier tested picker/launch/rendering and Safari/Reminders source branches remain preserved.

Current isolated work is0.12.0~dev.selectedcap1 on debug/selected-app-capabilities. It includes the UIKit overlay/app picker, mobile launch service and separately owned floating application scenes with guarded identity, lifecycle, lock and cleanup. Fresh selected-app installed metadata can conservatively admit simple iPhone multiscene apps; being listed or launchable does not establish eligibility or runtime compatibility. No bundle file IO or helper-process creation occurs on SpringBoard's main thread.

Actual device observations confirm the stated Safari0.9.1/0.10.0 window/input/Keep/lock/reuse operations and Reminders0.11.0 window/manual-close/timeout/reuse. These are version-specific observations. Contacts and new dynamic clients remain untested. Complete original functionality and full Dopamine/ElleKit compatibility are unconfirmed; development artifacts are not final releases.

[Current status](AUTONOMOUS_PORT_STATUS.md) · [0.12.0 validation and package](VALIDATION_0.12.0.md) · [Selected-app metadata contract](SELECTED_APP_CAPABILITIES.md) · [Actual device evidence](DEVICE_VALIDATION.md).

The final executable passed all20 automated suites, iOS static analysis, pinned Theos rootless arm64/arm64e build and package/hash inspection. Linux/macOS Intel fixtures do not execute iOS clients, and no compatible physical Apple Silicon Mac is accessible for vphone-cli. The remaining selected-app service/admission/rendering gate requires the actual phone. Older diagnostic guides describe their historical versions.

Nothing installs/resprings the phone, edits personal records or modifies other tweaks automatically. See the versioned validation report for the minimal manual test, recovery procedure and tested0.11.0 fallback.
