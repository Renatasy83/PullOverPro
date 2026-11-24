// Modified 2026-11-23 by Renatasy83: stability corrections; original credits and GPL-3.0 retained.
// Modified 2026-11-24: owned-view resizing with per-application size persistence.
#import <rootless.h>
//
//  PullOverViewController.m
//  PullOverPro
//
//  Created by Will Smillie on 4/8/19.
//

#import "PullOverViewController.h"
#import "POLog.h"
#import "../Shared/POHostStartupState.h"
#import "../Shared/POKeyboardGeometry.h"
#import "../Shared/POWindowSizeGeometry.h"
#import "POWindowSizeStore.h"

#define HANDLE_MARGIN 50
#define HALF_OPEN_HEIGHT 400

// The resize grip belongs to our wrapper. It does not intercept app-content
// touches, and VoiceOver can adjust it without performing a drag gesture.
@interface POWindowResizeHandle : UIView
@property (nonatomic, copy) void (^adjustFraction)(double delta);
@end

@implementation POWindowResizeHandle
-(void)accessibilityIncrement{
    if (self.adjustFraction) self.adjustFraction(0.05);
}
-(void)accessibilityDecrement{
    if (self.adjustFraction) self.adjustFraction(-0.05);
}
@end

static CGRect POWindowCGRect(POWindowSizeRect rect) {
    return CGRectMake(rect.x, rect.y, rect.width, rect.height);
}


@interface PullOverViewController () <UIGestureRecognizerDelegate> {
    NSString *pinnedBundleId;
    UIView *contextView;
    
    UIView *dragAndDropView;
    UIImageView *draggableImageView;
    UILabel *dragAndDropLabel;
    
    UIView *overlayView;
    UIActivityIndicatorView *activityIndicator;
    CGRect handleFrame;
    CGPoint handlePoint;
    CGFloat scale;
    BOOL showingCantHost;
    BOOL drawerClosing;
    POHostStartupState startup;
    NSTimer *startupTimer;
    UILabel *hostingStatusLabel;
    UIButton *hostingRetryButton;
    NSNumber *originalKeyboardOffset;
    uint64_t selectionGeneration;
    BOOL controllerDetached;
    double windowSizeFraction;
    POWindowSizeGeometry windowGeometry;
    POWindowResizeHandle *resizeGrip;
    UIImageView *resizeIcon;
    UIPanGestureRecognizer *resizePan;
    BOOL resizeGestureActive;
    double resizeStartFraction;
    POWindowSizeGeometry resizeStartGeometry;
    NSString *resizeBundleIdentifier;
    uint64_t resizeSelectionGeneration;
    CGRect resizeViewportBounds;
    UIEdgeInsets resizeSafeInsets;
}

@end

