# Autonomous port status — 2026-10-28

## Preservation

`main` is unchanged. `stable/verified-app-picker` preserves commit 9bde2538367754343153c32becbc913254bc76c7 (0.5.8, user-confirmed picker functionality). This does not establish complete platform compatibility. Development is isolated on `debug/autonomous-port`, based on bd0433090111b884a73f04e82f08411cc8881b84.

## Evidence

The device's 0.5.11 report records real/effective UID 501, executable stat success, root ownership and mode 0755, access(X_OK) EPERM and posix_spawn EPERM. No timeout occurred. The helper works when invoked from NewTerm according to the user. The specific enforcement mechanism is not established. Changing mode or blaming ElleKit/Dopamine is not justified.

Existing CI run 40629442968 at bd0433090111b884a73f04e82f08411cc8881b84 completed successfully. Its workflow includes Clang analysis, native macOS parser/persistence, ABI-guard and process-runner tests, Theos packaging and payload/architecture inspection. These are existing results, not tests of a new implementation or iOS runtime integration.

## Host investigation

The accessible executor reports Linux 6.18.55 x86_64 and has no xcrun or clang on PATH. No physical Apple Silicon Mac is attached or configured in the inspected environment. Lakr233/vphone-cli README requires a physical Apple Silicon Mac, macOS 15+, Recovery security configuration and explicitly excludes macOS VMs. It was not installed or run. GitHub-hosted macOS builds do not establish availability of a compatible virtualization host. Even a virtual iPhone would require separate verification of its injection environment and would not prove Dopamine/ElleKit compatibility on iPhone12,5.

Source: https://github.com/Lakr233/vphone-cli/blob/main/README.md

## Original hosting investigation

Reviewed c1d3rdev/PullOver-Pro main, PullOverPro/ContextHostManager.mm and ContextInterfaces.h. iOS13 hosting uses FBSceneManager, KVC `_scenesByID`, `_mutableSettings`, layerManager/layers, _UIContextLayerHostView initWithSceneLayer:, _UIExternalSceneLayerHostView initWithSceneLayer:parentScene:, foreground settings updates and KVO layer observation. Those headers are historical declarations, not iOS26 runtime evidence. Method existence/type encodings alone cannot establish lifecycle, ownership, entitlements or thread constraints. None of this hosting code was enabled in SpringBoard.

## Delivery gate

No final candidate DEB has been produced. Current diagnostic artifacts are not final candidates. Floating application hosting and panel launching remain incomplete. Dopamine/ElleKit compatibility is not confirmed.

Required automated integration coverage on a suitable target: launch IPC under actual caller sandbox; scene selection by exact app identity; host creation and teardown; touch and keyboard routing; foreground/background transitions; lock/unlock; orientation; app termination/relaunch; repeated open/close cycles; injection startup and watchdog observations. Mock tests cannot replace these checks.

Do not request further intermediate phone installations from the user. Continue automatable work on the development branch; do not promote a build solely because compilation succeeds. Preserve GPL-3.0 and original attribution. No device data, other tweaks, host security configuration or installed device packages were modified.


## Development implementation in this branch

The panel no longer links the process-spawn runner. It uses a bounded file mailbox on its existing serial worker queue. A separate launchd service runs as mobile, refreshes the app inventory on demand and requests launches only after exact membership and expiry checks. No scene hosting calls were introduced. The own-service installation/removal scripts are payload-verified. See BRIDGE_DESIGN.md.

The new portable transport passed365 filesystem/concurrency checks on Linux with ASan/UBSan. Foundation protocol/service policy and actual macOS subprocess integration are CI checks, not iOS runtime evidence. The branch's development package version is0.6.0~dev.bridge1. A development build must not be described as a completed port or final candidate.

## Continued review: emergency disable and scene evidence

A service control defect was found: the new service did not previously honor the overlay's `.ppo_disable` marker. It now fails closed before workspace access and rechecks after enumeration/before launch. Added policy and subprocess regression coverage for this behavior. This is a source-level correction, not a verified device fix.

Pinned iOS26 headers and a recent installed-app hosting reference were reviewed. They document newer presenter/container boundaries, but not the exact device build or safe acquisition/adoption of a SpringBoard-owned scene. The source was not copied and no speculative hosting calls were enabled. See HOSTING_RESEARCH.md for precise remaining evidence requirements.
