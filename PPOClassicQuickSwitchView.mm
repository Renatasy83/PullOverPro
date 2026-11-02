// PullOver Pro port — GPL-3.0. Original UI: c1d3r / Will Smillie.
// Compact layout is reconstructed with public UIKit; no private icon/switcher,
// scene, focus, application-launch or synthetic input operation occurs here.
#import "PPOClassicQuickSwitchView.h"
#include "PPOClassicInterfaceGeometry.h"
#import <QuartzCore/QuartzCore.h>
#include <cmath>

@interface PPOClassicChoiceButton : UIButton
@property(nonatomic) NSUInteger itemIndex;
@property(nonatomic) uint64_t projectionGeneration;
@end
@implementation PPOClassicChoiceButton
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    (void)event;
    return CGRectContainsPoint(CGRectInset(self.bounds, 0, -5), point);
}
@end

@class PPOClassicQuickSwitchView;
@interface PPOClassicScrollTarget : NSObject
@property(nonatomic, weak) PPOClassicQuickSwitchView *view;
- (void)tick:(CADisplayLink *)link;
@end

@interface PPOClassicQuickSwitchView () <UIScrollViewDelegate>
@property(nonatomic, copy) NSArray<NSDictionary *> *rows;
@property(nonatomic, strong) UIView *clipView;
@property(nonatomic, strong) UIScrollView *scrollView;
@property(nonatomic, strong) NSMutableArray<PPOClassicChoiceButton *> *buttons;
@property(nonatomic, strong) UIView *hoverBadge;
@property(nonatomic, strong) UILabel *hoverName;
@property(nonatomic, strong) UIView *dragBadge;
@property(nonatomic, strong) UILabel *dropHint;
@property(nonatomic, strong) UIView *dropTarget;
@property(nonatomic, strong) CAShapeLayer *dropOutline;
@property(nonatomic, strong) UISelectionFeedbackGenerator *feedback;
@property(nonatomic, strong) CADisplayLink *scrollLink;
@property(nonatomic, strong) PPOClassicScrollTarget *scrollTarget;
@property(nonatomic) uint64_t generation;
@property(nonatomic) CGRect sceneScreen;
@property(nonatomic) UIEdgeInsets sceneInsets;
@property(nonatomic) CGFloat handleCenterY;
@property(nonatomic) CGFloat hoverScale;
@property(nonatomic) BOOL leftEdge;
@property(nonatomic) BOOL dark;
@property(nonatomic) BOOL hideInstructions;
@property(nonatomic) BOOL presented;
@property(nonatomic) BOOL tracking;
@property(nonatomic) BOOL dragging;
@property(nonatomic) NSInteger hoveredIndex;
@property(nonatomic) NSInteger dragIndex;
@property(nonatomic) NSInteger lastChoiceIndex;
@property(nonatomic) uint64_t presentationSerial;
@property(nonatomic) BOOL emitting;
@property(nonatomic) CGPoint lastGesturePoint;
@property(nonatomic) CFTimeInterval lastScrollTick;
- (void)scrollTick:(CADisplayLink *)link;
- (void)selectButton:(PPOClassicChoiceButton *)button;
- (void)refreshHoverAtPoint:(CGPoint)point feedback:(BOOL)feedback;
- (void)stopTracking;
@end

@implementation PPOClassicScrollTarget
- (void)tick:(CADisplayLink *)link { [self.view scrollTick:link]; }
@end

static PPOHostRect ClassicRect(CGRect value) {
    return {value.origin.x, value.origin.y, value.size.width, value.size.height};
}
static CGRect ClassicCGRect(PPOHostRect value) {
    return CGRectMake(value.x, value.y, value.width, value.height);
}
static BOOL ClassicPoint(CGPoint value) {
    return std::isfinite(value.x) && std::isfinite(value.y) &&
        fabs(value.x) <= 32768 && fabs(value.y) <= 32768;
}
static NSArray<NSDictionary *> *ClassicRows(id value) {
    if (![value isKindOfClass:NSArray.class] || [value count] == 0 || [value count] > 16) return nil;
    NSMutableArray *rows = [NSMutableArray arrayWithCapacity:[value count]];
    NSMutableSet *identifiers = [NSMutableSet set];
    for (id item in (NSArray *)value) {
        if (![item isKindOfClass:NSDictionary.class]) return nil;
        id identifier = item[@"bundleIdentifier"], name = item[@"name"], available = item[@"available"];
        if (![identifier isKindOfClass:NSString.class] || ![identifier length] || [identifier length] > 512 ||
            ![name isKindOfClass:NSString.class] || ![name length] || [name length] > 512 ||
            ![available isKindOfClass:NSNumber.class] || [identifiers containsObject:identifier]) return nil;
        NSString *copied = [identifier copy]; [identifiers addObject:copied];
        [rows addObject:@{@"bundleIdentifier":copied, @"name":[name copy],
            @"available":[available boolValue] ? @YES : @NO}];
    }
    return [rows copy];
}

