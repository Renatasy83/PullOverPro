# Controlled additional application scenes — 0.11.0

The owned-scene path is extended from Safari to a small exact-firmware set:Safari(com.apple.mobilesafari), Reminders(com.apple.reminders) and Contacts(com.apple.MobileAddressBook). Eligibility is not a runtime compatibility claim. Only Safari has prior live evidence; the two new app clients require an actual phone gate. No other app is implicitly enabled by being enumerated or launchable.

## Eligibility evidence

SCENE_TARGETS_23A355.json records selected facts from the exact iPhone12,5 iOS26.0.1 build23A355 staged-system Info.plists, with source IPSW URL, verified mainOS member digest and per-Info SHA256. The existing APFS image was read without mounting or downloading again; no Apple binary or raw plist is included.

All three declare UIApplicationSupportsMultipleScenes=true, include iPhone device family1, and have exactly one UIWindowSceneSessionRoleApplication configuration. Reminders declares RemindersMainScene/TTRIWindowSceneController; Contacts declares ContactsSceneDelegate and LaunchScreen. These simple candidates do not add the extra secure-window flags found in Notes/Maps or the multiple app configurations of Files/Mail. Settings and several other stock apps explicitly declare no multiple-scene support. Configurations alone are insufficient:Books/Photos have configurations but support=false, so they remain excluded.

These are firmware facts, not proof that either app remains installed/unmodified on the phone or that its client accepts a hosted scene. UIKit chooses the app's configuration; PPO does not instantiate a guessed delegate/class or send new private selectors.

## Selected-identity ownership proof

PPOOwnedApplicationPolicy.h is an exact case-sensitive three-identifier policy shared by the UI, preflight and owner. Prefixes, casing variants, extensions, system processes, nil and nonstrings are refused. The owner accepts an explicit forBundleIdentifier: argument, copies it before private work, and independently requires both the original source client identity and the created child client identity to equal that selected value. Allowing a different eligible app is not sufficient. The copy prevents caller mutation during construction from changing the ownership proof.

Namespace/source inequality, UIKit application-role/specification checks, exact runtime proxy unwrapping, inactive-before-attachment guard, main-thread/firmware/ABI gates, owned cleanup, quarantine, deferred notification teardown, Keep and lock/data/scene guards remain. Private selector/setter surfaces are unchanged. Original scenes are read only and never hosted or invalidated. Historical PPOOwnedSafariTrial class/file names remain internal; labels/reports use the selected app's actual inventory name and identifier.

The active inventory/mobile service and package lifecycle scripts are unchanged in this stage. No bundleURL getter, additional Info.plist scan or service restart is introduced. Future dynamic capability discovery has separate requirements:actual CoreServices getter/owner/UUID validation, bounded file reads, normalized parser fields, lightweight launch membership refresh, and targeted restart of PPO's own persistent service when its executable changes. Do not combine those changes with this first non-Safari runtime gate or enable every enumerated app blindly.

## Automation and limits

Native fixtures preserve the earlier ownership/ABI/failure suite and add selected/source mismatches, wrong eligible child identities, unsupported requests before private access, caller mutation and100 mixed-application cleanup cycles. Source policy checks the exact policy against the selected JSON facts. Executable0bb57241e7aeb54a35b434e59f7b24bf844cc7c5 passed Actions run41214886266 with all17 suites, including790 ownership checks, plus iOS Clang analysis, Theos rootless arm64/arm64e compilation and package/lifecycle/license inspection. Artifact13047815553 contains one DEB; downloaded ZIP/DEB hashes and local payload inspection passed. See VALIDATION_0.11.0.md. None of these checks executes the actual additional app clients.

Native fixtures do not execute Reminders or Contacts. Real client admission, visible rendering, input, Keep, process/session cleanup and long-term behavior for each new app remain unconfirmed. Full Dopamine/ElleKit compatibility and final all-app functionality are not claimed. Safari's0.10.0 kept/lock/reuse baseline remains preserved; no phone operation or other-tweak change is made automatically.

## Essential phone gate after successful CI

Install manually and respring. First use Reminders if installed:open it normally once so a unique source exists, return to NewTerm, select Reminders in PPO and open its window. Observe content and try a short scroll or navigation without creating/completing/deleting reminders. Close with X and reopen once. Contacts is an alternative if Reminders is unavailable; view/scroll only, without editing contacts or initiating calls. Do not repeat Safari's already confirmed ordinary tests. Provide the actual app/result and /var/mobile/Library/Logs/PullOverPro/host-0.11.0.json. If no unique source exists, the operation remains a safe refusal.

Recovery remains X/default15-second timeout, /var/mobile/.ppo_disable, and manual respring for quarantine. Kept mode has no timed expiry. If injection prevents startup, use Dopamine without injection and remove only this package; tested0.10.0 remains the fallback. No personal records, contacts, reminders or other tweaks are modified by the port or its automation.

## Subsequent device result — 2026-10-31

The requested0.11.0 Reminders display/scroll/X/reopen gate is complete:the user confirms function and the supplied report contains two Reminders sessions with verified owned binding, manual/timeout closure, both invalidations returned and replacement allowed. Source0bb57241e7aeb54a35b434e59f7b24bf844cc7c5 is preserved as stable/verified-reminders-window-reuse. Contacts, Reminders Keep/lock and full platform compatibility remain unconfirmed. See DEVICE_VALIDATION.md. This addendum does not change the executable or imply another CI run. The next isolated metadata stage is SELECTED_APP_CAPABILITIES.md.
