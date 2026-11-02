// PullOver Pro port — GPL-3.0. Public keyboard observations, no focus or scene mutation.
#import "PPOKeyboardMonitor.h"
#include <cmath>
#include <cstring>
#include <initializer_list>

static BOOL MonitorFiniteRect(CGRect rect, BOOL positive) {
    for (CGFloat value : {rect.origin.x, rect.origin.y, rect.size.width, rect.size.height})
        if (!std::isfinite(value) || std::abs(value) > 32768) return NO;
    if (rect.size.width < 0 || rect.size.height < 0 ||
        (positive && (rect.size.width <= 0 || rect.size.height <= 0))) return NO;
    return std::abs(CGRectGetMaxX(rect)) <= 32768 && std::abs(CGRectGetMaxY(rect)) <= 32768;
}

static NSString *MonitorResetReason(NSString *reason) {
    if (![reason isKindOfClass:NSString.class] || reason.length > 64) return @"reset";
    for (NSString *allowed in @[@"locked", @"host-inactive", @"protected-data-unavailable",
             @"geometry-changed", @"scene-unavailable", @"malformed-notification", @"reset"])
        if ([reason isEqualToString:allowed]) return allowed;
    return @"reset";
}

@interface PPOKeyboardMonitor ()
- (void)removeOwnObservers;
- (void)clearStoredFrame:(NSString *)reason;
- (void)notifyChanged;
- (nullable NSString *)availabilityFailure;
- (BOOL)validateCapturedState;
- (void)receiveKeyboardNotification:(NSNotification *)note;
@end

@implementation PPOKeyboardMonitor {
    __weak UIWindowScene *_scene;
    __weak UIScreen *_capturedScreen;
    CGRect _capturedSceneBounds;
    CGRect _capturedScreenBounds;
    UIInterfaceOrientation _capturedOrientation;
    CGRect _frame;
    BOOL _frameKnown;
    BOOL _visible;
    BOOL _invalidated;
    BOOL _notifyingChanged;
    NSUInteger _notificationCount;
    NSString *_state;
    void (^_changed)(void);
    NSNotificationCenter *_center;
    NSMutableArray *_tokens;
}

- (instancetype)initWithScene:(UIWindowScene *)scene changed:(void (^)(void))changed {
    if (!NSThread.isMainThread || ![scene isKindOfClass:UIWindowScene.class]) return nil;
    self = [super init];
    if (self) {
        _scene = scene; _frame = CGRectNull; _state = @"not-observed";
        _changed = [changed copy]; _tokens = [NSMutableArray array];
        _center = NSNotificationCenter.defaultCenter;
        __weak PPOKeyboardMonitor *weakSelf = self;
        @try {
            for (NSNotificationName name in @[UIKeyboardWillChangeFrameNotification,
                    UIKeyboardDidChangeFrameNotification, UIKeyboardDidHideNotification]) {
                id token = [_center addObserverForName:name object:nil queue:NSOperationQueue.mainQueue
                    usingBlock:^(NSNotification *note) {
                        [weakSelf receiveKeyboardNotification:note];
                    }];
                if (!token) { [self invalidate]; return nil; }
                [_tokens addObject:token];
            }
            for (NSNotificationName name in @[UISceneWillDeactivateNotification, UISceneDidEnterBackgroundNotification]) {
                id token = [_center addObserverForName:name object:scene queue:NSOperationQueue.mainQueue
                    usingBlock:^(NSNotification *note) {
                        (void)note; [weakSelf resetFrameForReason:@"host-inactive"];
                    }];
                if (!token) { [self invalidate]; return nil; }
                [_tokens addObject:token];
            }
            id protectedToken = [_center addObserverForName:UIApplicationProtectedDataWillBecomeUnavailable
                object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) {
                    (void)note; [weakSelf resetFrameForReason:@"protected-data-unavailable"];
                }];
            if (!protectedToken) { [self invalidate]; return nil; }
            [_tokens addObject:protectedToken];
        } @catch (NSException *exception) {
            (void)exception; [self invalidate]; return nil;
        }
    }
    return self;
}

- (void)removeOwnObservers {
    for (id token in _tokens) [_center removeObserver:token];
    [_tokens removeAllObjects];
}

- (void)clearStoredFrame:(NSString *)reason {
    _frame = CGRectNull; _frameKnown = NO; _visible = NO; _capturedScreen = nil;
    _capturedSceneBounds = CGRectZero; _capturedScreenBounds = CGRectZero;
    _capturedOrientation = UIInterfaceOrientationUnknown; _state = reason;
}

- (void)notifyChanged {
    if (!NSThread.isMainThread || _invalidated || !_changed || _notifyingChanged) return;
    __attribute__((objc_precise_lifetime)) PPOKeyboardMonitor *keepAlive = self;
    (void)keepAlive;
    void (^changed)(void) = _changed;
    _notifyingChanged = YES;
    @try { changed(); }
    @catch (NSException *exception) {
        // A failing public callback must not propagate through UIKit's poster.
        (void)exception; _changed = nil; [self clearStoredFrame:@"callback-disabled"];
    } @finally { _notifyingChanged = NO; }
}

- (NSString *)availabilityFailure {
    if (!NSThread.isMainThread) return @"wrong-thread";
    if (_invalidated) return @"invalidated";
    UIWindowScene *scene = _scene;
    if (!scene || !scene.screen) return @"scene-unavailable";
    if (!UIApplication.sharedApplication.protectedDataAvailable) return @"protected-data-unavailable";
    if (scene.activationState != UISceneActivationStateForegroundActive) return @"host-inactive";
    return nil;
}

