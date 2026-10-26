#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <dispatch/dispatch.h>

// Alpha 4: interactive side panel UI only. No application hosting/private APIs.
static UIWindow *ppoWindow;
static UIViewController *ppoController;
static UIButton *ppoHandle;
static UIView *ppoPanel;
static BOOL ppoExpanded = NO;
static const CGFloat PPOClosedWidth = 78;
static const CGFloat PPOOpenWidth = 218;
static const CGFloat PPOPanelHeight = 188;

@interface PPOHandleTarget : NSObject
- (void)tapped:(id)sender;
- (void)panned:(UIPanGestureRecognizer *)recognizer;
@end

@implementation PPOHandleTarget
- (void)tapped:(id)sender {
    if (!ppoWindow || !ppoHandle || !ppoPanel) return;
    ppoExpanded = !ppoExpanded;
    [ppoHandle setTitle:(ppoExpanded ? @"PPO ✕" : @"PPO ▶") forState:UIControlStateNormal];
    CGRect frame = ppoWindow.frame;
    frame.size.width = ppoExpanded ? PPOOpenWidth : PPOClosedWidth;
    frame.size.height = ppoExpanded ? PPOPanelHeight : 44;
    CGFloat maxY = MAX(0, CGRectGetHeight(ppoWindow.windowScene.coordinateSpace.bounds) - CGRectGetHeight(frame));
    frame.origin.y = MAX(0, MIN(maxY, frame.origin.y));
    ppoWindow.frame = frame;
    ppoController.view.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    ppoPanel.hidden = !ppoExpanded;
    NSLog(@"[PullOverPro Alpha4] panel %@", ppoExpanded ? @"open" : @"closed");
}
- (void)panned:(UIPanGestureRecognizer *)recognizer {
    if (!ppoWindow) return;
    CGPoint delta = [recognizer translationInView:ppoWindow];
    CGRect frame = ppoWindow.frame;
    frame.origin.y += delta.y;
    CGFloat maxY = MAX(0, CGRectGetHeight(ppoWindow.windowScene.coordinateSpace.bounds) - CGRectGetHeight(frame));
    frame.origin.y = MAX(0, MIN(maxY, frame.origin.y));
    ppoWindow.frame = frame;
    [recognizer setTranslation:CGPointZero inView:ppoWindow];
}
@end

static PPOHandleTarget *ppoTarget;

static UILabel *PPOLabel(NSString *text, CGFloat y) {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(12, y, PPOOpenWidth - 24, 28)];
    label.text = text;
    label.textColor = UIColor.whiteColor;
    label.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    label.textAlignment = NSTextAlignmentLeft;
    return label;
}

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
    if (!scene) { NSLog(@"[PullOverPro Alpha4] no active scene"); return; }

    ppoWindow = [[UIWindow alloc] initWithWindowScene:scene];
    ppoWindow.frame = CGRectMake(0, 170, PPOClosedWidth, 44);
    ppoWindow.windowLevel = UIWindowLevelStatusBar + 1;
    ppoWindow.backgroundColor = UIColor.clearColor;
    ppoController = [UIViewController new];
    ppoController.view.backgroundColor = UIColor.clearColor;
    ppoWindow.rootViewController = ppoController;

    ppoPanel = [[UIView alloc] initWithFrame:CGRectMake(0, 44, PPOOpenWidth, PPOPanelHeight - 44)];
    ppoPanel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.88];
    ppoPanel.layer.cornerRadius = 12;
    ppoPanel.layer.masksToBounds = YES;
    [ppoPanel addSubview:PPOLabel(@"PullOver Pro • Alpha 4", 8)];
    [ppoPanel addSubview:PPOLabel(@"Panou lateral: funcțional", 43)];
    [ppoPanel addSubview:PPOLabel(@"Aplicații flotante: în lucru", 76)];
    [ppoPanel addSubview:PPOLabel(@"Glisează mânerul pentru mutare", 109)];
    ppoPanel.hidden = YES;
    [ppoController.view addSubview:ppoPanel];

    ppoHandle = [UIButton buttonWithType:UIButtonTypeSystem];
    ppoHandle.frame = CGRectMake(0, 0, PPOClosedWidth, 44);
    ppoHandle.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.88];
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
    NSLog(@"[PullOverPro Alpha4] side panel installed");
}

%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    NSLog(@"[PullOverPro Alpha4] SpringBoard hook reached");
    dispatch_async(dispatch_get_main_queue(), ^{ PPOInstallOverlay(); });
}
%end

%ctor {
    @autoreleasepool { NSLog(@"[PullOverPro Alpha4] loaded"); }
}
