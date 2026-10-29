#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <dispatch/dispatch.h>
#import <objc/runtime.h>
#import "PPOAppData.h"
#import "PPOBridgeClient.h"
#import "PPOBridgeProtocol.h"
#import "PPOScenePreflight.h"
#import "PPOFloatingTrial.h"
#include <errno.h>

// Public UIKit overlay. Read-only scene inspection requires an explicit diagnostic tap.
// Overlay requires .ppo_enable_overlay; .ppo_disable takes precedence.
static UIWindow *ppoWindow;
static UIViewController *ppoController;
static UIButton *ppoHandle;
static UIView *ppoPanel;
static BOOL ppoExpanded = NO;
static BOOL ppoLightTheme = NO;
static UILabel *ppoStatus;
static const CGFloat PPOClosedWidth = 78;
static const CGFloat PPOOpenWidth = 218;
static const CGFloat PPOPanelHeight = 390;


// Metadata only: never send messages to these private classes or instantiate them.
static NSString *PPOAPIMetadata(void) {
    struct Entry { const char *className; const char *selector; BOOL classMethod; };
    const Entry entries[] = {
        {"SBApplicationController", "sharedInstance", YES},
        {"SBApplicationController", "allApplications", NO},
        {"SBApplication", "bundleIdentifier", NO},
        {"SBApplication", "displayIdentifier", NO},
        {"SBApplication", "displayName", NO},
        {"LSApplicationWorkspace", "defaultWorkspace", YES},
        {"LSApplicationWorkspace", "allInstalledApplications", NO},
        {"LSApplicationProxy", "applicationIdentifier", NO},
        {"LSApplicationProxy", "bundleIdentifier", NO},
        {"LSApplicationProxy", "localizedName", NO},
    };
    NSMutableString *report = [NSMutableString stringWithFormat:
        @"PPO 0.5.6 metadata1\nOS: %@\n"
         "Metadata only; no private methods called. No applications enumerated.\n"
         "Encoding does not establish ownership, entitlements or threading rules.\n\n",
        NSProcessInfo.processInfo.operatingSystemVersionString];
    for (const Entry &entry : entries) {
        Class cls = objc_lookUpClass(entry.className);
        SEL selector = sel_registerName(entry.selector);
        Method method = cls ? (entry.classMethod
            ? class_getClassMethod(cls, selector)
            : class_getInstanceMethod(cls, selector)) : NULL;
        const char *encoding = method ? method_getTypeEncoding(method) : NULL;
        [report appendFormat:@"%s %c%s | class=%s method=%s types=%s\n",
            entry.className, entry.classMethod ? '+' : '-', entry.selector,
            cls ? "present" : "missing", method ? "present" : "missing",
            encoding ? encoding : "(none)"];
    }
    return report;
}


static NSString *const PPOAppsPath = @"/var/mobile/Library/Logs/PullOverPro/apps-0.5.7.json";
static NSString *const PPOSelectionPath = @"/var/mobile/Library/Preferences/com.renatasy83.pulloverpro.diagnostic.selection.plist";
static dispatch_queue_t PPOFileQueue(void) {
    static dispatch_queue_t queue;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ queue = dispatch_queue_create("com.renatasy83.ppo.files", DISPATCH_QUEUE_SERIAL); });
    return queue;
}


static NSString *PPOBridgeFailureMessage(NSDictionary *response) {
    NSString *detail = response[@"detail"];
    if ([detail isEqual:@"feature-disabled"]) return @"PPO este dezactivat";
    if ([detail isEqual:@"disable-check-failed"]) return @"Starea PPO nu poate fi verificată";
    if ([detail isEqual:@"request-expired"]) return @"Cererea a expirat";
    if ([detail isEqual:@"application-not-permitted"]) return @"Aplicația nu poate fi deschisă";
    if ([detail isEqual:@"inventory-unavailable"]) return @"Lista aplicațiilor nu este disponibilă";
    return @"Serviciul PPO nu a acceptat cererea";
}

