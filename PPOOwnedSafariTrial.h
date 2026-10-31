#import <UIKit/UIKit.h>
#import "PPOHostSessionSlot.h"

// Controlled independent-scene targets; class name retained from the Safari baseline.
// Never hosts or modifies an original scene.
// Replacement requires confirmed own-scene and own-workspace cleanup.
@interface PPOOwnedSafariTrial : NSObject <PPOHostedSession>
- (NSString *)openInScene:(UIWindowScene *)scene bundleIdentifier:(NSString *)bundleIdentifier
              displayName:(NSString *)displayName;
- (void)close;
@end
