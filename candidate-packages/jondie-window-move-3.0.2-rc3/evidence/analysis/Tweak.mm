#line 1 "Tweak/Tweak.xm"






#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "headers.h"
#import "PullOverWindow.h"
#import "POApplicationHelper.h"
#import "POLog.h"
#import <notify.h>
#import <objc/runtime.h>

static PullOverWindow *window;






static int POLockToken = NOTIFY_TOKEN_INVALID;

static BOOL POUnlocked(void) {
    Class cls = objc_getClass("SBLockStateAggregator");
    SBLockStateAggregator *aggregator = [cls respondsToSelector:@selector(sharedInstance)] ? [cls sharedInstance] : nil;
    if ([aggregator respondsToSelector:@selector(lockState)]) return [aggregator lockState] == 0;
    uint64_t state = 1;
    if (notify_is_valid_token(POLockToken) && notify_get_state(POLockToken, &state) == NOTIFY_STATUS_OK) return state == 0;
    return YES; 
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



static BOOL POCloseOnHome(void) {
    return [[POApplicationHelper settings][@"closeOnHome"] boolValue];
}



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


#include <substrate.h>
#if defined(__clang__)
#if __has_feature(objc_arc)
#define _LOGOS_SELF_TYPE_NORMAL __unsafe_unretained
#define _LOGOS_SELF_TYPE_INIT __attribute__((ns_consumed))
#define _LOGOS_SELF_CONST const
#define _LOGOS_RETURN_RETAINED __attribute__((ns_returns_retained))
#else
#define _LOGOS_SELF_TYPE_NORMAL
#define _LOGOS_SELF_TYPE_INIT
#define _LOGOS_SELF_CONST
#define _LOGOS_RETURN_RETAINED
#endif
#else
#define _LOGOS_SELF_TYPE_NORMAL
#define _LOGOS_SELF_TYPE_INIT
#define _LOGOS_SELF_CONST
#define _LOGOS_RETURN_RETAINED
#endif

__asm__(".linker_option \"-framework\", \"CydiaSubstrate\"");

@class SBLockStateAggregator; @class SBCoverSheetPresentationManager; @class SBHomeHardwareButton; @class SBFluidSwitcherGestureManager; @class SpringBoard; @class SBControlCenterController; @class SBLockHardwareButton; @class SBFluidSwitcherViewController; 
static void (*_logos_orig$_ungrouped$SpringBoard$applicationDidFinishLaunching$)(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL, UIApplication *); static void _logos_method$_ungrouped$SpringBoard$applicationDidFinishLaunching$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL, UIApplication *); static void (*_logos_orig$_ungrouped$SpringBoard$frontDisplayDidChange$)(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL, id); static void _logos_method$_ungrouped$SpringBoard$frontDisplayDidChange$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL, id); static void (*_logos_orig$_ungrouped$SBFluidSwitcherViewController$layoutStateTransitionCoordinator$transitionDidBeginWithTransitionContext$)(_LOGOS_SELF_TYPE_NORMAL SBFluidSwitcherViewController* _LOGOS_SELF_CONST, SEL, id, id); static void _logos_method$_ungrouped$SBFluidSwitcherViewController$layoutStateTransitionCoordinator$transitionDidBeginWithTransitionContext$(_LOGOS_SELF_TYPE_NORMAL SBFluidSwitcherViewController* _LOGOS_SELF_CONST, SEL, id, id); static void (*_logos_orig$_ungrouped$SBFluidSwitcherGestureManager$grabberTongueBeganPulling$withDistance$andVelocity$)(_LOGOS_SELF_TYPE_NORMAL SBFluidSwitcherGestureManager* _LOGOS_SELF_CONST, SEL, id, double, double); static void _logos_method$_ungrouped$SBFluidSwitcherGestureManager$grabberTongueBeganPulling$withDistance$andVelocity$(_LOGOS_SELF_TYPE_NORMAL SBFluidSwitcherGestureManager* _LOGOS_SELF_CONST, SEL, id, double, double); static void (*_logos_orig$_ungrouped$SBHomeHardwareButton$singlePressUp$)(_LOGOS_SELF_TYPE_NORMAL SBHomeHardwareButton* _LOGOS_SELF_CONST, SEL, id); static void _logos_method$_ungrouped$SBHomeHardwareButton$singlePressUp$(_LOGOS_SELF_TYPE_NORMAL SBHomeHardwareButton* _LOGOS_SELF_CONST, SEL, id); static void (*_logos_orig$_ungrouped$SBLockHardwareButton$singlePress$)(_LOGOS_SELF_TYPE_NORMAL SBLockHardwareButton* _LOGOS_SELF_CONST, SEL, id); static void _logos_method$_ungrouped$SBLockHardwareButton$singlePress$(_LOGOS_SELF_TYPE_NORMAL SBLockHardwareButton* _LOGOS_SELF_CONST, SEL, id); static void (*_logos_orig$_ungrouped$SBControlCenterController$_willPresent)(_LOGOS_SELF_TYPE_NORMAL SBControlCenterController* _LOGOS_SELF_CONST, SEL); static void _logos_method$_ungrouped$SBControlCenterController$_willPresent(_LOGOS_SELF_TYPE_NORMAL SBControlCenterController* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$_ungrouped$SBCoverSheetPresentationManager$_prepareForPresentationTransitionForUserGesture$)(_LOGOS_SELF_TYPE_NORMAL SBCoverSheetPresentationManager* _LOGOS_SELF_CONST, SEL, BOOL); static void _logos_method$_ungrouped$SBCoverSheetPresentationManager$_prepareForPresentationTransitionForUserGesture$(_LOGOS_SELF_TYPE_NORMAL SBCoverSheetPresentationManager* _LOGOS_SELF_CONST, SEL, BOOL); static void (*_logos_orig$_ungrouped$SBLockStateAggregator$_updateLockState)(_LOGOS_SELF_TYPE_NORMAL SBLockStateAggregator* _LOGOS_SELF_CONST, SEL); static void _logos_method$_ungrouped$SBLockStateAggregator$_updateLockState(_LOGOS_SELF_TYPE_NORMAL SBLockStateAggregator* _LOGOS_SELF_CONST, SEL); 