@interface PPOHandleTarget : NSObject
- (void)tapped:(id)sender;
- (void)panned:(UIPanGestureRecognizer *)recognizer;
- (void)toggleTheme:(id)sender;
- (void)resetPosition:(id)sender;
@property(nonatomic,strong) PPOHostSessionSlot *hostSessions;
- (void)openFloatingApp:(UIButton *)sender;
@property(nonatomic,copy) NSArray<NSDictionary *> *apps;
@property(nonatomic,copy) NSString *selectedIdentifier;
@property(nonatomic) NSUInteger page;
@property(nonatomic) NSUInteger listEpoch;
@property(nonatomic) NSUInteger saveEpoch;
@property(nonatomic) BOOL selectionSaving;
@property(nonatomic) BOOL launchInProgress;
@property(nonatomic) BOOL launchStopped;
@property(nonatomic,strong) UIButton *launchButton;
@property(nonatomic,strong) UIView *listView;
@property(nonatomic,strong) UIScrollView *listScroll;
@property(nonatomic,strong) UILabel *pageLabel;
@property(nonatomic,strong) UIButton *previousButton;
@property(nonatomic,strong) UIButton *nextButton;
- (void)showApps:(UIButton *)sender;
- (void)launchSelected:(UIButton *)sender;
- (void)updateLaunchButton;
- (void)renderApps;
- (void)closeApps:(id)sender;
- (void)changePage:(UIButton *)sender;
- (void)selectApp:(UIButton *)sender;
- (void)inspectAPI:(UIButton *)sender;
@end

@implementation PPOHandleTarget
- (void)openFloatingApp:(UIButton *)sender {
    (void)sender;
    if (self.launchInProgress || self.selectionSaving) return;
    if (!PPOHostApplicationAllowed(self.selectedIdentifier)) {
        ppoStatus.text = @"Selectează Safari sau Configurări"; return;
    }
    NSDictionary *selected = nil;
    for (NSDictionary *app in self.apps) {
        if ([app[@"bundleIdentifier"] isEqual:self.selectedIdentifier]) { selected = app; break; }
    }
    if (!selected) { ppoStatus.text = @"Selectează aplicația din listă"; return; }
    if (!self.hostSessions) self.hostSessions = [PPOHostSessionSlot new];
    PPOFloatingTrial *candidate = [PPOFloatingTrial new];
    NSError *error = nil;
    if (![self.hostSessions adopt:candidate error:&error]) {
        ppoStatus.text = error.code == EBUSY ? @"Închide întâi fereastra activă"
            : @"Închiderea anterioară este neconfirmată; oprește proba";
        return;
    }
    ppoStatus.text = [candidate openInScene:ppoWindow.windowScene
        bundleIdentifier:[self.selectedIdentifier copy] displayName:selected[@"name"]];
}

