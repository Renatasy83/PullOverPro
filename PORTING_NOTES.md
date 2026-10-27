# PullOver Pro port: iOS 26 research and Beta gates

Status: Alpha 4 (0.4.0) and Safe 3 (0.5.2) have been reported working by the device tester. 0.5.5 diagnostic1 is an unvalidated startup baseline, not a functional app-hosting Beta. See [DEBUGGING.md](DEBUGGING.md) for evidence, build checks, staged device tests and recovery.

## Upstream reference
Original source: https://github.com/c1d3rdev/PullOver-Pro
License: GPL-3.0; preserve original author attribution and license for reused upstream code.

Original implementation files inspected:
- `PullOverPro/POApplicationHelper.m`: obtains recent applications from `SBMainSwitcherViewController` and icons from `SBIconController`. Both are private APIs; do not assume iOS 26 compatibility.
- `PullOverPro/QuickSwitchTableView.m`: favorites/recent apps and tap/drag selection callbacks.
- `PullOverPro/headers.h`: private SpringBoard class declarations; signatures require runtime verification.

## Current implementation
- ElleKit SpringBoard injection: reported working.
- Separate `UIWindow` overlay and movable grabber: reported working.
- Expand/collapse sidebar: reported working.
- No real app list, launcher, scene embedding, or floating app windows yet.

## Required before calling this a Beta
1. Add a read-only installed-app enumerator with guarded runtime API lookups and graceful fallback; avoid blocking SpringBoard.
2. Add favorite selection/persistence, icon display and app launching; test locked/unlocked and foreground/background.
3. Investigate scene hosting via runtime metadata inspection of `SBApplication`, `FBScene`, `SBMainSwitcherViewController`. Availability checks alone are insufficient: verify signatures, ownership, threading and behavior for the actual OS before calling private APIs.
4. Implement app view hosting in a separate container without stealing focus; validate keyboard, touch, rotation and lifecycle.
5. Add kill switch, crash recovery and remove/disable instructions.
6. Compile, install and run device tests. Only mark Beta when app-hosting works reliably.

## Build/test safety
Keep `main` as the working Alpha 4 fallback. Develop on `beta-development`; no production claim without compilation and device testing.

