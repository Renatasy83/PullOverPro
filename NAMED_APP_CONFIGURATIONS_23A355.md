# Named application configurations — 0.17.0

Subsequent result:the supplied Files0.17.0 report and user confirmation exercise the named reason in two clean timeout sessions. The planned representative gate below is historical; no repeat is requested. See VALIDATION_0.17.0.md and DEVICE_VALIDATION.md. Current original-style RC interface work has its separate combined gate in VALIDATION_1.0.0_RC1.md.

Branch: `debug/named-application-configurations`. Version: `0.17.0~dev.namedconfigs1`.

This stage extends advisory metadata eligibility to a bounded list of named application configurations. UIKit and the application select the actual configuration. PPO does not choose a list entry, instantiate a declared class, call an app delegate, force a configuration name or transfer an existing scene.

## Exact-firmware selection audit

The existing iPhone12,5 iOS 26.0.1 build 23A355 cache was inspected with bounded disassembly. UIKitCore UUID is `C98EAB32-B273-3430-B0C5-46522C904CBB`. The observations below describe UIKit code, not private calls added to PPO or proof that a particular client reaches that code.

- The ordinary new-session path at `0x189cf408c` supplies a nil configuration name. In `UISceneConfiguration` construction at `0x18a0f42f0`, the nil-name branch at `0x18a0f4560` uses the operating system's `firstObject` selection. PPO does not repeat that selection or serialize a preferred entry.
- A requested name is matched by exact `UISceneConfigurationName` equality in the search block at `0x18a0f49f0`. A named miss initially sets a resolution error at `0x18a0f44e8`; fallback to an available first entry at `0x18a0f45ec` clears it before field resolution. A named miss therefore does not always leave a persistent error. The prior no-dictionary/nil-name programmatic path remains distinct from a nonnil name with no declaration dictionary.
- Class resolution follows `0x18a0f45fc`. A present `UISceneClassName` must resolve to a `UIScene` subclass; failure paths include `0x18a0f4654` and `0x18a0f46c8`. Omitting this field is permitted.
- Delegate resolution at `0x18a0f4758` requires a present class to resolve and conform to `UISceneDelegate`; failures include `0x18a0f477c` and `0x18a0f4808`. Omitting the field is permitted.
- The scene storyboard field is `UISceneStoryboardFile`. UIKit calls `storyboardWithName:bundle:` with the main bundle at `0x18a0f48d4`; a missing resource sets the error at `0x18a0f48f8`. Omission is permitted. `UILaunchStoryboardName` is not consumed by this constructor. The new multiple-configuration shape excludes it; the existing single-configuration allowance is retained.
- The connection path first considers matching requested configurations at `0x189cf4180–0x189cf41fc`. When allowed and implemented, the app delegate can override at `0x189cf4254`; optional SwiftUI configuration follows at `0x189cf4314`. Nil overrides retain the preceding configuration. PPO does not bypass these decisions.
- Final construction at `0x18916d008–0x18916d048` uses the selected scene class or the specification minimum, and checks the minimum and `UIScene` subclass constraints. Exact `UIApplicationSceneSpecification` resolves minimum `UIWindowScene` at `0x188a316f4`, normal application role at `0x1889f4e90`, UIKit-managed YES at `0x188a31648`, internal NO at `0x188a31650` and inherited app-delegate configuration permission YES at `0x188a30db0`.

Metadata cannot establish class availability, app callback behavior, FrontBoard admission, rendered pixels, input routing or successful cleanup. These remain runtime outcomes.

## Policy v3 boundary

The descriptor policy becomes `installed-basic-multiscene-v3`, with additional canonical eligible reason `declared-named-application-configurations`. Old v1 and v2 descriptors are rejected rather than translated. Both helper and tweak use the new policy; the existing own-service upgrade restart remains necessary. The schema, nonce binding, selected-identifier binding and five-second freshness bound do not change.

The new positive shape requires all of the following:

