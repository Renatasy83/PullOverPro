# Application scene hosting research

Research date: 2026-10-28. This is a source review, not an iOS runtime test.
Floating application hosting remains **unimplemented and unverified**. A visible
UIKit panel, successful build, or matching method encoding does not establish
working remote rendering, input routing, or scene lifecycle ownership.

## Original PullOver Pro

Sources reviewed:

- [ContextHostManager.mm](https://github.com/c1d3rdev/PullOver-Pro/blob/main/PullOverPro/ContextHostManager.mm)
- [ContextInterfaces.h](https://github.com/c1d3rdev/PullOver-Pro/blob/main/PullOverPro/ContextInterfaces.h)
- [Original license](https://github.com/c1d3rdev/PullOver-Pro/blob/main/LICENSE)

The iOS 13 path uses `FBSceneManager`, private KVC keys `_scenesByID` and
`_mutableSettings`, `layerManager`/`layers`, foreground scene settings updates,
and `_UIContextLayerHostView` / `_UIExternalSceneLayerHostView` constructors. The
historical declarations do not establish their iOS 26.0.1 ABI, lifecycle,
threading, permissions, or suitability for SpringBoard-owned installed apps.

Source defects that should not be carried into a port:

- Scene selection uses substring matching rather than exact application and
  scene identity. The multiple-match comparator reads `id1` for both ranges and
  does not return `NSOrderedSame`.
- `parentScene` and `primarySceneLayer` are shared globals, which do not express
  ownership of independent hosting sessions.
- KVO registration and removal are inferred from `observationInfo`, which does
  not prove this particular observer owns a registration.
- Closing unconditionally changes foreground settings without recording and
  restoring the scene's previous state or checking another owner's use.
- The iOS 13 host entry point returns nil and reports scene-stack changes through
  delegate callbacks. Returning from the entry point is not hosting success.

These findings concern the original source. They do not diagnose the earlier
device watchdog reports, which have not been inspected here.

## Modern reference: LiveContainer

Sources reviewed:

- [AppSceneViewController.m](https://github.com/LiveContainer/LiveContainer/blob/main/MultitaskSupport/AppSceneViewController.m)
- [VirtualWindowsHostView.m](https://github.com/LiveContainer/LiveContainer/blob/main/MultitaskSupport/VirtualWindowsHostView.m)
- [README and architecture](https://github.com/LiveContainer/LiveContainer/blob/main/README.md)
- [License](https://github.com/LiveContainer/LiveContainer/blob/main/LICENSE)

The current implementation uses `_UISceneHostingControllerAdvancedConfiguration`
and `_UISceneHostingController` for iOS 18 and later, plus event-deferring
configuration. Its source explicitly describes an iOS 26 keyboard-focus issue:
it uses `sceneViewController.view` instead of accessing `sceneView` directly.
That is evidence that displaying remote content and correctly routing keyboard
focus are separate requirements.

LiveContainer launches its own NSExtension guest processes, obtains RunningBoard
process handles, registers audit tokens with FrontBoard, and creates scenes under
that architecture. This does not establish a safe recipe for borrowing an
already installed application's SpringBoard-owned scene. Its own README also
documents compatibility limitations.

LiveContainer is AGPL-3.0. No code from it was copied into this project. Any future
reuse requires deliberate compliance with its license, including the resulting
combined work's obligations. Source review is not permission to silently import
AGPL implementation into the existing GPL project.

## Earlier reference: FrontBoardAppLauncher

Sources reviewed:

- [README](https://github.com/khanhduytran0/FrontBoardAppLauncher/blob/main/README.md)
- [AppSceneViewController.m](https://github.com/khanhduytran0/FrontBoardAppLauncher/blob/main/AppSceneViewController.m)
- [Entitlements](https://github.com/khanhduytran0/FrontBoardAppLauncher/blob/main/entitlements.xml)
- [License](https://github.com/khanhduytran0/FrontBoardAppLauncher/blob/main/LICENSE)

This Apache-2.0 reference describes external application scenes, but its README
lists keyboard failure over SpringBoard, reopening crashes, empty windows for
some single-scene apps, and apps remaining alive after closing. Its teardown
uses process termination while acknowledging a FIXME about other scenes.
Neither that termination behavior nor its broad TrollStore entitlements should
be transplanted into PPO. Apache-2.0 reuse would require attribution and license
notices; none of its source was copied during this review.

## vphone-cli and the available host

Source: [vphone-cli requirements](https://github.com/Lakr233/vphone-cli/blob/main/README.md).

The project requires a **physical Apple Silicon Mac**, macOS 15 or later,
sufficient disk space, and research-guest host configuration performed through
Recovery. It explicitly excludes macOS VMs. The inspected executor is Linux
x86_64, and no compatible physical Mac has been established. vphone-cli was not
installed or run, and no host security settings were changed.

GitHub Actions can provide compilation and native macOS tests; the presence of a
macOS runner does not establish the physical host, virtualization, Recovery
configuration, or firmware conditions required by vphone-cli. Even a working
virtual guest would need separate injection-environment validation and would
not prove Dopamine/ElleKit behavior on an iPhone12,5.

## Implementation and validation boundary

Actual hosting must wait for evidence of the appropriate target-side contracts,
including identity selection, lifecycle ownership, allowed operations and input
routing. Class existence and ABI guards are necessary checks for private calls,
but are insufficient to establish these semantics. No guessed private hosting
calls were enabled in SpringBoard as a result of this review.

Automated tests can cover a session coordinator's exact identity matching,
generation checks for stale completions, idempotent close, owned-observer
tracking, cancellation, bounded resize work, and resource cleanup. They cannot
demonstrate remote application hosting on iOS by themselves.

Integration validation on a suitable target must cover:

1. Actual app launch and exact bundle/process/scene identity, including apps
   with multiple scenes and apps already open full-screen.
2. Remote content rendering, touch coordinates, keyboard focus, rotation, and
   safe-area/size updates.
3. Lock/unlock and foreground/background transitions without exposing content on
   the lock screen or routing input to an inactive host.
4. App exit, app relaunch, failures during creation, repeated open/close, and
   switching apps while a previous asynchronous operation is pending.
5. Cleanup that removes only PPO-owned registrations/presenters and restores
   only settings PPO owns; it must not terminate the user's other app scenes.
6. SpringBoard responsiveness, bounded work, injection startup, and watchdog
   observations under the actual Dopamine/ElleKit environment.

Until those checks run, a DEB containing partial work must not be described as a
complete PullOver Pro port or as confirmed compatible with Dopamine and ElleKit.
