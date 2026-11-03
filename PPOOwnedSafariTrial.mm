#import "PPOOwnedSafariTrial.h"
#import "PPOScenePreflight.h"
#import "PPOOwnedSceneHost.h"
#import "PPOSceneLayerProbe.h"
#import "PPOScreenLockState.h"
#import "PPOOwnedApplicationPolicy.h"
#import "PPOOwnedAdmission.h"
#import "PPOUserPreferences.h"
#include "PPOHostGeometry.h"
#include "PPOFloatingWindowGeometry.h"
#include "PPOFloatingWindowPresentation.h"
#include "PPOEdgeDrawerGeometry.h"
#include "PPOClassicInterfaceGeometry.h"
#include "PPOWindowLifetime.h"
#import <objc/runtime.h>
#include <sys/stat.h>
#include <errno.h>
#include <cmath>

// A full-scene public window must not consume the rest of the display. Only
// the actually visible portion of PPO's own panel accepts normal UIKit hits.
// Remote scene input remains the existing OS path, not synthesized input.
@interface PPOOwnedPassthroughWindow : UIWindow
@property(nonatomic,weak) UIView *interactivePanel;
@end
@implementation PPOOwnedPassthroughWindow
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *panel = self.interactivePanel;
    if (self.hidden || self.alpha <= 0 || !panel || panel.hidden || panel.alpha <= 0 ||
        !CGRectContainsPoint(self.bounds, point)) return nil;
    CGPoint local = [panel convertPoint:point fromView:self];
    if (![panel pointInside:local withEvent:event]) return nil;
    UIView *hit = [super hitTest:point withEvent:event];
    return hit == self || hit == self.rootViewController.view ? nil : hit;
}
@end

