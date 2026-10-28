#import <Foundation/Foundation.h>

// Call only on the service's main thread. The service owns its execution alarm.
// Returns a schema-1 inventory, or nil if any runtime contract is unsupported.
// An inventory entry is not a guarantee that the app can launch or be hosted.
NSDictionary *PPOWorkspaceRefresh(void);

// The caller MUST verify exact identifier membership in a freshly validated
// inventory before calling. No scene hosting, entitlement changes or subprocesses.
// YES means LaunchServices accepted the request, not that a window appeared.
BOOL PPOWorkspaceLaunch(NSString *identifier, NSString **failureCode);
