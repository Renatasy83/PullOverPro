#import <UIKit/UIKit.h>

// Explicit one-shot live-rendering experiment. No foreign scene geometry,
// foreground settings, keyboard deferral or input APIs are changed.
@interface PPOFloatingTrial : NSObject
- (NSString *)openInScene:(UIWindowScene *)scene bundleIdentifier:(NSString *)bundleIdentifier;
- (void)close;
@end
