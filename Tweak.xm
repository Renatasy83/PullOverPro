#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/message.h>
#import <dispatch/dispatch.h>

// Beta development preview: installed-app list + conventional app activation.
// This does NOT host other applications inside a floating window.
static UIWindow *ppoWindow;
static UIViewController *ppoController;
static UIButton *ppoHandle;
static UIView *ppoPanel;
static UIScrollView *ppoList;
static UILabel *ppoStatus;
static BOOL ppoExpanded;
static const CGFloat PPOClosedWidth = 78;
static const CGFloat PPOOpenWidth = 252;
static const CGFloat PPOOpenHeight = 380;

static id PPOCall0(id object, SEL selector) {
    if (!object || ![object respondsToSelector:selector]) return nil;
    return ((id (*)(id, SEL))objc_msgSend)(object, selector);
}
static NSString *PPOString(id object, SEL selector) {
    id value = PPOCall0(object, selector);
    return [value isKindOfClass:NSString.class] ? value : nil;
}
static NSArray<NSDictionary *> *PPOApplications(void) {
    Class cls = NSClassFromString(@"SBApplicationController");
    id controller = PPOCall0(cls, NSSelectorFromString(@"sharedInstance"));
    id all = PPOCall0(controller, NSSelectorFromString(@"allApplications"));
    if (![all isKindOfClass:NSArray.class]) {
        NSLog(@"[PullOverPro Beta] allApplications unavailable");
        return @[];
    }
    NSMutableArray *items = [NSMutableArray array];
    for (id app in (NSArray *)all) {
        NSString *bid = PPOString(app, NSSelectorFromString(@"bundleIdentifier"));
        if (!bid.length) bid = PPOString(app, NSSelectorFromString(@"displayIdentifier"));
        NSString *name = PPOString(app, NSSelectorFromString(@"displayName"));
        if (!bid.length || [bid hasPrefix:@"com.apple.springboard"]) continue;
        [items addObject:@{@"id":bid, @"name":name.length ? name : bid}];
    }
    [items sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
        return [a[@"name"] localizedCaseInsensitiveCompare:b[@"name"]];
    }];
    return items;
}
static void PPOSetStatus(NSString *message) {
    ppoStatus.text = message;
    NSLog(@"[PullOverPro Beta] %@", message);
}
static void PPOLaunch(NSString *bundleID) {
    id sb = UIApplication.sharedApplication;
    SEL launch = NSSelectorFromString(@"launchApplicationWithIdentifier:suspended:");
    if ([sb respondsToSelector:launch]) {
        ((void (*)(id, SEL, id, BOOL))objc_msgSend)(sb, launch, bundleID, NO);
        PPOSetStatus([NSString stringWithFormat:@"Lansare: %@", bundleID]);
        return;
    }
    PPOSetStatus(@"API lansare indisponibil pe acest iOS");
}
@interface PPOTarget : NSObject
@property(nonatomic,copy) NSArray<NSDictionary *> *apps;
- (void)toggle:(id)sender;
- (void)move:(UIPanGestureRecognizer *)recognizer;
- (void)selectApp:(UIButton *)sender;
- (void)refresh:(id)sender;
@end
static PPOTarget *ppoTarget;
static void PPOReloadApps(void) {
    NSArray *apps = PPOApplications();
    ppoTarget.apps = apps;
    for (UIView *v in [ppoList.subviews copy]) [v removeFromSuperview];
    CGFloat y = 0;
    NSUInteger count = MIN(apps.count, (NSUInteger)250);
    for (NSUInteger i = 0; i < count; i++) {
        NSDictionary *app = apps[i];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.frame = CGRectMake(4, y, PPOOpenWidth - 16, 38);
        button.tag = (NSInteger)i;
        button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        button.titleLabel.font = [UIFont systemFontOfSize:12];
        [button setTitle:[NSString stringWithFormat:@"  %@", app[@"name"]] forState:UIControlStateNormal];
        [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        [button addTarget:ppoTarget action:@selector(selectApp:) forControlEvents:UIControlEventTouchUpInside];
        [ppoList addSubview:button];
        y += 40;
    }
    ppoList.contentSize = CGSizeMake(PPOOpenWidth - 12, y);
    PPOSetStatus(apps.count ? [NSString stringWithFormat:@"%lu aplicații găsite", (unsigned long)apps.count] : @"Lista indisponibilă");
}
@implementation PPOTarget
- (void)toggle:(id)sender {
    ppoExpanded = !ppoExpanded;
    CGRect frame = ppoWindow.frame;
    frame.size = CGSizeMake(ppoExpanded ? PPOOpenWidth : PPOClosedWidth, ppoExpanded ? PPOOpenHeight : 44);
    CGFloat maxY = MAX(0, CGRectGetHeight(ppoWindow.windowScene.coordinateSpace.bounds) - CGRectGetHeight(frame));
    frame.origin.y = MAX(0, MIN(maxY, frame.origin.y));
    ppoWindow.frame = frame;
    ppoController.view.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    ppoPanel.hidden = !ppoExpanded;
    [ppoHandle setTitle:ppoExpanded ? @"PPO ✕" : @"PPO ▶" forState:UIControlStateNormal];
    if (ppoExpanded) PPOReloadApps();
}
- (void)move:(UIPanGestureRecognizer *)recognizer {
    CGPoint delta = [recognizer translationInView:ppoWindow];
    CGRect frame = ppoWindow.frame;
    frame.origin.y = MAX(0, MIN(CGRectGetHeight(ppoWindow.windowScene.coordinateSpace.bounds) - CGRectGetHeight(frame), frame.origin.y + delta.y));
    ppoWindow.frame = frame;
    [recognizer setTranslation:CGPointZero inView:ppoWindow];
}
- (void)selectApp:(UIButton *)sender {
    if (sender.tag < 0 || (NSUInteger)sender.tag >= self.apps.count) return;
    PPOLaunch(self.apps[(NSUInteger)sender.tag][@"id"]);
}
- (void)refresh:(id)sender { PPOReloadApps(); }
@end
static void PPOInstall(void) {
    if (ppoWindow) return;
    UIWindowScene *scene = nil;
    for (UIScene *s in UIApplication.sharedApplication.connectedScenes) {
        if ([s isKindOfClass:UIWindowScene.class] && s.activationState == UISceneActivationStateForegroundActive) {
            scene = (UIWindowScene *)s; break;
        }
    }
    if (!scene) return;
    ppoWindow = [[UIWindow alloc] initWithWindowScene:scene];
    ppoWindow.frame = CGRectMake(0, 170, PPOClosedWidth, 44);
    ppoWindow.windowLevel = UIWindowLevelStatusBar + 1;
    ppoWindow.backgroundColor = UIColor.clearColor;
    ppoController = [UIViewController new];
    ppoController.view.backgroundColor = UIColor.clearColor;
    ppoWindow.rootViewController = ppoController;
    ppoTarget = [PPOTarget new];

    ppoPanel = [[UIView alloc] initWithFrame:CGRectMake(0, 44, PPOOpenWidth, PPOOpenHeight - 44)];
    ppoPanel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.9];
    ppoPanel.layer.cornerRadius = 12;
    ppoPanel.clipsToBounds = YES;
    UILabel *heading = [[UILabel alloc] initWithFrame:CGRectMake(12, 6, 220, 26)];
    heading.text = @"PullOver Pro • Beta preview";
    heading.textColor = UIColor.whiteColor;
    heading.font = [UIFont boldSystemFontOfSize:13];
    [ppoPanel addSubview:heading];
    ppoStatus = [[UILabel alloc] initWithFrame:CGRectMake(12, 31, 224, 24)];
    ppoStatus.textColor = UIColor.lightGrayColor;
    ppoStatus.font = [UIFont systemFontOfSize:11];
    [ppoPanel addSubview:ppoStatus];
    ppoList = [[UIScrollView alloc] initWithFrame:CGRectMake(6, 60, PPOOpenWidth - 12, PPOOpenHeight - 110)];
    [ppoPanel addSubview:ppoList];
    UIButton *refresh = [UIButton buttonWithType:UIButtonTypeSystem];
    refresh.frame = CGRectMake(170, 4, 70, 30);
    [refresh setTitle:@"↻" forState:UIControlStateNormal];
    [refresh setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [refresh addTarget:ppoTarget action:@selector(refresh:) forControlEvents:UIControlEventTouchUpInside];
    [ppoPanel addSubview:refresh];
    ppoPanel.hidden = YES;
    [ppoController.view addSubview:ppoPanel];

    ppoHandle = [UIButton buttonWithType:UIButtonTypeSystem];
    ppoHandle.frame = CGRectMake(0, 0, PPOClosedWidth, 44);
    ppoHandle.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.88];
    ppoHandle.layer.cornerRadius = 12;
    [ppoHandle setTitle:@"PPO ▶" forState:UIControlStateNormal];
    [ppoHandle setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [ppoHandle addTarget:ppoTarget action:@selector(toggle:) forControlEvents:UIControlEventTouchUpInside];
    [ppoHandle addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:ppoTarget action:@selector(move:)]];
    [ppoController.view addSubview:ppoHandle];
    ppoWindow.hidden = NO;
    NSLog(@"[PullOverPro Beta] preview loaded");
}
%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    dispatch_async(dispatch_get_main_queue(), ^{ PPOInstall(); });
}
%end
%ctor { NSLog(@"[PullOverPro Beta] injected"); }