@implementation PullOverViewController
@synthesize scrollView, handleScrollView;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    scale = ([UIScreen mainScreen].bounds.size.width-HANDLE_MARGIN)/[UIScreen mainScreen].bounds.size.width;

    self.backgroundView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.backgroundView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    self.backgroundView.alpha = 0;
    [self.view addSubview:self.backgroundView];
    
    
    NSString *rocketPath = ROOT_PATH_NS(@"/Library/Application Support/PullOverPro/rocket.png");
    UIImage *image = rocketPath ? [UIImage imageWithContentsOfFile:rocketPath] : nil;
    if (!image) image = [UIImage systemImageNamed:@"arrow.up.forward.app"];
    
    
    dragAndDropView = [[UIView alloc] initWithFrame:CGRectMake(0,0,100,100)];
    dragAndDropView.contentMode = UIViewContentModeScaleAspectFit;
    dragAndDropView.center = CGPointMake(self.backgroundView.center.x, self.backgroundView.center.y);
    dragAndDropView.alpha = 0;
    [self.backgroundView addSubview:dragAndDropView];
    
    CAShapeLayer *border = [CAShapeLayer layer];
    border.strokeColor = [UIColor whiteColor].CGColor;
    border.fillColor = nil;
    border.lineDashPattern = @[@4, @2];
    [dragAndDropView.layer addSublayer:border];
    
    border.path = [UIBezierPath bezierPathWithRect:dragAndDropView.bounds].CGPath;
    border.frame = dragAndDropView.bounds;


    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    imageView.image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    imageView.tintColor = [UIColor whiteColor];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.center = CGPointMake(dragAndDropView.frame.size.width/2, dragAndDropView.frame.size.height/2);
    [dragAndDropView addSubview:imageView];
    
    
    dragAndDropLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,dragAndDropView.frame.size.height+dragAndDropView.frame.origin.y+16,200, 44)];
    dragAndDropLabel.textColor = [UIColor whiteColor];
    dragAndDropLabel.textAlignment = NSTextAlignmentCenter;
    dragAndDropLabel.numberOfLines = 2;
    dragAndDropLabel.text = @"Drag QuickSwitch Items\nHere To Open";
    [self.backgroundView addSubview:dragAndDropLabel];
    dragAndDropLabel.alpha = 0;
    dragAndDropLabel.center = CGPointMake(dragAndDropView.center.x, dragAndDropLabel.center.y);
    
    
    scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    [scrollView setContentSize:CGSizeMake((self.view.bounds.size.width*2)-HANDLE_MARGIN, self.view.bounds.size.height)];
    [scrollView setDecelerationRate:UIScrollViewDecelerationRateFast];
    [scrollView setBackgroundColor:[UIColor clearColor]];
    [scrollView setShowsHorizontalScrollIndicator:NO];
    [scrollView setPagingEnabled:YES];
    [scrollView setDelegate:self];
    [self.view addSubview:scrollView];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(close)];
    tap.delegate = self;
    [scrollView addGestureRecognizer:tap];
    
    handleScrollView = [[BaseScrollView alloc] initWithFrame:CGRectMake(self.view.frame.size.width-HANDLE_MARGIN, 0, HANDLE_MARGIN, [UIScreen mainScreen].bounds.size.height*scale)];
    [handleScrollView setContentSize:CGSizeMake(handleScrollView.frame.size.width, (([UIScreen mainScreen].bounds.size.height*scale)*2)-34)];
    [handleScrollView setShowsVerticalScrollIndicator:NO];
    [handleScrollView setBackgroundColor:[UIColor clearColor]];
    [handleScrollView setDecelerationRate:UIScrollViewDecelerationRateFast];
    [handleScrollView setClipsToBounds:NO];
    [handleScrollView setDelegate:self];
    [handleScrollView setContentOffset:CGPointFromString([[POApplicationHelper state] valueForKey:@"handlePoint"])];
    handleScrollView.center = CGPointMake(handleScrollView.center.x, self.view.frame.size.height/2);
    [scrollView addSubview:handleScrollView];

    
    self.handle = [[POHandle alloc] initWithController:self];
    [self.handle setDelegate:self];
    CGRect r = self.handle.frame; r.origin.y = ([UIScreen mainScreen].bounds.size.height*scale)-self.handle.frame.size.height; self.handle.frame = r;
    handleFrame = self.handle.frame;
    handlePoint = handleScrollView.contentOffset;
    [handleScrollView addSubview:self.handle];
    
    self.quickSwitchTableView = [[QuickSwitchTableView alloc] initWithDarkMode:self.handle.darkMode];
    self.quickSwitchTableView.selectionDelegate = self;
    [handleScrollView addSubview:self.quickSwitchTableView];
    
    self.contentView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width, 20, [UIScreen mainScreen].bounds.size.width*scale, [UIScreen mainScreen].bounds.size.height*scale)];
    self.contentView.center = CGPointMake(self.contentView.center.x, self.view.frame.size.height/2);
    if (@available(iOS 13, *)){
        NSLog(@"iOS 13 bg color");
        self.contentView.backgroundColor = [UIColor secondarySystemBackgroundColor];
    }else{
        NSLog(@"pre 13 bg color");

        self.contentView.backgroundColor = [[POApplicationHelper settings][@"darkHandle"] boolValue] ? [UIColor darkGrayColor] : [UIColor whiteColor];
    }
    self.contentView.layer.cornerRadius = 12;
    self.contentView.clipsToBounds = YES;
    
    activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    activityIndicator.color = [UIColor whiteColor];
    activityIndicator.frame = CGRectMake(42, 54, 37, 37);
    activityIndicator.layer.shadowOpacity = 0.5;
    activityIndicator.layer.shadowRadius = 6;
    activityIndicator.layer.shadowOffset = CGSizeMake(0, 0);
    [activityIndicator startAnimating];

    [self.contentView addSubview:activityIndicator];

    
    [scrollView addSubview:self.contentView];
    [self configureResizeGrip];
    
    if ([[POApplicationHelper state] stringForKey:@"lastPinnedBundleId"]) {
        pinnedBundleId = [[POApplicationHelper state] stringForKey:@"lastPinnedBundleId"];
        UIImage *image = [POApplicationHelper imageForBundleId:pinnedBundleId];
        self.handle.imageView.image = image;
    }else{
        pinnedBundleId = @"com.apple.MobileSMS";
        UIImage *image = [POApplicationHelper imageForBundleId:pinnedBundleId];
        self.handle.imageView.image = image;
    }
    [self loadWindowSizeForPinnedApplication];
    
    if ([[POApplicationHelper settings][@"leftHanded"] boolValue]){
        imageView.transform = CGAffineTransformMakeScale(-1.0, 1.0);
        dragAndDropLabel.transform = CGAffineTransformMakeScale(-1.0, 1.0);
        self.handle.imageView.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    }
    
    overlayView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    overlayView.backgroundColor = [UIColor clearColor];
    overlayView.userInteractionEnabled = NO;
    [self.view addSubview:overlayView];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [self updateHandleVisibility:0];
}

