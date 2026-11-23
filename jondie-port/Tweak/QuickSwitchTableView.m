//
//  QuickSwitchTableView.m
//  PullOverPro
//
//  Created by Will Smillie on 4/8/19.
//

#import "QuickSwitchTableView.h"
#import "POLog.h"
#import <AudioToolbox/AudioToolbox.h>
#import <CoreGraphics/CoreGraphics.h>

#import "PullOverWindow.h"
#import "../Shared/POQuickSwitchGeometry.h"
#import "../Shared/POPreferencesValidation.h"

@interface QuickSwitchTableView (){
    NSDictionary *settings;
    NSArray<NSString *> *items; // immutable for the lifetime of one gesture
    NSString *selectedBundleId;
    __weak UILongPressGestureRecognizer *activeRecognizer;
    NSTimer *autoscrollTimer;
    BOOL gestureActive;
    NSUInteger gestureGeneration;
    
    NSIndexPath *lastHoveredIndexPath;
    UITableViewCell *lastCellToAnimate;
    UITableViewCell *thisCellToAnimate;
    SBApplication *draggingApp;
    
    float scale;
}

@end

@implementation QuickSwitchTableView

-(instancetype)initWithDarkMode:(BOOL)darkMode{
    if (self = [super init]) {
        [self registerClass:[QuickSwitchTableViewCell class] forCellReuseIdentifier:@"QuickSwitchCell"];
        self.alpha = 0;
        self.clipsToBounds = NO;
        [self.layer setShadowColor:[UIColor blackColor].CGColor];
        [self.layer setShadowOpacity:0.4];
        [self.layer setShadowRadius:4.0];
        [self.layer setShadowOffset:CGSizeMake(0, 0)];
        self.separatorColor = [UIColor clearColor];
        self.darkMode = darkMode;

        self.delegate = self;
        self.dataSource = self;
        
        self.backgroundColor = self.darkMode?[UIColor darkGrayColor]:[UIColor whiteColor];
        self.layer.cornerRadius = 34/2;
        
        
        if (@available(iOS 13, *)){
            self.backgroundColor = [UIColor performSelector:@selector(secondarySystemBackgroundColor)];
        }else{
            self.backgroundColor = [[POApplicationHelper settings][@"darkHandle"] boolValue] ? [UIColor darkGrayColor] : [UIColor whiteColor];
        }

        
        [self refresh];
    }
    return self;
}

-(void)refresh{
    settings = [POApplicationHelper settings];
    scale = [settings[@"quickswitchScale"] floatValue];
    NSArray *source = [settings[@"style"] isEqualToString:@"Recent Apps"]
        ? [POApplicationHelper recentAppsWithCount:[settings[@"recentAppsCount"] intValue]]
        : settings[@"favorites"];
    NSMutableOrderedSet *snapshot = [NSMutableOrderedSet orderedSet];
    for (id identifier in source) {
        if (POValidFavoriteIdentifier(identifier)) [snapshot addObject:[identifier copy]];
    }
    items = [snapshot.array copy];
    POLog(@"quickswitch style=%@ items=%@", settings[@"style"], items);
    [self reloadData];
}

-(BOOL)isValidIndexPath:(NSIndexPath *)indexPath{
    return indexPath && indexPath.section == 0 && POQuickSwitchValidRow(indexPath.row, items.count);
}

-(void)hoverAtPoint:(CGPoint)point{
    if (!CGRectContainsPoint(self.bounds, point)) return;
    NSIndexPath *indexPath = [self indexPathForRowAtPoint:point];
    if (![self isValidIndexPath:indexPath]) return;
    if (![indexPath isEqual:lastHoveredIndexPath] || draggingApp) {
        [self.selectionDelegate draggingDidEnterBoundsOfQuickSwitchTableView:self];
        if ([settings[@"hapticFeedback"] boolValue]) AudioServicesPlaySystemSound(1519);
        lastCellToAnimate = [self isValidIndexPath:lastHoveredIndexPath]
            ? [self cellForRowAtIndexPath:lastHoveredIndexPath] : nil;
        thisCellToAnimate = [self cellForRowAtIndexPath:indexPath];
        [self animateZoomforCellremove:lastCellToAnimate];
        [self animateZoomforCell:thisCellToAnimate];
        lastHoveredIndexPath = indexPath;
        selectedBundleId = [items[indexPath.row] copy];
        draggingApp = nil;
    }
}