- (void)updateLaunchButton {
    self.launchButton.enabled = !self.selectionSaving && !self.launchInProgress &&
        !self.launchStopped && PPOBridgeValidIdentifier(self.selectedIdentifier) &&
        ![self.selectedIdentifier isEqual:@"com.apple.springboard"] &&
        ![self.selectedIdentifier isEqual:@"com.apple.backboardd"];
}
- (void)launchSelected:(UIButton *)sender {
    (void)sender;
    if (!self.launchButton.enabled) return;
    self.launchInProgress = YES;
    [self updateLaunchButton];
    NSUInteger selectionEpoch = self.saveEpoch;
    NSString *identifier = [self.selectedIdentifier copy];
    ppoStatus.text = @"Se solicită deschiderea aplicației…";
    dispatch_async(PPOFileQueue(), ^{
        @autoreleasepool {
            NSError *error = nil;
            NSDictionary *response = PPOBridgeSend(@"launch", identifier, &error);
            dispatch_async(dispatch_get_main_queue(), ^{
                self.launchInProgress = NO;
                // Unknown result must not be retried automatically.
                self.launchStopped = !response;
                [self updateLaunchButton];
                if (selectionEpoch != self.saveEpoch) return;
                NSString *status = response[@"status"];
                if ([status isEqual:@"accepted"]) ppoStatus.text = @"Cerere de deschidere acceptată";
                else if (response) ppoStatus.text = PPOBridgeFailureMessage(response);
                else ppoStatus.text = [NSString stringWithFormat:@"Serviciu indisponibil (%ld); rezultat necunoscut", (long)error.code];
            });
        }
    });
}
- (void)inspectAPI:(UIButton *)sender {
    static BOOL requested = NO; // One bounded report per SpringBoard process.
    if (requested) { ppoStatus.text = @"Raport deja solicitat"; return; }
    requested = YES;
    sender.enabled = NO;
    ppoStatus.text = @"Se verifică scena Safari…";
    // The only entry point: explicit tap, main thread, once per process.
    NSDictionary *sceneReport = PPOScenePreflight([self.selectedIdentifier copy]);
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        @autoreleasepool {
            NSError *error = nil;
            BOOL saved = NO;
            @try {
                NSString *report = PPOAPIMetadata();
                NSString *directory = @"/var/mobile/Library/Logs/PullOverPro";
                if ([NSFileManager.defaultManager createDirectoryAtPath:directory
                    withIntermediateDirectories:YES attributes:nil error:&error]) {
                    NSData *sceneJSON = [NSJSONSerialization dataWithJSONObject:sceneReport
                        options:NSJSONWritingPrettyPrinted error:&error];
                    BOOL sceneSaved = sceneJSON && [sceneJSON writeToFile:
                        [directory stringByAppendingPathComponent:@"scene-0.7.0.json"]
                        options:NSDataWritingAtomic error:&error];
                    saved = sceneSaved && [report writeToFile:[directory stringByAppendingPathComponent:
                        @"metadata-0.5.6.txt"] atomically:YES
                        encoding:NSUTF8StringEncoding error:&error];
                }
                NSLog(@"[PPO 0.8.0] metadata-report=%@", saved ? @"saved" : @"write-failed");
            } @catch (NSException *exception) {
                NSLog(@"[PPO 0.8.0] metadata-exception=%@", exception.name);
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                ppoStatus.text = saved ? @"Raport scenă salvat (Filza)" : @"Raport API: eroare";
            });
        }
    });
}
- (void)tapped:(id)sender {
    if (!ppoWindow || !ppoHandle || !ppoPanel) return;
    ppoExpanded = !ppoExpanded;
    [ppoHandle setTitle:(ppoExpanded ? @"PPO ✕" : @"PPO ▶") forState:UIControlStateNormal];
    CGRect frame = ppoWindow.frame;
    frame.size.width = ppoExpanded ? PPOOpenWidth : PPOClosedWidth;
    frame.size.height = ppoExpanded ? PPOPanelHeight : 44;
    CGFloat maxY = MAX(0, CGRectGetHeight(ppoWindow.windowScene.coordinateSpace.bounds) - CGRectGetHeight(frame));
    frame.origin.y = MAX(0, MIN(maxY, frame.origin.y));
    ppoWindow.frame = frame;
    ppoController.view.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    self.listEpoch++;
    self.listView.hidden = YES;
    ppoPanel.hidden = !ppoExpanded;
    ppoStatus.text = @"Selectează o aplicație";
    NSLog(@"[PPO 0.8.0] panel %@", ppoExpanded ? @"open" : @"closed");
}
- (void)panned:(UIPanGestureRecognizer *)recognizer {
    if (!ppoWindow) return;
    CGPoint delta = [recognizer translationInView:ppoWindow];
    CGRect frame = ppoWindow.frame;
    frame.origin.y += delta.y;
    CGFloat maxY = MAX(0, CGRectGetHeight(ppoWindow.windowScene.coordinateSpace.bounds) - CGRectGetHeight(frame));
    frame.origin.y = MAX(0, MIN(maxY, frame.origin.y));
    ppoWindow.frame = frame;
    [recognizer setTranslation:CGPointZero inView:ppoWindow];
}
- (void)toggleTheme:(id)sender {
    ppoLightTheme = !ppoLightTheme;
    UIColor *background = ppoLightTheme ? [UIColor colorWithWhite:0.94 alpha:0.96] : [[UIColor blackColor] colorWithAlphaComponent:0.88];
    UIColor *foreground = ppoLightTheme ? UIColor.blackColor : UIColor.whiteColor;
    ppoPanel.backgroundColor = background;
    ppoHandle.backgroundColor = background;
    [ppoHandle setTitleColor:foreground forState:UIControlStateNormal];
    for (UIView *v in ppoPanel.subviews) {
        if ([v isKindOfClass:UILabel.class]) ((UILabel *)v).textColor = foreground;
        if ([v isKindOfClass:UIButton.class]) [(UIButton *)v setTitleColor:foreground forState:UIControlStateNormal];
    }
    ppoStatus.text = ppoLightTheme ? @"Temă: deschisă" : @"Temă: închisă";
}
- (void)showApps:(UIButton *)sender {
    if (!ppoExpanded) return;
    sender.enabled = NO;
    NSUInteger epoch = ++self.listEpoch;
    ppoStatus.text = @"Se încarcă aplicațiile…";
    dispatch_async(PPOFileQueue(), ^{
        @autoreleasepool {
            NSArray<NSDictionary *> *apps = nil;
            NSDictionary *selected = nil;
            NSString *loadMessage = nil;
            @try {
                NSDictionary *refresh = PPOBridgeSend(@"refresh", nil, NULL);
                if (![refresh[@"status"] isEqual:@"refreshed"]) {
                    loadMessage = refresh ? PPOBridgeFailureMessage(refresh) : @"Serviciul PPO nu răspunde";
                } else {
                    apps = PPOAppsFromData(PPOReadBoundedFile(PPOAppsPath, 2 * 1024 * 1024, NULL), NULL);
                    selected = PPOSelectionFromData(PPOReadBoundedFile(PPOSelectionPath, 16384, NULL));
                    BOOL found = NO;
                    for (NSDictionary *app in apps) {
                        if ([app[@"bundleIdentifier"] isEqual:selected[@"bundleIdentifier"]]) { found = YES; break; }
                    }
                    if (!found) selected = nil;
                }
            } @catch (NSException *exception) {
                NSLog(@"[PPO 0.8.0] app-file-exception=%@", exception.name);
                apps = nil;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                sender.enabled = YES;
                if (epoch != self.listEpoch || !ppoExpanded) return;
                if (!apps) { ppoStatus.text = loadMessage ?: @"Lista nu este disponibilă"; return; }
                self.apps = apps;
                self.page = 0;
                self.selectedIdentifier = selected[@"bundleIdentifier"];
                [self updateLaunchButton];
                ppoStatus.text = selected ? [NSString stringWithFormat:@"Selectat: %@", selected[@"name"]]
                                         : @"Nicio aplicație selectată";
                @try {
                    [self renderApps];
                    self.listView.hidden = NO;
                    ppoPanel.hidden = YES;
                } @catch (NSException *exception) {
                    [self.listView removeFromSuperview];
                    self.listView = nil;
                    ppoPanel.hidden = NO;
                    ppoStatus.text = @"Lista nu poate fi afișată";
                    NSLog(@"[PPO 0.8.0] app-ui-exception=%@", exception.name);
                }
            });
        }
    });
}
- (void)renderApps {
    if (!self.listView) {
        UIView *panel = [[UIView alloc] initWithFrame:ppoPanel.frame];
        panel.layer.cornerRadius = 12;
        panel.clipsToBounds = YES;
        UIButton *back = [UIButton buttonWithType:UIButtonTypeSystem];
        back.frame = CGRectMake(8, 4, 94, 32);
        [back setTitle:@"◀ Înapoi" forState:UIControlStateNormal];
        [back addTarget:self action:@selector(closeApps:) forControlEvents:UIControlEventTouchUpInside];
        [panel addSubview:back];
        UILabel *pageLabel = [[UILabel alloc] initWithFrame:CGRectMake(104, 4, 106, 32)];
        pageLabel.font = [UIFont systemFontOfSize:11];
        pageLabel.textAlignment = NSTextAlignmentRight;
        [panel addSubview:pageLabel];
        UIScrollView *scroll = [[UIScrollView alloc] initWithFrame:CGRectMake(6, 42, PPOOpenWidth - 12, 214)];
        [panel addSubview:scroll];
        UIButton *previous = [UIButton buttonWithType:UIButtonTypeSystem];
        previous.frame = CGRectMake(8, 264, 94, 32);
        previous.tag = -1;
        [previous setTitle:@"◀ Anterior" forState:UIControlStateNormal];
        [previous addTarget:self action:@selector(changePage:) forControlEvents:UIControlEventTouchUpInside];
        [panel addSubview:previous];
        UIButton *next = [UIButton buttonWithType:UIButtonTypeSystem];
        next.frame = CGRectMake(112, 264, 98, 32);
        next.tag = 1;
        [next setTitle:@"Următor ▶" forState:UIControlStateNormal];
        [next addTarget:self action:@selector(changePage:) forControlEvents:UIControlEventTouchUpInside];
        [panel addSubview:next];
        [ppoController.view addSubview:panel];
        self.listView = panel;
        self.listScroll = scroll;
        self.pageLabel = pageLabel;
        self.previousButton = previous;
        self.nextButton = next;
    }
    UIColor *foreground = ppoLightTheme ? UIColor.blackColor : UIColor.whiteColor;
    self.listView.backgroundColor = ppoPanel.backgroundColor;
    self.pageLabel.textColor = foreground;
    for (UIView *view in self.listView.subviews) {
        if ([view isKindOfClass:UIButton.class]) [(UIButton *)view setTitleColor:foreground forState:UIControlStateNormal];
    }
    for (UIView *view in [self.listScroll.subviews copy]) {
        if ([view isKindOfClass:UIButton.class]) [view removeFromSuperview];
    }
    NSUInteger pages = (self.apps.count + 24) / 25;
    if (!pages || self.page >= pages) self.page = 0;
    self.previousButton.enabled = self.page > 0;
    self.nextButton.enabled = self.page + 1 < pages;
    self.pageLabel.text = pages ? [NSString stringWithFormat:@"%lu/%lu · %lu",
        (unsigned long)self.page + 1, (unsigned long)pages, (unsigned long)self.apps.count] : @"0 aplicații";
    NSUInteger start = self.page * 25;
    NSUInteger end = MIN(start + 25, self.apps.count);
    CGFloat y = 0;
    for (NSUInteger i = start; i < end; i++) {
        NSDictionary *app = self.apps[i];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.frame = CGRectMake(2, y, PPOOpenWidth - 16, 46);
        button.tag = (NSInteger)i;
        button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        button.titleLabel.numberOfLines = 2;
        button.titleLabel.font = [UIFont systemFontOfSize:11];
        button.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        NSString *mark = [app[@"bundleIdentifier"] isEqual:self.selectedIdentifier] ? @"✓ " : @"";
        [button setTitle:[NSString stringWithFormat:@"%@%@\n%@", mark, app[@"name"], app[@"bundleIdentifier"]]
               forState:UIControlStateNormal];
        [button setTitleColor:foreground forState:UIControlStateNormal];
        [button addTarget:self action:@selector(selectApp:) forControlEvents:UIControlEventTouchUpInside];
        [self.listScroll addSubview:button];
        y += 48;
    }
    self.listScroll.contentSize = CGSizeMake(PPOOpenWidth - 12, y);
    self.listScroll.contentOffset = CGPointZero;
}
- (void)closeApps:(id)sender {
    self.listEpoch++;
    self.listView.hidden = YES;
    ppoPanel.hidden = !ppoExpanded;
}
- (void)changePage:(UIButton *)sender {
    NSInteger next = (NSInteger)self.page + sender.tag;
    NSUInteger pages = (self.apps.count + 24) / 25;
    if (next < 0 || (NSUInteger)next >= pages) return;
    self.page = (NSUInteger)next;
    @try { [self renderApps]; }
    @catch (NSException *exception) {
        [self closeApps:nil];
        ppoStatus.text = @"Pagina nu poate fi afișată";
        NSLog(@"[PPO 0.8.0] page-exception=%@", exception.name);
    }
}
- (void)selectApp:(UIButton *)sender {
    if (sender.tag < 0 || (NSUInteger)sender.tag >= self.apps.count) return;
    NSDictionary *selection = self.apps[(NSUInteger)sender.tag];
    self.selectedIdentifier = selection[@"bundleIdentifier"];
    self.selectionSaving = YES;
    [self updateLaunchButton];
    [self closeApps:nil];
    NSUInteger epoch = ++self.saveEpoch;
    ppoStatus.text = @"Se salvează selecția…";
    dispatch_async(PPOFileQueue(), ^{
        @autoreleasepool {
            BOOL saved = NO;
            @try {
                NSData *data = PPOSelectionData(selection, NULL);
                NSString *directory = PPOSelectionPath.stringByDeletingLastPathComponent;
                if (data && [NSFileManager.defaultManager createDirectoryAtPath:directory
                    withIntermediateDirectories:YES attributes:nil error:NULL]) {
                    saved = [data writeToFile:PPOSelectionPath options:NSDataWritingAtomic error:NULL];
                }
            } @catch (NSException *exception) {
                NSLog(@"[PPO 0.8.0] selection-exception=%@", exception.name);
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (epoch != self.saveEpoch) return;
                ppoStatus.text = saved ? [NSString stringWithFormat:@"Selectat: %@", selection[@"name"]]
                                      : @"Selecție nesalvată";
                if (!saved) self.selectedIdentifier = nil;
                self.selectionSaving = NO;
                [self updateLaunchButton];
            });
        }
    });
}
- (void)resetPosition:(id)sender {
    if (!ppoWindow) return;
    CGRect frame = ppoWindow.frame;
    frame.origin.y = 170;
    CGFloat maxY = MAX(0, CGRectGetHeight(ppoWindow.windowScene.coordinateSpace.bounds) - CGRectGetHeight(frame));
    frame.origin.y = MIN(frame.origin.y, maxY);
    ppoWindow.frame = frame;
    ppoStatus.text = @"Poziție resetată";
}
@end