#line 114 "Tweak/Tweak.xm"


static void _logos_method$_ungrouped$SpringBoard$applicationDidFinishLaunching$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, UIApplication * arg1){
    _logos_orig$_ungrouped$SpringBoard$applicationDidFinishLaunching$(self, _cmd, arg1);

    if (![[POApplicationHelper settings][@"enabled"] boolValue]) return;

    window = [PullOverWindow sharedWindow];
    window.alpha = 0;
    [window makeKeyAndVisible];
    [window applySettings];
    
    
    POUpdateVisibility();
    for (NSNumber *delay in @[@1, @3, @8]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay.doubleValue * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ POUpdateVisibility(); });
    }

    
    
    if ([self respondsToSelector:@selector(addActiveOrientationObserver:)]) {
        [self addActiveOrientationObserver:[POOrientationObserver shared]];
    }
}



static void _logos_method$_ungrouped$SpringBoard$frontDisplayDidChange$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id display){
    _logos_orig$_ungrouped$SpringBoard$frontDisplayDidChange$(self, _cmd, display);
    NSString *front = [display respondsToSelector:@selector(bundleIdentifier)] ? [display bundleIdentifier] : nil;
    POSetFrontMostBundleId(front);
    
    
    if (!front && [window.controller isOpened]) {
        if (POCloseOnHome()) {
            dispatch_async(dispatch_get_main_queue(), ^{ [window.controller close]; });
        } else {
            
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                PullOverViewController *c = window.controller;
                if (![c isOpened]) return;
                [c endHosting];
                [c retryHostingIfNeeded];
            });
        }
    }
}




@protocol POLayoutState <NSObject>
- (long long)unlockedEnvironmentMode;
@end
@protocol POLayoutTransitionContext <NSObject>
- (id<POLayoutState>)toLayoutState;
@end

