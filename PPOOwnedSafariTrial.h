#import <UIKit/UIKit.h>
#import "PPOHostSessionSlot.h"

// Controlled independent-scene targets; class name retained from the Safari baseline.
// Never hosts or modifies an original scene.
// Replacement requires confirmed own-scene and own-workspace cleanup.
@interface PPOOwnedSafariTrial : NSObject <PPOHostedSession>
// Main-thread-only public presentation options, frozen before a session opens.
// This never reads preferences or changes a private scene configuration.
- (void)configurePresentationWithPreferences:(NSDictionary *)preferences;
@property(nonatomic,readonly) double drawerProgress;
@property(nonatomic,readonly) double drawerTravel;
- (BOOL)setDrawerProgress:(double)progress;
- (BOOL)finishDrawerOpen:(BOOL)open;
- (NSString *)openInScene:(UIWindowScene *)scene bundleIdentifier:(NSString *)bundleIdentifier
              displayName:(NSString *)displayName capability:(NSDictionary *)capability;
- (void)close;
@end