- The existing APPL, nonextension, iPhone-family, critical-identifier and genuine-Boolean checks pass. Explicit multiple-scene support is true. Explicit false remains a hard negative.
- The manifest has exactly `UIApplicationSupportsMultipleScenes` and `UISceneConfigurations`. The configurations dictionary has exactly one role, `UIWindowSceneSessionRoleApplication`.
- That role contains 2–8 dictionaries. Every entry is validated, including the last entry. Allowed keys are `UISceneConfigurationName`, `UISceneClassName`, `UISceneDelegateClassName` and `UISceneStoryboardFile`. Every present value is a nonempty string of at most 256 characters.
- Every entry has a configuration name that is not whitespace-only. Names are distinct by exact equality; trimming is used only to reject blank names, not to change stored names or merge case/space variants.
- Existing extra top-level scene/window-key rejection remains. This is a bounded scene metadata policy, not a validator for all unrelated Info.plist fields.

The previous single-static and absent-configurations programmatic positives retain their behavior and reasons. A single static dictionary retains its prior five-key allowance, including `UILaunchStoryboardName`, and does not gain the new mandatory-name requirement. Empty/malformed arrays, nine or more entries, extra roles/keys, malformed later declarations and duplicate/blank names remain unknown. No unknown result grants a new dynamic target admission.

`PPOOwnedApplicationPolicy.h` and `SCENE_TARGETS_23A355.json` remain the same three-app Safari/Reminders/Contacts baseline. Files, Mail and Calendar gain no baseline bypass. Fresh installed metadata is still required for other targets. Nonbaseline source and child must retain exact `UIApplicationSceneSpecification`, normal application role and independently checked identity. Owned namespace/proxy/pointer proof, inactive preparation, framework/ABI gates, cleanup/quarantine, lifetime, lock and input behavior remain unchanged. No new private dispatch or scene setting mutation is introduced.

## Selected firmware facts and live boundary

`NAMED_CONFIGURATION_SCENE_TARGETS_23A355.json` records selected declarations and original Info.plist SHA256 values, separately from the baseline:

| Target | Application configurations | Exact Info.plist SHA256 |
| --- | --- | --- |
| Files — `com.apple.DocumentsApp` | `FilesMainScene`, `QuickLook` | `7f5c31594e50a5ef22065c93f60acf032efba6755616ba649bbcdd6354aa3223` |
| Mail — `com.apple.mobilemail` | `MainScene`, `ComposeScene`, `ConversationScene`, `QuickLookScene` | `07629d09383aaf90d7962b8fd3c59e1a5c8d8cb3cca6ec549966743a020819e3` |

Both selected manifests declare true multiple-scene support, only the normal application role, iPhone support and no extra root scene/window keys. These stock declarations do not prove that currently installed bundles match or that either client works. No raw Apple plist or binary is committed. Mail remains an untested example of this metadata shape.

Executable `ad6ece8c6cbde196cc4be1ee0b2910cd9c832134` passed all25 automated suites, including metadata2456, protocol176, admission87 and owner839 checks, iOS static analysis, Theos rootless arm64/arm64e compilation and downloaded-artifact/package/hash inspection. Fixtures cover counts, every declaration, exact names, field types/lengths, old-policy rejection, canonical reason/status/Boolean combinations, transport, freshness/identity binding and entry into unchanged ownership cleanup. See [VALIDATION_0.17.0.md](VALIDATION_0.17.0.md) for exact Actions/artifact digests and execution limits. These fixtures do not execute actual Files/Mail clients.

After successful automation, the indispensable new hardware gate is one representative configuration-list client: open Files normally once, return to NewTerm, select Files in PPO and request its small window. Check visible content and scrolling without opening, editing or deleting personal documents; close with X and reopen once. Leave Keep off for the default 15-second limit. The host report must record `declared-named-application-configurations` to establish that this new path ran. A metadata refusal instead needs its capability report and displayed message. No repeated ordinary Safari/Calendar/favorites test or test of every installed application is requested.

Native fixtures and macOS Intel CI cannot run the real iOS client/compositor path. No compatible physical Apple Silicon Mac is accessible for vphone-cli. General Dopamine/ElleKit compatibility and complete original feature parity remain unconfirmed. Recovery remains X/default timeout, the existing disable marker and manual respring for pinned uncertain resources; no automatic phone installation, respring, personal-data operation or other-tweak modification occurs.
