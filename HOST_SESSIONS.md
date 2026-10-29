#0.8.0 Controlled floating sessions

This is a development build, not the final port. The user confirmed Safari rendering, control interaction, keyboard/navigation, manual close, timeout close, and the requested Safari-over-NewTerm scenario on0.7.2. The additional runtime observations required here are repeated presenter sessions and Settings hosting.

## Behavior

The picker and separate foreground-launch action remain. "Deschide în fereastră" hosts the selected Safari or Settings application only if an existing, unique FBScene passes the same exact dual-identity/receiver ABI/framework UUID checks. It does not create an app scene, launch an app into the background, change its foreground settings, force key-window/first-responder state, or use event-deferral APIs.

A resource-free refusal can be retried after opening the app normally. One session is retained before any private call can reenter UIKit. While it is active, a second session is refused. A new session may be explicitly adopted after confirmed presenter invalidation and UI cleanup. Unconfirmed cleanup or state-inspection exceptions poison the slot and retain the old object; no automatic cleanup retry or replacement occurs.

The existing15-second timeout, X-close, drag header, disable-marker checks and host-scene/protected-data cleanup paths remain. No other apps are enabled in this first expansion. The legacy Diagnostic API report remains a Safari-only read preflight; the hosting session's own report covers the selected permitted target.

## Reports

host-0.8.0.json in /var/mobile/Library/Logs/PullOverPro uses schema3. Each session has a UUID and exact selected bundle identifier. The report retains the last snapshot of up to8 sessions, each with up to16 lifecycle events. History snapshots never contain history themselves. Storage and JSON serialization occur on the existing ordered worker queue; cached dictionaries are immutable. No URLs, typed content, screenshots or touch coordinates are recorded.

UIView interaction flags remain literal property values; inputBlockingGuaranteed=false. Human observations of actual Safari input are documented separately. The JSON does not instrument event ownership or assert full runtime compatibility.

## Automated scope

Native Foundation session-slot fixtures cover pre-open/active refusal, explicit clean replacement, uncertain cleanup, status exceptions, reentrancy, thread rejection and100 replacement cycles. The existing actual presenter adapter fixtures also run100 create/activate/invalidate cycles against fake receivers. These exercise implementation/ownership rules, not UIKit/WindowServer.

CI additionally runs strict Clang analysis (including the UIKit implementation), existing parser/ABI/transport/protocol/service/subprocess/lifecycle suites, sanitizers, Theos rootless arm64/arm64e compilation, payload/architecture/license/lifecycle inspection and validation report generation. Existing private dispatch sites/selectors are not expanded.

## Single device gate after successful CI

Keep the working0.7.2 package in Filza. Install only the artifact identified for the successful source commit and respring manually. Open Safari and Settings normally once, then return to NewTerm.

1. Select Settings in PPO, without pressing the separate foreground-launch action. Press "Deschide în fereastră", observe rendering and scroll without changing any setting, then close X.
2. Reopen Settings without respring. Allow the15-second timeout.
3. Select Safari, reopen its window over NewTerm and check the previously working interaction. A second simultaneous session must be refused.
4. Share observed behavior and host-0.8.0.json. If a session reports unknown cleanup, stop; do not keep retrying.

Recovery is unchanged: responsive phone — create /var/mobile/.ppo_disable; blocked SpringBoard — force restart, enable Dopamine without tweak injection and uninstall only com.renatasy83.pulloverpro.diagnostic. No installation/respring/reboot or personal-data deletion is automated. No compatible physical Apple Silicon Mac is accessible for vphone-cli; the Intel Actions runner is a build/native-fixture host only.

Long-lived windows, other apps, rotation, app death, lock/unlock and full compatibility are not established by this build or the previous observations.
