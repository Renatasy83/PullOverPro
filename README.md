# PullOver Pro port development

This is an incomplete GPL-3.0 port of c1d3rdev/Will Smillie’s PullOver Pro.

`main` preserves Alpha 4. `stable/verified-app-picker` preserves the user-confirmed 0.5.8 picker. Work continues on `debug/autonomous-port`. Development artifacts are not final release candidates.

Current development implements the public UIKit overlay/picker and a bounded file bridge to a separate launchd service running as mobile. The service refreshes the app inventory and requests launches through runtime-guarded LaunchServices calls. SpringBoard creates no helper process and makes no private launch/hosting calls. This architecture has not yet been tested under the device’s actual sandbox or launchd environment.

**Application content in floating windows is not implemented. Dopamine/ElleKit compatibility is not confirmed.** See [AUTONOMOUS_PORT_STATUS.md](AUTONOMOUS_PORT_STATUS.md), [BRIDGE_DESIGN.md](BRIDGE_DESIGN.md) and [HOSTING_RESEARCH.md](HOSTING_RESEARCH.md). Older diagnostic guides describe their historical versions.
