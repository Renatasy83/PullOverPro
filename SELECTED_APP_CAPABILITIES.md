# Selected-app installed metadata — 0.12.0

Work is isolated on debug/selected-app-capabilities. The verified0.11.0 Reminders source and all previous stable references remain preserved. This stage replaces a per-app rebuild requirement with conservative eligibility inspection of the installed, selected app. It does not implement every original feature or confirm new clients at runtime.

## Process and protocol boundary

An explicit floating-window tap queues inspect-scene through the existing bounded file mailbox. SpringBoard performs no bundle filesystem read, private LaunchServices getter, synchronous mailbox wait or subprocess launch. The mobile service enumerates at most4096 proxy identifiers, requires exactly one selected match and reads only that bundle's Info.plist. Inventory schema1 and normal launching remain unchanged; it does not collect all application manifests.

The new bundleURL dispatch is pinned to CoreServices UUID0FFF723A-7DE6-3705-B327-ADD82FAEF345. Exact23A355 LSBundleProxy -bundleURL at0x181627138 is a cached object getter. The actual object ancestry must include LSApplicationProxy and LSBundleProxy; the first declared method owner must be exactly LSBundleProxy with the checked two-argument object getter ABI. Even compatible subclass overrides are refused. The check runs on the helper main thread before the single new private dispatch site. Unsupported UUID/ABI becomes unknown without dispatch. No delegate/class name from a manifest is instantiated.

The file URL must be a local absolute .app URL without host/query/fragment/NUL/dot components. The final app directory and fixed Info.plist open with O_NOFOLLOW/O_NONBLOCK; the file must be regular and at most256KiB. Reads and post-read identity/size/timestamp checks are bounded. Parsing is immutable. Bundle paths, raw manifests, configuration names and personal records are not serialized. Filesystem metadata is advisory and not authenticated provenance.

The existing request nonce binds one response to one request. Capability schema1 has exactly seven normalized fields, copied nested strings, a genuine Boolean, a fixed policy/reason vocabulary, finite uptime and at most5s validity with0.1s skew tolerance. The service rechecks request expiry and disable state after work. Client timeout remains8s; the service's existing20s process alarm is unchanged. Invalid, mismatched, stale or overlong envelopes cannot reach scene construction. A nonce is correlation, not authentication or an entitlement grant.

## Conservative eligibility and scene ownership

A positive requires the same installed identifier, APPL package, iPhone family, no extension/background-only declaration, true multiple-scene support, exactly one application-role configuration and a small known scalar-key subset. Explicit no-multiple-scenes/non-iPhone/non-application/extension declarations are negative. Missing/ambiguous manifests, multiple configurations/roles or extra scene/window policy flags are unknown. Configurations alone are insufficient. Thus many listed/launchable apps intentionally remain unsupported.

All selected apps, including baseline apps, request inspection. A fresh explicit negative overrides the baseline. Valid unknown metadata, or an unavailable/old inspection service, can preserve only the exact Safari/Reminders/Contacts firmware baseline. Malformed, stale, mismatched or explicitly rejected responses never grant dynamic eligibility. A newly eligible nonbaseline client additionally requires the source and child specification's actual class to be exactly UIApplicationSceneSpecification, before dispatching specification methods. This avoids broadening the reviewed subclass/extension surface.

Admission freezes the identifier and normalized metadata independently of mutable caller input and records its basis in the host report. The existing unique-source, selected-original/selected-child equality, owned namespace, pointer inequality, verified proxy unwrap, inactive-before-UI, four-framework ABI/UUID, lock/data/lifetime, invalidation and quarantine rules remain. Neither an original scene nor its foreground/security settings are mutated. A manifest positive does not prove scene acceptance, event routing or compatible extensions.

## Upgrade lifecycle and diagnostics

An already-loaded PPO service is restarted with launchctl kickstart -k system/com.renatasy83.ppo.bridge during package configuration; an absent own job is bootstrapped. Only PPO's own label is addressed. Failure propagates; no respring or phone installation is run automatically. New lifetime, Keep, lock and cleanup behavior is not combined with this change.

The latest selected request produces capability-0.12.0.json with selected identifier, normalized result, status, scalar error and uptime. host-0.12.0.json records actual admission basis and scene lifecycle. Reports remain local; metadata results are not runtime compatibility claims. Keep defaults to off and the ordinary15-second timeout remains.

## Automated checks and necessary live boundary

Native fixtures cover conservative parsing/negative precedence/strict Booleans, malformed/stale/cross-app proofs, immutable ownership snapshots, temp-bundle binary/XML/symlink/FIFO/oversize failures, exact getter owner and zero-dispatch rejection, service freshness/disable changes and actual mailbox subprocess exchange. iOS Clang analysis and Theos rootless arm64/arm64e packaging are required before delivery. See the versioned validation report for actual results; no success is implied before CI completes.

CI cannot execute installed iOS bundles, launchd upgrade restart, SpringBoard/client rendering or Dopamine/ElleKit. No compatible physical Apple Silicon Mac is accessible for vphone-cli. After automation, one actual selected-app inspection and window operation is indispensable. Contacts is a useful previously untested baseline client; another simple-manifest app can exercise dynamic admission. A safe refusal is evidence too and does not justify overriding its manifest. No personal-record edit/call, other-tweak modification or intermediate reinstall loop is requested.

Recovery: X/default15-second timeout, /var/mobile/.ppo_disable and manual respring for pinned quarantine; if injection blocks startup, start Dopamine without injection and remove only this package. Tested0.11.0 remains the fallback.