@implementation PPOClassicQuickSwitchView {
    PPOClassicQuickSwitchLayout _layout;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _rows = @[]; _buttons = [NSMutableArray array];
        _hoveredIndex = -1; _dragIndex = -1; _lastChoiceIndex = -1;
        _hapticFeedbackEnabled = YES;
        self.backgroundColor = UIColor.clearColor;
        self.hidden = YES;
        self.clipsToBounds = YES;
        _clipView = [UIView new]; _clipView.clipsToBounds = YES;
        _clipView.layer.cornerRadius = 17;
        [self addSubview:_clipView];
        _scrollView = [UIScrollView new];
        _scrollView.delegate = self;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.bounces = NO;
        [_clipView addSubview:_scrollView];
        _hoverName = [UILabel new]; _hoverName.userInteractionEnabled = NO;
        _hoverName.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
        _hoverName.textAlignment = NSTextAlignmentCenter;
        _hoverName.lineBreakMode = NSLineBreakByTruncatingTail;
        _hoverName.layer.cornerRadius = 10; _hoverName.clipsToBounds = YES;
        _hoverName.hidden = YES; [self addSubview:_hoverName];
        _dropTarget = [UIView new]; _dropTarget.userInteractionEnabled = NO;
        _dropTarget.hidden = YES; _dropTarget.layer.cornerRadius = 14;
        _dropOutline = [CAShapeLayer layer];
        _dropOutline.fillColor = UIColor.clearColor.CGColor;
        _dropOutline.lineWidth = 2; _dropOutline.lineDashPattern = @[@6,@4];
        [_dropTarget.layer addSublayer:_dropOutline];
        [self addSubview:_dropTarget];
        _dropHint = [UILabel new]; _dropHint.userInteractionEnabled = NO;
        _dropHint.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        _dropHint.textAlignment = NSTextAlignmentCenter; _dropHint.numberOfLines = 2;
        _dropHint.text = @"Eliberează pentru\na deschide aplicația";
        _dropHint.hidden = YES; [self addSubview:_dropHint];
    }
    return self;
}

- (BOOL)isVisible {
    return NSThread.isMainThread && self.presented && !self.hidden && self.superview &&
        !self.superview.hidden && self.window && !self.window.hidden;
}

- (CGRect)localRect:(PPOHostRect)rect {
    CGRect result = ClassicCGRect(rect);
    result.origin.x -= self.sceneScreen.origin.x; result.origin.y -= self.sceneScreen.origin.y;
    return result;
}

- (UIColor *)foreground { return self.dark ? UIColor.whiteColor : UIColor.blackColor; }
- (UIColor *)surface {
    return self.dark ? [UIColor colorWithWhite:0.13 alpha:0.97] : [UIColor colorWithWhite:0.98 alpha:0.97];
}

- (UIView *)badgeForIndex:(NSUInteger)index iconSize:(CGFloat)size {
    UIView *badge = [[UIView alloc] initWithFrame:CGRectMake(0,0,size,size)];
    badge.userInteractionEnabled = NO;
    NSDictionary *row = self.rows[index];
    UIImage *image = nil;
    if (self.symbolProvider) {
        @try {
            id supplied = self.symbolProvider(row[@"bundleIdentifier"]);
            if ([supplied isKindOfClass:UIImage.class]) image = supplied;
        } @catch (NSException *exception) { (void)exception; }
    }
    if (image) {
        UIImageView *icon = [[UIImageView alloc] initWithImage:image];
        icon.frame = badge.bounds; icon.contentMode = UIViewContentModeScaleAspectFit;
        icon.tintColor = [self foreground]; [badge addSubview:icon];
    } else {
        UILabel *initial = [[UILabel alloc] initWithFrame:badge.bounds];
        NSString *name = row[@"name"];
        initial.text = [name substringWithRange:[name rangeOfComposedCharacterSequenceAtIndex:0]];
        initial.textAlignment = NSTextAlignmentCenter; initial.textColor = [self foreground];
        initial.font = [UIFont systemFontOfSize:MAX(10,size*0.66) weight:UIFontWeightSemibold];
        initial.backgroundColor = [[self foreground] colorWithAlphaComponent:0.12];
        initial.layer.cornerRadius = 4; initial.clipsToBounds = YES;
        [badge addSubview:initial];
    }
    badge.alpha = [row[@"available"] boolValue] ? 1 : 0.35;
    return badge;
}

