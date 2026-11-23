// PullOver Pro (rootless) — SpringBoard hooks.
// Original by c1d3r (Will Smillie), GPL-3.0. iOS 15-27 rootless and RootHide support: Jond-ie.
// Changes from the original: the licence check, the What's New sheet and the
// activation alert are gone, and the window is attached to SpringBoard's scene.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "headers.h"
#import "PullOverWindow.h"
#import "POApplicationHelper.h"
#import "POLog.h"
#import <notify.h>
#import <objc/runtime.h>

static PullOverWindow *window;

// The drawer shows only while the phone is unlocked: SpringBoard's lock state aggregator says 0. The system
// lock notification is the answer only where the aggregator is missing; otherwise it is one more moment to
// look again (it reads "unlocked" while the Lock Screen is still up after Face ID, so it cannot decide alone).
// 3.0.0 started invisible and only looked when the aggregator changed, so a phone where that change did not
// arrive after a respring, or whose scene connected late, never showed the handle (issue #1).
static int POLockToken = NOTIFY_TOKEN_INVALID;

static BOOL POUnlocked(void) {
    Class cls = objc_getClass("SBLockStateAggregator");
    SBLockStateAggregator *aggregator = [cls respondsToSelector:@selector(sharedInstance)] ? [cls sharedInstance] : nil;
    if ([aggregator respondsToSelector:@selector(lockState)]) return [aggregator lockState] == 0;
    uint64_t state = 1;
    if (notify_is_valid_token(POLockToken) && notify_get_state(POLockToken, &state) == NOTIFY_STATUS_OK) return state == 0;
    return YES; // nothing to ask: show it, as a hidden handle is the worse failure
}

static void POUpdateVisibility(void) {
    if (!window) return;
    [window attachSceneIfNeeded];
    CGFloat alpha = POUnlocked() ? 1 : 0;
    POLog(@"visibility: unlocked=%d scene=%d hidden=%d alpha %.0f -> %.0f", (int)alpha, window.windowScene != nil, window.hidden, window.alpha, alpha);
    if (window.alpha == alpha) return;
    [UIView animateWithDuration:0.2 animations:^{ window.alpha = alpha; }];
}

@interface SpringBoard (PullOver)
- (void)addActiveOrientationObserver:(id)observer;
@end

// Hides the drawer in landscape when "Hide in Landscape" is on.
@interface POOrientationObserver : NSObject
+ (instancetype)shared;
@end

@implementation POOrientationObserver
+ (instancetype)shared {
    static POOrientationObserver *shared;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ shared = [self new]; });
    return shared;
}
- (void)activeInterfaceOrientationWillChangeToOrientation:(long long)orientation {}
- (void)activeInterfaceOrientationDidChangeToOrientation:(long long)orientation willAnimateWithDuration:(double)duration fromOrientation:(long long)from {
    if (!window || ![[POApplicationHelper settings][@"hideInLandscape"] boolValue]) return;
    BOOL portrait = (orientation == UIInterfaceOrientationPortrait);
    if (!portrait && [window.controller isOpened]) {
        [window.controller endHosting];
        [window.controller close];
    }
    [UIView animateWithDuration:0.2 animations:^{
        window.rootViewController.view.alpha = portrait ? 1 : 0;
    }];
}
@end

// Settings changed in the settings page: re-read them and rebuild the drawer
// so every option applies without a respring.
static void POPrefsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [POApplicationHelper reloadSettings];
        BOOL enabled = [[POApplicationHelper settings][@"enabled"] boolValue];
        if (enabled && !window) {
            window = [PullOverWindow sharedWindow];
            window.alpha = 0;
            [window makeKeyAndVisible];
        }
        [window applySettings];
        POUpdateVisibility();
    });
}

// "Close When Going Home" (on by default): the Home button, the home swipe and anything else
// that lands on the Home Screen tucks the pulled-over app away.
static BOOL POCloseOnHome(void) {
    return [[POApplicationHelper settings][@"closeOnHome"] boolValue];
}

// Commands from other tweaks (POShared.h). Ignored while the drawer is hidden:
// switched off, on the Lock Screen, or in landscape with "Hide in Landscape" on.
static void POCommand(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    NSString *command = [(__bridge NSString *)name lastPathComponent];
    dispatch_async(dispatch_get_main_queue(), ^{
        PullOverViewController *controller = window.controller;
        if (!controller || window.hidden || window.alpha == 0 || controller.view.alpha == 0) return;
        BOOL open = [command isEqualToString:@"open"] || ([command isEqualToString:@"toggle"] && !controller.isOpened);
        if (open) {
            if (controller.isOpened) return;
            if (controller.handle.isNubbed) controller.handle.isNubbed = NO;
            [controller open];
        } else if (controller.isOpened) {
            [controller close];
        }
    });
}

%hook SpringBoard