// Hide Handle (needs the Triggr add-on): invisible while closed, so it also takes
// no touches; fades in as an app is pulled over, so it can still be closed by hand.
-(void)updateHandleVisibility:(float)progress{
    BOOL hide = [[POApplicationHelper settings][@"hideHandle"] boolValue] && POTriggrAddonInstalled();
    self.handle.alpha = hide ? MAX(0, MIN(1, progress * 4)) : 1;
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    [self applyWindowSizeLayout];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    controllerDetached = NO;
    scrollView.delegate = self;
    handleScrollView.delegate = self;
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    controllerDetached = YES;
    drawerClosing = YES;
    selectionGeneration++;
    _isOpened = NO;
    [self endHosting];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    scrollView.delegate = nil;
    handleScrollView.delegate = nil;
}

-(BOOL)shouldAutorotate
{
    return NO;
}

-(void)keyboardWillShow:(NSNotification *)notification{
    if (![[POApplicationHelper settings][@"keyboardAvoiding"] boolValue] || !self.view.window) return;
    NSValue *value = notification.userInfo[UIKeyboardFrameEndUserInfoKey];
    if (![value isKindOfClass:[NSValue class]]) return;
    UIWindow *window = self.view.window;
    CGRect keyboardInWindow = [window convertRect:value.CGRectValue fromCoordinateSpace:window.screen.coordinateSpace];
    CGRect keyboard = [self.view convertRect:keyboardInWindow fromView:window];
    CGFloat original = originalKeyboardOffset ? originalKeyboardOffset.doubleValue : handleScrollView.contentOffset.y;
    CGRect naturalHandle = [self.handle convertRect:self.handle.bounds toView:self.view];
    naturalHandle.origin.y += handleScrollView.contentOffset.y - original;
    UIEdgeInsets inset = handleScrollView.adjustedContentInset;
    CGFloat minimum = -inset.top;
    CGFloat maximum = MAX(minimum, handleScrollView.contentSize.height - handleScrollView.bounds.size.height + inset.bottom);
    double target = POKeyboardAvoidanceOffset(
        (PORect){naturalHandle.origin.x, naturalHandle.origin.y, naturalHandle.size.width, naturalHandle.size.height},
        (PORect){keyboard.origin.x, keyboard.origin.y, keyboard.size.width, keyboard.size.height},
        original, minimum, maximum, self.view.safeAreaInsets.top);
    if (fabs(target - original) > 0.5 && !originalKeyboardOffset) originalKeyboardOffset = @(original);
    [self animateHandleOffset:target notification:notification];
}

-(void)keyboardWillHide:(NSNotification *)notification{
    if (!originalKeyboardOffset) return;
    [self animateHandleOffset:originalKeyboardOffset.doubleValue notification:notification];
    originalKeyboardOffset = nil;
}

-(void)animateHandleOffset:(CGFloat)offset notification:(NSNotification *)notification{
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    NSUInteger curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
    UIViewAnimationOptions options = (UIViewAnimationOptions)(curve << 16) | UIViewAnimationOptionBeginFromCurrentState;
    [UIView animateWithDuration:duration delay:0 options:options animations:^{
        [self->handleScrollView setContentOffset:CGPointMake(self->handleScrollView.contentOffset.x, offset)];
    } completion:nil];
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)recognizer shouldReceiveTouch:(UITouch *)touch{
    if (recognizer == resizePan) return [self canResizeWindow];
    if ([touch.view isDescendantOfView:resizeGrip]) return NO;
    // Background taps close the drawer; app content and the Retry button keep their touches.
    return ![touch.view isDescendantOfView:self.contentView];
}


-(void)pinAppWithBundleId:(NSString *)bundleId{
    if (![bundleId isKindOfClass:[NSString class]] || bundleId.length == 0) return;
    uint64_t request = ++selectionGeneration;
    [self endHosting]; // Release the old bundle before changing its identifier.
    POLog(@"pin %@ (front=%@)", bundleId, [POApplicationHelper frontMostBundleId]);
    pinnedBundleId = bundleId;
    [self loadWindowSizeForPinnedApplication];
    
    [[POApplicationHelper state] setObject:bundleId forKey:@"lastPinnedBundleId"];
    UIImage *image = [POApplicationHelper imageForBundleId:bundleId];
    self.handle.imageView.image = image;
    
    if ([[POApplicationHelper frontMostBundleId] isEqualToString:bundleId]) {
        // _returnToHomescreenWithCompletion: is gone on iOS 15+; a simulated Home press does the same (iOS 15-27).
        id sb = [UIApplication sharedApplication];
        if ([sb respondsToSelector:@selector(_simulateHomeButtonPressWithCompletion:)]) [sb _simulateHomeButtonPressWithCompletion:nil];
        else if ([sb respondsToSelector:@selector(_simulateHomeButtonPress)]) [sb _simulateHomeButtonPress];
    }else{
        __weak PullOverViewController *weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            PullOverViewController *controller = weakSelf;
            if (!controller || controller->controllerDetached ||
                controller->selectionGeneration != request || !controller.viewIfLoaded.window) return;
            [controller open];
            [controller retryHostingIfNeeded];
        });
    }
}

