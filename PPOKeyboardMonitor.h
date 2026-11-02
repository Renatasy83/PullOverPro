#pragma once
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Public UIKit observations only. An absent/invalidated/stale observation is
// unknown, not proof that another process has no keyboard. This monitor never
// requests a key window/focus, moves views, or changes application scenes.
// All public entry points/getters are main-thread-only. Getters may discard
// stale cached frame metadata, but never call changed or alter a view.
@interface PPOKeyboardMonitor : NSObject
- (nullable instancetype)initWithScene:(UIWindowScene *)scene
                              changed:(nullable void (^)(void))changed NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@property(nonatomic, readonly) CGRect keyboardFrameInScene; // CGRectNull when hidden/unknown.
@property(nonatomic, readonly) BOOL frameKnown;
@property(nonatomic, readonly) BOOL visible;
@property(nonatomic, readonly) NSUInteger notificationCount; // Keyboard events, capped at1,000,000.
@property(nonatomic, readonly, copy) NSString *status; // Bounded reason, never notification contents.
- (void)resetFrameForReason:(nullable NSString *)reason;
- (void)invalidate;
@end

NS_ASSUME_NONNULL_END
