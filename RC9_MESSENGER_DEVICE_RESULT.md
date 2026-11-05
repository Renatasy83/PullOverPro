# RC9 Messenger result — two timed windows and successful return

The user supplied `host-1.0.8.json` and confirmed that the requested test works. The requested procedure was two consecutive timed PPO Messenger windows in the same app process, with normal full-screen return after each. No raw report, application content or personal Data is published here.

## Aggregate observations

The report retains two distinct `com.facebook.Messenger` sessions on version `1.0.8~rc9`:

| Session | Window shown uptime | Close-returned uptime | Duration | Helper result |
| --- | ---: | ---: | ---: | --- |
| First | 56076.71146587501 | 56091.737115625 | 15.025650 seconds | Schema3, phase3, flags31 |
| Second | 56103.853871750005 | 56118.87808433334 | 15.024213 seconds | Schema3, phase3, flags15 |

Both close reasons are `timeout`, with timed lifetime mode. Both owners report a verified proxy matching their created child and not the borrowed original source. Controller/workspace invalidation returned, `closed=true`, `pinned=false`, `poisoned=false`, and `replacementAllowed=true`. Each final hosted-source sample has one active, nonbackgrounded layer before closure.

In schema3, phase3 is the companion's logical Restored/readback result. Flags15 decode to captured1 + owned-session-seen2 + accepted migration4 + public original-window/current-root return readback8. First-session flags31 add bit16. Neither session reports refusal128, exception64 or deferred-visibility32. `ready=false` is expected after consuming and completing a trial; it is not a preparation failure.

## What bit16 establishes

RC9 sets bit16 when the prior weak root baseline is absent **or** differs from the window's current root at the accepted migration check. CurrentRootOwned still verifies that the current root/view belong to the exact tracked original UIWindow. The first session therefore exercises an accepted missing/different root-baseline condition. It does not distinguish baseline release from an actual controller replacement, establish exactly when a replacement occurred, or show an old root being restored.

Rearming a completed session resets its flags and updates the root comparison baseline. Second-session flags15 are consistent with that behavior; absence of bit16 in the second session is not evidence of a regression.

## Confirmation and limits

The user's success confirmation supplies the visual/functional outcome for the requested repeated timed-window test. Together with both helper readbacks and clean owned-scene teardown, this supports a scoped RC9 repeated-window/restoration result on the reported device/app/profile.

The JSON contains no process ID, generation echo or boot ID. Uninterrupted same-process continuity is supported by the requested procedure and user response, rather than independently proven by these metadata fields. Do not claim that the report authenticates process continuity or the Darwin notification sender.

The first final original-scene sample is at56091.72310620834 and the second at56118.375468583334; both precede their respective close-returned events. They show two layers, active and not backgrounded, but do not establish post-close pixels. Three return-observation events follow each closure; the helper is a report/session snapshot rather than a per-event history. Its integer packed timestamp can remain unchanged after the bounded timer stops. Visual/input confirmation comes from the user, not those layer counts or timestamps.

Manual-X closure, Keep/long duration, minimize/resize, lock/protected/background transitions, other app versions and global Dopamine/ElleKit compatibility are not established by this test. The conservative `runtimeCompatibilityConfirmed=false` field does not contradict the scoped successful result. No new phone action or repeated RC9 test is needed merely to record this evidence.

## Preserved recovery candidate

The exact tested RC9 candidate remains source `d183e1b28caa7c4e1f380decab96608b74ff6cbf`, macOS Actions41942732626 with38 suites, archive commit `3a1eecdbffba0c576ea7790af541bb2db68b192c`. DEB321808bytes, SHA256 `fd50b7bcf8671903733f574a5103d5dc4786d8eab25e9b96121cdea32fe0a502`.

Preserve that candidate before broader lifetime changes. The result above does not authorize removing the existing lifetime, ownership or cleanup gates without a separately implemented and verified stage.