-(void)open{
    if (controllerDetached || !self.viewIfLoaded.window) return;
    drawerClosing = NO;
    CGRect frame = scrollView.frame; frame.origin.y = 0;
    frame.origin.x = frame.size.width * 1;
    [scrollView scrollRectToVisible:frame animated:YES];
}

-(void)close{
    selectionGeneration++;
    drawerClosing = YES;
    if (self.isOpened) self.isOpened = NO;
    else [self endHosting];
    CGRect frame = scrollView.frame; frame.origin.y = 0;
    frame.origin.x = frame.size.width * 0;
    [scrollView scrollRectToVisible:frame animated:YES];
}
     

#pragma mark - MHHandleDelegate

-(void)handle:(POHandle *)handle didReceiveTap:(UIGestureRecognizer *)recognizer{
    if (!self.isOpened) {
        [self open];
    }else{
        [self close];
    }
}

-(void)handle:(POHandle *)handle didLongPress:(UILongPressGestureRecognizer *)recognizer{
    if (!self.isOpened) {
        if (self.handle.isNubbed) {
            self.handle.isNubbed = NO;
        }

        [self.quickSwitchTableView presentFromHandle:handle withRecognizer:recognizer];
        
        [UIView animateWithDuration:0.3 animations:^{
            if (recognizer.state == UIGestureRecognizerStateBegan) {
                self.backgroundView.alpha = 1;
            }else if (recognizer.state != UIGestureRecognizerStateChanged){
                self.backgroundView.alpha = 0;
            }
        }];
    }
}


#pragma mark - QuickSwitch

-(void)quickSwitchTableView:(QuickSwitchTableView *)quickSwitchTableView didSelectBundleId:(NSString *)bundleId{
    [self pinAppWithBundleId:bundleId];
}

-(void)quickSwitchTableViewWillAppear:(QuickSwitchTableView *)quickSwitchTableView{
    dragAndDropView.alpha = 1;
    if (![[POApplicationHelper settings][@"hideLabels"] boolValue]){
        dragAndDropLabel.alpha = 1;
    }
}

-(void)quickSwitchTableView:(QuickSwitchTableView *)quickSwitchTableView draggingDidChangeForQuickSwitchItem:(SBApplication *)app withPoint:(CGPoint)point{
    
    if (!draggableImageView) {
        draggableImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
        draggableImageView.image = [POApplicationHelper imageForBundleId:app.bundleIdentifier];
        draggableImageView.contentMode = UIViewContentModeScaleAspectFill;
        draggableImageView.center = [self.backgroundView convertPoint:point fromView:quickSwitchTableView];
        [self.backgroundView addSubview:draggableImageView];
        
        if ([[POApplicationHelper settings][@"leftHanded"] boolValue]){
            draggableImageView.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(-1.0, 1.0), CGAffineTransformMakeScale(0.01, 0.01));
            [UIView animateWithDuration:0.2 animations:^{
                draggableImageView.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(-1.0, 1.0), CGAffineTransformMakeScale(1, 1));
            }];
        }else{
            draggableImageView.transform = CGAffineTransformMakeScale(0.01, 0.01);
            [UIView animateWithDuration:0.2 animations:^{
                draggableImageView.transform = CGAffineTransformMakeScale(1, 1);
            }];
        }
    }
    
    draggableImageView.center = [self.backgroundView convertPoint:point fromView:quickSwitchTableView];

    CGPoint locationInView = [dragAndDropView convertPoint:point fromView:quickSwitchTableView];
    if (CGRectContainsPoint(dragAndDropView.bounds, locationInView) ) {
        [UIView animateWithDuration:0.3f animations:^{
            dragAndDropLabel.text = [NSString stringWithFormat:@"Open %@", app.displayName];
            dragAndDropView.transform = CGAffineTransformMakeScale(1.3, 1.3);
        }];
    }else{
        [UIView animateWithDuration:0.3f animations:^{
            dragAndDropLabel.text = @"Drag QuickSwitch Items\nHere To Open";
            dragAndDropView.transform = CGAffineTransformMakeScale(1, 1);
        }];
    }
}