static void _logos_method$_ungrouped$SBFluidSwitcherViewController$layoutStateTransitionCoordinator$transitionDidBeginWithTransitionContext$(_LOGOS_SELF_TYPE_NORMAL SBFluidSwitcherViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id coordinator, id context) {
    _logos_orig$_ungrouped$SBFluidSwitcherViewController$layoutStateTransitionCoordinator$transitionDidBeginWithTransitionContext$(self, _cmd, coordinator, context);
    if (![window.controller isOpened] || !POCloseOnHome()) return;
    id<POLayoutState> to = [context respondsToSelector:@selector(toLayoutState)] ? [(id<POLayoutTransitionContext>)context toLayoutState] : nil;
    if ([to respondsToSelector:@selector(unlockedEnvironmentMode)] && [to unlockedEnvironmentMode] == 1) {
        [window.controller close];
    }
}



static void _logos_method$_ungrouped$SBFluidSwitcherGestureManager$grabberTongueBeganPulling$withDistance$andVelocity$(_LOGOS_SELF_TYPE_NORMAL SBFluidSwitcherGestureManager* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id arg1, double arg2, double arg3) {
    if ([window.controller isOpened] && POCloseOnHome()){
        [window.controller close];
        [self grabberTongueCanceledPulling:arg1 withDistance:arg2 andVelocity:arg3];
    }else{
        _logos_orig$_ungrouped$SBFluidSwitcherGestureManager$grabberTongueBeganPulling$withDistance$andVelocity$(self, _cmd, arg1, arg2, arg3);
    }
}



static void _logos_method$_ungrouped$SBHomeHardwareButton$singlePressUp$(_LOGOS_SELF_TYPE_NORMAL SBHomeHardwareButton* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id arg1){
    if ([window.controller isOpened] && POCloseOnHome()){
        [window.controller close];
    }else{
        _logos_orig$_ungrouped$SBHomeHardwareButton$singlePressUp$(self, _cmd, arg1);
    }
}



static void _logos_method$_ungrouped$SBLockHardwareButton$singlePress$(_LOGOS_SELF_TYPE_NORMAL SBLockHardwareButton* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id arg1) {
    if ([window.controller isOpened]){
        [window.controller close];
    }
    _logos_orig$_ungrouped$SBLockHardwareButton$singlePress$(self, _cmd, arg1);
}





static void _logos_method$_ungrouped$SBControlCenterController$_willPresent(_LOGOS_SELF_TYPE_NORMAL SBControlCenterController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    if ([window.controller isOpened]) [window.controller close];
    _logos_orig$_ungrouped$SBControlCenterController$_willPresent(self, _cmd);
}



static void _logos_method$_ungrouped$SBCoverSheetPresentationManager$_prepareForPresentationTransitionForUserGesture$(_LOGOS_SELF_TYPE_NORMAL SBCoverSheetPresentationManager* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, BOOL gesture) {
    if ([window.controller isOpened]) [window.controller close];
    _logos_orig$_ungrouped$SBCoverSheetPresentationManager$_prepareForPresentationTransitionForUserGesture$(self, _cmd, gesture);
}



static void _logos_method$_ungrouped$SBLockStateAggregator$_updateLockState(_LOGOS_SELF_TYPE_NORMAL SBLockStateAggregator* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd){
    _logos_orig$_ungrouped$SBLockStateAggregator$_updateLockState(self, _cmd);
    POUpdateVisibility();
}


