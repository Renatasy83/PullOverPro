# PullOver Pro port development

**Known0.8.0/0.8.1 device regression:** the user reports black hosted content for Safari and Settings, with close/reopen controls responding. Rendering is under investigation; successful CI is not runtime validation. The previously working0.7.2 source remains preserved. See DEVICE_VALIDATION.md.

This is an incomplete GPL-3.0 port of c1d3rdev/Will Smillie’s PullOver Pro.

`main` preserves Alpha 4. `stable/verified-app-picker` preserves the user-confirmed 0.5.8 picker. Work continues on `debug/autonomous-port`. Development artifacts are not final release candidates.

Current development implements the public UIKit overlay/picker and a bounded file bridge to a separate launchd service running as mobile. The service refreshes the app inventory and requests launches through runtime-guarded LaunchServices calls. SpringBoard creates no helper process and makes no private LaunchServices calls. The user confirmed Safari launching from the panel with 0.6.1; see DEVICE_VALIDATION.md.

**The user confirmed live Safari rendering and manual X-close/restoration with 0.7.1. The 0.7.2 report confirmed automatic close; the user observed scrolling even with its touch switch off. The 0.7.3 correction removes that misleading switch and reports UIKit flags separately from unconfirmed input routing. The user confirms Safari keyboard/navigation and the proposed Safari-over-NewTerm trial, including automatic close. This is not a final candidate. Dopamine/ElleKit compatibility is not confirmed.** See [AUTONOMOUS_PORT_STATUS.md](AUTONOMOUS_PORT_STATUS.md), [BRIDGE_DESIGN.md](BRIDGE_DESIGN.md) and [HOSTING_RESEARCH.md](HOSTING_RESEARCH.md). Older diagnostic guides describe their historical versions.


The 0.7.0 device report confirmed exact framework UUIDs and unique Safari scene selection. The next 0.7.1 operation creates/activates only a newly owned PPO presenter, and invalidates it on close. Nothing is hosted automatically on install/respring. See [HOSTING_TRIAL.md](HOSTING_TRIAL.md) for safeguards, remaining device checks and recovery. Keep `stable/verified-safari-launch` (0.6.1) as the working baseline.

The render-confirmed 0.7.1 source is preserved on `stable/verified-safari-rendering`. See [TOUCH_TRIAL.md](TOUCH_TRIAL.md) and [INPUT_23A355.md](INPUT_23A355.md) for the current implementation and the remaining real-device gate.

Current report correction: [INPUT_REPORT_CORRECTION.md](INPUT_REPORT_CORRECTION.md). The 0.7.2 source is preserved on `stable/verified-safari-timeout`; it does not provide verified remote input blocking.

0.8.0 development adds explicit single-session ownership/reopen after confirmed cleanup and a controlled Settings target, using the existing presenter API surface. Only Safari is device-confirmed so far; repeated UIKit sessions and Settings require the next real-device gate. See [HOST_SESSIONS.md](HOST_SESSIONS.md). The timeout remains15 seconds; this is not a final release.

0.8.1 is a rendering correction candidate: PPO scales an owned wrapper rather than assigning the private presentation view's geometry. Reports include bounded delayed layout and live-state samples. This does not establish that the observed black-content regression is fixed. See [RENDER_LAYOUT_23A355.md](RENDER_LAYOUT_23A355.md).

The actual0.8.1 report shows valid visible geometry and live active/hosting state, but no context-host view in the recorded tree. The scaling-wrapper change did not restore visible content. Layer availability/filtering/attachment and the foreground/background distinction remain under investigation; see [LAYER_ATTACHMENT_23A355.md](LAYER_ATTACHMENT_23A355.md).