-(void)quickSwitchTableView:(QuickSwitchTableView *)quickSwitchTableView didDropApp:(SBApplication *)app atPoint:(CGPoint)point{
    [self removeDraggableImageViewAnimated];
    
    if (CGRectContainsPoint(dragAndDropView.bounds, [dragAndDropView convertPoint:point fromView:quickSwitchTableView]) ) {
        [[ContextHostManager sharedInstance] openFullScreen:app.bundleIdentifier];
    }
}

-(void)draggingDidEnterBoundsOfQuickSwitchTableView:(QuickSwitchTableView *)quickSwitchTableView{
    [self removeDraggableImageViewAnimated];
}

-(void)removeDraggableImageViewAnimated{
    [draggableImageView.layer removeAllAnimations];

    
    if ([[POApplicationHelper settings][@"leftHanded"] boolValue]){
        draggableImageView.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(-1.0, 1.0), CGAffineTransformMakeScale(1, 1));
        [UIView animateWithDuration:0.2 animations:^{
            draggableImageView.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(-1.0, 1.0), CGAffineTransformMakeScale(0.01, 0.01));
        }completion:^(BOOL finished) {
            [draggableImageView removeFromSuperview];
            draggableImageView = nil;
        }];

    }else{
        draggableImageView.transform = CGAffineTransformMakeScale(1, 1);
        [UIView animateWithDuration:0.2 animations:^{
            draggableImageView.transform = CGAffineTransformMakeScale(0.01, 0.01);
        }completion:^(BOOL finished) {
            [draggableImageView removeFromSuperview];
            draggableImageView = nil;
        }];
    }

    
    [UIView animateWithDuration:0.3f animations:^{
        dragAndDropLabel.text = @"Drag QuickSwitch Items\nHere To Open";
        dragAndDropView.transform = CGAffineTransformMakeScale(1, 1);
    }];
}

-(void)quickSwitchTableViewDidDisappear:(QuickSwitchTableView *)quickSwitchTableView{
    dragAndDropView.alpha = 0;
    dragAndDropLabel.alpha = 0;
}



#pragma mark - UIScrollViewDelegate

-(void)scrollViewWillBeginDragging:(UIScrollView *)sv{
    if (sv == handleScrollView) {
        // A deliberate vertical move becomes the new handle position. Do not
        // later restore the pre-keyboard position over the user's choice.
        originalKeyboardOffset = nil;
        [handleScrollView.layer removeAllAnimations];
    }
}

-(void)scrollViewDidEndDragging:(UIScrollView *)sv willDecelerate:(BOOL)decelerate{
    float progress = scrollView.contentOffset.x / (scrollView.frame.size.width-HANDLE_MARGIN);
    if (progress == 0 && !originalKeyboardOffset) {
        handleFrame = self.handle.frame;
        handlePoint = handleScrollView.contentOffset;
        [[POApplicationHelper state] setValue:NSStringFromCGPoint(handlePoint) forKey:@"handlePoint"];
    }
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)sv{
    float progress = scrollView.contentOffset.x / (scrollView.frame.size.width-HANDLE_MARGIN);
    if (progress == 0 && !originalKeyboardOffset) {
        handleFrame = self.handle.frame;
        handlePoint = handleScrollView.contentOffset;
        [[POApplicationHelper state] setValue:NSStringFromCGPoint(handlePoint) forKey:@"handlePoint"];
    }else if (progress == 1 && self.isOpened && !drawerClosing){
        [self beginHosting];
    }
}

-(void)scrollViewDidScroll:(UIScrollView *)sv{
    float progress = scrollView.contentOffset.x / (scrollView.frame.size.width-HANDLE_MARGIN);
    
    if (sv == scrollView) {
        self.backgroundView.alpha = progress;
        [self updateHandleVisibility:progress];
        
        if (progress <= 0.001) {
            self.isOpened = NO;
            drawerClosing = NO;
        }else if (!drawerClosing){
            self.isOpened = YES;
        }
        
        
        if (progress < 0) {
            if (!self.handle.isNubbed) {
                self.handle.isNubbed = YES;
            }
        }else if (progress > 0){
            if (self.handle.isNubbed) {
                self.handle.isNubbed = NO;
            }
        }
        [self updateResizeGripVisibility];
    }
}

-(void)setIsOpened:(BOOL)isOpened{
    if (_isOpened == isOpened) return;
    _isOpened = isOpened;
    
    overlayView.userInteractionEnabled = NO;
    if (isOpened) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(autoNubAfterDelay) object:nil];
        [self beginHosting];
    }else{
        [self endHosting];
        if ([[POApplicationHelper settings][@"autoNub"] boolValue]){
            [self performSelector:@selector(autoNubAfterDelay) withObject:nil afterDelay:[[POApplicationHelper settings][@"autoNub-time"] intValue]];
        }
    }
}