-(SBApplication *)selectedApplication{
    if (!selectedBundleId) return nil;
    Class controllerClass = objc_getClass("SBApplicationController");
    if (![controllerClass respondsToSelector:@selector(sharedInstance)]) return nil;
    id controller = [controllerClass sharedInstance];
    if (![controller respondsToSelector:@selector(applicationWithBundleIdentifier:)]) return nil;
    return [controller applicationWithBundleIdentifier:selectedBundleId];
}

-(void)autoscrollTick{
    UILongPressGestureRecognizer *recognizer = activeRecognizer;
    if (!gestureActive || !recognizer ||
        (recognizer.state != UIGestureRecognizerStateBegan && recognizer.state != UIGestureRecognizerStateChanged)) {
        [autoscrollTimer invalidate];
        autoscrollTimer = nil;
        return;
    }
    CGPoint point = [recognizer locationInView:self];
    if (point.x < CGRectGetMinX(self.bounds) || point.x > CGRectGetMaxX(self.bounds)) return;
    CGFloat offset = POQuickSwitchScrollOffset(self.contentOffset.y, self.contentSize.height,
        self.bounds.size.height, point.y - CGRectGetMinY(self.bounds), 1.0 / 30.0);
    if (fabs(offset - self.contentOffset.y) > 0.01) {
        [self setContentOffset:CGPointMake(0, offset) animated:NO];
        [self layoutIfNeeded];
        [self hoverAtPoint:[recognizer locationInView:self]];
    }
}

-(void)presentFromHandle:(UIView *)handle withRecognizer:(UILongPressGestureRecognizer *)recognizer{
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [autoscrollTimer invalidate];
        autoscrollTimer = nil;
        gestureActive = NO;
        gestureGeneration++;
        selectedBundleId = nil;
        draggingApp = nil;
        lastHoveredIndexPath = nil;
        [self refresh];
        if (items.count == 0 || !self.superview) return;

        // Convert the real safe area into the handle scroll view's coordinates.
        // This accounts for its content offset and the left-handed transform.
        UIWindow *window = self.window;
        CGRect safeBounds = self.superview.bounds;
        if (window) {
            CGRect windowSafeBounds = UIEdgeInsetsInsetRect(window.bounds, window.safeAreaInsets);
            safeBounds = [self.superview convertRect:windowSafeBounds fromView:window];
        }
        POQuickSwitchViewport viewport = POQuickSwitchMakeViewport(
            CGRectGetMinY(safeBounds), CGRectGetMaxY(safeBounds),
            CGRectGetMinY(handle.frame), CGRectGetHeight(handle.frame), 34, items.count);
        if (viewport.height <= 0) return;
        if (viewport.reversed) items = [[[items reverseObjectEnumerator] allObjects] copy];
        self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        if (@available(iOS 15.0, *)) self.sectionHeaderTopPadding = 0;
        self.contentInset = UIEdgeInsetsZero;
        self.frame = CGRectMake(handle.frame.origin.x, viewport.origin, handle.frame.size.width, viewport.height);
        self.clipsToBounds = viewport.height + 0.5 < 34 * items.count;
        self.showsVerticalScrollIndicator = self.clipsToBounds;
        [self reloadData];
        [self layoutIfNeeded];
        CGFloat initialOffset = viewport.reversed ? MAX(0, self.contentSize.height - self.bounds.size.height) : 0;
        [self setContentOffset:CGPointMake(0, initialOffset) animated:NO];
        gestureActive = YES;
        activeRecognizer = recognizer;
        [self.layer removeAllAnimations];
        [self present];
        [self.selectionDelegate quickSwitchTableViewWillAppear:self];
        [self hoverAtPoint:[recognizer locationInView:self]];
        if (self.clipsToBounds) {
            __weak QuickSwitchTableView *weakSelf = self;
            autoscrollTimer = [NSTimer timerWithTimeInterval:1.0 / 30.0 repeats:YES block:^(NSTimer *timer) {
                [weakSelf autoscrollTick];
            }];
            [[NSRunLoop mainRunLoop] addTimer:autoscrollTimer forMode:NSRunLoopCommonModes];
        }
        return;
    }
    if (!gestureActive) return;
    CGPoint point = [recognizer locationInView:self];
    BOOL horizontalInside = point.x >= CGRectGetMinX(self.bounds) && point.x <= CGRectGetMaxX(self.bounds);
    if (recognizer.state == UIGestureRecognizerStateChanged) {
        if (horizontalInside) {
            [self hoverAtPoint:point];
        } else if (selectedBundleId) {
            [self animateZoomforCellremove:thisCellToAnimate];
            [self animateZoomforCellremove:lastCellToAnimate];
            if (!draggingApp) draggingApp = [self selectedApplication];
            if (draggingApp) [self.selectionDelegate quickSwitchTableView:self draggingDidChangeForQuickSwitchItem:draggingApp withPoint:point];
        }
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        // Re-evaluate the final finger position; never substitute row zero for
        // a missing selection, or index a list after the gesture has ended.
        if (CGRectContainsPoint(self.bounds, point)) {
            NSIndexPath *indexPath = [self indexPathForRowAtPoint:point];
            if ([self isValidIndexPath:indexPath]) {
                NSString *identifier = [items[indexPath.row] copy];
                [self.selectionDelegate quickSwitchTableView:self didSelectBundleId:identifier];
            }
        } else if (!horizontalInside && selectedBundleId) {
            SBApplication *application = [self selectedApplication];
            if (application) [self.selectionDelegate quickSwitchTableView:self didDropApp:application atPoint:point];
        }
        [self end];
    } else if (recognizer.state != UIGestureRecognizerStateBegan) {
        [self end];
    }
}