static __attribute__((constructor)) void _logosLocalCtor_28a06894(int __unused argc, char __unused **argv, char __unused **envp) {
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
static __attribute__((constructor)) void _logosLocalInit() {
{Class _logos_class$_ungrouped$SpringBoard = objc_getClass("SpringBoard"); { MSHookMessageEx(_logos_class$_ungrouped$SpringBoard, @selector(applicationDidFinishLaunching:), (IMP)&_logos_method$_ungrouped$SpringBoard$applicationDidFinishLaunching$, (IMP*)&_logos_orig$_ungrouped$SpringBoard$applicationDidFinishLaunching$);}{ MSHookMessageEx(_logos_class$_ungrouped$SpringBoard, @selector(frontDisplayDidChange:), (IMP)&_logos_method$_ungrouped$SpringBoard$frontDisplayDidChange$, (IMP*)&_logos_orig$_ungrouped$SpringBoard$frontDisplayDidChange$);}Class _logos_class$_ungrouped$SBFluidSwitcherViewController = objc_getClass("SBFluidSwitcherViewController"); { MSHookMessageEx(_logos_class$_ungrouped$SBFluidSwitcherViewController, @selector(layoutStateTransitionCoordinator:transitionDidBeginWithTransitionContext:), (IMP)&_logos_method$_ungrouped$SBFluidSwitcherViewController$layoutStateTransitionCoordinator$transitionDidBeginWithTransitionContext$, (IMP*)&_logos_orig$_ungrouped$SBFluidSwitcherViewController$layoutStateTransitionCoordinator$transitionDidBeginWithTransitionContext$);}Class _logos_class$_ungrouped$SBFluidSwitcherGestureManager = objc_getClass("SBFluidSwitcherGestureManager"); { MSHookMessageEx(_logos_class$_ungrouped$SBFluidSwitcherGestureManager, @selector(grabberTongueBeganPulling:withDistance:andVelocity:), (IMP)&_logos_method$_ungrouped$SBFluidSwitcherGestureManager$grabberTongueBeganPulling$withDistance$andVelocity$, (IMP*)&_logos_orig$_ungrouped$SBFluidSwitcherGestureManager$grabberTongueBeganPulling$withDistance$andVelocity$);}Class _logos_class$_ungrouped$SBHomeHardwareButton = objc_getClass("SBHomeHardwareButton"); { MSHookMessageEx(_logos_class$_ungrouped$SBHomeHardwareButton, @selector(singlePressUp:), (IMP)&_logos_method$_ungrouped$SBHomeHardwareButton$singlePressUp$, (IMP*)&_logos_orig$_ungrouped$SBHomeHardwareButton$singlePressUp$);}Class _logos_class$_ungrouped$SBLockHardwareButton = objc_getClass("SBLockHardwareButton"); { MSHookMessageEx(_logos_class$_ungrouped$SBLockHardwareButton, @selector(singlePress:), (IMP)&_logos_method$_ungrouped$SBLockHardwareButton$singlePress$, (IMP*)&_logos_orig$_ungrouped$SBLockHardwareButton$singlePress$);}Class _logos_class$_ungrouped$SBControlCenterController = objc_getClass("SBControlCenterController"); { MSHookMessageEx(_logos_class$_ungrouped$SBControlCenterController, @selector(_willPresent), (IMP)&_logos_method$_ungrouped$SBControlCenterController$_willPresent, (IMP*)&_logos_orig$_ungrouped$SBControlCenterController$_willPresent);}Class _logos_class$_ungrouped$SBCoverSheetPresentationManager = objc_getClass("SBCoverSheetPresentationManager"); { MSHookMessageEx(_logos_class$_ungrouped$SBCoverSheetPresentationManager, @selector(_prepareForPresentationTransitionForUserGesture:), (IMP)&_logos_method$_ungrouped$SBCoverSheetPresentationManager$_prepareForPresentationTransitionForUserGesture$, (IMP*)&_logos_orig$_ungrouped$SBCoverSheetPresentationManager$_prepareForPresentationTransitionForUserGesture$);}Class _logos_class$_ungrouped$SBLockStateAggregator = objc_getClass("SBLockStateAggregator"); { MSHookMessageEx(_logos_class$_ungrouped$SBLockStateAggregator, @selector(_updateLockState), (IMP)&_logos_method$_ungrouped$SBLockStateAggregator$_updateLockState, (IMP*)&_logos_orig$_ungrouped$SBLockStateAggregator$_updateLockState);}} }
#line 247 "Tweak/Tweak.xm"