- (BOOL)validateCapturedState {
    NSString *failure = [self availabilityFailure];
    if (failure) {
        if (NSThread.isMainThread && !_invalidated) [self clearStoredFrame:failure];
        return NO;
    }
    if (!_frameKnown) return NO;
    UIWindowScene *scene = _scene;
    UIScreen *screen = scene.screen;
    if (!screen || screen != _capturedScreen ||
        !CGRectEqualToRect(scene.coordinateSpace.bounds, _capturedSceneBounds) ||
        !CGRectEqualToRect(screen.coordinateSpace.bounds, _capturedScreenBounds) ||
        scene.interfaceOrientation != _capturedOrientation) {
        // Latch an observed geometry change. Returning to the old bounds must
        // not revive this keyboard frame without another public notification.
        [self clearStoredFrame:@"geometry-changed"]; return NO;
    }
    return YES;
}

- (CGRect)keyboardFrameInScene {
    return [self validateCapturedState] && _visible ? _frame : CGRectNull;
}
- (BOOL)frameKnown { return [self validateCapturedState]; }
- (BOOL)visible { return [self validateCapturedState] && _visible; }
- (NSUInteger)notificationCount { return NSThread.isMainThread ? _notificationCount : 0; }
- (NSString *)status {
    NSString *failure = [self availabilityFailure];
    if (failure) {
        if (NSThread.isMainThread && !_invalidated) [self clearStoredFrame:failure];
        return failure;
    }
    [self validateCapturedState]; // Discards stale metadata without invoking changed.
    return _state ?: @"not-observed";
}

- (void)resetFrameForReason:(NSString *)reason {
    if (!NSThread.isMainThread || _invalidated) return;
    [self clearStoredFrame:MonitorResetReason(reason)]; [self notifyChanged];
}

- (void)receiveKeyboardNotification:(NSNotification *)note {
    if (!NSThread.isMainThread || _invalidated) return;
    if (_notificationCount < 1000000) _notificationCount++;
    NSString *failure = [self availabilityFailure];
    if (failure) { [self resetFrameForReason:failure]; return; }
    @try {
        UIWindowScene *scene = _scene;
        UIScreen *screen = scene.screen;
        CGRect sceneBounds = scene.coordinateSpace.bounds, screenBounds = screen.coordinateSpace.bounds;
        if (!MonitorFiniteRect(sceneBounds, YES) || !MonitorFiniteRect(screenBounds, YES)) {
            [self resetFrameForReason:@"geometry-changed"]; return;
        }
        BOOL didHide = [note.name isEqualToString:UIKeyboardDidHideNotification];
        if (!didHide && ![note.name isEqualToString:UIKeyboardWillChangeFrameNotification] &&
            ![note.name isEqualToString:UIKeyboardDidChangeFrameNotification]) {
            [self resetFrameForReason:@"malformed-notification"]; return;
        }
        CGRect converted = CGRectNull;
        if (!didHide) {
            id raw = note.userInfo[UIKeyboardFrameEndUserInfoKey];
            if (![raw isKindOfClass:NSValue.class]) {
                [self resetFrameForReason:@"malformed-notification"]; return;
            }
            const char *encoding = [(NSValue *)raw objCType];
            if (!encoding || std::strcmp(encoding, @encode(CGRect)) != 0) {
                [self resetFrameForReason:@"malformed-notification"]; return;
            }
            CGRect end = [(NSValue *)raw CGRectValue];
            if (!MonitorFiniteRect(end, NO)) {
                [self resetFrameForReason:@"malformed-notification"]; return;
            }
            converted = [scene.coordinateSpace convertRect:end fromCoordinateSpace:screen.coordinateSpace];
            if (!MonitorFiniteRect(converted, NO)) {
                [self resetFrameForReason:@"malformed-notification"]; return;
            }
        }
        if (scene != _scene || screen != scene.screen ||
            !CGRectEqualToRect(sceneBounds, scene.coordinateSpace.bounds) ||
            !CGRectEqualToRect(screenBounds, screen.coordinateSpace.bounds)) {
            [self resetFrameForReason:@"geometry-changed"]; return;
        }
        failure = [self availabilityFailure];
        if (failure) { [self resetFrameForReason:failure]; return; }
        CGRect intersection = didHide ? CGRectNull : CGRectIntersection(converted, sceneBounds);
        _visible = !didHide && !CGRectIsNull(intersection) && !CGRectIsEmpty(intersection);
        _frame = _visible ? converted : CGRectNull; _frameKnown = YES;
        _capturedScreen = screen; _capturedSceneBounds = sceneBounds;
        _capturedScreenBounds = screenBounds; _capturedOrientation = scene.interfaceOrientation;
        _state = _visible ? @"visible" : @"hidden";
        [self notifyChanged];
    } @catch (NSException *exception) {
        (void)exception; [self resetFrameForReason:@"malformed-notification"];
    }
}

- (void)invalidate {
    if (!NSThread.isMainThread || _invalidated) return;
    _invalidated = YES; _changed = nil; [self removeOwnObservers];
    [self clearStoredFrame:@"invalidated"]; _scene = nil;
}
- (void)dealloc {
    // Removing our own observation tokens is safe even if the last external
    // owner releases off-main. No UIKit getter or callback occurs on this path.
    [self removeOwnObservers];
}
@end