- (BOOL)presentRows:(NSArray<NSDictionary *> *)rows generation:(uint64_t)generation
            screen:(CGRect)screen insets:(UIEdgeInsets)insets leftEdge:(BOOL)leftEdge
     handleCenterY:(CGFloat)handleCenterY scale:(CGFloat)scale dark:(BOOL)dark
  hideInstructions:(BOOL)hideInstructions {
    if (!NSThread.isMainThread) return NO;
    [self dismiss];
    NSArray *snapshot = ClassicRows(rows);
    if (!snapshot || generation == 0 || !std::isfinite(scale) || scale < 1 || scale > 3) return NO;
    self.rows = snapshot; self.generation = generation; self.presentationSerial++;
    self.emitting = NO;
    self.hoverScale = scale; self.dark = dark; self.hideInstructions = hideInstructions;
    self.clipView.backgroundColor = [self surface]; self.hoverName.backgroundColor = [self surface];
    self.hoverName.textColor = [self foreground]; self.dropHint.textColor = [self foreground];
    self.dropTarget.backgroundColor = [[self surface] colorWithAlphaComponent:0.8];
    self.dropOutline.strokeColor = [self foreground].CGColor;
    if (![self relayoutWithScreen:screen insets:insets leftEdge:leftEdge handleCenterY:handleCenterY]) {
        [self dismiss]; return NO;
    }
    for (PPOClassicChoiceButton *button in self.buttons) [button removeFromSuperview];
    [self.buttons removeAllObjects];
    // Keep lookup indexed by original item, independent of upward visual order.
    for (NSUInteger index = 0; index < self.rows.count; index++) {
        PPOClassicChoiceButton *button = [PPOClassicChoiceButton new];
        button.itemIndex = index; button.projectionGeneration = generation;
        button.enabled = [self.rows[index][@"available"] boolValue];
        button.accessibilityLabel = self.rows[index][@"name"];
        button.accessibilityHint = @"Deschide în PullOver Pro";
        [button addTarget:self action:@selector(selectButton:) forControlEvents:UIControlEventTouchUpInside];
        [button addSubview:[self badgeForIndex:index iconSize:18]];
        [self.scrollView addSubview:button]; [self.buttons addObject:button];
    }
    [self layoutButtons];
    [self.scrollView setContentOffset:CGPointMake(0,_layout.initialScrollOffset) animated:NO];
    self.presented = YES; self.hidden = NO;
    if (self.hapticFeedbackEnabled) {
        self.feedback = [UISelectionFeedbackGenerator new];
        [self.feedback prepare]; [self.feedback selectionChanged];
    }
    return YES;
}

- (BOOL)relayoutWithScreen:(CGRect)screen insets:(UIEdgeInsets)insets
                 leftEdge:(BOOL)leftEdge handleCenterY:(CGFloat)handleCenterY {
    if (!NSThread.isMainThread) return NO;
    PPOClassicQuickSwitchLayout layout{};
    if (!PPOClassicMakeQuickSwitch(ClassicRect(screen), {insets.top,insets.left,insets.bottom,insets.right},
        leftEdge ? PPOEdgeDrawerSide::Left : PPOEdgeDrawerSide::Right, handleCenterY,
        self.rows.count, &layout)) return NO;
    BOOL same = CGRectEqualToRect(screen,self.sceneScreen) && UIEdgeInsetsEqualToEdgeInsets(insets,self.sceneInsets) &&
        leftEdge == self.leftEdge && handleCenterY == self.handleCenterY && _layout.count == layout.count;
    if (same) return YES;
    [self stopTracking];
    _layout = layout; self.sceneScreen = screen; self.sceneInsets = insets;
    self.leftEdge = leftEdge; self.handleCenterY = handleCenterY;
    self.frame = CGRectMake(0,0,screen.size.width,screen.size.height);
    CGRect visible = [self localRect:layout.visibleList];
    self.clipView.frame = visible;
    self.scrollView.frame = CGRectMake(layout.list.x-layout.visibleList.x,
        layout.list.y-layout.visibleList.y,layout.list.width,layout.list.height);
    self.scrollView.contentSize = CGSizeMake(layout.list.width,layout.contentHeight);
    self.scrollView.scrollEnabled = layout.scrollable;
    [self.scrollView setContentOffset:CGPointMake(0,layout.initialScrollOffset) animated:NO];
    CGRect safe = [self localRect:layout.safe];
    self.dropTarget.frame = CGRectMake(CGRectGetMidX(safe)-50,CGRectGetMidY(safe)-50,100,100);
    self.dropOutline.frame = self.dropTarget.bounds;
    self.dropOutline.path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(self.dropTarget.bounds,2,2) cornerRadius:12].CGPath;
    self.dropHint.frame = CGRectMake(MAX(CGRectGetMinX(safe),CGRectGetMidX(safe)-100),
        MIN(CGRectGetMaxY(safe)-40,CGRectGetMaxY(self.dropTarget.frame)+10),MIN(200,safe.size.width),38);
    [self layoutButtons];
    return YES;
}

