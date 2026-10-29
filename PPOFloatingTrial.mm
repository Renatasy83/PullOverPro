#import "PPOFloatingTrial.h"
#import "PPOScenePreflight.h"
#import "PPOScenePresenter.h"
#import <objc/runtime.h>
#include <sys/stat.h>
#include <errno.h>
#include <cmath>

static BOOL PPOTrialAllowed(void) {
    struct stat marker = {};
    return lstat("/var/mobile/.ppo_disable", &marker) != 0 && errno == ENOENT;
}
@interface PPOFloatingTrial ()
@property(nonatomic,strong) PPOScenePresenter *session;
@property(nonatomic,strong) UIWindow *window;
@property(nonatomic,strong) UIWindowScene *windowScene;
@property(nonatomic,strong) UIView *content;
@property(nonatomic,strong) UIButton *inputButton;
@property(nonatomic,copy) NSString *closeReason;
@property(nonatomic) BOOL inputEverEnabled;
@property(nonatomic,strong) id observer;
@property(nonatomic,strong) id backgroundObserver;
@property(nonatomic,strong) id protectedObserver;
@property(nonatomic,strong) dispatch_source_t timer;
@property(nonatomic,strong) NSMutableArray *events;
@property(nonatomic,strong) NSDictionary *selection;
@property(nonatomic,strong) NSDictionary *frameworks;
@property(nonatomic) BOOL attempted;
@property(nonatomic) BOOL opening;
@property(nonatomic) BOOL running;
@property(nonatomic) BOOL closePending;
@property(nonatomic) BOOL closed;
@property(nonatomic) NSTimeInterval deadline;
- (void)toggleInput:(UIButton *)sender;
- (void)closeFromButton:(UIButton *)sender;
- (void)closeBecause:(NSString *)reason;
@end
@implementation PPOFloatingTrial
- (void)record:(NSString *)event {
    if (!NSThread.isMainThread) return;
    if (!self.events) self.events = [NSMutableArray array];
    if (self.events.count < 16) [self.events addObject:@{@"event": event,
        @"uptime": @(NSProcessInfo.processInfo.systemUptime),
        @"presenter": self.session.snapshot ?: @{},
        @"inputEnabled": @(self.content.userInteractionEnabled),
        @"closeReason": self.closeReason ?: @"none"}];
    UIView *presentation = self.session.presentationView;
    NSDictionary *report = @{@"schema": @1, @"version": @"0.7.2~dev.touchtrial1",
        @"presenter": self.session.snapshot ?: @{},
        @"presentationViewInteractionEnabled": @(presentation.userInteractionEnabled),
        @"hostWindowIsKey": @(self.window.isKeyWindow),
        @"frameworks": self.frameworks ?: @{}, @"selection": self.selection ?: @{},
        @"events": [self.events copy], @"hostingRequested": @YES,
        @"inputEnabled": @(self.content.userInteractionEnabled),
        @"inputEverEnabled": @(self.inputEverEnabled),
        @"closeReason": self.closeReason ?: @"none",
        @"touchDeliveryVerified": @NO, @"keyboardRoutingVerified": @NO,
        @"runtimeCompatibilityConfirmed": @NO};
    // Serialize immutable snapshots off the main thread, in order. No app data.
    static dispatch_queue_t queue;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ queue = dispatch_queue_create("com.renatasy83.ppo.hostreport", DISPATCH_QUEUE_SERIAL); });
    dispatch_async(queue, ^{
        @autoreleasepool {
            NSString *directory = @"/var/mobile/Library/Logs/PullOverPro";
            NSData *data = [NSJSONSerialization dataWithJSONObject:report
                options:NSJSONWritingPrettyPrinted error:NULL];
            if (data && [NSFileManager.defaultManager createDirectoryAtPath:directory
                withIntermediateDirectories:YES attributes:nil error:NULL])
                [data writeToFile:[directory stringByAppendingPathComponent:@"host-0.7.2.json"]
                    options:NSDataWritingAtomic error:NULL];
        }
    });
    NSLog(@"[PPO 0.7.2] host=%@ state=%@", event, self.session.state ?: @"none");
}
- (NSString *)openInScene:(UIWindowScene *)scene bundleIdentifier:(NSString *)bundleIdentifier {
    if (!NSThread.isMainThread || self.attempted) return @"Probă deja solicitată";
    self.attempted = YES;
    self.frameworks = PPOSceneFrameworkIdentity();
    if (!PPOTrialAllowed()) return @"PPO este dezactivat";
    if (![bundleIdentifier isEqual:@"com.apple.mobilesafari"]) return @"Proba este limitată la Safari";
    if (![self.frameworks[@"matches"] boolValue]) return @"Firmware diferit; probă refuzată";
    if (!scene || scene.activationState != UISceneActivationStateForegroundActive)
        return @"Scena PPO nu este activă";
    self.opening = YES;
    NSString *result = @"Probă de prezentare refuzată";
    @try {
        id foreignScene = nil;
        self.selection = PPOFindUniqueScene(objc_lookUpClass("FBSceneManager"),
            objc_lookUpClass("FBScene"), bundleIdentifier, &foreignScene);
        if (!foreignScene) { [self record:@"selection-refused"]; return @"Deschide întâi Safari; scena trebuie să fie unică"; }
        self.windowScene = scene;
        __weak PPOFloatingTrial *weakSelf = self;
        void (^inactive)(NSNotification *) = ^(NSNotification *note) {
            (void)note; [weakSelf closeBecause:@"host-inactive"];
        };
        void (^protectedStop)(NSNotification *) = ^(NSNotification *note) {
            (void)note; [weakSelf closeBecause:@"protected-data-unavailable"];
        };
        self.observer = [NSNotificationCenter.defaultCenter addObserverForName:UISceneWillDeactivateNotification
            object:scene queue:NSOperationQueue.mainQueue usingBlock:inactive];
        self.backgroundObserver = [NSNotificationCenter.defaultCenter addObserverForName:UISceneDidEnterBackgroundNotification
            object:scene queue:NSOperationQueue.mainQueue usingBlock:inactive];
        self.protectedObserver = [NSNotificationCenter.defaultCenter addObserverForName:UIApplicationProtectedDataWillBecomeUnavailable
            object:nil queue:NSOperationQueue.mainQueue usingBlock:protectedStop];
        self.session = [[PPOScenePresenter alloc] initWithManagerClass:objc_lookUpClass("UIScenePresentationManager")
            presenterClass:objc_lookUpClass("_UIScenePresenter") viewClass:UIView.class];
        [self record:@"prepare-requested"];
        if (self.closePending || !PPOTrialAllowed() || ![self.session prepareScene:foreignScene]) return result;
        UIView *view = self.session.presentationView;
        // A new presenter must supply an unattached view. Never steal/reparent
        // an existing system-owned view, even if a getter returns one.
        if (view.superview || view.window || self.closePending || !PPOTrialAllowed()) return result;
        CGRect screen = scene.coordinateSpace.bounds;
        CGFloat width = MIN(300, CGRectGetWidth(screen) - 24);
        CGFloat height = MIN(480, CGRectGetHeight(screen) - 100);
        if (width < 240 || height < 240) return result;
        self.window = [[UIWindow alloc] initWithWindowScene:scene];
        self.window.frame = CGRectMake(CGRectGetMidX(screen) - width / 2, 60, width, height);
        self.window.windowLevel = UIWindowLevelStatusBar + 2;
        self.window.backgroundColor = UIColor.blackColor;
        self.window.layer.cornerRadius = 14; self.window.clipsToBounds = YES;
        UIViewController *root = [UIViewController new];
        self.window.rootViewController = root;
        root.view.frame = CGRectMake(0, 0, width, height);
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(12, 0, width - 180, 44)];
        title.text = @"Safari · 15 s"; title.textColor = UIColor.whiteColor;
        title.font = [UIFont systemFontOfSize:12]; title.userInteractionEnabled = YES;
        [title addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)]];
        [root.view addSubview:title];
        self.inputButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.inputButton.frame = CGRectMake(width - 156, 6, 108, 32);
        self.inputButton.titleLabel.font = [UIFont systemFontOfSize:10];
        [self.inputButton setTitle:@"Atingeri: oprite" forState:UIControlStateNormal];
        [self.inputButton addTarget:self action:@selector(toggleInput:) forControlEvents:UIControlEventTouchUpInside];
        self.inputButton.enabled = NO;
        [root.view addSubview:self.inputButton];
        UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
        close.frame = CGRectMake(width - 44, 0, 44, 44);
        [close setTitle:@"✕" forState:UIControlStateNormal];
        [close addTarget:self action:@selector(closeFromButton:) forControlEvents:UIControlEventTouchUpInside];
        [root.view addSubview:close];
        self.content = [[UIView alloc] initWithFrame:CGRectMake(0, 44, width, height - 44)];
        self.content.clipsToBounds = YES;
        // Starts read-only. Touch acceptance requires the explicit header button;
        // UIKit performs hit testing/coordinate conversion. No synthetic events.
        self.content.userInteractionEnabled = NO;
        [root.view addSubview:self.content];
        CGSize native = view.bounds.size;
        if (!std::isfinite(native.width) || !std::isfinite(native.height) ||
            native.width <= 0 || native.height <= 0 || native.width > 8192 || native.height > 8192)
            native = screen.size;
        view.bounds = CGRectMake(0, 0, native.width, native.height);
        CGFloat scale = MIN(width / native.width, (height - 44) / native.height);
        view.transform = CGAffineTransformMakeScale(scale, scale);
        view.center = CGPointMake(width / 2, (height - 44) / 2);
        [self.content addSubview:view];
        // Keep existing key-window ownership and app scene foreground/geometry.
        self.window.hidden = NO;
        [self record:@"activate-requested"];
        if (self.closePending || !PPOTrialAllowed() || ![self.session activate]) return result;
        [self record:@"activate-returned"];
        self.deadline = NSProcessInfo.processInfo.systemUptime + 15;
        self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        if (!self.timer) return @"Temporizator indisponibil; proba se închide";
        dispatch_source_set_timer(self.timer, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC / 4),
            NSEC_PER_SEC / 4, NSEC_PER_MSEC * 25);
        dispatch_source_set_event_handler(self.timer, ^{
            PPOFloatingTrial *trial = weakSelf;
            if (!trial) return;
            if (!PPOTrialAllowed()) [trial closeBecause:@"disabled"];
            else if (trial.windowScene.activationState != UISceneActivationStateForegroundActive)
                [trial closeBecause:@"host-inactive"];
            else if (NSProcessInfo.processInfo.systemUptime >= trial.deadline)
                [trial closeBecause:@"timeout"];
        });
        dispatch_resume(self.timer);
        self.running = YES;
        self.inputButton.enabled = YES;
        result = @"Probă Safari: închidere automată în 15 s";
        return result;
    } @catch (NSException *exception) {
        (void)exception;
        if (!self.closeReason) self.closeReason = @"ui-exception";
        [self record:@"ui-exception"];
        return @"Proba s-a oprit după o excepție";
    } @finally {
        self.opening = NO;
        if (self.closePending || !self.running) [self closeBecause:self.closeReason ?: @"opening-failed"];
    }
}
- (void)toggleInput:(UIButton *)sender {
    if (!NSThread.isMainThread || self.closed || self.opening || !self.running || self.closePending) return;
    if (!PPOTrialAllowed()) { [self closeBecause:@"disabled"]; return; }
    if (self.windowScene.activationState != UISceneActivationStateForegroundActive) {
        [self closeBecause:@"host-inactive"]; return;
    }
    if (NSProcessInfo.processInfo.systemUptime >= self.deadline) {
        [self closeBecause:@"timeout"]; return;
    }
    @try {
        self.content.userInteractionEnabled = !self.content.userInteractionEnabled;
        if (self.content.userInteractionEnabled) self.inputEverEnabled = YES;
        [sender setTitle:self.content.userInteractionEnabled ? @"Atingeri: pornite" : @"Atingeri: oprite"
            forState:UIControlStateNormal];
        [self record:self.content.userInteractionEnabled ? @"input-enabled" : @"input-disabled"];
    } @catch (NSException *exception) {
        (void)exception; [self closeBecause:@"input-toggle-exception"];
    }
}
- (void)closeFromButton:(UIButton *)sender {
    (void)sender; [self closeBecause:@"manual"];
}
- (void)closeBecause:(NSString *)reason {
    if (!NSThread.isMainThread || self.closed) return;
    // Preserve the first reason even if notifications reenter during cleanup.
    if (!self.closeReason) self.closeReason = [reason copy];
    [self close];
}
- (void)pan:(UIPanGestureRecognizer *)pan {
    if (!self.window || self.closed) return;
    CGPoint delta = [pan translationInView:self.window];
    CGRect f = self.window.frame, screen = self.windowScene.coordinateSpace.bounds;
    f.origin.x = MAX(CGRectGetMinX(screen), MIN(CGRectGetMaxX(screen) - f.size.width, f.origin.x + delta.x));
    f.origin.y = MAX(CGRectGetMinY(screen), MIN(CGRectGetMaxY(screen) - f.size.height, f.origin.y + delta.y));
    self.window.frame = f; [pan setTranslation:CGPointZero inView:self.window];
}
- (void)close {
    if (!NSThread.isMainThread || self.closed) return;
    if (!self.closeReason) self.closeReason = @"external";
    if (self.opening) { self.closePending = YES; return; }
    self.closed = YES;
    self.running = NO;
    self.inputButton.enabled = NO;
    if (self.timer) { dispatch_source_cancel(self.timer); self.timer = nil; }
    for (id observer in @[self.observer ?: NSNull.null, self.backgroundObserver ?: NSNull.null,
                          self.protectedObserver ?: NSNull.null])
        if (observer != NSNull.null) [NSNotificationCenter.defaultCenter removeObserver:observer];
    self.observer = nil; self.backgroundObserver = nil; self.protectedObserver = nil;
    BOOL uiClean = YES;
    @try {
        self.content.userInteractionEnabled = NO;
        self.window.hidden = YES;
        // Detach only our container's contents, never a view that failed adoption.
        for (UIView *view in [self.content.subviews copy]) [view removeFromSuperview];
    } @catch (NSException *exception) { (void)exception; uiClean = NO; }
    // Still invalidate our owned presenter if UIKit detachment raised.
    BOOL closed = !self.session || [self.session close];
    @try { self.window.rootViewController = nil; }
    @catch (NSException *exception) { (void)exception; uiClean = NO; }
    if (uiClean) { self.window = nil; self.content = nil; }
    [self record:closed && uiClean ? @"close-returned" : @"cleanup-unconfirmed"];
    // Keep the session retained even after a failed cleanup; no automatic retry.
}
@end