#pragma mark — TableView

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return items.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 34;
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"QuickSwitchCell";
    QuickSwitchTableViewCell *cell = [self dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[QuickSwitchTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    NSString *identifier = [self isValidIndexPath:indexPath] ? items[indexPath.row] : nil;
    [cell.imgView setImage:[POApplicationHelper imageForBundleId:identifier]];
    cell.imgView.frame = CGRectMake(8, 8, 18, 18);
    cell.layer.cornerRadius = 34/2;
    cell.clipsToBounds = YES;
    
    return cell;
}

#pragma mark - Animations

-(void)present{
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 1;
    }];
}

-(void)end{
    gestureActive = NO;
    activeRecognizer = nil;
    [autoscrollTimer invalidate];
    autoscrollTimer = nil;
    [self animateZoomforCellremove:thisCellToAnimate];
    [self animateZoomforCellremove:lastCellToAnimate];
    selectedBundleId = nil;
    draggingApp = nil;
    lastHoveredIndexPath = nil;
    [self.selectionDelegate draggingDidEnterBoundsOfQuickSwitchTableView:self];
    NSUInteger endedGeneration = gestureGeneration;
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        if (!self->gestureActive && endedGeneration == self->gestureGeneration)
            [self.selectionDelegate quickSwitchTableViewDidDisappear:self];
    }];
}

-(void)dealloc{
    [autoscrollTimer invalidate];
}

-(void)animateZoomforCell:(UITableViewCell*)zoomCell {
    zoomCell.layer.zPosition = 3;
    
    
    [UIView animateWithDuration:0.2 delay:0  options:UIViewAnimationOptionCurveEaseOut animations:^{
        zoomCell.transform = CGAffineTransformMakeScale(scale,scale);
    }completion:^(BOOL finished){}];
}

-(void)animateZoomforCellremove:(UITableViewCell*)zoomCell {
    zoomCell.layer.zPosition = 2;
    
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        zoomCell.transform = CGAffineTransformMakeScale(1.0,1.0);
    }completion:^(BOOL finished){}];
}


@end