- (void)layoutButtons {
    for (NSUInteger visual = 0; visual < _layout.count; visual++) {
        NSUInteger index = _layout.itemIndices[visual];
        if (index >= self.buttons.count) continue;
        PPOClassicChoiceButton *button = self.buttons[index];
        button.frame = ClassicCGRect(_layout.rows[visual]);
        UIView *badge = button.subviews.firstObject;
        badge.frame = CGRectMake(self.leftEdge ? 54 : 8,8,18,18);
    }
}

- (BOOL)itemAtPoint:(CGPoint)point index:(NSUInteger *)index {
    if (!ClassicPoint(point) || !self.visible) return NO;
    std::size_t found = 0;
    if (!PPOClassicQuickSwitchItemAtPoint(_layout, point.x+self.sceneScreen.origin.x,
        point.y+self.sceneScreen.origin.y,self.scrollView.contentOffset.y,&found) || found >= self.rows.count) return NO;
    if (index) *index = found;
    return YES;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    (void)event;
    return [self itemAtPoint:point index:NULL];
}
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    (void)event;
    NSUInteger index = 0;
    if (![self itemAtPoint:point index:&index] || index >= self.buttons.count) return nil;
    PPOClassicChoiceButton *button = self.buttons[index];
    // UIKit still sees the real UIScrollView ancestor for ordinary scrolling.
    return button.enabled ? button : self.scrollView;
}

- (void)showHoveredIndex:(NSInteger)index feedback:(BOOL)feedback {
    if (index == self.hoveredIndex) return;
    [self.hoverBadge removeFromSuperview]; self.hoverBadge = nil;
    self.hoverName.hidden = YES; self.hoveredIndex = index;
    if (index < 0 || (NSUInteger)index >= self.rows.count || ![self.rows[(NSUInteger)index][@"available"] boolValue]) return;
    if (feedback && self.hapticFeedbackEnabled) [self.feedback selectionChanged];
    PPOClassicChoiceButton *button = self.buttons[(NSUInteger)index];
    CGRect row = [button convertRect:button.bounds toView:self];
    UIView *badge = [[UIView alloc] initWithFrame:CGRectMake(0,0,80,34)];
    badge.userInteractionEnabled = NO; badge.backgroundColor = [self surface];
    badge.layer.cornerRadius = 17;
    UIView *icon = [self badgeForIndex:(NSUInteger)index iconSize:18];
    icon.frame = CGRectMake(self.leftEdge ? 54 : 8,8,18,18); [badge addSubview:icon];
    CGRect safe = [self localRect:_layout.safe];
    CGFloat scale = MIN(self.hoverScale,MIN(safe.size.width/80,safe.size.height/34));
    badge.transform = CGAffineTransformMakeScale(scale,scale);
    CGFloat halfWidth = 40*scale, halfHeight = 17*scale;
    CGFloat x = CGRectGetMidX(row), y = CGRectGetMidY(row);
    x = MAX(CGRectGetMinX(safe)+halfWidth,MIN(CGRectGetMaxX(safe)-halfWidth,x));
    y = MAX(CGRectGetMinY(safe)+halfHeight,MIN(CGRectGetMaxY(safe)-halfHeight,y));
    badge.center = CGPointMake(x,y); [self addSubview:badge]; self.hoverBadge = badge;
    CGFloat width = MIN(190,MAX(80,safe.size.width-80));
    CGFloat labelX = self.leftEdge ? CGRectGetMaxX(badge.frame)+8 : CGRectGetMinX(badge.frame)-width-8;
    labelX = MAX(CGRectGetMinX(safe),MIN(CGRectGetMaxX(safe)-width,labelX));
    self.hoverName.frame = CGRectMake(labelX,MAX(CGRectGetMinY(safe),MIN(CGRectGetMaxY(safe)-34,y-17)),width,34);
    self.hoverName.text = self.rows[(NSUInteger)index][@"name"]; self.hoverName.hidden = NO;
    [self bringSubviewToFront:self.hoverName];
}