- (void)applicationDidFinishLaunching:(UIApplication *)arg1{
    %orig;

    if (![[POApplicationHelper settings][@"enabled"] boolValue]) return;

    window = [PullOverWindow sharedWindow];
    window.alpha = 0;
    [window makeKeyAndVisible];
    [window applySettings];
    // Work out visibility now and again shortly after: SpringBoard is still starting, and neither the lock
    // state nor the window scene is guaranteed to be settled at this point.
    POUpdateVisibility();
    for (NSNumber *delay in @[@1, @3, @8]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay.doubleValue * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ POUpdateVisibility(); });
    }

    // Orientation: SpringBoard's own observer list (same API on iOS 15-27)
    // instead of hooking noteInterfaceOrientationChanged:, which iOS 27 dropped.
    if ([self respondsToSelector:@selector(addActiveOrientationObserver:)]) {
        [self addActiveOrientationObserver:[POOrientationObserver shared]];
    }
}

// Remember the front app (nil = Home Screen). _accessibilityFrontMostApplication
// is not declared on iOS 27, frontDisplayDidChange: exists on 15-27.
-(void)frontDisplayDidChange:(id)display{
    %orig;
    NSString *front = [display respondsToSelector:@selector(bundleIdentifier)] ? [display bundleIdentifier] : nil;
    POSetFrontMostBundleId(front);
    // Back on the Home Screen. The transition hook above already closed the drawer as the animation
    // began; this is the fallback, and re-attaches the app when the drawer stays open.
    if (!front && [window.controller isOpened]) {
        if (POCloseOnHome()) {
            dispatch_async(dispatch_get_main_queue(), ^{ [window.controller close]; });
        } else {
            // Staying open: going home sends every app to the background, the pulled-over one too
            // (it shows black). Attach it again once the Home Screen has settled.
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                PullOverViewController *c = window.controller;
                if (![c isOpened]) return;
                [c endHosting];
                [c retryHostingIfNeeded];
            });
        }
    }
}
%end

// Closes the drawer as the trip home STARTS (swipe released, Home pressed, an action), so it slides away
// with iOS's own animation. Same API on iOS 15-27. unlockedEnvironmentMode 1 = Home Screen.
@protocol POLayoutState <NSObject>
- (long long)unlockedEnvironmentMode;
@end
@protocol POLayoutTransitionContext <NSObject>
- (id<POLayoutState>)toLayoutState;
@end
%hook SBFluidSwitcherViewController
- (void)layoutStateTransitionCoordinator:(id)coordinator transitionDidBeginWithTransitionContext:(id)context {
    %orig;
    if (![window.controller isOpened] || !POCloseOnHome()) return;
    id<POLayoutState> to = [context respondsToSelector:@selector(toLayoutState)] ? [(id<POLayoutTransitionContext>)context toLayoutState] : nil;
    if ([to respondsToSelector:@selector(unlockedEnvironmentMode)] && [to unlockedEnvironmentMode] == 1) {
        [window.controller close];
    }
}
%end

%hook SBFluidSwitcherGestureManager
-(void)grabberTongueBeganPulling:(id)arg1 withDistance:(double)arg2 andVelocity:(double)arg3 {
    if ([window.controller isOpened] && POCloseOnHome()){
        [window.controller close];
        [self grabberTongueCanceledPulling:arg1 withDistance:arg2 andVelocity:arg3];
    }else{
        %orig;
    }
}
%end

%hook SBHomeHardwareButton
-(void)singlePressUp:(id)arg1{
    if ([window.controller isOpened] && POCloseOnHome()){
        [window.controller close];
    }else{
        %orig;
    }
}
%end

%hook SBLockHardwareButton
-(void)singlePress:(id)arg1 {
    if ([window.controller isOpened]){
        [window.controller close];
    }
    %orig;
}
%end

// Control Center or Notification Center closes the drawer as soon as it STARTS
// coming down, not after. Both methods exist on iOS 15-27 (checked against 15.8.6 to 27.0.1).
%hook SBControlCenterController
- (void)_willPresent {
    if ([window.controller isOpened]) [window.controller close];
    %orig;
}
%end

%hook SBCoverSheetPresentationManager
- (void)_prepareForPresentationTransitionForUserGesture:(BOOL)gesture {
    if ([window.controller isOpened]) [window.controller close];
    %orig;
}
%end

%hook SBLockStateAggregator
-(void)_updateLockState{
    %orig;
    POUpdateVisibility();
}
%end

%ctor {
    notify_register_dispatch("com.apple.springboard.lockstate", &POLockToken, dispatch_get_main_queue(), ^(int token) { POUpdateVisibility(); });
    [[NSNotificationCenter defaultCenter] addObserverForName:UISceneDidActivateNotification object:nil queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) { POUpdateVisibility(); }];
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, POPrefsChanged,
                                    CFSTR(POPrefsChangedNotification), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    for (NSString *name in @[@POOpenNotification, @POCloseNotification, @POToggleNotification]) {
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, POCommand,
                                        (__bridge CFStringRef)name, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    }
}
