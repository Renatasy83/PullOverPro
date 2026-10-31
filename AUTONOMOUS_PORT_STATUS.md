# Autonomous port status — 2026-10-31

Current isolated development:0.10.0~dev.keep1 on debug/kept-safari-window. New capability:explicit Păstrează keeps an independently owned Safari window open after the normal15-second deadline. Default sessions still time out. This remains an incomplete Safari-only development candidate; current CI is pending and the new lifetime/lock behavior is not device-confirmed.

## Preserved tested source

Executable025cf5d835d4454c60c771fea19e17e60c126add is preserved as stable/verified-safari-ownscene-input-reuse and stable/verified-safari-ownscene-timeout. Its successful Actions run41165469987 and artifact13028552395 remain available. The older debug/owned-safari-scene source remains the0.9.1 fallback. Main remains Alpha4 at af336d84a6b4812e6b6406af87803fb15bf29c3b; previous picker/launch/rendering baselines and GPL attribution remain untouched.

## Latest actual device evidence

Target:iPhone12,5, iOS26.0.1 build23A355, user-reported Dopamine rootless, screenshot-confirmed ElleKit1.2; exact Dopamine version unknown. The latest0.9.1 report contains five sessions including the prior timeout, so four are newly supplied. Two close by timeout and three with X. All have verified own proxy binding, both invalidations returned, closed/unpinned/unpoisoned state and replacement allowed. The shortest close-to-next-prepare gap is about1.999 seconds.

The user explicitly confirms manual X, reopening, actual interaction/web navigation and rendering over another foreground app. The new scene has layers while the original is logically backgrounded without layers. These establish the stated operations, not full platform compatibility. Keyboard routing, lock/orientation, prolonged lifetime, other hosted apps and global client/session cleanup remain unverified. Raw phone JSON is not published. Historical watchdog causes remain unconfirmed because the original IPS reports were not supplied. See DEVICE_VALIDATION.md.

## Current change and automation

Keep is explicit and cannot revive a timed-out or failed session. A side-effect-free lifecycle policy preserves15-second default and2-second initial activation grace, while lock/pending/unknown state, data loss, host inactivity, scene invalidity/inactivity and invalid clocks close the session. Size changes close rather than add unverified rotation handling. Existing input flags/key-window ownership, Safari-only target and owned cleanup/quarantine rules remain.

A read-only lock adapter uses only the exact23A355 existing-manager getter and two Boolean flags. Four loaded framework UUIDs, main-thread enforcement and actual method-table ABI checks gate dispatch. The verified Foundation lock-state notification requests conservative closure; no private observer protocol or setter is used. Polling/notifications do not establish zero lock-transition frames. A kept window has no timer expiry; X and safety closures remain essential.

Local lifetime policy tests410 checks with G++ ASan/UBSan, source policy and lifecycle24 checks passed. CI will run the new native lock fixtures, all existing suites, iOS Clang analysis, Theos rootless arm64/arm64e build and package/lifecycle/license checks. See KEPT_SAFARI_WINDOW.md for exact firmware evidence and limits. Linux and macOS Intel CI do not execute SpringBoard. No compatible physical Apple Silicon Mac is accessible for vphone-cli.

## Remaining indispensable live gate

After successful CI, use one package: first test lock/unlock closure in unchanged default15-second mode. Only if that closes correctly with no window remaining on the lock screen, reopen and press Păstrează within15 seconds, keep it for at least30 seconds, close with X and reopen once. Provide visual results and /var/mobile/Library/Logs/PullOverPro/host-0.10.0.json. Ordinary input/navigation tests already confirmed on0.9.1 need not be repeated.

Recovery:X;15-second timeout in default mode; /var/mobile/.ppo_disable to prevent new attempts/request closure; manual respring for quarantine. Kept mode deliberately has no timed expiry. If injection prevents startup, use Dopamine without injection and remove only this package. Nothing is installed or resprung automatically; personal data and other tweaks are not modified. Full Dopamine/ElleKit compatibility and final all-app functionality remain unconfirmed.
