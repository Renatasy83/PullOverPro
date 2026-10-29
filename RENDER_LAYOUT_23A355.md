# Rendering investigation and0.8.1 candidate

## Actual0.8.0 evidence

The supplied host-0.8.0.json contains four completed sessions: Settings manual close, Settings timeout, Safari timeout, Safari manual close. All select one exact scene among10, match the expected three framework UUIDs, immediately report active/hosting=true, and complete invalidation without poison. The user sees black content in both apps.

This proves the recorded lifecycle transitions, not pixels. Geometry was not captured and active/hosting were only read immediately after activation. The final view/window properties were read after those objects had been cleared. No private API crash, priority failure, geometry failure, sandbox cause or process-background root cause is established.

## Exact firmware finding

Inspected UIKitCore UUID C98EAB32-B273-3430-B0C5-46522C904CBB from the manifest-digest-verified23A355 cache documented in FIRMWARE_23A355.md. _UIScenePresentationView::_updateFrameAndTransform at0x188ad444c calls the selector stubs setTransform: (0x18acdf200, call at0x188ad4628) and setFrame: (0x18acb7300, call at0x188ad4640). Its layoutSubviews at0x188ad51e4 notifies scenePresentationViewIsLayingOutSubviews through stub0x18ac996a0.

Therefore the presentation view owns geometry changes internally. PPO's direct pre-activation bounds/transform/center assignments can conflict with that ownership. This integration fragility also existed in the previously working0.7.2 code, so static evidence does not prove it caused the0.8.0 regression.

## Candidate changes

0.8.1 leaves the private presentation view's geometry untouched. It adopts the new presenter's unattached view into a PPO-owned wrapper and scales/centers only that wrapper. Public layout is allowed to complete after activation. The wrapper fits the current presentation frame, with a bounded screen-frame fallback while native geometry is unavailable. Invalid dimensions stop the operation.

The existing single-session gate, Safari/Settings target policy, unique dual-identity lookup, loaded-library UUID check, method ABI checks, ownership-only invalidation,15-second deadline and disable/host-inactive/protected-data cleanup remain. There are no new private selectors, reactivation attempts, priority/foreground changes, key-window forcing or event-deferral calls.

Diagnostic sampling uses only the same previously exercised ABI-checked isActive/isHosting/isInvalidated getters. Samples occur after layout, then after100ms and750ms, while that session is still running. They do not run indefinitely, sample closed/foreign objects, or mutate the presenter.

## Report scope

host-0.8.1.json uses schema4 and retains up to8 session snapshots with up to16 events each. Per-event geometry records the ancestor chain and a bounded subset of descendant views: class names, frames, bounds, transforms, visibility/alpha, attachment to PPO's window, and layer/subview counts. It does not capture images, URLs, typed text, accessibility content or touch coordinates. Live-state samples are separate from historical activation flags.

These measurements can distinguish a zero/offscreen/hidden layout or later loss of hosting from an apparently attached/visible hierarchy, but still cannot prove actual pixels or the precise underlying cause by themselves.

## Automated validation

PPOHostGeometry.h is portable aspect-fit math. LinuxASan/UBSan execution passed1027 containment/centering/invalid-input checks. CI repeats these tests, analyzes UIKit and the adapter, tests live sampling with native fake receivers, runs existing lifecycle/slot/parser/bridge suites and sanitizers, compiles rootless arm64/arm64e, and inspects the exact payload/license/scripts. Native tests do not reproduce UIKit/WindowServer, and successful compilation is not proof of recovery.

## Single real-device gate after successful CI

Preserve the working0.7.2 DEB. Install only the successful0.8.1 artifact and respring manually. Test Safari FIRST over NewTerm before opening a Settings window in PPO; open Safari normally once first so it has a scene. Observe live content and controls, close X and reopen once. Then test Settings similarly. This ordering avoids conflating a Settings-specific first session with Safari's baseline.

Share host-0.8.1.json and the observed content. If black content persists, this package's delayed samples provide the missing evidence; do not label the issue resolved or change private APIs based on the activation flags alone.

Recovery remains /var/mobile/.ppo_disable when responsive; otherwise force restart, enable Dopamine without tweak injection and uninstall only com.renatasy83.pulloverpro.diagnostic. No automatic phone installation, respring, personal-data deletion or changes to other tweaks are performed. main and the0.7.2 stable source remain untouched.
