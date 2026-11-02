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
// Expanded default drawer has no floating toolbar. Other presets retain it.
@property(nonatomic,readonly) BOOL classicLayout;
// Model geometry in scene coordinates, clipped to the screen. It is not a
// presentation-layer/input guarantee during an in-flight UIKit animation.
@property(nonatomic,readonly) CGRect drawerVisibleFrameInScene;
// Main-thread, synchronous public-UI update hook. Use weak/global captures.
// The callback must not perform private scene operations; close clears it.
@property(nonatomic,copy) void (^presentationDidChange)(void);
- (BOOL)setDrawerProgress:(double)progress;
- (BOOL)finishDrawerOpen:(BOOL)open;
- (NSString *)openInScene:(UIWindowScene *)scene bundleIdentifier:(NSString *)bundleIdentifier
              displayName:(NSString *)displayName capability:(NSDictionary *)capability;
- (void)close;
@end
