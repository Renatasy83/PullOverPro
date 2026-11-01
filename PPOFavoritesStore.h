#pragma once
#import <Foundation/Foundation.h>

// Worker-only store for a private, absolute directory whose parent exists.
// Only favorites.plist is read or replaced. The directory must be owned by
// getuid() with mode 0700, and files must be single-link regular files owned by
// getuid() with mode 0600. Existing permissions are never changed.
// Missing data is a valid, immutable empty array; other failures return nil/NO.
// Commit uses a nonblocking directory lock and compares the current ordered
// identifiers with expected before atomically replacing the file. Cooperating
// writers must use the same directory lock; an editor that ignores the lock can
// race the final comparison and rename. Conflicts return NSPOSIXErrorDomain /
// ESTALE; lock contention returns EWOULDBLOCK.
// Both functions reject the main thread with EDEADLK before any file access.
// Paths are bounded to 4096 UTF-16 code units and 4096 UTF-8 bytes.
NSArray<NSString *> *PPOFavoritesLoad(NSString *directory, NSError **error);
BOOL PPOFavoritesCommit(NSString *directory, NSArray<NSString *> *expected,
                        NSArray<NSString *> *replacement, NSError **error);
