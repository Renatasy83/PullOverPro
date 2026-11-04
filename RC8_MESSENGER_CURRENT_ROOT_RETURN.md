# RC8 Messenger current-root window return

Candidate1.0.7~rc8. This is the next necessary original-UI return test, not a confirmed restoration or a promise of duplicated Messenger content while a small window is active. Final source/run/hash/download evidence is recorded in OPENCODE_HANDOFF.md and validation after CI completes.

## New RC7 evidence

The supplied host-1.0.6.json retains three sessions: an unavailable-companion refusal, a stale captured-readiness refusal, then a timed owned-window session. Its final v1 helper state is phase4/flags147. In RC7,147 decodes to captured1 + owned-scope-seen2 + old-root-mismatch16 + unsupported-close128; migration4 and returned8 are absent. The v1 code sets16 only after the exact captured UIWindow is observed in a distinct identified PPO session but its old weak root is absent/different. Therefore injection, libnotify transport and public PPO-session recognition worked at the observed times, and the old-root condition prevented the return. It does not tell whether the old root was replaced or released. The user supplied no new visual description for RC7; do not infer its after-close pixels.

The owner again reports a distinct verified proxy/child, closed/unpinned/unpoisoned, controller/workspace invalidation returned and replacementAllowed=true. Own-object cleanup is separate from original-app visible restoration. RC6 content/touch/scroll remain user-confirmed, with its black original surface reported separately.

## Targeted change

The exact original UIWindow identity is preserved. Instead of requiring the pre-trial root pointer, the agent accepts its CURRENT root only when public UIKit proves: root exists, parentViewController is nil, viewIfLoaded is present and view.window is exactly that captured UIWindow. It does not force-load a view, assign rootViewController, resurrect an old controller or reparent another view/window. An unready root waits under the existing bounded observation rather than immediately causing the v1 mismatch refusal. A different window is still refused.

The same window is retained only for the bounded disconnect handoff so it cannot disappear solely between the closing-scene callback and deferred validation. That reference is released on completion/refusal/timer expiry; the timer starts at an identified owned scope or matching migration and never resets. Allocation failure/20second expiry fail closed. The return waits one main-queue turn after the exact PPO session disconnect, then rechecks same window, current public root ownership, still-connected original normal target, screen and owned-or-detached closing association. After public windowScene assignment it checks current ownership/readback again.

When app/protected-data/target state already allow visible foreground return, RC8 avoids unnecessarily hiding the window before moving it. It still hides/defers visibility for inactive/protected contexts and makes no key-window/focus or app activation request. Current app UI state travels with its own window; it is not rolled back to an earlier controller. Visible return/input remain a phone gate.

## Versioned telemetry and retained guards

Schema2 and channel com.renatasy83.ppo.messenger.return.v2 isolate the new semantics. Bit16 now means a legitimately observed current-root replacement during an accepted migration; in old v1 it meant a refusal. Old producer state cannot authorize v2 readiness. Snapshot includes transportSchema2. Other flags:1 captured,2 owned scope seen,4 accepted migration,8 return readback,32 deferred visibility,64 exception,128 refusal/unsupported. Logical readback is not proof of pixels/input.

The Messenger-only hookless component, exact installed585.0.0/build1101076820 Info.plist SHA256, UIKit UUID, public session-prefix identification, normal foreground source/layers, no cold fallback, no Keep/resize/minimize/pan,15second trial maximum/8second render deadline and strict private owner/proxy/cleanup/quarantine remain. Private owner/admission/bridge implementations are unchanged. No screenshots, app Data writes, private app selectors, root/controller assignments, synthetic input or automatic phone actions. The server borrowedSourceMutationRequested flag still describes FBScene operations only; the companion's public UIWindow return is separately reported.

## Automated evidence and limits

The updated pure state/transport suite has171 local ASan/UBSan checks, including legitimately replaced current roots, waiting unowned/unattached roots, foreign-window refusal, all restoration conditions, failed readback/replay/clocks and rejection of old v1 state. Source policy rejects root assignments, screenshots/focus/private selectors and enforces current ownership/exact window gates. Full37-suite/Clang/Theos/two-dylib/filter/rootless evidence is recorded after CI, not assumed from configuration.

These fixtures cannot create Messenger's real UIKit hierarchy. Actual loaded/current-root attachment, window lifetime after release, protected visibility, scene disconnect order, source return and touch remain untested for RC8. General Dopamine/ElleKit or complete Messenger compatibility is not confirmed. No compatible physical Apple Silicon Mac is available for vphone-cli. No raw user report or app plist is published.

## Necessary device gate only

After manual install and one respring, manually close Messenger from the app switcher and reopen it normally, to load v2 rather than the still-running v1 library. Open one timed PPO window promptly after Messenger is visible. Let it close, wait about two seconds and observe whether the original full-screen Messenger returns/responds. No broad repeat of small-window input or other app tests is requested.

Send /var/mobile/Library/Logs/PullOverPro/host-1.0.7.json with that visual result. A helper-readiness refusal should produce the host report; stop rather than repeat loops. An earlier verification failure needs capability-1.0.7.json instead. During-trial black original background may remain; this gate concerns AFTER-close return. Do not collect conversations/Data or modify the app bundle.

Recovery remains /var/mobile/.ppo_disable plus manual respring, or known reboot/Dopamine without injection/uninstall-only-PPO if unusable. Disabling injection also disables the companion. Previous RC7/RC6/RC5/RC4/stable/main/recovery remain accessible with defects scoped; package GPL-3.0/original attribution is preserved. No automatic install/respring/process kill or personal-data/other-tweak modification was performed.