static PPOHandleTarget *ppoTarget;

static UILabel *PPOLabel(NSString *text, CGFloat y) {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(12, y, PPOOpenWidth - 24, 28)];
    label.text = text;
    label.textColor = UIColor.whiteColor;
    label.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    label.textAlignment = NSTextAlignmentLeft;
    return label;
}

static void PPOCommitOverlay(UIWindow *window, UIViewController *controller,
                             PPOHandleTarget *target, UIView *panel,
                             UILabel *status, UIButton *handle) {
    ppoWindow = window;
    ppoController = controller;
    ppoTarget = target; // UIControl does not retain its action target.
    ppoPanel = panel;
    ppoStatus = status;
    ppoHandle = handle;
}

static void PPOBuildOverlay(UIWindowScene *scene) {
    NSLog(@"[PPO 0.8.0] ui-build-begin");
    UIWindow *ppoWindow = [[UIWindow alloc] initWithWindowScene:scene];
    ppoWindow.frame = CGRectMake(0, 170, PPOClosedWidth, 44);
    ppoWindow.windowLevel = UIWindowLevelStatusBar + 1;
    ppoWindow.backgroundColor = UIColor.clearColor;
    UIViewController *ppoController = [UIViewController new];
    ppoController.view.backgroundColor = UIColor.clearColor;
    ppoWindow.rootViewController = ppoController;
    // Initialize the action target before attaching any favorite buttons.
    PPOHandleTarget *ppoTarget = [PPOHandleTarget new];

    UIView *ppoPanel = [[UIView alloc] initWithFrame:CGRectMake(0, 44, PPOOpenWidth, PPOPanelHeight - 44)];
    ppoPanel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.88];
    ppoPanel.layer.cornerRadius = 12;
    ppoPanel.layer.masksToBounds = YES;
    [ppoPanel addSubview:PPOLabel(@"PullOver Pro • 0.8.0-dev", 8)];
    [ppoPanel addSubview:PPOLabel(@"Aplicații", 43)];
    UIButton *apps = [UIButton buttonWithType:UIButtonTypeSystem];
    apps.frame = CGRectMake(10, 72, PPOOpenWidth - 20, 32);
    [apps setTitle:@"Deschide lista" forState:UIControlStateNormal];
    [apps setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [apps addTarget:ppoTarget action:@selector(showApps:) forControlEvents:UIControlEventTouchUpInside];
    [ppoPanel addSubview:apps];
    [ppoPanel addSubview:PPOLabel(@"Alege aplicația pentru PPO", 110)];
    UIButton *launch = [UIButton buttonWithType:UIButtonTypeSystem];
    launch.frame = CGRectMake(10, 143, PPOOpenWidth - 20, 32);
    [launch setTitle:@"Deschide aplicația" forState:UIControlStateNormal];
    [launch setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [launch addTarget:ppoTarget action:@selector(launchSelected:) forControlEvents:UIControlEventTouchUpInside];
    ppoTarget.launchButton = launch;
    [ppoTarget updateLaunchButton];
    [ppoPanel addSubview:launch];
    UILabel *ppoStatus = PPOLabel(@"Nicio aplicație selectată", 182);
    ppoStatus.numberOfLines = 2;
    ppoStatus.font = [UIFont systemFontOfSize:11];
    ppoStatus.frame = CGRectMake(12, 182, PPOOpenWidth - 24, 32);
    [ppoPanel addSubview:ppoStatus];
    UIButton *theme = [UIButton buttonWithType:UIButtonTypeSystem];
    theme.frame = CGRectMake(10, 218, 92, 32);
    [theme setTitle:@"Temă" forState:UIControlStateNormal];
    [theme setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [theme addTarget:ppoTarget action:@selector(toggleTheme:) forControlEvents:UIControlEventTouchUpInside];
    [ppoPanel addSubview:theme];
    UIButton *reset = [UIButton buttonWithType:UIButtonTypeSystem];
    reset.frame = CGRectMake(110, 218, 98, 32);
    [reset setTitle:@"Recentrare" forState:UIControlStateNormal];
    [reset setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [reset addTarget:ppoTarget action:@selector(resetPosition:) forControlEvents:UIControlEventTouchUpInside];
    [ppoPanel addSubview:reset];
    UIButton *inspect = [UIButton buttonWithType:UIButtonTypeSystem];
    inspect.frame = CGRectMake(10, 258, PPOOpenWidth - 20, 32);
    [inspect setTitle:@"Diagnostic API" forState:UIControlStateNormal];
    [inspect setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [inspect addTarget:ppoTarget action:@selector(inspectAPI:) forControlEvents:UIControlEventTouchUpInside];
    [ppoPanel addSubview:inspect];
    UIButton *trial = [UIButton buttonWithType:UIButtonTypeSystem];
    trial.frame = CGRectMake(10, 298, PPOOpenWidth - 20, 32);
    [trial setTitle:@"Deschide în fereastră" forState:UIControlStateNormal];
    [trial setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [trial addTarget:ppoTarget action:@selector(openFloatingApp:) forControlEvents:UIControlEventTouchUpInside];
    [ppoPanel addSubview:trial];
    ppoPanel.hidden = YES;
    [ppoController.view addSubview:ppoPanel];

    UIButton *ppoHandle = [UIButton buttonWithType:UIButtonTypeSystem];
    ppoHandle.frame = CGRectMake(0, 0, PPOClosedWidth, 44);
    ppoHandle.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.88];
    ppoHandle.layer.cornerRadius = 12;
    [ppoHandle setTitle:@"PPO ▶" forState:UIControlStateNormal];
    [ppoHandle setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    ppoHandle.titleLabel.font = [UIFont boldSystemFontOfSize:13];
    [ppoHandle addTarget:ppoTarget action:@selector(tapped:) forControlEvents:UIControlEventTouchUpInside];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:ppoTarget action:@selector(panned:)];
    [ppoHandle addGestureRecognizer:pan];
    [ppoController.view addSubview:ppoHandle];

    NSLog(@"[PPO 0.8.0] ui-built; showing");
    ppoWindow.hidden = NO;
    PPOCommitOverlay(ppoWindow, ppoController, ppoTarget, ppoPanel, ppoStatus, ppoHandle);
    NSLog(@"[PPO 0.8.0] ui-visible");
}

static BOOL ppoScheduled;
static BOOL ppoStopped;
static NSUInteger ppoAttempts;
static id ppoSceneObserver;

static BOOL PPOOverlayAllowed(void) {
    NSFileManager *files = NSFileManager.defaultManager;
    return ![files fileExistsAtPath:@"/var/mobile/.ppo_disable"] &&
           [files fileExistsAtPath:@"/var/mobile/.ppo_enable_overlay"];
}

// Main queue only, at most three attempts per process; never wait for a scene.
static void PPOScheduleOverlay(void) {
    if (ppoScheduled || ppoStopped || ppoWindow) return;
    ppoScheduled = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
                   dispatch_get_main_queue(), ^{
        ppoScheduled = NO;
        if (ppoStopped || ppoWindow) return;
        if (!PPOOverlayAllowed()) { ppoStopped = YES; return; }
        @try {
            ppoAttempts++;
            UIWindowScene *scene = nil;
            for (UIScene *candidate in UIApplication.sharedApplication.connectedScenes) {
                if ([candidate isKindOfClass:UIWindowScene.class] &&
                    candidate.activationState == UISceneActivationStateForegroundActive) {
                    scene = (UIWindowScene *)candidate;
                    break;
                }
            }
            if (scene) {
                PPOBuildOverlay(scene);
                ppoStopped = YES;
            } else if (ppoAttempts < 3) {
                PPOScheduleOverlay();
            } else {
                NSLog(@"[PPO 0.8.0] no-active-scene; stopped");
                ppoStopped = YES;
            }
        } @catch (NSException *exception) {
            // Catches synchronous ObjC exceptions only, not hangs or memory faults.
            NSLog(@"[PPO 0.8.0] ui-exception=%@; stopped", exception.name);
            ppoStopped = YES;
        }
        if (ppoStopped && ppoSceneObserver) {
            [NSNotificationCenter.defaultCenter removeObserver:ppoSceneObserver];
            ppoSceneObserver = nil;
        }
    });
}

%ctor {
    @autoreleasepool {
        NSLog(@"[PPO 0.8.0] loaded; os=%@",
              NSProcessInfo.processInfo.operatingSystemVersionString);
        if (!PPOOverlayAllowed()) {
            NSLog(@"[PPO 0.8.0] overlay-disabled; no hooks installed");
            return;
        }
        // No UIKit objects or private SpringBoard methods touched in the ctor.
        dispatch_async(dispatch_get_main_queue(), ^{
            ppoSceneObserver = [NSNotificationCenter.defaultCenter
                addObserverForName:UISceneDidActivateNotification object:nil
                queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) {
                    PPOScheduleOverlay();
                }];
            NSLog(@"[PPO 0.8.0] overlay-armed");
            PPOScheduleOverlay();
        });
    }
}