-(void)autoNubAfterDelay{
    [self.handle setIsNubbed:YES];
}


-(void)beginHosting{
    if (controllerDetached || !self.viewIfLoaded.window || !self.isOpened || drawerClosing || !pinnedBundleId.length) return;
    if (startup.phase == POStartupWaiting || startup.phase == POStartupFailed) return;
    if ([[ContextHostManager sharedInstance] isHostViewHosting:contextView]) return;
    [contextView removeFromSuperview];
    contextView = nil;
    [self clearHostingStatus];
    uint64_t generation = POStartupBegin(&startup, CACurrentMediaTime());
    [activityIndicator startAnimating];
    [self pollHostingForGeneration:generation];
}

-(void)pollHostingForGeneration:(uint64_t)generation{
    if (controllerDetached || !self.viewIfLoaded.window || !self.isOpened || drawerClosing || !POStartupMatches(&startup, generation)) return;
    [startupTimer invalidate];
    startupTimer = nil;
    if (POStartupTimedOut(&startup, CACurrentMediaTime())) {
        [self failHosting:@"The app did not provide a window in time. You can try again."];
        return;
    }
    if ([[POApplicationHelper frontMostBundleId] isEqualToString:pinnedBundleId]) {
        [self showCantHostView];
        return;
    }
    NSString *bundle = [pinnedBundleId copy];
    if (POStartupTakeLaunch(&startup)) {
        __weak PullOverViewController *weakSelf = self;
        [[ContextHostManager sharedInstance] launchInBackground:bundle completion:^(NSError *error) {
            PullOverViewController *controller = weakSelf;
            if (!controller || !controller.isOpened ||
                !POStartupMatches(&controller->startup, generation) ||
                ![controller->pinnedBundleId isEqualToString:bundle]) return;
            if (error) [controller failHosting:@"The app could not be started. You can try again."];
        }];
    }
    contextView = [[ContextHostManager sharedInstance] hostViewForBundleID:bundle];
    if (contextView) {
        startup.phase = POStartupHosted;
        [activityIndicator stopAnimating];
        [self layoutContextView];
        POLog(@"host ready %@", bundle);
        return;
    }
    NSTimeInterval delay = POStartupNextDelay(&startup, CACurrentMediaTime());
    __weak PullOverViewController *weakSelf = self;
    startupTimer = [NSTimer timerWithTimeInterval:delay repeats:NO block:^(NSTimer *timer) {
        [weakSelf pollHostingForGeneration:generation];
    }];
    [[NSRunLoop mainRunLoop] addTimer:startupTimer forMode:NSRunLoopCommonModes];
}

-(void)clearHostingStatus{
    [hostingStatusLabel removeFromSuperview];
    [hostingRetryButton removeFromSuperview];
    hostingStatusLabel = nil;
    hostingRetryButton = nil;
    showingCantHost = NO;
}

-(void)failHosting:(NSString *)message{
    startup.phase = POStartupFailed;
    [startupTimer invalidate];
    startupTimer = nil;
    [activityIndicator stopAnimating];
    [[ContextHostManager sharedInstance] stopHostingForBundleID:pinnedBundleId];
    [contextView removeFromSuperview];
    contextView = nil;
    [self clearHostingStatus];
    hostingStatusLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, self.contentView.bounds.size.height/2-80,
                                                                 self.contentView.bounds.size.width-32, 100)];
    hostingStatusLabel.text = message;
    hostingStatusLabel.textColor = UIColor.labelColor;
    hostingStatusLabel.textAlignment = NSTextAlignmentCenter;
    hostingStatusLabel.numberOfLines = 0;
    [self.contentView addSubview:hostingStatusLabel];
    hostingRetryButton = [UIButton buttonWithType:UIButtonTypeSystem];
    hostingRetryButton.frame = CGRectMake(16, self.contentView.bounds.size.height/2+28,
                                         self.contentView.bounds.size.width-32, 44);
    [hostingRetryButton setTitle:@"Try again" forState:UIControlStateNormal];
    [hostingRetryButton addTarget:self action:@selector(retryHosting:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:hostingRetryButton];
    if ([[POApplicationHelper settings][@"leftHanded"] boolValue]) {
        hostingStatusLabel.transform = CGAffineTransformMakeScale(-1, 1);
        hostingRetryButton.transform = CGAffineTransformMakeScale(-1, 1);
    }
    POLog(@"host startup failed %@: %@", pinnedBundleId, message);
}

-(void)retryHosting:(id)sender{
    if (!self.isOpened || drawerClosing) return;
    [self endHosting];
    [self beginHosting];
}

-(void)layoutContextView{
    [self.contentView addSubview:contextView];
    [self applyWindowSizeLayout];
    contextView.alpha = 0;
    [UIView animateWithDuration:0.3 animations:^{
        contextView.alpha = 1;
    }];
    [self updateResizeGripVisibility];
}

