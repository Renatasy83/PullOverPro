#import <UIKit/UIKit.h>
#import "PPOHostSessionSlot.h"

// Safari-only independent scene trial. Never hosts or modifies the original scene.
// Replacement requires confirmed own-scene and own-workspace cleanup.
@interface PPOOwnedSafariTrial : NSObject <PPOHostedSession>
- (NSString *)openInScene:(UIWindowScene *)scene bundleIdentifier:(NSString *)bundleIdentifier
              displayName:(NSString *)displayName;
- (void)close;
@end
