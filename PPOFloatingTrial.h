#import <UIKit/UIKit.h>
#import "PPOHostSessionSlot.h"

// One live-rendering session; replacement requires confirmed cleanup. No foreign scene geometry,
// foreground settings or keyboard deferral APIs are changed. UIView interaction
// flags are reported as properties, never as proof of remote input blocking.
@interface PPOFloatingTrial : NSObject <PPOHostedSession>
- (NSString *)openInScene:(UIWindowScene *)scene bundleIdentifier:(NSString *)bundleIdentifier
              displayName:(NSString *)displayName;
- (void)close;
@end
