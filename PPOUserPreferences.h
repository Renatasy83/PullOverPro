#pragma once
#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const PPOUserPreferencesDomain;
FOUNDATION_EXPORT NSString *const PPOUserPreferencesChangedNotification;

// Pure snapshots containing seventeen scalar keys and recentIdentifiers. Missing
// or malformed values use defaults; finite numeric values are clamped. Unknown
// keys are ignored by reads, never propagated into an output snapshot.
// recentIdentifiers is only PPO's own ordered choice cache: at most sixteen
// distinct copied ASCII identifiers. It never authorizes launch or hosting.
// keepWindowOpen defaults to YES for the persistent release UI. This is only a
// preference; the host still owns its activation/lock/data/marker/cleanup guards.
FOUNDATION_EXPORT NSDictionary<NSString *, id> *PPOUserPreferencesDefaults(void);
FOUNDATION_EXPORT NSDictionary<NSString *, id> *PPOUserPreferencesNormalize(id raw);

// Pure edit validation. Unlike normalization, edits reject unknown keys, bad
// types, nonfinite/out-of-range numbers and nonintegral windowSize/recentAppsCount.
// Empty edits are valid. Errors return nil without changing either input.
FOUNDATION_EXPORT NSDictionary<NSString *, id> *PPOUserPreferencesApplyingChanges(id current,
    id changes, NSError **error);

// Run storage operations on a serial worker, never the SpringBoard/UI thread.
// Only this exact domain/current-user/any-host is read or written. Reads return
// a normalized default snapshot on failure and set error. Writes validate all
// edits before I/O, update only the supplied known keys, synchronize and post
// the Darwin notification on success. No domain clear, favorite access, marker
// edit or personal-data deletion is performed. Concurrent writers need their
// own ordering; this interface does not promise a cross-process transaction.
FOUNDATION_EXPORT NSDictionary<NSString *, id> *PPOUserPreferencesRead(NSError **error);
FOUNDATION_EXPORT BOOL PPOUserPreferencesWriteChanges(id changes, NSError **error);