- (void)refreshHoverAtPoint:(CGPoint)point feedback:(BOOL)feedback {
    NSUInteger index = 0;
    if ([self itemAtPoint:point index:&index] && [self.rows[index][@"available"] boolValue]) {
        self.lastChoiceIndex = (NSInteger)index;
        [self showHoveredIndex:(NSInteger)index feedback:feedback];
    } else [self showHoveredIndex:-1 feedback:NO];
}

- (void)beginDraggingIndex:(NSUInteger)index atPoint:(CGPoint)point {
    self.dragging = YES; self.dragIndex = (NSInteger)index;
    [self showHoveredIndex:-1 feedback:NO];
    self.dragBadge = [self badgeForIndex:index iconSize:44];
    self.dragBadge.layer.cornerRadius = 10; self.dragBadge.clipsToBounds = YES;
    self.dragBadge.backgroundColor = [self surface]; [self addSubview:self.dragBadge];
    self.dragBadge.center = point;
    self.dropTarget.hidden = NO; self.dropHint.hidden = self.hideInstructions;
    [self bringSubviewToFront:self.dragBadge]; self.scrollLink.paused = YES;
}

- (void)ensureScrollLink {
    if (self.scrollLink || !_layout.scrollable) return;
    self.scrollTarget = [PPOClassicScrollTarget new]; self.scrollTarget.view = self;
    self.scrollLink = [CADisplayLink displayLinkWithTarget:self.scrollTarget selector:@selector(tick:)];
    self.scrollLink.preferredFramesPerSecond = 30;
    [self.scrollLink addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
    self.scrollLink.paused = YES;
}

- (CGFloat)scrollDirectionAtPoint:(CGPoint)point {
    if (!self.visible || !_layout.scrollable || !self.tracking || self.dragging) return 0;
    CGRect visible = [self localRect:_layout.visibleList];
    if (point.x < CGRectGetMinX(visible) || point.x >= CGRectGetMaxX(visible)) return 0;
    if (point.y >= CGRectGetMinY(visible) && point.y < CGRectGetMinY(visible)+12) return -1;
    if (point.y < CGRectGetMaxY(visible) && point.y >= CGRectGetMaxY(visible)-12) return 1;
    return 0;
}

- (void)updateGestureAtPoint:(CGPoint)point {
    if (!NSThread.isMainThread || !self.visible) return;
    if (!ClassicPoint(point)) { [self dismiss]; return; }
    self.tracking = YES; self.lastGesturePoint = point;
    NSUInteger index = 0;
    BOOL hit = [self itemAtPoint:point index:&index];
    CGRect visible = [self localRect:_layout.visibleList];
    BOOL inward = self.leftEdge ? point.x >= CGRectGetMaxX(visible) : point.x < CGRectGetMinX(visible);
    if (self.dragging && hit && [self.rows[index][@"available"] boolValue]) {
        self.dragging = NO; self.dragIndex = -1;
        [self.dragBadge removeFromSuperview]; self.dragBadge = nil;
        self.dropTarget.hidden = YES; self.dropHint.hidden = YES;
    }
    if (!self.dragging && !hit && inward && self.lastChoiceIndex >= 0)
        [self beginDraggingIndex:(NSUInteger)self.lastChoiceIndex atPoint:point];
    if (self.dragging) {
        CGRect safe = [self localRect:_layout.safe];
        self.dragBadge.center = CGPointMake(MAX(CGRectGetMinX(safe)+22,MIN(CGRectGetMaxX(safe)-22,point.x)),
            MAX(CGRectGetMinY(safe)+22,MIN(CGRectGetMaxY(safe)-22,point.y)));
        self.dropTarget.backgroundColor = CGRectContainsPoint(self.dropTarget.frame,point)
            ? [[UIColor systemBlueColor] colorWithAlphaComponent:0.25] : [self surface];
    } else {
        [self refreshHoverAtPoint:point feedback:YES];
        [self ensureScrollLink];
        self.scrollLink.paused = [self scrollDirectionAtPoint:point] == 0;
        if (!self.scrollLink.paused) self.lastScrollTick = 0;
    }
}

- (void)scrollTick:(CADisplayLink *)link {
    if (!NSThread.isMainThread || !self.visible || !self.tracking || self.dragging) {
        link.paused = YES; return;
    }
    CGFloat direction = [self scrollDirectionAtPoint:self.lastGesturePoint];
    if (direction == 0) { link.paused = YES; return; }
    CFTimeInterval elapsed = self.lastScrollTick > 0 ? link.timestamp-self.lastScrollTick : 1.0/30;
    self.lastScrollTick = link.timestamp;
    if (!std::isfinite(elapsed) || elapsed <= 0) return;
    CGFloat offset = self.scrollView.contentOffset.y;
    CGFloat maximum = MAX(0,_layout.contentHeight-_layout.list.height);
    CGFloat next = MAX(0,MIN(maximum,offset+direction*80*MIN(elapsed,0.05)));
    if (next == offset) { link.paused = YES; return; }
    [self.scrollView setContentOffset:CGPointMake(0,next) animated:NO];
    [self refreshHoverAtPoint:self.lastGesturePoint feedback:YES];
}

- (void)selectButton:(PPOClassicChoiceButton *)button {
    if (!self.visible || self.tracking || button.projectionGeneration != self.generation ||
        button.itemIndex >= self.rows.count || ![self.rows[button.itemIndex][@"available"] boolValue]) return;
    [self emitIndex:button.itemIndex normal:NO];
}

- (void)emitIndex:(NSUInteger)index normal:(BOOL)normal {
    if (!self.visible || self.emitting || index >= self.rows.count || ![self.rows[index][@"available"] boolValue]) return;
    self.emitting = YES;
    __attribute__((objc_precise_lifetime)) PPOClassicQuickSwitchView *keepAlive = self;
    (void)keepAlive;
    NSString *identifier = [self.rows[index][@"bundleIdentifier"] copy];
    uint64_t generation = self.generation, serial = self.presentationSerial;
    PPOClassicQuickSwitchChoiceHandler handler = normal ? self.normalLaunchHandler : self.selectionHandler;
    [self stopTracking];
    if (handler) handler(identifier,generation); // Owner checks its current immutable projection before acting.
    if (self.presentationSerial == serial) [self dismiss];
}

- (void)endGestureAtPoint:(CGPoint)point cancelled:(BOOL)cancelled {
    if (!NSThread.isMainThread || !self.visible) return;
    if (cancelled || !ClassicPoint(point)) { [self dismiss]; return; }
    if (self.dragging) {
        NSInteger index = self.dragIndex;
        if (index >= 0 && CGRectContainsPoint(self.dropTarget.frame,point))
            [self emitIndex:(NSUInteger)index normal:YES];
        else [self dismiss];
    } else {
        NSUInteger index = 0;
        if ([self itemAtPoint:point index:&index] && [self.rows[index][@"available"] boolValue])
            [self emitIndex:index normal:NO];
        else [self dismiss];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    (void)scrollView;
    if (self.tracking && !self.dragging && self.visible)
        [self refreshHoverAtPoint:self.lastGesturePoint feedback:YES];
}

- (void)stopTracking {
    self.tracking = NO; self.dragging = NO; self.hoveredIndex = -1; self.dragIndex = -1; self.lastChoiceIndex = -1;
    self.feedback = nil; self.lastScrollTick = 0;
    [self.scrollLink invalidate]; self.scrollLink = nil; self.scrollTarget = nil;
    [self.hoverBadge removeFromSuperview]; self.hoverBadge = nil;
    [self.dragBadge removeFromSuperview]; self.dragBadge = nil;
    self.hoverName.hidden = YES; self.dropTarget.hidden = YES; self.dropHint.hidden = YES;
}
- (void)dismiss {
    if (!NSThread.isMainThread) return;
    [self stopTracking]; self.presented = NO; self.hidden = YES;
    self.presentationSerial++; self.emitting = NO;
}
- (void)dealloc { [_scrollLink invalidate]; }

@end
