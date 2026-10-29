#import <UIKit/UIKit.h>

// Explicit one-shot live-rendering experiment. No foreign scene geometry,
// foreground settings or keyboard deferral APIs are changed. Touch acceptance
// defaults off and uses only the public UIKit userInteractionEnabled property.
@interface PPOFloatingTrial : NSObject
- (NSString *)openInScene:(UIWindowScene *)scene bundleIdentifier:(NSString *)bundleIdentifier;
- (void)close;
@end