#pragma mark - Owned window size

-(void)configureResizeGrip{
    resizeGrip = [[POWindowResizeHandle alloc] initWithFrame:CGRectZero];
    resizeGrip.hidden = YES;
    resizeGrip.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.85];
    resizeGrip.layer.cornerRadius = 9;
    resizeGrip.isAccessibilityElement = YES;
    resizeGrip.accessibilityTraits = UIAccessibilityTraitAdjustable;
    resizeGrip.accessibilityLabel = @"Window size";
    resizeGrip.accessibilityHint = @"Swipe up or down to adjust. Use Restore original size in the actions menu.";
    resizeIcon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"arrow.up.left.and.arrow.down.right"]];
    resizeIcon.tintColor = UIColor.whiteColor;
    resizeIcon.contentMode = UIViewContentModeScaleAspectFit;
    resizeIcon.userInteractionEnabled = NO;
    [resizeGrip addSubview:resizeIcon];
    [scrollView addSubview:resizeGrip];
    resizePan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(resizeWindow:)];
    resizePan.maximumNumberOfTouches = 1;
    resizePan.delegate = self;
    [resizeGrip addGestureRecognizer:resizePan];
    // The drawer must not start paging while this dedicated grip is dragged.
    [scrollView.panGestureRecognizer requireGestureRecognizerToFail:resizePan];
    UITapGestureRecognizer *restore = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resetWindowSize:)];
    restore.numberOfTapsRequired = 2;
    [resizeGrip addGestureRecognizer:restore];
    __weak PullOverViewController *weakSelf = self;
    resizeGrip.adjustFraction = ^(double delta) { [weakSelf adjustWindowSizeBy:delta]; };
    UIAccessibilityCustomAction *reset = [[UIAccessibilityCustomAction alloc] initWithName:@"Restore original size" actionHandler:^BOOL(UIAccessibilityCustomAction *action) {
        return [weakSelf restoreDefaultWindowSize];
    }];
    resizeGrip.accessibilityCustomActions = @[reset];
}

-(void)loadWindowSizeForPinnedApplication{
    windowSizeFraction = [POWindowSizeStore fractionForBundleIdentifier:pinnedBundleId defaults:[POApplicationHelper state]];
    [self applyWindowSizeLayout];
}

-(void)applyWindowSizeLayout{
    if (!self.contentView || !self.isViewLoaded) return;
    CGSize native = UIScreen.mainScreen.bounds.size;
    UIEdgeInsets safe = self.view.safeAreaInsets;
    POWindowSizeGeometry geometry = POWindowSizeMakeGeometry(native.width, native.height,
        self.view.bounds.size.width, self.view.bounds.size.height, safe.top, safe.bottom, windowSizeFraction);
    windowGeometry = geometry;
    if (!geometry.valid) { resizeGrip.hidden = YES; return; }
    self.contentView.frame = POWindowCGRect(geometry.pane);
    resizeGrip.frame = POWindowCGRect(geometry.grip);
    resizeIcon.frame = CGRectInset(resizeGrip.bounds, 13, 3);
    resizeGrip.accessibilityValue = [NSString stringWithFormat:@"%ld%%", (long)llround(windowSizeFraction * 100)];
    activityIndicator.center = CGPointMake(self.contentView.bounds.size.width/2, self.contentView.bounds.size.height/2);
    hostingStatusLabel.frame = CGRectMake(16, self.contentView.bounds.size.height/2-80, self.contentView.bounds.size.width-32, 100);
    hostingRetryButton.frame = CGRectMake(16, self.contentView.bounds.size.height/2+28, self.contentView.bounds.size.width-32, 44);
    [self layoutHostedContent];
    [self updateResizeGripVisibility];
}

-(void)layoutHostedContent{
    if (!contextView || !windowGeometry.valid) return;
    CGSize native = UIScreen.mainScreen.bounds.size;
    // Keep the existing native app canvas. Resize only its owned UIKit wrapper,
    // with one uniform transform; no scene settings or host restart is needed.
    contextView.bounds = CGRectMake(0, 0, native.width, native.height);
    CGFloat horizontal = [[POApplicationHelper settings][@"leftHanded"] boolValue] ? -windowGeometry.scale : windowGeometry.scale;
    contextView.transform = CGAffineTransformMakeScale(horizontal, windowGeometry.scale);
    contextView.center = CGPointMake(self.contentView.bounds.size.width/2, self.contentView.bounds.size.height/2);
}

-(BOOL)canResizeWindow{
    CGFloat distance = scrollView.bounds.size.width - HANDLE_MARGIN;
    return !controllerDetached && !drawerClosing && self.viewIfLoaded.window && self.isOpened &&
        startup.phase == POStartupHosted && contextView && windowGeometry.valid && distance > 0 &&
        fabs(scrollView.contentOffset.x - distance) < 1.0;
}