static BOOL PPOTrialAllowed(void) {
    struct stat marker = {};
    return lstat("/var/mobile/.ppo_disable", &marker) != 0 && errno == ENOENT;
}
// Capture screen-relative insets from full-scene windows once. Insets on our
// small moving window are frame-relative and must not feed back into placement.
static UIEdgeInsets PPOPlacementInsets(UIWindowScene *scene) {
    UIEdgeInsets result = UIEdgeInsetsZero;
    CGRect screen = scene.coordinateSpace.bounds;
    NSArray<UIWindow *> *windows = scene.windows;
    if (windows.count <= 128) {
        for (UIWindow *candidate in windows) {
            if (![candidate isKindOfClass:UIWindow.class] || candidate.hidden || candidate.windowScene != scene) continue;
            CGRect frame = [candidate convertRect:candidate.bounds toCoordinateSpace:scene.coordinateSpace];
            if (!std::isfinite(frame.origin.x) || !std::isfinite(frame.origin.y) ||
                !std::isfinite(frame.size.width) || !std::isfinite(frame.size.height) ||
                std::abs(frame.origin.x - screen.origin.x) > 1 ||
                std::abs(frame.origin.y - screen.origin.y) > 1 ||
                std::abs(frame.size.width - screen.size.width) > 1 ||
                std::abs(frame.size.height - screen.size.height) > 1) continue;
            UIEdgeInsets insets = candidate.safeAreaInsets;
            if (!std::isfinite(insets.top) || !std::isfinite(insets.left) ||
                !std::isfinite(insets.bottom) || !std::isfinite(insets.right) ||
                insets.top < 0 || insets.left < 0 || insets.bottom < 0 || insets.right < 0) continue;
            result.top = MAX(result.top, insets.top); result.left = MAX(result.left, insets.left);
            result.bottom = MAX(result.bottom, insets.bottom); result.right = MAX(result.right, insets.right);
        }
    }
    CGRect status = scene.statusBarManager.statusBarFrame;
    if (std::isfinite(status.origin.y) && std::isfinite(status.size.height) &&
        status.size.height > 0 && status.size.height <= screen.size.height &&
        std::abs(status.origin.y - screen.origin.y) <= 1)
        result.top = MAX(result.top, CGRectGetMaxY(status) - CGRectGetMinY(screen));
    return result;
}
static PPOHostRect PPOFloatingRect(CGRect value) {
    return {value.origin.x, value.origin.y, value.size.width, value.size.height};
}
static PPOFloatingInsets PPOFloatingSafeInsets(UIEdgeInsets value) {
    return {value.top, value.left, value.bottom, value.right};
}
static NSString *PPOFloatingSizeName(PPOFloatingSize size) {
    switch (size) {
        case PPOFloatingSize::Compact: return @"compact";
        case PPOFloatingSize::Standard: return @"standard";
        case PPOFloatingSize::Large: return @"large";
    }
    return @"invalid";
}
static NSString *PPOWindowStopName(PPOWindowStop reason) {
    switch (reason) {
        case PPOWindowStop::Disabled: return @"disabled";
        case PPOWindowStop::ProtectedDataUnavailable: return @"protected-data-unavailable";
        case PPOWindowStop::HostInactive: return @"host-inactive";
        case PPOWindowStop::LockUnknown: return @"lock-state-unavailable";
        case PPOWindowStop::Locked: return @"device-locked";
        case PPOWindowStop::SceneUnknown: return @"scene-state-unavailable";
        case PPOWindowStop::SceneInvalid: return @"scene-invalid";
        case PPOWindowStop::SceneInactive: return @"scene-inactive";
        case PPOWindowStop::ActivationTimeout: return @"scene-activation-timeout";
        case PPOWindowStop::ColdRenderTimeout: return @"cold-render-timeout";
        case PPOWindowStop::ClockInvalid: return @"clock-invalid";
        case PPOWindowStop::Timeout: return @"timeout";
        case PPOWindowStop::None: return @"none";
    }
    return @"lifecycle-error";
}
@interface PPOOwnedSafariTrial ()
@property(nonatomic,strong) PPOOwnedSceneHost *session;
@property(nonatomic,strong) UIWindow *window;
@property(nonatomic,strong) UIView *panel;
@property(nonatomic) CGRect panelBaseFrame;
@property(nonatomic,copy) NSDictionary *presentationPreferences;
@property(nonatomic) double presentedDrawerProgress;
@property(nonatomic) BOOL keepPreferenceAttempted;
@property(nonatomic,strong) UIWindowScene *windowScene;
@property(nonatomic,strong) UIView *content;
@property(nonatomic,strong) UIView *scalingWrapper;
@property(nonatomic) CGRect fallbackNativeFrame;
@property(nonatomic) BOOL usedFallbackFrame;
@property(nonatomic) BOOL drawerSized;
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
@property(nonatomic,strong) id deviceLockObserver;
@property(nonatomic,copy) NSDictionary *lastLockSample;
@property(nonatomic) BOOL protectedDataAvailable;
@property(nonatomic) BOOL protectedDataSampled;
@property(nonatomic,strong) UIButton *actionsButton;
@property(nonatomic,strong) UIButton *sizeButton;
@property(nonatomic,strong) UIButton *closeButton;
@property(nonatomic,strong) UIButton *restoreButton;
@property(nonatomic,strong) UILabel *titleLabel;
@property(nonatomic) UIEdgeInsets placementInsets;
@property(nonatomic) NSUInteger completedMoves;
@property(nonatomic) NSUInteger completedResizes;
@property(nonatomic) NSUInteger completedMinimizes;
@property(nonatomic) NSUInteger completedRestores;
@property(nonatomic) BOOL minimizedAtClose;
@property(nonatomic,copy) NSString *displayName;
@property(nonatomic,strong) dispatch_source_t timer;
@property(nonatomic,strong) NSMutableArray *events;
@property(nonatomic,strong) NSDictionary *selection;
@property(nonatomic,strong) NSDictionary *frameworks;
@property(nonatomic) BOOL coldStart;
@property(nonatomic) NSTimeInterval nextColdLayerProbe;
@property(nonatomic,strong) UIActivityIndicatorView *startupSpinner;
@property(nonatomic) BOOL attempted;
@property(nonatomic) BOOL opening;
@property(nonatomic) BOOL running;
@property(nonatomic) BOOL closePending;
@property(nonatomic) BOOL closed;
@property(nonatomic) BOOL closing;
@property(nonatomic) BOOL cleanupConfirmed;
@property(nonatomic,copy) NSString *bundleIdentifier;
@property(nonatomic,copy) NSDictionary *sceneCapability;
@property(nonatomic,copy) NSString *reportID;
@property(nonatomic) NSTimeInterval nextHeartbeat;
- (void)closeFromButton:(UIButton *)sender;
- (void)closeBecause:(NSString *)reason;
- (void)closeAfterNotification:(NSString *)reason;
- (BOOL)fitPresentation;
- (void)captureLayout:(NSString *)event;
- (void)captureState:(NSString *)event;
- (void)sampleObservations;
- (UIView *)hostView;
- (void)pollCleanup;
- (NSDictionary *)geometrySnapshot;
- (BOOL)accessAllowed;
- (PPOWindowConditions)lifetimeConditions;
- (BOOL)checkLifetime;
- (void)keepFromButton:(UIButton *)sender;
- (void)resizeFromButton:(UIButton *)sender;
- (BOOL)applyWindowFrame:(PPOHostRect)frame;
- (void)updateActionsMenu;
- (void)minimizeFromButton:(UIButton *)sender;
- (void)restoreFromButton:(UIButton *)sender;
- (BOOL)applyDrawerTransform;
- (void)notifyPresentationChange;
@end
@implementation PPOOwnedSafariTrial {
    PPOWindowLifetime _lifetime;
    PPOFloatingSize _sizePreset;
    PPOFloatingWindowPresentation _presentation;
}
- (void)configurePresentationWithPreferences:(NSDictionary *)preferences {
    if (!NSThread.isMainThread || self.attempted) return;
    self.presentationPreferences = PPOUserPreferencesNormalize(preferences);
}
- (double)drawerProgress { return self.presentedDrawerProgress; }
- (BOOL)classicLayout { return self.drawerSized && !self.closed && !_presentation.minimized(); }
- (CGRect)drawerVisibleFrameInScene {
    if (!NSThread.isMainThread || !self.running || self.closed || self.closing || self.closePending ||
        !self.window || self.window.hidden || !self.panel || self.panel.hidden ||
        self.window.alpha <= 0 || self.panel.alpha <= 0 || !self.windowScene) return CGRectNull;
    @try {
        CGRect inWindow = [self.panel convertRect:self.panel.bounds toView:self.window];
        CGRect frame = [self.window convertRect:inWindow toCoordinateSpace:self.windowScene.coordinateSpace];
        for (CGFloat value : {frame.origin.x,frame.origin.y,frame.size.width,frame.size.height})
            if (!std::isfinite(value)) return CGRectNull;
        if (frame.size.width <= 0 || frame.size.height <= 0) return CGRectNull;
        CGRect visible = CGRectIntersection(frame,self.windowScene.coordinateSpace.bounds);
        return CGRectIsNull(visible) || CGRectIsEmpty(visible) ? CGRectNull : visible;
    } @catch (NSException *exception) { (void)exception; return CGRectNull; }
}
- (void)notifyPresentationChange {
    if (!NSThread.isMainThread) return;
    void (^changed)(void) = self.presentationDidChange;
    if (!changed) return;
    @try { changed(); }
    @catch (NSException *exception) {
        // A public UI callback must never interrupt owned-scene teardown.
        (void)exception; self.presentationDidChange = nil;
        NSLog(@"[PPO] presentation-callback-disabled");
    }
}
- (double)drawerTravel {
    if (!NSThread.isMainThread || !self.windowScene || !self.panel) return 0;
    double translation = 0, travel = 0;
    PPOEdgeDrawerSide side = [self.presentationPreferences[@"edge"] isEqual:@"left"]
        ? PPOEdgeDrawerSide::Left : PPOEdgeDrawerSide::Right;
    if (!PPOEdgeDrawerPanelTranslation(PPOFloatingRect(self.windowScene.coordinateSpace.bounds),
        PPOFloatingRect(self.panelBaseFrame), side, self.presentedDrawerProgress,
        &translation, &travel)) return 0;
    return travel;
}
- (BOOL)applyDrawerTransform {
    if (!self.panel || !self.windowScene) return NO;
    double translation = 0, travel = 0;
    PPOEdgeDrawerSide side = [self.presentationPreferences[@"edge"] isEqual:@"left"]
        ? PPOEdgeDrawerSide::Left : PPOEdgeDrawerSide::Right;
    if (!PPOEdgeDrawerPanelTranslation(PPOFloatingRect(self.windowScene.coordinateSpace.bounds),
        PPOFloatingRect(self.panelBaseFrame), side, self.presentedDrawerProgress,
        &translation, &travel)) return NO;
    self.panel.transform = CGAffineTransformMakeTranslation(translation, 0);
    UIView *updatedPanel = self.panel;
    [self notifyPresentationChange];
    return self.panel == updatedPanel && !self.closed && !self.closing && !self.closePending;
}
- (BOOL)setDrawerProgress:(double)progress {
    if (!NSThread.isMainThread || !std::isfinite(progress) || progress < 0 || progress > 1 ||
        !self.running || self.opening || self.closed || self.closing || self.closePending) return NO;
    @try {
        // Per-frame drag updates touch only public presentation state. The
        // existing timer/notifications and guarded gesture finish enforce
        // lifetime without sampling private scene state at touch frequency.
        [self.panel.layer removeAllAnimations];
        self.presentedDrawerProgress = progress;
        if (![self applyDrawerTransform]) { [self closeBecause:@"drawer-layout-refused"]; return NO; }
        return YES;
    } @catch (NSException *exception) {
        (void)exception; [self closeBecause:@"drawer-exception"]; return NO;
    }
}
- (BOOL)finishDrawerOpen:(BOOL)open {
    if (!NSThread.isMainThread || !self.running || self.opening || self.closed || self.closing || self.closePending)
        return NO;
    @try {
        if (![self checkLifetime]) return NO;
        if (open && _presentation.minimized()) {
            [self restoreFromButton:nil];
            if (!self.running || self.closed || self.closing || self.closePending) return NO;
        }
        self.presentedDrawerProgress = open ? 1 : 0;
        // Only our panel is animated. No completion owns or reopens a session.
        __weak PPOOwnedSafariTrial *weakSelf = self;
        __block BOOL applied = NO;
        [UIView animateWithDuration:0.22 delay:0
            options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
            animations:^{
                PPOOwnedSafariTrial *trial = weakSelf;
                if (trial && trial.running && !trial.closed && !trial.closing && !trial.closePending)
                    applied = [trial applyDrawerTransform];
            } completion:nil];
        if (!applied) { [self closeBecause:@"drawer-layout-refused"]; return NO; }
        [self record:open ? @"drawer-opened" : @"drawer-closed"];
        return YES;
    } @catch (NSException *exception) {
        (void)exception; [self closeBecause:@"drawer-exception"]; return NO;
    }
}
- (void)record:(NSString *)event {
    if (!NSThread.isMainThread) return;
    if (!self.events) self.events = [NSMutableArray array];
    NSDictionary *geometry = [self geometrySnapshot];
    [self.events addObject:@{@"event": event,
        @"uptime": @(NSProcessInfo.processInfo.systemUptime),
        @"sceneHost": self.session.snapshot ?: @{},
        @"geometry": geometry,
        @"lastLiveSample": self.lastLiveSample ?: @{},
        @"lastHostedSourceSample": self.lastSourceSample ?: @{},
        @"lastOriginalSourceSample": self.lastOriginalSample ?: @{},
        @"lastLockSample": self.lastLockSample ?: @{},
        @"lifetimeMode": _lifetime.kept() ? @"kept" : @"timed",
        @"containerUserInteractionEnabled": @(self.content.userInteractionEnabled),
        @"closeReason": self.closeReason ?: @"none"}];
    // Keep initial ownership evidence and the latest fourteen events, including
    // terminal cleanup, even after a long kept session. No unbounded history.
    if (self.events.count > 16) [self.events removeObjectAtIndex:2];
    UIView *presentation = [self hostView];
    NSDictionary *report = @{@"schema": @10, @"version": @"1.0.4~rc5",
        @"sessionID": self.reportID ?: @"none", @"bundleIdentifier": self.bundleIdentifier ?: @"none",
        @"replacementAllowed": @(self.replacementAllowed), @"coldPreparation": @(self.coldStart),
        @"activationGraceSeconds": @(self.coldStart ? PPOWindowLifetime::ColdActivationGraceSeconds : PPOWindowLifetime::ActivationGraceSeconds),
        @"coldRenderObserved": @(_lifetime.observedRendered()),
        @"geometry": geometry,
        @"lastLiveSample": self.lastLiveSample ?: @{},
        @"lastHostedSourceSample": self.lastSourceSample ?: @{},
        @"lastOriginalSourceSample": self.lastOriginalSample ?: @{},
        @"sceneHost": self.session.snapshot ?: @{},
        @"lastLockSample": self.lastLockSample ?: @{},
        @"protectedDataAvailable": self.protectedDataSampled ? @(self.protectedDataAvailable) : (id)NSNull.null,
        @"lifetimeMode": _lifetime.kept() ? @"kept" : @"timed",
        @"heartbeatIntervalSeconds": @30,
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
                [data writeToFile:[directory stringByAppendingPathComponent:@"host-1.0.4.json"]
                    options:NSDataWritingAtomic error:NULL];
        }
    });
    NSLog(@"[PPO 1.0.4] host=%@ state=%@", event, self.session.state ?: @"none");
}
- (BOOL)isFinished {
    return NSThread.isMainThread && self.attempted && !self.opening && !self.running && !self.closing;
}
- (BOOL)replacementAllowed {
    if (!self.finished) return NO;
    if (self.closed) return self.cleanupConfirmed;
    // Refusal before resource acquisition is also safe to replace.
    return !self.session && !self.window && !self.observer && !self.backgroundObserver &&
        !self.protectedObserver && !self.deviceLockObserver && !self.timer;
}
- (BOOL)accessAllowed {
    if (!PPOTrialAllowed()) return NO;
    self.protectedDataAvailable = UIApplication.sharedApplication.protectedDataAvailable;
    self.protectedDataSampled = YES;
    if (!self.protectedDataAvailable) return NO;
    NSMutableDictionary *lock = [PPOReadScreenLockState(objc_lookUpClass("SBLockScreenManager"),
        [self.frameworks[@"matches"] boolValue]) mutableCopy];
    lock[@"sampleUptime"] = @(NSProcessInfo.processInfo.systemUptime);
    self.lastLockSample = lock;
    return [lock[@"status"] isEqual:@"sampled"] && ![lock[@"locked"] boolValue] &&
        ![lock[@"waitingToLock"] boolValue];
}
- (PPOWindowConditions)lifetimeConditions {
    PPOWindowConditions conditions;
    conditions.now = NSProcessInfo.processInfo.systemUptime;
    conditions.allowed = PPOTrialAllowed();
    if (!conditions.allowed) return conditions;
    self.protectedDataAvailable = UIApplication.sharedApplication.protectedDataAvailable;
    self.protectedDataSampled = YES;
    conditions.protectedDataAvailable = self.protectedDataAvailable;
    conditions.hostActive = self.windowScene &&
        self.windowScene.activationState == UISceneActivationStateForegroundActive;
    if (!conditions.protectedDataAvailable || !conditions.hostActive) return conditions;
    NSMutableDictionary *lock = [PPOReadScreenLockState(objc_lookUpClass("SBLockScreenManager"),
        [self.frameworks[@"matches"] boolValue]) mutableCopy];
    lock[@"sampleUptime"] = @(conditions.now); self.lastLockSample = lock;
    conditions.lockKnown = [lock[@"status"] isEqual:@"sampled"];
    if (!conditions.lockKnown) return conditions;
    conditions.locked = [lock[@"locked"] boolValue];
    conditions.waitingToLock = [lock[@"waitingToLock"] boolValue];
    if (conditions.locked || conditions.waitingToLock) return conditions;
    NSMutableDictionary *live = [[self.session sampleState] mutableCopy];
    live[@"sampleUptime"] = @(conditions.now); self.lastLiveSample = [live copy];
    conditions.sceneKnown = [live[@"status"] isEqual:@"sampled"];
    if (conditions.sceneKnown) {
        conditions.sceneValid = [live[@"valid"] boolValue];
        conditions.sceneActive = [live[@"active"] boolValue];
    }
    return conditions;
}
- (BOOL)checkLifetime {
    if (!NSThread.isMainThread || !self.running || self.closed || self.closing || self.closePending) return NO;
    @try {
        NSTimeInterval probeNow = NSProcessInfo.processInfo.systemUptime;
        if (self.coldStart && !_lifetime.observedRendered() && !self.opening && probeNow >= self.nextColdLayerProbe) {
            self.nextColdLayerProbe = probeNow + 0.5;
            [self sampleObservations];
        }
        PPOWindowConditions conditions = [self lifetimeConditions];
        if (!self.running || self.closed || self.closing || self.closePending) return NO;
        conditions.renderReady = [self.lastSourceSample[@"status"] isEqual:@"sampled"] &&
            [self.lastSourceSample[@"layerCount"] unsignedIntegerValue] > 0;
        PPOWindowStop stop = _lifetime.evaluate(conditions);
        if (_lifetime.observedRendered()) [self.startupSpinner stopAnimating];
        if (stop != PPOWindowStop::None) { [self closeBecause:PPOWindowStopName(stop)]; return NO; }
        if (!CGSizeEqualToSize(self.windowScene.coordinateSpace.bounds.size, self.fallbackNativeFrame.size)) {
            [self closeBecause:@"geometry-changed"]; return NO;
        }
        // The configured presentation preference uses the same guarded Keep policy,
        // once after the newly owned scene has actually become active. It does
        // not extend activation grace or repeatedly restart a deadline.
        if (!self.opening && !self.keepPreferenceAttempted && _lifetime.observedActive() &&
            (!self.coldStart || _lifetime.observedRendered()) &&
            [self.presentationPreferences[@"keepWindowOpen"] boolValue]) {
            self.keepPreferenceAttempted = YES;
            if (!_lifetime.kept() && _lifetime.keep(conditions)) {
                [self updateActionsMenu]; self.titleLabel.text = self.displayName;
                self.nextHeartbeat = conditions.now + 30;
                [self record:@"kept-by-preference"];
            }
        }
        return YES;
    } @catch (NSException *exception) {
        (void)exception; [self closeBecause:@"lifecycle-exception"]; return NO;
    }
}
- (void)keepFromButton:(UIButton *)sender {
    (void)sender;
    if (!NSThread.isMainThread || !self.running || self.opening || self.closed || self.closing || self.closePending) return;
    @try {
        if (![self checkLifetime]) return;
        PPOWindowConditions conditions = [self lifetimeConditions];
        if (!self.running || self.closed || self.closing || self.closePending) return;
        if (!_lifetime.keep(conditions)) { [self checkLifetime]; return; }
        [self updateActionsMenu];
        self.titleLabel.text = self.displayName;
        self.nextHeartbeat = NSProcessInfo.processInfo.systemUptime + 30;
        [self record:@"kept-by-user"];
    } @catch (NSException *exception) {
        (void)exception; [self closeBecause:@"keep-exception"];
    }
}
- (void)updateActionsMenu {
    __weak PPOOwnedSafariTrial *weakSelf = self;
    UIAction *keep = [UIAction actionWithTitle:_lifetime.kept() ? @"Păstrată" : @"Păstrează"
        image:nil identifier:nil handler:^(__kindof UIAction *action) {
            (void)action; dispatch_async(dispatch_get_main_queue(), ^{ [weakSelf keepFromButton:nil]; });
        }];
    if (_lifetime.kept()) { keep.attributes = UIMenuElementAttributesDisabled; keep.state = UIMenuElementStateOn; }
    UIAction *minimize = [UIAction actionWithTitle:@"Minimizează" image:nil identifier:nil
        handler:^(__kindof UIAction *action) { (void)action; dispatch_async(dispatch_get_main_queue(), ^{ [weakSelf minimizeFromButton:nil]; }); }];
    self.actionsButton.menu = [UIMenu menuWithTitle:@"" children:@[keep, minimize]];
    self.actionsButton.showsMenuAsPrimaryAction = YES;
}
- (NSString *)openInScene:(UIWindowScene *)scene bundleIdentifier:(NSString *)bundleIdentifier
              displayName:(NSString *)displayName capability:(NSDictionary *)capability {
    if (!NSThread.isMainThread || self.attempted) return @"Fereastră deja solicitată";
    self.attempted = YES;
    self.presentationPreferences = PPOUserPreferencesNormalize(self.presentationPreferences);
    self.presentedDrawerProgress = 1;
    NSInteger preferredSize = [self.presentationPreferences[@"windowSize"] integerValue];
    _sizePreset = preferredSize == 0 ? PPOFloatingSize::Compact
        : (preferredSize == 2 ? PPOFloatingSize::Large : PPOFloatingSize::Standard);
    if (!_presentation.start()) return @"Starea ferestrei nu poate fi inițializată";
    self.bundleIdentifier = [bundleIdentifier copy];
    self.reportID = NSUUID.UUID.UUIDString;
    self.frameworks = PPOSceneFrameworkIdentity();
    if (!PPOTrialAllowed() || ![self.presentationPreferences[@"enabled"] boolValue]) {
        [self record:@"disabled"]; return @"PPO este dezactivat";
    }
    NSDictionary *admission = PPOOwnedAdmissionSnapshot(self.bundleIdentifier, capability,
        NSProcessInfo.processInfo.systemUptime);
    if (!admission) {
        [self record:@"application-refused"];
        return @"Aplicația nu poate fi deschisă în fereastră";
    }
    self.sceneCapability = admission[@"sceneCapability"] == NSNull.null ? nil : admission[@"sceneCapability"];
    if (![self.frameworks[@"matches"] boolValue]) {
        [self record:@"framework-refused"]; return @"Firmware diferit; probă refuzată";
    }
    if (!scene || scene.activationState != UISceneActivationStateForegroundActive) {
        [self record:@"host-inactive"]; return @"Scena PPO nu este activă";
    }
    self.opening = YES;
    NSString *result = @"Fereastra nu poate fi deschisă";
    @try {
        if (![self accessAllowed]) {
            [self record:@"access-refused"]; return @"Fereastra nu poate fi deschisă în starea curentă";
        }
        id foreignScene = nil;
        self.selection = PPOFindUniqueScene(objc_lookUpClass("FBSceneManager"),
            objc_lookUpClass("FBScene"), bundleIdentifier, &foreignScene);
        if (!foreignScene && ![self.selection[@"state"] isEqual:@"not-found"]) {
            [self record:@"selection-refused"];
            return @"Scena aplicației nu poate fi selectată în siguranță";
        }
        self.coldStart = foreignScene == nil;
        if (self.coldStart && (![admission[@"basis"] isEqual:@"installed-info"] ||
            ![self.sceneCapability[@"status"] isEqual:@"eligible"])) {
            [self record:@"cold-admission-refused"];
            return @"Pornirea directă necesită verificarea aplicației instalate";
        }
        self.originalScene = foreignScene;
        self.windowScene = scene;
        __weak PPOOwnedSafariTrial *weakSelf = self;
        void (^inactive)(NSNotification *) = ^(NSNotification *note) {
            (void)note; [weakSelf closeAfterNotification:@"host-inactive"];
        };
        void (^protectedStop)(NSNotification *) = ^(NSNotification *note) {
            (void)note; [weakSelf closeAfterNotification:@"protected-data-unavailable"];
        };
        self.observer = [NSNotificationCenter.defaultCenter addObserverForName:UISceneWillDeactivateNotification
            object:scene queue:NSOperationQueue.mainQueue usingBlock:inactive];
        self.backgroundObserver = [NSNotificationCenter.defaultCenter addObserverForName:UISceneDidEnterBackgroundNotification
            object:scene queue:NSOperationQueue.mainQueue usingBlock:inactive];
        self.protectedObserver = [NSNotificationCenter.defaultCenter addObserverForName:UIApplicationProtectedDataWillBecomeUnavailable
            object:nil queue:NSOperationQueue.mainQueue usingBlock:protectedStop];
        self.deviceLockObserver = [NSNotificationCenter.defaultCenter
            addObserverForName:@"SBDeviceLockStateChangedNotification" object:nil
            queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) {
                (void)note; [weakSelf closeAfterNotification:@"device-lock-notification"];
            }];
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
        if (self.closePending || !PPOTrialAllowed() ||
            ![self.session prepareScene:foreignScene forBundleIdentifier:self.bundleIdentifier
                capability:self.sceneCapability]) return result;
        self.sourceScene = self.session.hostedScene;
        UIViewController *child = self.session.viewController;
        if (![child isKindOfClass:UIViewController.class] || child.parentViewController ||
            child.viewIfLoaded.superview || child.viewIfLoaded.window || self.closePending || !PPOTrialAllowed()) return result;
        self.childController = child;
        [self record:@"owned-scene-prepared"];
        CGRect screen = scene.coordinateSpace.bounds;
        self.placementInsets = PPOPlacementInsets(scene);
        PPOHostRect initial{};
        self.drawerSized = preferredSize == 3;
        if (self.drawerSized) {
            PPOEdgeDrawerSide side = [self.presentationPreferences[@"edge"] isEqual:@"left"]
                ? PPOEdgeDrawerSide::Left : PPOEdgeDrawerSide::Right;
            if (!PPOClassicAppPanelFrame(PPOFloatingRect(screen),
                {self.placementInsets.top,self.placementInsets.left,self.placementInsets.bottom,self.placementInsets.right},
                side,screen.size.width,screen.size.height,&initial)) return @"Spațiu insuficient pentru sertar";
        } else {
            if (!PPOFloatingInitial(PPOFloatingRect(screen), PPOFloatingSafeInsets(self.placementInsets),
                _sizePreset, &initial)) return @"Spațiu insuficient pentru fereastră";
            PPOHostRect usable{};
            if (!PPOFloatingUsable(PPOFloatingRect(screen), PPOFloatingSafeInsets(self.placementInsets), &usable))
                return @"Spațiu insuficient pentru fereastră";
            initial.x = [self.presentationPreferences[@"edge"] isEqual:@"left"]
                ? usable.x : usable.x + (usable.width - initial.width);
            initial.y = usable.y + (usable.height - initial.height) / 2;
        }
        CGFloat width = initial.width, height = initial.height;
        self.window = [[PPOOwnedPassthroughWindow alloc] initWithWindowScene:scene];
        self.window.frame = screen;
        self.window.windowLevel = UIWindowLevelStatusBar + 2;
        self.window.backgroundColor = UIColor.clearColor;
        self.window.clipsToBounds = YES;
        NSString *appearance = self.presentationPreferences[@"appearance"];
        self.window.overrideUserInterfaceStyle = [appearance isEqual:@"light"] ? UIUserInterfaceStyleLight
            : ([appearance isEqual:@"dark"] ? UIUserInterfaceStyleDark : UIUserInterfaceStyleUnspecified);
        UIViewController *root = [UIViewController new];
        self.rootController = root;
        self.window.rootViewController = root;
        root.view.frame = self.window.bounds;
        root.view.backgroundColor = UIColor.clearColor;
        root.view.clipsToBounds = YES;
        self.panelBaseFrame = CGRectMake(initial.x, initial.y, width, height);
        // The full-scene window uses its own bounds coordinates. Keep a separate
        // untransformed panel frame so interactive slides never feed geometry.
        UIView *panel = [[UIView alloc] initWithFrame:CGRectMake(initial.x - screen.origin.x,
            initial.y - screen.origin.y, width, height)];
        panel.backgroundColor = UIColor.secondarySystemBackgroundColor;
        panel.layer.cornerRadius = self.classicLayout ? 12 : 14; panel.clipsToBounds = YES;
        [root.view addSubview:panel]; self.panel = panel;
        ((PPOOwnedPassthroughWindow *)self.window).interactivePanel = panel;
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(12, 0, width - 156, 44)];
        NSString *name = [displayName isKindOfClass:NSString.class] && displayName.length > 0 && displayName.length <= 128
            ? displayName : @"PPO";
        title.text = [self.presentationPreferences[@"keepWindowOpen"] boolValue] ? name : [NSString stringWithFormat:@"%@ · 15 s", name];
        self.displayName = name; self.titleLabel = title;
        title.lineBreakMode = NSLineBreakByTruncatingTail; title.textColor = UIColor.labelColor;
        title.font = [UIFont systemFontOfSize:12]; title.userInteractionEnabled = YES;
        title.accessibilityHint = @"Trage pentru a muta fereastra";
        [title addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)]];
        [panel addSubview:title];
        UIButton *actions = [UIButton buttonWithType:UIButtonTypeSystem];
        actions.frame = CGRectMake(width - 132, 0, 44, 44);
        [actions setTitle:@"•••" forState:UIControlStateNormal];
        actions.accessibilityLabel = @"Acțiuni fereastră";
        self.actionsButton = actions; [self updateActionsMenu]; [panel addSubview:actions];
        UIButton *size = [UIButton buttonWithType:UIButtonTypeSystem];
        size.frame = CGRectMake(width - 88, 0, 44, 44);
        [size setTitle:@"↗" forState:UIControlStateNormal];
        size.accessibilityLabel = @"Schimbă dimensiunea ferestrei";
        size.accessibilityValue = _sizePreset == PPOFloatingSize::Large ? @"Mare"
            : (_sizePreset == PPOFloatingSize::Compact ? @"Mică" : @"Medie");
        [size addTarget:self action:@selector(resizeFromButton:) forControlEvents:UIControlEventTouchUpInside];
        self.sizeButton = size; [panel addSubview:size];
        UIButton *restore = [UIButton buttonWithType:UIButtonTypeSystem];
        restore.frame = CGRectMake(width - 88, 0, 44, 44);
        [restore setTitle:@"▢" forState:UIControlStateNormal];
        restore.accessibilityLabel = @"Restabilește fereastra"; restore.hidden = YES;
        [restore addTarget:self action:@selector(restoreFromButton:) forControlEvents:UIControlEventTouchUpInside];
        self.restoreButton = restore; [panel addSubview:restore];
        UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
        close.frame = CGRectMake(width - 44, 0, 44, 44);
        [close setTitle:@"✕" forState:UIControlStateNormal];
        [close addTarget:self action:@selector(closeFromButton:) forControlEvents:UIControlEventTouchUpInside];
        self.closeButton = close; [panel addSubview:close];
        BOOL classic = self.classicLayout;
        title.hidden = classic; actions.hidden = classic; size.hidden = classic; close.hidden = classic;
        CGFloat contentTop = classic ? 0 : 44;
        self.content = [[UIView alloc] initWithFrame:CGRectMake(0, contentTop, width, height - contentTop)];
        self.content.clipsToBounds = YES;
        // Preserve the container flag used in the observed 0.7.2 trial. This
        // UIView property does NOT establish blocking of remote scene input.
        // No event synthesis or private input/focus calls are introduced.
        self.content.userInteractionEnabled = NO;
        [panel addSubview:self.content];
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
        if (self.closePending || ![self accessAllowed]) return @"Deschiderea ferestrei a fost oprită";
        NSTimeInterval startedAt = NSProcessInfo.processInfo.systemUptime;
        if (!(self.coldStart ? _lifetime.startForApplicationIdentity(startedAt) : _lifetime.start(startedAt)))
            return @"Temporizator indisponibil";
        self.nextColdLayerProbe = startedAt + 0.25;
        if (self.coldStart) {
            self.startupSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
            self.startupSpinner.center = CGPointMake(CGRectGetMidX(self.content.bounds),CGRectGetMidY(self.content.bounds));
            self.startupSpinner.hidesWhenStopped = YES; self.startupSpinner.userInteractionEnabled = NO;
            [self.content addSubview:self.startupSpinner]; [self.startupSpinner startAnimating];
        }
        // Keep existing key-window ownership and app scene foreground/geometry.
        self.window.hidden = NO;
        [self record:@"window-shown"];
        if (self.closePending || !PPOTrialAllowed()) return result;
        self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        if (!self.timer) return @"Temporizator indisponibil; fereastra se închide";
        dispatch_source_set_timer(self.timer, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC / 4),
            NSEC_PER_SEC / 4, NSEC_PER_MSEC * 25);
        dispatch_source_set_event_handler(self.timer, ^{
            PPOOwnedSafariTrial *trial = weakSelf;
            if (!trial) return;
            if (![trial checkLifetime]) return;
            if (trial->_lifetime.kept() && NSProcessInfo.processInfo.systemUptime >= trial.nextHeartbeat) {
                trial.nextHeartbeat = NSProcessInfo.processInfo.systemUptime + 30;
                [trial captureState:@"kept-heartbeat"];
            }
        });
        dispatch_resume(self.timer);
        self.running = YES;
        if (![self checkLifetime]) return @"Fereastra a fost închisă de protecțiile active";
        if (![self applyDrawerTransform]) { [self closeBecause:@"drawer-layout-refused"]; return @"Geometria sertarului nu este disponibilă"; }
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
        // These early observations do not extend the timer or rewrite layout.
        for (NSNumber *delay in @[@2, @4, @6, @8, @10, @12]) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay.doubleValue * NSEC_PER_SEC)),
                dispatch_get_main_queue(), ^{
                    [weakSelf captureState:@"transition-sample"];
                });
        }
        result = [self.presentationPreferences[@"keepWindowOpen"] boolValue] ? @"Fereastră deschisă" : @"Fereastră deschisă; închidere automată în 15 s";
        return result;
    } @catch (NSException *exception) {
        (void)exception;
        if (!self.closeReason) self.closeReason = @"ui-exception";
        [self record:@"ui-exception"];
        return @"Fereastra s-a oprit după o eroare";
    } @finally {
        self.opening = NO;
        if (self.closePending || !self.running) [self closeBecause:self.closeReason ?: @"opening-failed"];
    }
}
- (UIView *)hostView { return self.childController.viewIfLoaded; }
- (BOOL)applyWindowFrame:(PPOHostRect)requested {
    if (!NSThread.isMainThread || !self.running || self.opening || self.closed ||
        self.closing || self.closePending || !self.window || !self.rootController || !self.panel || !self.content) return NO;
    CGRect screen = self.windowScene.coordinateSpace.bounds;
    if (!CGSizeEqualToSize(screen.size, self.fallbackNativeFrame.size)) return NO;
    PPOHostRect frame{};
    if (self.classicLayout) {
        PPOEdgeDrawerSide side = [self.presentationPreferences[@"edge"] isEqual:@"left"]
            ? PPOEdgeDrawerSide::Left : PPOEdgeDrawerSide::Right;
        if (!PPOClassicAppPanelFrame(PPOFloatingRect(screen),
            {self.placementInsets.top,self.placementInsets.left,self.placementInsets.bottom,self.placementInsets.right},
            side,self.fallbackNativeFrame.size.width,self.fallbackNativeFrame.size.height,&frame)) return NO;
    } else if (!_presentation.move(requested, PPOFloatingRect(screen), PPOFloatingSafeInsets(self.placementInsets),
        0, 0, &frame)) return NO;
    self.panelBaseFrame = CGRectMake(frame.x, frame.y, frame.width, frame.height);
    self.panel.transform = CGAffineTransformIdentity;
    self.panel.frame = CGRectMake(frame.x - screen.origin.x, frame.y - screen.origin.y,
        frame.width, frame.height);
    if (![self applyDrawerTransform]) return NO;
    BOOL minimized = _presentation.minimized();
    self.titleLabel.frame = CGRectMake(12, 0, frame.width - (minimized ? 112 : 156), 44);
    self.actionsButton.frame = CGRectMake(frame.width - 132, 0, 44, 44);
    self.sizeButton.frame = CGRectMake(frame.width - 88, 0, 44, 44);
    self.restoreButton.frame = CGRectMake(frame.width - 88, 0, 44, 44);
    self.closeButton.frame = CGRectMake(frame.width - 44, 0, 44, 44);
    BOOL classic = self.classicLayout;
    self.titleLabel.hidden = classic; self.closeButton.hidden = classic;
    self.actionsButton.hidden = classic || minimized; self.sizeButton.hidden = classic || minimized;
    self.restoreButton.hidden = classic || !minimized;
    self.panel.layer.cornerRadius = classic ? 12 : 14;
    // The minimized window clips below its 44-point bar. Keep the positive
    // expanded viewport, wrapper, native view and containment exactly in place.
    if (minimized) return self.content.bounds.size.width > 0 && self.content.bounds.size.height > 0;
    CGFloat contentTop = classic ? 0 : 44;
    self.content.frame = CGRectMake(0, contentTop, frame.width, frame.height - contentTop);
    self.sizeButton.accessibilityValue = _sizePreset == PPOFloatingSize::Large ? @"Mare"
        : (_sizePreset == PPOFloatingSize::Compact ? @"Mică" : @"Medie");
    // Resize only our viewport/wrapper. The child's native frame is supplied
    // once before containment; no attached private view or scene is resized.
    return [self fitPresentation];
}
- (void)resizeFromButton:(UIButton *)sender {
    (void)sender;
    if (!NSThread.isMainThread || !self.running || self.opening || self.closed || self.closing ||
        self.closePending || _presentation.minimized()) return;
    @try {
        if (![self checkLifetime]) return;
        PPOFloatingSize next = PPOFloatingNextSize(_sizePreset);
        PPOHostRect frame{};
        if (!PPOFloatingResize(PPOFloatingRect(self.panelBaseFrame),
            PPOFloatingRect(self.windowScene.coordinateSpace.bounds), PPOFloatingSafeInsets(self.placementInsets),
            next, &frame)) { [self closeBecause:@"resize-refused"]; return; }
        _sizePreset = next; self.drawerSized = NO;
        if (![self applyWindowFrame:frame]) { [self closeBecause:@"resize-layout-refused"]; return; }
        self.completedResizes = MIN(self.completedResizes + 1, (NSUInteger)1000000);
        [self captureLayout:@"window-resized"];
    } @catch (NSException *exception) {
        (void)exception; [self closeBecause:@"resize-exception"];
    }
}
- (void)minimizeFromButton:(UIButton *)sender {
    (void)sender;
    if (!NSThread.isMainThread || !self.running || self.opening || self.closed || self.closing ||
        self.closePending || _presentation.minimized()) return;
    @try {
        if (![self checkLifetime] || !_lifetime.observedActive()) return;
        PPOHostRect frame{};
        if (!_presentation.minimize(PPOFloatingRect(self.panelBaseFrame),
            PPOFloatingRect(self.windowScene.coordinateSpace.bounds), PPOFloatingSafeInsets(self.placementInsets),
            &frame) || ![self applyWindowFrame:frame]) {
            [self closeBecause:@"minimize-refused"]; return;
        }
        self.completedMinimizes = MIN(self.completedMinimizes + 1, (NSUInteger)1000000);
        [self captureLayout:@"window-minimized"];
    } @catch (NSException *exception) {
        (void)exception; [self closeBecause:@"minimize-exception"];
    }
}
- (void)restoreFromButton:(UIButton *)sender {
    (void)sender;
    if (!NSThread.isMainThread || !self.running || self.opening || self.closed || self.closing ||
        self.closePending || !_presentation.minimized()) return;
    @try {
        if (![self checkLifetime]) return;
        PPOHostRect frame{};
        if (!_presentation.restore(PPOFloatingRect(self.panelBaseFrame),
            PPOFloatingRect(self.windowScene.coordinateSpace.bounds), PPOFloatingSafeInsets(self.placementInsets),
            &frame) || ![self applyWindowFrame:frame]) {
            [self closeBecause:@"restore-refused"]; return;
        }
        self.completedRestores = MIN(self.completedRestores + 1, (NSUInteger)1000000);
        [self captureLayout:@"window-restored"];
    } @catch (NSException *exception) {
        (void)exception; [self closeBecause:@"restore-exception"];
    }
}
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
        @"presentationMode": self.closed ? @"closed" : (_presentation.minimized() ? @"minimized" : @"expanded"),
        @"minimizedAtClose": @(self.minimizedAtClose),
        @"completedMinimizes": @(self.completedMinimizes), @"completedRestores": @(self.completedRestores),
        @"savedExpandedFrame": NSStringFromCGRect(CGRectMake(_presentation.expandedFrame().x,
            _presentation.expandedFrame().y, _presentation.expandedFrame().width, _presentation.expandedFrame().height)),
        @"viewportFrame": self.content ? NSStringFromCGRect(self.content.frame) : @"none",
        @"sizePreset": self.drawerSized ? @"drawer" : PPOFloatingSizeName(_sizePreset),
        @"completedMoves": @(self.completedMoves), @"completedResizes": @(self.completedResizes),
        @"placementInsets": NSStringFromUIEdgeInsets(self.placementInsets), @"wrapperOnlyResize": @YES,
        @"panelBaseFrame": self.panel ? NSStringFromCGRect(self.panelBaseFrame) : @"none",
        @"panelTransform": self.panel ? NSStringFromCGAffineTransform(self.panel.transform) : @"none",
        @"drawerProgress": @(self.presentedDrawerProgress), @"drawerTravel": @(self.drawerTravel),
        @"fullScenePassthrough": @YES, @"classicInterface": @(self.classicLayout),
        @"contentHeaderHeight": self.classicLayout ? @0 : @44,
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
        if (!_presentation.minimized()) {
            [self.window.rootViewController.view layoutIfNeeded];
            [(UIView *)[self hostView] layoutIfNeeded];
            if (self.closed || self.closing || self.closePending) return;
            if (![self fitPresentation]) { [self closeBecause:@"geometry-refused"]; return; }
        }
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
        // A cold client may not have supplied layer/settings objects while inactive.
        // Wait for the independently sampled owned-scene activation; unsupported
        // active objects still stop this probe rather than being retried blindly.
        BOOL inspectLayers = !self.coldStart || ([self.lastLiveSample[@"status"] isEqual:@"sampled"] &&
            [self.lastLiveSample[@"active"] boolValue]);
        if (inspectLayers && !self.sourceProbeStopped && self.sourceScene && [self.frameworks[@"matches"] boolValue]) {
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
- (void)closeAfterNotification:(NSString *)reason {
    if (!NSThread.isMainThread || self.closed) return;
    BOOL wasPending = self.closePending;
    if (!self.closeReason) self.closeReason = [reason copy];
    self.closePending = YES;
    // Hide our public UI now, but do not call FrontBoard teardown inside a
    // SpringBoard/UIKit notification poster's transition stack.
    @try { self.content.userInteractionEnabled = NO; self.window.hidden = YES; }
    @catch (NSException *exception) { (void)exception; }
    [self notifyPresentationChange];
    if (wasPending) return; // Still attempt hiding on every notification.
    __weak PPOOwnedSafariTrial *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{ [weakSelf closeBecause:reason]; });
}
- (void)pan:(UIPanGestureRecognizer *)pan {
    if (!NSThread.isMainThread || !self.running || self.opening || self.closed || self.closing ||
        self.closePending || !self.window) return;
    @try {
        if (pan.state == UIGestureRecognizerStateBegan && ![self checkLifetime]) return;
        if (pan.state != UIGestureRecognizerStateBegan && pan.state != UIGestureRecognizerStateChanged &&
            pan.state != UIGestureRecognizerStateEnded) return;
        // Window-axis translation is a vector; placement is clamped in scene coordinates.
        CGPoint delta = [pan translationInView:self.window];
        PPOHostRect frame{};
        if (!_presentation.move(PPOFloatingRect(self.panelBaseFrame),
            PPOFloatingRect(self.windowScene.coordinateSpace.bounds), PPOFloatingSafeInsets(self.placementInsets),
            delta.x, delta.y, &frame) || ![self applyWindowFrame:frame]) {
            [self closeBecause:@"move-refused"]; return;
        }
        [pan setTranslation:CGPointZero inView:self.window];
        if (pan.state == UIGestureRecognizerStateEnded && [self checkLifetime]) {
            self.completedMoves = MIN(self.completedMoves + 1, (NSUInteger)1000000);
            [self record:@"window-moved"];
        }
    } @catch (NSException *exception) {
        (void)exception; [self closeBecause:@"move-exception"];
    }
}
- (void)close {
    if (!NSThread.isMainThread || self.closed) return;
    if (!self.closeReason) self.closeReason = @"external";
    if (self.opening) { self.closePending = YES; return; }
    self.minimizedAtClose = _presentation.minimized();
    _presentation.stop();
    self.closed = YES;
    self.closing = YES;
    self.running = NO;
    if (self.timer) { dispatch_source_cancel(self.timer); self.timer = nil; }
    for (id observer in @[self.observer ?: NSNull.null, self.backgroundObserver ?: NSNull.null,
                          self.protectedObserver ?: NSNull.null, self.deviceLockObserver ?: NSNull.null])
        if (observer != NSNull.null) [NSNotificationCenter.defaultCenter removeObserver:observer];
    self.observer = nil; self.backgroundObserver = nil; self.protectedObserver = nil;
    self.deviceLockObserver = nil;
    BOOL uiClean = YES;
    @try {
        self.content.userInteractionEnabled = NO;
        self.window.hidden = YES;
        [self.panel.layer removeAllAnimations];
        if (self.panel && self.panel.superview && self.panel.superview != self.rootController.view)
            uiClean = NO;
        if (self.content && self.content.superview && self.content.superview != self.panel)
            uiClean = NO;
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
    [self notifyPresentationChange];
    self.presentationDidChange = nil;
    // The owner invalidates only its independently created controller/scene.
    BOOL ownerClosed = !self.session || [self.session close];
    if (uiClean) {
        @try { self.window.rootViewController = nil; }
        @catch (NSException *exception) { (void)exception; uiClean = NO; }
    }
    if (uiClean) {
        [self.startupSpinner stopAnimating]; self.startupSpinner = nil;
        self.window = nil; self.panel = nil; self.content = nil; self.scalingWrapper = nil;
        self.childController = nil; self.rootController = nil;
        self.actionsButton = nil; self.titleLabel = nil;
        self.sizeButton = nil; self.closeButton = nil; self.restoreButton = nil;
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
