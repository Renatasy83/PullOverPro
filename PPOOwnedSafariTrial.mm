#import "PPOOwnedSafariTrial.h"
#import "PPOScenePreflight.h"
#import "PPOOwnedSceneHost.h"
#import "PPOSceneLayerProbe.h"
#include "PPOHostGeometry.h"
#import <objc/runtime.h>
#include <sys/stat.h>
#include <errno.h>
#include <cmath>

static BOOL PPOTrialAllowed(void) {
    struct stat marker = {};
    return lstat("/var/mobile/.ppo_disable", &marker) != 0 && errno == ENOENT;
}
@interface PPOOwnedSafariTrial ()
@property(nonatomic,strong) PPOOwnedSceneHost *session;
@property(nonatomic,strong) UIWindow *window;
@property(nonatomic,strong) UIWindowScene *windowScene;
@property(nonatomic,strong) UIView *content;
@property(nonatomic,strong) UIView *scalingWrapper;
@property(nonatomic) CGRect fallbackNativeFrame;
@property(nonatomic) BOOL usedFallbackFrame;
@property(nonatomic,strong) NSDictionary *lastLiveSample;
@property(nonatomic,strong) NSDictionary *lastSourceSample;
@property(nonatomic,strong) id sourceScene;
@property(nonatomic,strong) id originalScene;
@property(nonatomic,strong) UIViewController *childController;
@property(nonatomic,strong) UIViewController *rootController;
@property(nonatomic) BOOL childAdopted;
@property(nonatomic,strong) NSDictionary *lastOriginalSample;
@property(nonatomic) BOOL originalProbeStopped;
@property(nonatomic) BOOL uiCleanupConfirmed;
@property(nonatomic) NSUInteger cleanupPolls;
@property(nonatomic) BOOL sourceProbeStopped;
@property(nonatomic) BOOL sampling;
@property(nonatomic,copy) NSString *closeReason;
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
@property(nonatomic) BOOL closing;
@property(nonatomic) BOOL cleanupConfirmed;
@property(nonatomic,copy) NSString *bundleIdentifier;
@property(nonatomic,copy) NSString *reportID;
@property(nonatomic) NSTimeInterval deadline;
- (void)closeFromButton:(UIButton *)sender;
- (void)closeBecause:(NSString *)reason;
- (BOOL)fitPresentation;
- (void)captureLayout:(NSString *)event;
- (void)captureState:(NSString *)event;
- (void)sampleObservations;
- (UIView *)hostView;
- (void)pollCleanup;
- (NSDictionary *)geometrySnapshot;
@end
@implementation PPOOwnedSafariTrial
- (void)record:(NSString *)event {
    if (!NSThread.isMainThread) return;
    if (!self.events) self.events = [NSMutableArray array];
    NSDictionary *geometry = [self geometrySnapshot];
    if (self.events.count < 16) [self.events addObject:@{@"event": event,
        @"uptime": @(NSProcessInfo.processInfo.systemUptime),
        @"sceneHost": self.session.snapshot ?: @{},
        @"geometry": geometry,
        @"lastLiveSample": self.lastLiveSample ?: @{},
        @"lastHostedSourceSample": self.lastSourceSample ?: @{},
        @"lastOriginalSourceSample": self.lastOriginalSample ?: @{},
        @"containerUserInteractionEnabled": @(self.content.userInteractionEnabled),
        @"closeReason": self.closeReason ?: @"none"}];
    UIView *presentation = [self hostView];
    NSDictionary *report = @{@"schema": @7, @"version": @"0.9.1~dev.componentproxy1",
        @"sessionID": self.reportID ?: @"none", @"bundleIdentifier": self.bundleIdentifier ?: @"none",
        @"replacementAllowed": @(self.replacementAllowed),
        @"geometry": geometry,
        @"lastLiveSample": self.lastLiveSample ?: @{},
        @"lastHostedSourceSample": self.lastSourceSample ?: @{},
        @"lastOriginalSourceSample": self.lastOriginalSample ?: @{},
        @"sceneHost": self.session.snapshot ?: @{},
        @"hostingViewUserInteractionEnabled": @(presentation.userInteractionEnabled),
        @"hostWindowIsKey": @(self.window.isKeyWindow),
        @"frameworks": self.frameworks ?: @{}, @"selection": self.selection ?: @{},
        @"events": [self.events copy], @"hostingRequested": @YES,
        @"containerUserInteractionEnabled": @(self.content.userInteractionEnabled),
        @"inputBlockingGuaranteed": @NO,
        @"inputRoutingMechanism": @"unconfirmed",
        @"closeReason": self.closeReason ?: @"none",
        @"touchDeliveryVerified": @NO, @"keyboardRoutingVerified": @NO,
        @"runtimeCompatibilityConfirmed": @NO, @"usesSeparateScene": @YES};
    // Keep the latest bounded snapshots of up to eight sessions. The cached
    // dictionaries never contain this history, so nesting cannot grow.
    static NSMutableArray<NSDictionary *> *history;
    if (!history) history = [NSMutableArray array];
    NSUInteger existing = NSNotFound;
    for (NSUInteger i = 0; i < history.count; i++) {
        if ([history[i][@"sessionID"] isEqual:report[@"sessionID"]]) { existing = i; break; }
    }
    if (existing != NSNotFound) history[existing] = report;
    else [history addObject:report];
    if (history.count > 8) [history removeObjectAtIndex:0];
    NSMutableDictionary *withHistory = [report mutableCopy];
    withHistory[@"sessions"] = [history copy];
    report = [withHistory copy];
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
                [data writeToFile:[directory stringByAppendingPathComponent:@"host-0.9.1.json"]
                    options:NSDataWritingAtomic error:NULL];
        }
    });
    NSLog(@"[PPO 0.9.1] host=%@ state=%@", event, self.session.state ?: @"none");
}
- (BOOL)isFinished {
    return NSThread.isMainThread && self.attempted && !self.opening && !self.running && !self.closing;
}
- (BOOL)replacementAllowed {
    if (!self.finished) return NO;
    if (self.closed) return self.cleanupConfirmed;
    // Refusal before resource acquisition is also safe to replace.
    return !self.session && !self.window && !self.observer && !self.backgroundObserver &&
        !self.protectedObserver && !self.timer;
}
- (NSString *)openInScene:(UIWindowScene *)scene bundleIdentifier:(NSString *)bundleIdentifier
              displayName:(NSString *)displayName {
    if (!NSThread.isMainThread || self.attempted) return @"Probă deja solicitată";
    self.attempted = YES;
    self.bundleIdentifier = [bundleIdentifier copy];
    self.reportID = NSUUID.UUID.UUIDString;
    self.frameworks = PPOSceneFrameworkIdentity();
    if (!PPOTrialAllowed()) { [self record:@"disabled"]; return @"PPO este dezactivat"; }
    if (![bundleIdentifier isEqual:@"com.apple.mobilesafari"]) {
        [self record:@"application-refused"];
        return @"Scena separată este disponibilă doar pentru Safari";
    }
    if (![self.frameworks[@"matches"] boolValue]) {
        [self record:@"framework-refused"]; return @"Firmware diferit; probă refuzată";
    }
    if (!scene || scene.activationState != UISceneActivationStateForegroundActive) {
        [self record:@"host-inactive"]; return @"Scena PPO nu este activă";
    }
    self.opening = YES;
    NSString *result = @"Probă de prezentare refuzată";
    @try {
        id foreignScene = nil;
        self.selection = PPOFindUniqueScene(objc_lookUpClass("FBSceneManager"),
            objc_lookUpClass("FBScene"), bundleIdentifier, &foreignScene);
        if (!foreignScene) {
            [self record:@"selection-refused"];
            return [self.selection[@"state"] isEqual:@"not-found"]
                ? @"Deschide aplicația o dată, apoi revino aici"
                : @"Scena aplicației nu poate fi selectată în siguranță";
        }
        self.originalScene = foreignScene;
        self.windowScene = scene;
        __weak PPOOwnedSafariTrial *weakSelf = self;
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
        NSMutableDictionary *classes = [NSMutableDictionary dictionary];
        for (NSString *name in @[@"FBSceneWorkspace", @"_UISceneHostingControllerAdvancedConfiguration",
                @"_UISceneHostingController", @"FBScene", @"FBSSceneDefinition",
                @"UIApplicationSceneSpecification", @"FBSSceneClientIdentity",
                @"_UISceneHostingActivationStateHostComponent", @"FBSComponentScene", @"UIViewController"]) {
            Class cls = objc_lookUpClass(name.UTF8String);
            if (cls) classes[name] = cls;
        }
        self.session = [[PPOOwnedSceneHost alloc] initWithClasses:classes];
        [self record:@"prepare-requested"];
        if (self.closePending || !PPOTrialAllowed() || ![self.session prepareScene:foreignScene]) return result;
        self.sourceScene = self.session.hostedScene;
        UIViewController *child = self.session.viewController;
        if (![child isKindOfClass:UIViewController.class] || child.parentViewController ||
            child.viewIfLoaded.superview || child.viewIfLoaded.window || self.closePending || !PPOTrialAllowed()) return result;
        self.childController = child;
        [self record:@"owned-scene-prepared"];
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
        self.rootController = root;
        self.window.rootViewController = root;
        root.view.frame = CGRectMake(0, 0, width, height);
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(12, 0, width - 60, 44)];
        NSString *name = [displayName isKindOfClass:NSString.class] && displayName.length > 0 && displayName.length <= 128
            ? displayName : @"PPO";
        title.text = [NSString stringWithFormat:@"%@ · 15 s", name];
        title.lineBreakMode = NSLineBreakByTruncatingTail; title.textColor = UIColor.whiteColor;
        title.font = [UIFont systemFontOfSize:12]; title.userInteractionEnabled = YES;
        [title addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)]];
        [root.view addSubview:title];
        UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
        close.frame = CGRectMake(width - 44, 0, 44, 44);
        [close setTitle:@"✕" forState:UIControlStateNormal];
        [close addTarget:self action:@selector(closeFromButton:) forControlEvents:UIControlEventTouchUpInside];
        [root.view addSubview:close];
        self.content = [[UIView alloc] initWithFrame:CGRectMake(0, 44, width, height - 44)];
        self.content.clipsToBounds = YES;
        // Preserve the container flag used in the observed 0.7.2 trial. This
        // UIView property does NOT establish blocking of remote scene input.
        // No event synthesis or private input/focus calls are introduced.
        self.content.userInteractionEnabled = NO;
        [root.view addSubview:self.content];
        // Normal UIKit child-controller containment supplies geometry before
        // appearance. UIKit's own sceneWillActivate provider applies that frame
        // to the NEW scene; PPO never writes the original scene's settings.
        self.scalingWrapper = [UIView new];
        self.scalingWrapper.clipsToBounds = YES;
        self.fallbackNativeFrame = screen;
        UIView *childView = child.view;
        if (childView.superview || childView.window || child.parentViewController) return result;
        childView.frame = CGRectMake(0, 0, screen.size.width, screen.size.height);
        NSDictionary *beforeAttach = [self.session sampleState];
        if (![beforeAttach[@"status"] isEqual:@"sampled"] ||
            ![beforeAttach[@"valid"] boolValue] || [beforeAttach[@"active"] boolValue]) {
            [self record:@"unexpected-pre-attachment-state"];
            return @"Scena separată nu poate fi atașată în siguranță";
        }
        [root addChildViewController:child];
        self.childAdopted = child.parentViewController == root;
        if (!self.childAdopted) return result;
        [self.scalingWrapper addSubview:childView];
        [self.content addSubview:self.scalingWrapper];
        [child didMoveToParentViewController:root];
        if (![self fitPresentation]) return @"Geometria ferestrei nu este disponibilă";
        // Keep existing key-window ownership and app scene foreground/geometry.
        self.window.hidden = NO;
        [self record:@"window-shown"];
        if (self.closePending || !PPOTrialAllowed()) return result;
        self.deadline = NSProcessInfo.processInfo.systemUptime + 15;
        self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        if (!self.timer) return @"Temporizator indisponibil; proba se închide";
        dispatch_source_set_timer(self.timer, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC / 4),
            NSEC_PER_SEC / 4, NSEC_PER_MSEC * 25);
        dispatch_source_set_event_handler(self.timer, ^{
            PPOOwnedSafariTrial *trial = weakSelf;
            if (!trial) return;
            if (!PPOTrialAllowed()) [trial closeBecause:@"disabled"];
            else if (trial.windowScene.activationState != UISceneActivationStateForegroundActive)
                [trial closeBecause:@"host-inactive"];
            else if (NSProcessInfo.processInfo.systemUptime >= trial.deadline)
                [trial closeBecause:@"timeout"];
        });
        dispatch_resume(self.timer);
        self.running = YES;
        [self captureLayout:@"post-layout"];
        if (self.closed || self.closePending || !self.running) return @"Fereastra nu poate fi afișată";
        for (NSNumber *delay in @[@0.1, @0.75]) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay.doubleValue * NSEC_PER_SEC)),
                dispatch_get_main_queue(), ^{
                    PPOOwnedSafariTrial *trial = weakSelf;
                    if (trial && trial.running && !trial.closed && !trial.closing && !trial.closePending)
                        [trial captureLayout:delay.doubleValue < 0.5 ? @"layout-100ms" : @"layout-750ms"];
                });
        }
        // Six extra state-only samples cover the observed foreground transition.
        // No timer extension, private notifications or repeated layout writes.
        for (NSNumber *delay in @[@2, @4, @6, @8, @10, @12]) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay.doubleValue * NSEC_PER_SEC)),
                dispatch_get_main_queue(), ^{
                    [weakSelf captureState:@"transition-sample"];
                });
        }
        result = @"Fereastră deschisă; închidere automată în 15 s";
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
- (UIView *)hostView { return self.childController.viewIfLoaded; }
- (BOOL)fitPresentation {
    UIView *presentation = [self hostView];
    if (!presentation || !self.scalingWrapper || !self.content) return NO;
    CGRect native = presentation.frame;
    PPOHostRect rectangle = {native.origin.x, native.origin.y, native.size.width, native.size.height};
    CGRect viewport = self.content.bounds;
    PPOHostFit fit{};
    PPOHostRect target = {viewport.origin.x, viewport.origin.y, viewport.size.width, viewport.size.height};
    self.usedFallbackFrame = native.size.width < 32 || native.size.height < 32 ||
        !PPOHostFitRect(rectangle, target, &fit);
    if (self.usedFallbackFrame) {
        native = self.fallbackNativeFrame;
        rectangle = {native.origin.x, native.origin.y, native.size.width, native.size.height};
        if (!PPOHostFitRect(rectangle, target, &fit)) return NO;
    }
    self.scalingWrapper.bounds = native;
    self.scalingWrapper.transform = CGAffineTransformMakeScale(fit.scale, fit.scale);
    self.scalingWrapper.center = CGPointMake(fit.centerX, fit.centerY);
    return YES;
}
- (NSDictionary *)geometrySnapshot {
    @try {
    UIView *presentation = [self hostView];
    NSMutableArray *chain = [NSMutableArray array];
    for (UIView *v = presentation; v && chain.count < 8; v = v.superview) {
        [chain addObject:@{@"class": NSStringFromClass(v.class),
            @"frame": NSStringFromCGRect(v.frame), @"bounds": NSStringFromCGRect(v.bounds),
            @"transform": NSStringFromCGAffineTransform(v.transform), @"hidden": @(v.hidden),
            @"alpha": @(v.alpha), @"subviews": @(v.subviews.count),
            @"attachedToPPOWindow": @(v.window != nil && v.window == self.window)}];
    }
    NSMutableArray *descendants = [NSMutableArray array];
    NSMutableArray<UIView *> *pending = [NSMutableArray array];
    if (presentation) [pending addObject:presentation];
    for (NSUInteger i = 0; i < pending.count && i < 8; i++) {
        UIView *v = pending[i];
        [descendants addObject:@{@"class": NSStringFromClass(v.class),
            @"frame": NSStringFromCGRect(v.frame), @"bounds": NSStringFromCGRect(v.bounds),
            @"hidden": @(v.hidden), @"alpha": @(v.alpha),
            @"layerClass": NSStringFromClass(v.layer.class),
            @"layerChildren": @(v.layer.sublayers.count), @"subviews": @(v.subviews.count)}];
        for (UIView *child in v.subviews) {
            if (pending.count >= 8) break;
            [pending addObject:child];
        }
    }
    return @{@"chain": chain, @"descendants": descendants,
        @"usedFallbackFrame": @(self.usedFallbackFrame),
        @"windowFrame": self.window ? NSStringFromCGRect(self.window.frame) : @"none",
        @"windowHidden": @(!self.window || self.window.hidden),
        @"hostSceneState": self.windowScene ? @((NSInteger)self.windowScene.activationState) : @(-1)};
    } @catch (NSException *exception) {
        return @{@"status": @"geometry-exception", @"exceptionName": exception.name ?: @"unknown"};
    }
}
- (void)captureLayout:(NSString *)event {
    if (!NSThread.isMainThread || self.closed || self.closing || self.closePending || !self.running) return;
    if (!PPOTrialAllowed()) { [self closeBecause:@"disabled"]; return; }
    @try {
        [self.window.rootViewController.view layoutIfNeeded];
        [(UIView *)[self hostView] layoutIfNeeded];
        if (self.closed || self.closing || self.closePending) return;
        if (![self fitPresentation]) { [self closeBecause:@"geometry-refused"]; return; }
        [self sampleObservations];
        [self record:event];
    } @catch (NSException *exception) {
        (void)exception; [self closeBecause:@"layout-exception"];
    }
}
- (void)sampleObservations {
    if (!NSThread.isMainThread || self.sampling || !self.running || self.closed || self.closing ||
        self.closePending || !PPOTrialAllowed()) return;
    self.sampling = YES;
    @try {
        NSMutableDictionary *sample = [[self.session sampleState] mutableCopy];
        sample[@"sampleUptime"] = @(NSProcessInfo.processInfo.systemUptime);
        self.lastLiveSample = [sample copy];
        if (!self.sourceProbeStopped && self.sourceScene && [self.frameworks[@"matches"] boolValue]) {
            sample = [PPOReadSceneLayerState(self.sourceScene, objc_lookUpClass("FBScene"),
                objc_lookUpClass("FBSceneLayerManager"), objc_lookUpClass("FBSceneLayer"),
                objc_lookUpClass("FBSSceneSettings")) mutableCopy];
            sample[@"sampleUptime"] = @(NSProcessInfo.processInfo.systemUptime);
            self.lastSourceSample = [sample copy];
            // Unsupported/exceptional probes are not retried in this session.
            self.sourceProbeStopped = ![sample[@"status"] isEqual:@"sampled"];
        }
        if (!self.originalProbeStopped && self.originalScene && [self.frameworks[@"matches"] boolValue]) {
            sample = [PPOReadSceneLayerState(self.originalScene, objc_lookUpClass("FBScene"),
                objc_lookUpClass("FBSceneLayerManager"), objc_lookUpClass("FBSceneLayer"),
                objc_lookUpClass("FBSSceneSettings")) mutableCopy];
            sample[@"sampleUptime"] = @(NSProcessInfo.processInfo.systemUptime);
            self.lastOriginalSample = [sample copy];
            self.originalProbeStopped = ![sample[@"status"] isEqual:@"sampled"];
        }
    } @finally { self.sampling = NO; }
}
- (void)captureState:(NSString *)event {
    if (!NSThread.isMainThread || !self.running || self.closed || self.closing || self.closePending) return;
    if (!PPOTrialAllowed()) { [self closeBecause:@"disabled"]; return; }
    @try {
        [self sampleObservations];
        if (self.running && !self.closed && !self.closing && !self.closePending) [self record:event];
    } @catch (NSException *exception) {
        (void)exception; self.sourceProbeStopped = YES;
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
    self.closing = YES;
    self.running = NO;
    if (self.timer) { dispatch_source_cancel(self.timer); self.timer = nil; }
    for (id observer in @[self.observer ?: NSNull.null, self.backgroundObserver ?: NSNull.null,
                          self.protectedObserver ?: NSNull.null])
        if (observer != NSNull.null) [NSNotificationCenter.defaultCenter removeObserver:observer];
    self.observer = nil; self.backgroundObserver = nil; self.protectedObserver = nil;
    BOOL uiClean = YES;
    @try {
        self.content.userInteractionEnabled = NO;
        self.window.hidden = YES;
        // A rejected/preparented child must never be detached from someone
        // else's hierarchy. Partial adoption into our own root is removable.
        UIViewController *child = self.childController;
        UIView *childView = child.viewIfLoaded;
        if (child && self.rootController && child.parentViewController == self.rootController &&
            (!childView.superview || childView.superview == self.scalingWrapper) &&
            (!childView.window || childView.window == self.window)) {
            [child willMoveToParentViewController:nil];
            [childView removeFromSuperview];
            [child removeFromParentViewController];
            self.childAdopted = NO;
        } else if (child && (child.parentViewController || childView.superview || childView.window)) {
            uiClean = NO;
        }
        if (!self.scalingWrapper.superview || self.scalingWrapper.superview == self.content) {
            if (uiClean) [self.scalingWrapper removeFromSuperview];
        } else uiClean = NO;
    } @catch (NSException *exception) { (void)exception; uiClean = NO; }
    // The owner invalidates only its independently created controller/scene.
    BOOL ownerClosed = !self.session || [self.session close];
    if (uiClean) {
        @try { self.window.rootViewController = nil; }
        @catch (NSException *exception) { (void)exception; uiClean = NO; }
    }
    if (uiClean) {
        self.window = nil; self.content = nil; self.scalingWrapper = nil;
        self.childController = nil; self.rootController = nil;
    }
    self.uiCleanupConfirmed = uiClean;
    if (ownerClosed) {
        self.cleanupConfirmed = uiClean;
        self.sourceScene = nil; self.originalScene = nil;
        self.closing = NO;
        [self record:uiClean ? @"close-returned" : @"cleanup-unconfirmed"];
    } else if (self.session.poisoned) {
        self.closing = NO;
        [self record:@"cleanup-unconfirmed"];
    } else {
        [self record:@"cleanup-pending"];
        self.cleanupPolls = 0;
        [self pollCleanup];
    }
}
- (void)pollCleanup {
    if (!NSThread.isMainThread || !self.closing) return;
    if ([self.session pollCleanup]) {
        self.cleanupConfirmed = self.uiCleanupConfirmed;
        self.sourceScene = nil; self.originalScene = nil;
        self.closing = NO;
        [self record:self.cleanupConfirmed ? @"close-returned" : @"cleanup-unconfirmed"];
        return;
    }
    if (self.session.poisoned || self.cleanupPolls >= 8) {
        [self.session quarantineCleanup];
        self.closing = NO;
        [self record:@"cleanup-unconfirmed"];
        return;
    }
    self.cleanupPolls++;
    __weak PPOOwnedSafariTrial *weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC / 4), dispatch_get_main_queue(), ^{
        [weakSelf pollCleanup];
    });
}
@end
