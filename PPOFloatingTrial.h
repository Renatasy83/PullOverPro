#import <UIKit/UIKit.h>

// Explicit one-shot live-rendering experiment. No foreign scene geometry,
// foreground settings or keyboard deferral APIs are changed. UIView interaction
// flags are reported as properties, never as proof of remote input blocking.
@interface PPOFloatingTrial : NSObject
- (NSString *)openInScene:(UIWindowScene *)scene bundleIdentifier:(NSString *)bundleIdentifier;
- (void)close;
@end
