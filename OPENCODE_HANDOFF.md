# Active OpenCode continuation — Jond_ie stability derivative (2026-11-23)

The user authorized implementation. Continue on `improve/jondie-stability`, source directory `jondie-port/`, not the older root diagnostic implementation. Read the [current handoff](https://github.com/Renatasy83/PullOverPro/blob/improve/jondie-stability/OPENCODE_HANDOFF.md) and [validation / necessary phone checks](https://github.com/Renatasy83/PullOverPro/blob/improve/jondie-stability/docs/JOND_IE_STABILITY_RC1_VALIDATION.md).

Candidate3.0.2~rc1 is archived at `candidate/jondie-stability-3.0.2-rc1`, commit `6c3fdc2fe19b09d1fa5d11a5be9f0aec095fb463`. Built source `22adc654e237d21d26a67535a994f63c4980b4bd`; successful Actions run45205953764. Six suites,10 production Clang analysis units, Theos rootless build, modern-arm64e/payload and embedded ldid CodeDirectory hash checks passed. SHA256 `b3f8fc9a946ea4d87a7c0a8bd5649ab8deef54b6fe05c026f6e2ab2b3bb9b50d`. Mac codesign diagnostic does not establish Apple/device trust. The user has now reported “Funcționează” for the delivered candidate on the previously stated setup; the report does not separately establish every probe, all applications or prolonged stability.

No automatic phone actions were performed. Preserve main, stable branches, archives and upstream GPL attribution. This branch retains the earlier custom source for recovery; only this documentation pointer changed.

## User-reported working recovery point

On 2026-11-23 the user replied “Funcționează” (“It works”). This feedback is recorded in the current handoff and validation report, with the exact DEB/source hashes. Recovery checkpoint: `checkpoint/user-reported-working-jondie-3.0.2-rc1` at `4c986fb7b881f9b80ce5eb747057f3b0c3153ef7`. The original candidate archive and DEB remain unchanged. No new build or phone action was performed for this documentation update.

## Historical handoff before implementation

# PullOver Pro — current OpenCode / ChatGPT handoff (2026-11-23)

## Priority: evaluate the existing GPL port before further custom candidates

The user identified the existing package `com.johndie.pulloverpro-rootless` at https://jond-ie.github.io/repo/. Repository metadata and public source have now been checked. The prior custom port is incomplete; RC15's real menu-selection gate has not been confirmed. Do not keep asking the user to install custom RC candidates without first comparing this existing implementation against the user's goal.

Public source: https://github.com/Jond-ie/pulloverpro, inspected head `076da8f07e707453bc58ed9baadeefb40f0e93e4`, GPL-3.0. Source README describes the original edge drawer, QuickSwitch and live Settings. The package repository explicitly links that source. Makefile uses Theos rootless, arm64+arm64e, SDK16.5 and deployment15.0, with Tweak/ and Prefs/ subprojects.

The package index at Jond-ie/repo head `84183ec8b6c3bce2d777575264d4380ebf6740f1` lists3.0.1 builds for iphoneos-arm64 and iphoneos-arm64e. Dependencies: mobilesubstrate, com.opa334.altlist, firmware>=15 and<28; PreferenceLoader recommended. The author advertises iOS15–27 and Rootless/RootHide. These are upstream statements, not an independently confirmed test on the user's iPhone12,5/iOS26.0.1 build23A355/Dopamine/ElleKit1.2.

Read [external port reference](EXTERNAL_PORT_REFERENCE.md) for exact package hashes, links, stated tests and limitations. The source assessment is now recorded in [the improvement review](docs/JOND_IE_IMPROVEMENT_REVIEW.md): keyboard geometry, duplicate/unbounded startup retries, rollback after partial scene setup, QuickSwitch bounds and preference validation. These are static findings and proposals, not measured runtime improvements. Preserve GPL/c1d3r/Jond_ie attribution. Do not restart a long UI-only candidate sequence or copy binaries without source/licence review. No new custom DEB or phone test was prepared for this reference checkpoint.

## Latest user request: can Jond_ie's port be improved?

Yes; prioritize the source-grounded corrections in [the review](docs/JOND_IE_IMPROVEMENT_REVIEW.md) while preserving its original interface. Adjustable per-app window size/position is a possible later feature. This turn assessed feasibility only: no application patch, upstream modification, new build, package, installation or phone test was performed. Do not imply these changes have already shipped. The remaining phone compatibility and performance claims are unverified.

## Preserved local project state

Active branch remains debug/two-stage-handle-messages; no application code changed for this checkpoint. Last built custom executable `becd7123fec59177684f52cfd58fc8aea03e23e3`/1.0.14~rc15, archive `fb57ef02e5d04d721e058cdaa14d8adccd4b26d9`, SHA256 `8d2242c49276bf4a7a71dc19e07d1e452545e2b124139ff0d3a279528d8e99a2`. Native40/portable13/copy-binding378 checks passed, but actual corrected-menu behavior remains unconfirmed.

Verified scoped recovery remains RC13, stable/verified-rc13-messenger586-minimize at `c87589dc45eb4d5039081eff7015f48ad1ff4a7e`, archive `7f77890d4229375c83050683eb0ef6718b90b9ef`. RC14's Keep menu was unusable and is not a verified stable. Preserve main, all stable branches and candidate archives.

Full preceding evidence, validation IDs, recovery and remaining limitations are in [the prior handoff](docs/OPENCODE_HISTORY_THROUGH_RC15_VALIDATION.md). Its request for another RC15 installation is superseded by the existing-port evaluation above; do not assume that old gate was completed.

## Tandem workflow

Fresh-fetch remote head and handoff before edits, preserve OpenCode changes with explicit Git tree deltas and CAS; no broad reset/push. Keep this file current. No automatic install/respring/process termination, personal-data deletion or other-tweak changes. No general device compatibility or signature-trust claim without actual evidence. Recovery instructions and the earlier unconfirmed watchdog cause remain as recorded in the prior handoff.
