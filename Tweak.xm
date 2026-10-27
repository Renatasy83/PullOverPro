#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <dispatch/dispatch.h>

// Diagnostic baseline: public UIKit only. No SpringBoard hooks or private calls.
// Overlay requires .ppo_enable_overlay; .ppo_disable takes precedence.
static UIWindow *ppoWindow;
static UIViewController *ppoController;
static UIButton *ppoHandle;
static UIView *ppoPanel;
static BOOL ppoExpanded = NO;
static BOOL ppoLightTheme = NO;
static UILabel *ppoStatus;
static const CGFloat PPOClosedWidth = 78;
static const CGFloat PPOOpenWidth = 218;
static const CGFloat PPOPanelHeight = 310;

@interface PPOHandleTarget : NSObject
- (void)tapped:(id)sender;
- (void)panned:(UIPanGestureRecognizer *)recognizer;
- (void)toggleTheme:(id)sender;
- (void)resetPosition:(id)sender;
- (void)selectFavorite:(UIButton *)sender;
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
    NSLog(@"[PPO 0.5.5] panel %@", ppoExpanded ? @"open" : @"closed");
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
- (void)toggleTheme:(id)sender {
    ppoLightTheme = !ppoLightTheme;
    UIColor *background = ppoLightTheme ? [UIColor colorWithWhite:0.94 alpha:0.96] : [[UIColor blackColor] colorWithAlphaComponent:0.88];
    UIColor *foreground = ppoLightTheme ? UIColor.blackColor : UIColor.whiteColor;
    ppoPanel.backgroundColor = background;
    ppoHandle.backgroundColor = background;
    [ppoHandle setTitleColor:foreground forState:UIControlStateNormal];
    for (UIView *v in ppoPanel.subviews) {
        if ([v isKindOfClass:UILabel.class]) ((UILabel *)v).textColor = foreground;
        if ([v isKindOfClass:UIButton.class]) [(UIButton *)v setTitleColor:foreground forState:UIControlStateNormal];
    }
    ppoStatus.text = ppoLightTheme ? @"Temă: deschisă" : @"Temă: închisă";
}
- (void)selectFavorite:(UIButton *)sender {
    NSArray<NSString *> *names = @[@"Safari", @"Mesaje", @"Muzică"];
    if (sender.tag < 0 || sender.tag >= (NSInteger)names.count) return;
    ppoStatus.text = [NSString stringWithFormat:@"Selectat: %@ (test UI)", names[(NSUInteger)sender.tag]];
    NSLog(@"[PPO 0.5.5] favorite selected: %@", names[(NSUInteger)sender.tag]);
}
- (void)resetPosition:(id)sender {
    if (!ppoWindow) return;
    CGRect frame = ppoWindow.frame;
    frame.origin.y = 170;
    CGFloat maxY = MAX(0, CGRectGetHeight(ppoWindow.windowScene.coordinateSpace.bounds) - CGRectGetHeight(frame));
    frame.origin.y = MIN(frame.origin.y, maxY);
    ppoWindow.frame = frame;
    ppoStatus.text = @"Poziție resetată";
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

static void PPOCommitOverlay(UIWindow *window, UIViewController *controller,
                             PPOHandleTarget *target, UIView *panel,
                             UILabel *status, UIButton *handle) {
    ppoWindow = window;
    ppoController = controller;
    ppoTarget = target; // UIControl does not retain its action target.
    ppoPanel = panel;
    ppoStatus = status;
    ppoHandle = handle;
}

static void PPOBuildOverlay(UIWindowScene *scene) {
    NSLog(@"[PPO 0.5.5] ui-build-begin");
    UIWindow *ppoWindow = [[UIWindow alloc] initWithWindowScene:scene];
    ppoWindow.frame = CGRectMake(0, 170, PPOClosedWidth, 44);
    ppoWindow.windowLevel = UIWindowLevelStatusBar + 1;
    ppoWindow.backgroundColor = UIColor.clearColor;
    UIViewController *ppoController = [UIViewController new];
    ppoController.view.backgroundColor = UIColor.clearColor;
    ppoWindow.rootViewController = ppoController;
    // Initialize the action target before attaching any favorite buttons.
    PPOHandleTarget *ppoTarget = [PPOHandleTarget new];

    UIView *ppoPanel = [[UIView alloc] initWithFrame:CGRectMake(0, 44, PPOOpenWidth, PPOPanelHeight - 44)];
    ppoPanel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.88];
    ppoPanel.layer.cornerRadius = 12;
    ppoPanel.layer.masksToBounds = YES;
    [ppoPanel addSubview:PPOLabel(@"PullOver Pro • Diagnostic 0.5.5", 8)];
    [ppoPanel addSubview:PPOLabel(@"Favorite (test interfață)", 43)];
    NSArray<NSString *> *favorites = @[@"Safari", @"Mesaje", @"Muzică"];
    for (NSUInteger i = 0; i < favorites.count; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.frame = CGRectMake(10, 72 + (CGFloat)i * 34, PPOOpenWidth - 20, 30);
        button.tag = (NSInteger)i;
        button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [button setTitle:[NSString stringWithFormat:@"  %@", favorites[i]] forState:UIControlStateNormal];
        [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        [button addTarget:ppoTarget action:@selector(selectFavorite:) forControlEvents:UIControlEventTouchUpInside];
        [ppoPanel addSubview:button];
    }
    UILabel *ppoStatus = PPOLabel(@"Atinge un favorit pentru test", 182);
    [ppoPanel addSubview:ppoStatus];
    UIButton *theme = [UIButton buttonWithType:UIButtonTypeSystem];
    theme.frame = CGRectMake(10, 218, 92, 32);
    [theme setTitle:@"Temă" forState:UIControlStateNormal];
    [theme setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [theme addTarget:ppoTarget action:@selector(toggleTheme:) forControlEvents:UIControlEventTouchUpInside];
    [ppoPanel addSubview:theme];
    UIButton *reset = [UIButton buttonWithType:UIButtonTypeSystem];
    reset.frame = CGRectMake(110, 218, 98, 32);
    [reset setTitle:@"Recentrare" forState:UIControlStateNormal];
    [reset setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [reset addTarget:ppoTarget action:@selector(resetPosition:) forControlEvents:UIControlEventTouchUpInside];
    [ppoPanel addSubview:reset];
    ppoPanel.hidden = YES;
    [ppoController.view addSubview:ppoPanel];

    UIButton *ppoHandle = [UIButton buttonWithType:UIButtonTypeSystem];
    ppoHandle.frame = CGRectMake(0, 0, PPOClosedWidth, 44);
    ppoHandle.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.88];
    ppoHandle.layer.cornerRadius = 12;
    [ppoHandle setTitle:@"PPO ▶" forState:UIControlStateNormal];
    [ppoHandle setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    ppoHandle.titleLabel.font = [UIFont boldSystemFontOfSize:13];
    [ppoHandle addTarget:ppoTarget action:@selector(tapped:) forControlEvents:UIControlEventTouchUpInside];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:ppoTarget action:@selector(panned:)];
    [ppoHandle addGestureRecognizer:pan];
    [ppoController.view addSubview:ppoHandle];

    NSLog(@"[PPO 0.5.5] ui-built; showing");
    ppoWindow.hidden = NO;
    PPOCommitOverlay(ppoWindow, ppoController, ppoTarget, ppoPanel, ppoStatus, ppoHandle);
    NSLog(@"[PPO 0.5.5] ui-visible");
}

static BOOL ppoScheduled;
static BOOL ppoStopped;
static NSUInteger ppoAttempts;
static id ppoSceneObserver;

static BOOL PPOOverlayAllowed(void) {
    NSFileManager *files = NSFileManager.defaultManager;
    return ![files fileExistsAtPath:@"/var/mobile/.ppo_disable"] &&
           [files fileExistsAtPath:@"/var/mobile/.ppo_enable_overlay"];
}

// Main queue only, at most three attempts per process; never wait for a scene.
static void PPOScheduleOverlay(void) {
    if (ppoScheduled || ppoStopped || ppoWindow) return;
    ppoScheduled = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
                   dispatch_get_main_queue(), ^{
        ppoScheduled = NO;
        if (ppoStopped || ppoWindow) return;
        if (!PPOOverlayAllowed()) { ppoStopped = YES; return; }
        @try {
            ppoAttempts++;
            UIWindowScene *scene = nil;
            for (UIScene *candidate in UIApplication.sharedApplication.connectedScenes) {
                if ([candidate isKindOfClass:UIWindowScene.class] &&
                    candidate.activationState == UISceneActivationStateForegroundActive) {
                    scene = (UIWindowScene *)candidate;
                    break;
                }
            }
            if (scene) {
                PPOBuildOverlay(scene);
                ppoStopped = YES;
            } else if (ppoAttempts < 3) {
                PPOScheduleOverlay();
            } else {
                NSLog(@"[PPO 0.5.5] no-active-scene; stopped");
                ppoStopped = YES;
            }
        } @catch (NSException *exception) {
            // Catches synchronous ObjC exceptions only, not hangs or memory faults.
            NSLog(@"[PPO 0.5.5] ui-exception=%@; stopped", exception.name);
            ppoStopped = YES;
        }
        if (ppoStopped && ppoSceneObserver) {
            [NSNotificationCenter.defaultCenter removeObserver:ppoSceneObserver];
            ppoSceneObserver = nil;
        }
    });
}

%ctor {
    @autoreleasepool {
        NSLog(@"[PPO 0.5.5] loaded; os=%@",
              NSProcessInfo.processInfo.operatingSystemVersionString);
        if (!PPOOverlayAllowed()) {
            NSLog(@"[PPO 0.5.5] overlay-disabled; no hooks installed");
            return;
        }
        // No UIKit objects or private SpringBoard methods touched in the ctor.
        dispatch_async(dispatch_get_main_queue(), ^{
            ppoSceneObserver = [NSNotificationCenter.defaultCenter
                addObserverForName:UISceneDidActivateNotification object:nil
                queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) {
                    PPOScheduleOverlay();
                }];
            NSLog(@"[PPO 0.5.5] overlay-armed");
            PPOScheduleOverlay();
        });
    }
}

