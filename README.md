# PullOver Pro port development

This is an incomplete GPL-3.0 port of c1d3rdev/Will Smillie’s PullOver Pro.

`main` preserves Alpha 4. `stable/verified-app-picker` preserves the user-confirmed 0.5.8 picker. Work continues on `debug/autonomous-port`. Development artifacts are not final release candidates.

Current development implements the public UIKit overlay/picker and a bounded file bridge to a separate launchd service running as mobile. The service refreshes the app inventory and requests launches through runtime-guarded LaunchServices calls. SpringBoard creates no helper process and makes no private LaunchServices calls. The user confirmed Safari launching from the panel with 0.6.1; see DEVICE_VALIDATION.md.

**The user confirmed live Safari rendering and manual X-close/restoration with 0.7.1. The 0.7.2 development trial adds an explicit public UIKit touch-acceptance switch; touch delivery and keyboard focus remain unverified. This is not a final candidate. Dopamine/ElleKit compatibility is not confirmed.** See [AUTONOMOUS_PORT_STATUS.md](AUTONOMOUS_PORT_STATUS.md), [BRIDGE_DESIGN.md](BRIDGE_DESIGN.md) and [HOSTING_RESEARCH.md](HOSTING_RESEARCH.md). Older diagnostic guides describe their historical versions.


The 0.7.0 device report confirmed exact framework UUIDs and unique Safari scene selection. The next 0.7.1 operation creates/activates only a newly owned PPO presenter, and invalidates it on close. Nothing is hosted automatically on install/respring. See [HOSTING_TRIAL.md](HOSTING_TRIAL.md) for safeguards, remaining device checks and recovery. Keep `stable/verified-safari-launch` (0.6.1) as the working baseline.

The render-confirmed 0.7.1 source is preserved on `stable/verified-safari-rendering`. See [TOUCH_TRIAL.md](TOUCH_TRIAL.md) and [INPUT_23A355.md](INPUT_23A355.md) for the current implementation and the remaining real-device gate.
