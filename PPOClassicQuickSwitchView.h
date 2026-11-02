#pragma once
#import <UIKit/UIKit.h>
#include <stdint.h>

NS_ASSUME_NONNULL_BEGIN

typedef UIImage * _Nullable (^PPOClassicQuickSwitchSymbolProvider)(NSString *identifier);
typedef void (^PPOClassicQuickSwitchChoiceHandler)(NSString *identifier, uint64_t generation);

// Public UIKit projection only. Rows are cached display data, never permission
// to launch or host an app. The owner must recheck the returned ID/generation.
// All entry points and callbacks are main-thread-only. Gesture points are in
// the containing root view's local coordinates, not UIScrollView coordinates.
@interface PPOClassicQuickSwitchView : UIView
@property(nonatomic, copy, nullable) PPOClassicQuickSwitchChoiceHandler selectionHandler;
@property(nonatomic, copy, nullable) PPOClassicQuickSwitchChoiceHandler normalLaunchHandler;
@property(nonatomic, copy, nullable) PPOClassicQuickSwitchSymbolProvider symbolProvider;
@property(nonatomic) BOOL hapticFeedbackEnabled;
@property(nonatomic, readonly, getter=isVisible) BOOL visible;
@property(nonatomic, readonly) uint64_t generation;

- (BOOL)presentRows:(NSArray<NSDictionary *> *)rows
        generation:(uint64_t)generation
            screen:(CGRect)screen
            insets:(UIEdgeInsets)insets
          leftEdge:(BOOL)leftEdge
     handleCenterY:(CGFloat)handleCenterY
 handleTouchHeight:(CGFloat)handleTouchHeight
             scale:(CGFloat)scale
              dark:(BOOL)dark
  hideInstructions:(BOOL)hideInstructions;
- (BOOL)relayoutWithScreen:(CGRect)screen insets:(UIEdgeInsets)insets
                 leftEdge:(BOOL)leftEdge handleCenterY:(CGFloat)handleCenterY
       handleTouchHeight:(CGFloat)handleTouchHeight;
- (void)updateGestureAtPoint:(CGPoint)point;
- (void)endGestureAtPoint:(CGPoint)point cancelled:(BOOL)cancelled;
- (void)dismiss;
@end

NS_ASSUME_NONNULL_END