-(void)updateResizeGripVisibility{
    resizeGrip.hidden = ![self canResizeWindow];
}

-(void)cancelWindowResize{
    if (!resizeGestureActive) return;
    resizeGestureActive = NO;
    if ([pinnedBundleId isEqualToString:resizeBundleIdentifier]) windowSizeFraction = resizeStartFraction;
    resizeBundleIdentifier = nil;
    // Clear the transaction before disabling; UIKit can synchronously send Cancelled.
    resizePan.enabled = NO;
    resizePan.enabled = YES;
    [self applyWindowSizeLayout];
}

-(void)resizeWindow:(UIPanGestureRecognizer *)recognizer{
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        if (![self canResizeWindow]) return;
        resizeGestureActive = YES;
        resizeStartFraction = windowSizeFraction;
        resizeStartGeometry = windowGeometry;
        resizeBundleIdentifier = [pinnedBundleId copy];
        resizeSelectionGeneration = selectionGeneration;
        resizeViewportBounds = self.view.bounds;
        resizeSafeInsets = self.view.safeAreaInsets;
        [recognizer setTranslation:CGPointZero inView:scrollView];
        return;
    }
    if (!resizeGestureActive) return;
    BOOL current = [self canResizeWindow] && [pinnedBundleId isEqualToString:resizeBundleIdentifier] &&
        selectionGeneration == resizeSelectionGeneration && CGRectEqualToRect(resizeViewportBounds, self.view.bounds) &&
        UIEdgeInsetsEqualToEdgeInsets(resizeSafeInsets, self.view.safeAreaInsets);
    if (!current || recognizer.state == UIGestureRecognizerStateCancelled || recognizer.state == UIGestureRecognizerStateFailed) {
        [self cancelWindowResize];
        return;
    }
    if (recognizer.state == UIGestureRecognizerStateChanged || recognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint delta = [recognizer translationInView:scrollView];
        windowSizeFraction = POWindowSizeFractionForTranslation(resizeStartFraction, delta.x, delta.y,
            resizeStartGeometry.maximumWidth, resizeStartGeometry.maximumHeight);
        [self applyWindowSizeLayout];
        if (recognizer.state == UIGestureRecognizerStateEnded) {
            NSString *bundle = resizeBundleIdentifier;
            resizeGestureActive = NO;
            resizeBundleIdentifier = nil;
            [POWindowSizeStore saveFraction:windowSizeFraction forBundleIdentifier:bundle defaults:[POApplicationHelper state]];
        }
    }
}

-(void)adjustWindowSizeBy:(double)delta{
    if (![self canResizeWindow] || !isfinite(delta)) return;
    [self cancelWindowResize];
    windowSizeFraction = POWindowSizeClampFraction(windowSizeFraction + delta);
    [self applyWindowSizeLayout];
    [POWindowSizeStore saveFraction:windowSizeFraction forBundleIdentifier:pinnedBundleId defaults:[POApplicationHelper state]];
}

-(BOOL)restoreDefaultWindowSize{
    if (![self canResizeWindow]) return NO;
    [self cancelWindowResize];
    [POWindowSizeStore resetFractionForBundleIdentifier:pinnedBundleId defaults:[POApplicationHelper state]];
    windowSizeFraction = 1.0;
    [self applyWindowSizeLayout];
    return YES;
}

-(void)resetWindowSize:(UITapGestureRecognizer *)recognizer{
    if (recognizer.state == UIGestureRecognizerStateRecognized) [self restoreDefaultWindowSize];
}

-(void)cleanUpSubviews{
    for (UIView *v in self.contentView.subviews) {
        if (![v isKindOfClass:[UIActivityIndicatorView class]]) {
            [v removeFromSuperview];
        }
    }
}

-(void)endHosting{
    [self cancelWindowResize];
    resizeGrip.hidden = YES;
    POStartupCancel(&startup);
    [startupTimer invalidate];
    startupTimer = nil;
    [activityIndicator stopAnimating];
    if (pinnedBundleId) [[ContextHostManager sharedInstance] stopHostingForBundleID:pinnedBundleId];
    [self cleanUpSubviews];
    [self clearHostingStatus];
    
    [contextView removeFromSuperview];
    for (UIView *v in overlayView.subviews) {
        [v removeFromSuperview];
    }
    contextView = nil;

    showingCantHost = NO;
}

-(void)showCantHostView{
    [self failHosting:@"This app is already open on screen, so it can't be pulled over right now."];
    showingCantHost = YES;
}

-(void)retryHostingIfNeeded{
    if (self.isOpened && pinnedBundleId && !drawerClosing && startup.phase != POStartupFailed) [self beginHosting];
}

-(void)dealloc{
    [startupTimer invalidate];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
