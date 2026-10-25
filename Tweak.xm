#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <dispatch/dispatch.h>

// Alpha 3: isolated interactive overlay. No app hosting or private APIs.
static UIWindow *ppoWindow = nil;
static UIViewController *ppoController = nil;
static UIButton *ppoHandle = nil;
static BOOL ppoExpanded = NO;

@interface PPOHandleTarget : NSObject
- (void)tapped:(id)sender;
- (void)panned:(UIPanGestureRecognizer *)recognizer;
@end

@implementation PPOHandleTarget
- (void)tapped:(id)sender {
    ppoExpanded = !ppoExpanded;
    [ppoHandle setTitle:(ppoExpanded ? @"PPO ✕" : @"PPO ▶") forState:UIControlStateNormal];
    CGRect f = ppoWindow.frame;
    f.size.width = ppoExpanded ? 160 : 78;
    ppoWindow.frame = f;
    NSLog(@"[PullOverPro Alpha3] handle %@", ppoExpanded ? @"expanded" : @"collapsed");
}
- (void)panned:(UIPanGestureRecognizer *)recognizer {
    if (!ppoWindow) return;
    CGPoint delta = [recognizer translationInView:ppoWindow.superview];
    CGRect f = ppoWindow.frame;
    f.origin.y += delta.y;
    CGFloat maxY = MAX(0, CGRectGetHeight(ppoWindow.windowScene.coordinateSpace.bounds) - CGRectGetHeight(f));
    f.origin.y = MAX(0, MIN(maxY, f.origin.y));
    ppoWindow.frame = f;
    [recognizer setTranslation:CGPointZero inView:ppoWindow.superview];
}
@end

static PPOHandleTarget *ppoTarget = nil;

static void PPOInstallOverlay(void) {
    if (ppoWindow) return;
    UIWindowScene *scene = nil;
    for (UIScene *candidate in UIApplication.sharedApplication.connectedScenes) {
        if ([candidate isKindOfClass:UIWindowScene.class] &&
            candidate.activationState == UISceneActivationStateForegroundActive) {
            scene = (UIWindowScene *)candidate;
            break;
        }
    }
    if (!scene) { NSLog(@"[PullOverPro Alpha3] No active UIWindowScene"); return; }

    ppoWindow = [[UIWindow alloc] initWithWindowScene:scene];
    ppoWindow.frame = CGRectMake(0, 170, 78, 44);
    ppoWindow.windowLevel = UIWindowLevelStatusBar + 1;
    ppoWindow.backgroundColor = UIColor.clearColor;
    ppoController = [UIViewController new];
    ppoController.view.backgroundColor = UIColor.clearColor;
    ppoWindow.rootViewController = ppoController;

    ppoHandle = [UIButton buttonWithType:UIButtonTypeSystem];
    ppoHandle.frame = CGRectMake(0, 0, 78, 44);
    ppoHandle.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    ppoHandle.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.83];
    ppoHandle.layer.cornerRadius = 12;
    [ppoHandle setTitle:@"PPO ▶" forState:UIControlStateNormal];
    [ppoHandle setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    ppoHandle.titleLabel.font = [UIFont boldSystemFontOfSize:13];
    ppoTarget = [PPOHandleTarget new];
    [ppoHandle addTarget:ppoTarget action:@selector(tapped:) forControlEvents:UIControlEventTouchUpInside];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:ppoTarget action:@selector(panned:)];
    [ppoHandle addGestureRecognizer:pan];
    [ppoController.view addSubview:ppoHandle];
    ppoWindow.hidden = NO;
    NSLog(@"[PullOverPro Alpha3] interactive overlay installed");
}

%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    NSLog(@"[PullOverPro Alpha3] SpringBoard hook reached");
    dispatch_async(dispatch_get_main_queue(), ^{ PPOInstallOverlay(); });
}
%end

%ctor {
    @autoreleasepool { NSLog(@"[PullOverPro Alpha3] loaded"); }
}
