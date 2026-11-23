# Jond_ie PullOver Pro: improvement review

Reviewed 2026-11-23 at upstream commit `076da8f07e707453bc58ed9baadeefb40f0e93e4`.
Source: https://github.com/Jond-ie/pulloverpro (GPL-3.0).

## Scope and evidence

The user asks whether the existing port can be improved. This checkpoint is a read-only source assessment, followed by documentation updates in Renatasy83/PullOverPro. No upstream code was changed, compiled, installed or executed. No battery, performance or exact-device compatibility improvement has been measured. The package-index and author-test claims remain separately attributed in [EXTERNAL_PORT_REFERENCE.md](../EXTERNAL_PORT_REFERENCE.md).

Preserve the original edge drawer and working behavior as the starting point. Do not resume a long sequence of incomplete custom candidates merely to answer the feasibility question. Any future derivative must preserve GPL source availability, licence and c1d3r/Jond_ie attribution.

## Prioritized corrections

1. **Keyboard geometry.** [PullOverViewController.m:194](https://github.com/Jond-ie/pulloverpro/blob/076da8f07e707453bc58ed9baadeefb40f0e93e4/Tweak/PullOverViewController.m#L194) uses UIKeyboardFrameBeginUserInfoKey and handleFrame.origin.x in a vertical overlap calculation. Use the final keyboard rectangle converted to the relevant window/view coordinates, safe-area bounds and frame-change handling. Test geometry independently; confirm actual placement and restoration on device. This is a source-level calculation defect, not a reproduced keyboard complaint.

2. **One startup attempt per state transition.** [PullOverViewController.m:400](https://github.com/Jond-ie/pulloverpro/blob/076da8f07e707453bc58ed9baadeefb40f0e93e4/Tweak/PullOverViewController.m#L400) assigns isOpened during each scroll callback; its setter always invokes beginHosting/endHosting even when the state is unchanged. [beginHosting:446](https://github.com/Jond-ie/pulloverpro/blob/076da8f07e707453bc58ed9baadeefb40f0e93e4/Tweak/PullOverViewController.m#L446) can schedule another retry every second. Make transitions idempotent, allow only one pending retry per selected application, cancel obsolete requests, and propagate launch errors instead of only logging them in [ContextHostManager.mm:39](https://github.com/Jond-ie/pulloverpro/blob/076da8f07e707453bc58ed9baadeefb40f0e93e4/Tweak/ContextHostManager.mm#L39). Bound the *startup retry* and offer a useful error/retry action. This does not justify an arbitrary timeout that closes a healthy window. Repeated work is evident in the source; its effect on actual CPU/battery use has not been measured.

3. **Rollback partial scene setup.** [ContextHostManager.mm:74](https://github.com/Jond-ie/pulloverpro/blob/076da8f07e707453bc58ed9baadeefb40f0e93e4/Tweak/ContextHostManager.mm#L74) foregrounds a scene before creating its presenter. If creation returns nil, it exits before recording the scene; stopHosting returns immediately when there is no presenter. Restore the prior scene state on every partial failure and retain enough transaction state for cleanup. Validate that successful hosting and normal cleanup remain unchanged. This is an error-path defect, not proof of an observed SpringBoard crash.

4. **QuickSwitch selection and bounds.** [QuickSwitchTableView.m:83](https://github.com/Jond-ie/pulloverpro/blob/076da8f07e707453bc58ed9baadeefb40f0e93e4/Tweak/QuickSwitchTableView.m#L83) sizes the table for every item and only flips it upward, without capping it to the available safe area. It also dereferences items[lastHoveredIndexPath.row] on drag/drop paths without validating the selection and bounds. Use a valid selected bundle ID or an immutable list snapshot, cancel when there is no valid selection, and keep long lists within a scrollable viewport. A missing NSIndexPath can yield row zero; an empty/outdated list needs explicit guards. These are static edge-case risks, not reproduced crashes.

5. **Preference validation.** [POApplicationHelper.m:99](https://github.com/Jond-ie/pulloverpro/blob/076da8f07e707453bc58ed9baadeefb40f0e93e4/Tweak/POApplicationHelper.m#L99) merges stored values directly with defaults. Validate accepted types, finite numeric ranges and favorite identifiers before consumers use them. Settings are already cached; do not claim the existing code rereads preferences from disk on every gesture.

## Possible user-facing additions

- Adjustable window size and remembered size/position per application.
- Optional per-app preferences and better handling of long QuickSwitch lists.
- Accessibility labels and localization where absent.

These are proposals, not implemented features. The AltList favorite picker already enables search; adding search should not be advertised as a missing feature. A refresh-only stale-favorites observation is insufficient to claim that clearing favorites fails in the normal UI, because applySettings recreates the controller/table.

Multiple simultaneous windows and hosting an app that is already full screen require separate scene/lifecycle work. Upstream explicitly documents the latter limitation; neither is promised as a simple UI change.

## Verification boundary and next work

The complete source tree was inspected for build/test infrastructure: no committed tests or GitHub Actions workflows were present at the inspected commit. The public open-issues list was empty when checked; that does not prove absence of bugs.

For a future authorized implementation: preserve a pinned upstream baseline and recovery artifact, isolate the changes above, add meaningful geometry/selection/startup-state tests plus a rootless Theos build, then group only the unavoidable device checks. Preserve existing private method contracts; do not add guessed signatures. Build success does not establish SpringBoard runtime safety, working app contents, or Dopamine/ElleKit compatibility.

No new DEB or installation request is appropriate for this assessment-only checkpoint. Keep main, stable branches and all prior candidate archives untouched.
