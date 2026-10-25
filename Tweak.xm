#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <dispatch/dispatch.h>

// Alpha 2: reversible, visual proof of injection.
// No private window-hosting APIs or additional UIWindow instances.
static NSString *const kAlpha2EnabledKey = @"com.renatasy83.pulloverpro.alpha2.enabled";
static const NSInteger kAlpha2Tag = 260102;

static void PPOInstallIndicator(void) {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kAlpha2EnabledKey] == NO) {
        // Opt-in via preference key; defaults to OFF for safety.
        NSLog(@"[PullOverPro Alpha2] injection active, indicator disabled by default");
        return;
    }
    UIWindow *window = nil;
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) continue;
        UIWindowScene *windowScene = (UIWindowScene *)scene;
        if (windowScene.activationState != UISceneActivationStateForegroundActive) continue;
        for (UIWindow *candidate in windowScene.windows) {
            if (!candidate.hidden && candidate.rootViewController) { window = candidate; break; }
        }
        if (window) break;
    }
    if (!window || [window viewWithTag:kAlpha2Tag]) {
        NSLog(@"[PullOverPro Alpha2] no eligible window or already installed");
        return;
    }
    UILabel *indicator = [[UILabel alloc] initWithFrame:CGRectMake(8, 110, 74, 24)];
    indicator.tag = kAlpha2Tag;
    indicator.text = @"PPO A2";
    indicator.textColor = UIColor.whiteColor;
    indicator.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.75];
    indicator.font = [UIFont boldSystemFontOfSize:11];
    indicator.textAlignment = NSTextAlignmentCenter;
    indicator.layer.cornerRadius = 8;
    indicator.layer.masksToBounds = YES;
    indicator.userInteractionEnabled = NO;
    indicator.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    [window addSubview:indicator];
    NSLog(@"[PullOverPro Alpha2] indicator installed");
}

%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    NSLog(@"[PullOverPro Alpha2] SpringBoard launch hook reached");
    dispatch_async(dispatch_get_main_queue(), ^{
        PPOInstallIndicator();
    });
}
%end

%ctor {
    @autoreleasepool {
        NSLog(@"[PullOverPro Alpha2] tweak loaded");
    }
}
