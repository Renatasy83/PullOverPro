#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <dispatch/dispatch.h>
#import <objc/runtime.h>
#import "PPOAppData.h"
#import "PPOFavoriteApps.h"
#import "PPOFavoritesStore.h"
#import "PPOPickerState.h"
#import "PPOBridgeClient.h"
#import "PPOBridgeProtocol.h"
#import "PPOScenePreflight.h"
#import "PPOOwnedSafariTrial.h"
#import "PPOOwnedApplicationPolicy.h"
#import "PPOOwnedAdmission.h"
#import "PPOSceneCapability.h"
#import "PPOUserPreferences.h"
#import "PPOClassicQuickSwitchView.h"
#import "PPOKeyboardMonitor.h"
#include "PPOKeyboardAvoidance.h"
#include "PPOHandleNubState.h"
#import "PPOScreenLockState.h"
#include "PPOEdgeDrawerGeometry.h"
#include "PPOInteractionIntent.h"
#include <sys/stat.h>
#include <errno.h>

// Public edge UI. Scene creation stays in the existing guarded owner adapter.
static UIWindow *ppoWindow;
static UIViewController *ppoController;
static UIButton *ppoHandle;
static UIView *ppoHandlePill;
static UIVisualEffectView *ppoHandleBlur;
static UIImageView *ppoHandleIcon;
static UIButton *ppoClassicClose;
static PPOClassicQuickSwitchView *ppoClassicView;
static UIControl *ppoOutsideDismiss;
static CAShapeLayer *ppoOutsideMask;
static NSInteger ppoRenderedTheme = -1;
static NSString *ppoRenderedSymbol;
static UIView *ppoPanel;
static BOOL ppoExpanded = NO;
static BOOL ppoLightTheme = NO;
static UILabel *ppoStatus;
static CGFloat PPOOpenWidth = 320;
static NSDictionary *ppoPreferences;
static PPOEdgeDrawerLayout ppoEdgeLayout;
static double ppoChooserProgress;
static BOOL ppoHandleNubbed;
static PPOHandleNubState ppoNubState;
static PPOKeyboardMonitor *ppoKeyboardMonitor;
static UIEdgeInsets ppoCompactInsets;
static BOOL ppoKeyboardAdjusted;
static CGFloat ppoKeyboardShiftY;
static NSUInteger ppoManualNubCount;
static void PPORecordInterfaceEvent(NSString *event);
static void PPOKeyboardDidChange(void);
static BOOL ppoWasDrawerOpen;
static NSTimeInterval ppoLastInteraction;
static BOOL ppoFirmwareMatches;
static dispatch_source_t ppoVisibilityTimer;
static BOOL PPOOverlayAllowed(void);
static void PPOScheduleOverlay(void);
static void PPOApplyOverlayLayout(void);
static void PPORefreshOverlayVisibility(void);
static void PPORequestPreferences(void);
static CGRect PPOCGRect(PPOHostRect r) { return CGRectMake(r.x, r.y, r.width, r.height); }
static PPOEdgeDrawerSide PPOChosenEdge(void) {
    return [ppoPreferences[@"edge"] isEqual:@"left"] ? PPOEdgeDrawerSide::Left : PPOEdgeDrawerSide::Right;
}

@interface PPOEdgeStatusLabel : UILabel
@property(nonatomic) NSUInteger messageGeneration;
@end
@implementation PPOEdgeStatusLabel
- (void)setText:(NSString *)text {
    [super setText:text];
    if (!NSThread.isMainThread || !ppoWindow || !text.length) return;
    NSUInteger generation = ++self.messageGeneration;
    CGRect screen = ppoWindow.bounds;
    self.frame = CGRectMake(MAX(8,(screen.size.width-300)/2), MAX(48,MIN(screen.size.height-110,CGRectGetMidY(ppoHandle.frame)-70)), MIN(300,screen.size.width-16),60);
    self.hidden = NO;
    __weak PPOEdgeStatusLabel *weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,4*NSEC_PER_SEC),dispatch_get_main_queue(), ^{
        if (weakSelf.messageGeneration == generation) weakSelf.hidden = YES;
    });
}
@end

@interface PPOOutsideControl : UIControl
@property(nonatomic) CGRect excludedPanel;
@end
@implementation PPOOutsideControl
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if (!CGRectIsNull(self.excludedPanel) && CGRectContainsPoint(self.excludedPanel,point)) return NO;
    return [super pointInside:point withEvent:event];
}
@end

@interface PPOEdgeOverlayWindow : UIWindow
@end
@implementation PPOEdgeOverlayWindow
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (ppoClassicView.visible) {
        UIView *classicHit = [ppoClassicView hitTest:[ppoClassicView convertPoint:point fromView:self] withEvent:event];
        if (classicHit) return classicHit;
    }
    UIView *hit = [super hitTest:point withEvent:event];
    // A transparent full-scene window must never consume the surrounding app.
    if (hit && ((ppoHandle && [hit isDescendantOfView:ppoHandle]) ||
        (ppoPanel && !ppoPanel.hidden && [hit isDescendantOfView:ppoPanel]) ||
        (ppoOutsideDismiss && !ppoOutsideDismiss.hidden && [hit isDescendantOfView:ppoOutsideDismiss]))) return hit;
    return nil;
}
@end

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
static NSString *const PPOFavoritesDirectory = @"/var/mobile/Library/Preferences/com.renatasy83.pulloverpro.diagnostic.favorites";
static NSString *const PPOSelectionPath = @"/var/mobile/Library/Preferences/com.renatasy83.pulloverpro.diagnostic.selection.plist";
static dispatch_queue_t PPOFileQueue(void) {
    static dispatch_queue_t queue;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ queue = dispatch_queue_create("com.renatasy83.ppo.files", DISPATCH_QUEUE_SERIAL); });
    return queue;
}


static dispatch_queue_t PPOPreferenceQueue(void) {
    static dispatch_queue_t queue;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ queue = dispatch_queue_create("com.renatasy83.ppo.presentation-preferences", DISPATCH_QUEUE_SERIAL); });
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

// Worker queue only. A bounded selected-app diagnostic, never bundle paths or
// plist/user contents. The bridge response has already passed nonce validation.
static void PPOWriteCapabilityObservation(NSString *identifier, NSDictionary *response, NSError *error) {
    NSDictionary *capability = PPOSceneCapabilityNormalize(response[@"sceneCapability"]);
    NSDictionary *report = @{@"schema": @1, @"version": @"1.0.2~rc3",
        @"bundleIdentifier": identifier, @"responseStatus": response[@"status"] ?: @"unavailable",
        @"sceneCapability": capability ?: (id)NSNull.null, @"errorCode": @(error.code),
        @"observedUptime": @(NSProcessInfo.processInfo.systemUptime), @"runtimeCompatibilityConfirmed": @NO};
    NSString *directory = @"/var/mobile/Library/Logs/PullOverPro";
    NSData *data = [NSJSONSerialization dataWithJSONObject:report options:NSJSONWritingPrettyPrinted error:NULL];
    if (data && [NSFileManager.defaultManager createDirectoryAtPath:directory
        withIntermediateDirectories:YES attributes:nil error:NULL])
        [data writeToFile:[directory stringByAppendingPathComponent:@"capability-1.0.2.json"]
            options:NSDataWritingAtomic error:NULL];
}

// Worker-only bounded diagnostics: counts/outcome, never the favorite IDs or names.
static void PPOWritePickerObservation(NSString *event, NSUInteger count, BOOL readable, NSError *error) {
    NSDictionary *report = @{@"schema": @1, @"version": @"1.0.2~rc3", @"event": event,
        @"favoriteCount": @(MIN(count, PPOFavoriteIdentifiersLimit)), @"readable": @(readable),
        @"errorCode": @(error.code), @"errorDomain": error ? ([error.domain isEqual:NSPOSIXErrorDomain] ? @"posix" : @"data") : @"none",
        @"runtimeCompatibilityConfirmed": @NO};
    NSData *data = [NSJSONSerialization dataWithJSONObject:report options:NSJSONWritingPrettyPrinted error:NULL];
    NSString *directory = @"/var/mobile/Library/Logs/PullOverPro";
    if (data && [NSFileManager.defaultManager createDirectoryAtPath:directory withIntermediateDirectories:YES
        attributes:nil error:NULL]) [data writeToFile:[directory stringByAppendingPathComponent:@"picker-1.0.2.json"]
            options:NSDataWritingAtomic error:NULL];
}

// Each row carries immutable identity and a render generation, rather than an
// index that could silently select another app after filtering or page changes.
@interface PPOPickerRowButton : UIButton
@property(nonatomic,copy) NSString *boundIdentifier;
@property(nonatomic) NSUInteger boundGeneration;
@property(nonatomic) CGRect restingFrame;
@end
@implementation PPOPickerRowButton
@end

@interface PPOHandleTarget : NSObject <UIGestureRecognizerDelegate>
- (void)tapped:(id)sender;
- (void)panned:(UIPanGestureRecognizer *)recognizer;
@property(nonatomic,strong) PPOHostSessionSlot *hostSessions;
@property(nonatomic) double panStartProgress;
@property(nonatomic) BOOL verticalPan;
@property(nonatomic) BOOL panDirectionCommitted;
@property(nonatomic) double panStartCenterY;
@property(nonatomic) double panStartRatio;
@property(nonatomic) BOOL panTargetsHost;
@property(nonatomic) BOOL quickChoosing;
@property(nonatomic) BOOL classicRequested;
@property(nonatomic) BOOL cacheRestoreStarted;
- (void)restoreCachedPicker;
- (NSArray<NSDictionary *> *)projectedRows;
- (void)showClassicChooser;
- (void)classicChoice:(NSString *)identifier generation:(uint64_t)generation normal:(BOOL)normal;
- (void)selectApplicationRow:(NSDictionary *)row;
- (void)launchNormalRow:(NSDictionary *)row;
- (void)closeClassicWindow:(id)sender;
- (void)outsideTapped:(id)sender;
- (void)showAllApplications:(UITapGestureRecognizer *)recognizer;
@property(nonatomic) BOOL handlingPan;
@property(nonatomic) BOOL quickDragging;
@property(nonatomic,strong) PPOPickerRowButton *quickDragSource;
@property(nonatomic) CGPoint quickSourcePoint;
@property(nonatomic,strong) UIView *quickDropTarget;
@property(nonatomic,strong) UILabel *quickDropInstruction;
@property(nonatomic,strong) UILabel *quickDragBadge;
- (void)cancelQuickChoosing;
- (void)beginQuickDragAtPoint:(CGPoint)point;
- (void)updateQuickDragAtPoint:(CGPoint)point;
@property(nonatomic) NSInteger pickerMode;
@property(nonatomic,strong) PPOPickerRowButton *hoveredButton;
@property(nonatomic,strong) UISelectionFeedbackGenerator *feedback;
- (PPOOwnedSafariTrial *)activeDrawer;
- (void)showChooser:(NSInteger)mode;
- (void)layoutPicker;
- (void)closeChooser;
- (void)touchHandle;
- (void)inspectSelectedForIntent:(uint64_t)intent;
- (void)cancelOpening;
- (void)hideChooser;
@property(nonatomic,copy) NSDictionary *pendingApplication;
@property(nonatomic,copy) NSDictionary *pendingCapability;

- (void)openFloatingApp:(UIButton *)sender;
- (void)openPreparedApplication:(NSDictionary *)selected capability:(NSDictionary *)capability intent:(uint64_t)intent;
@property(nonatomic,strong) PPOPickerState *picker;
@property(nonatomic,copy,readonly) NSArray<NSDictionary *> *apps;
@property(nonatomic,copy,readonly) NSString *selectedIdentifier;
@property(nonatomic,copy) NSArray<NSDictionary *> *listRows;
@property(nonatomic) NSUInteger renderGeneration;
@property(nonatomic,strong) UISegmentedControl *pickerModes;
@property(nonatomic,strong) UILabel *pickerStatus;
@property(nonatomic,copy) NSString *pickerMessage;
@property(nonatomic) NSUInteger page;
@property(nonatomic,readonly) NSUInteger saveEpoch;
@property(nonatomic,readonly) BOOL selectionSaving;
@property(nonatomic) BOOL launchInProgress;
@property(nonatomic) BOOL launchStopped;
@property(nonatomic) BOOL hostInspectionPending;
@property(nonatomic) BOOL hostInspectionInFlight;
@property(nonatomic,strong) UIButton *launchButton;
@property(nonatomic,strong) UIView *listView;
@property(nonatomic,strong) UIScrollView *listScroll;
@property(nonatomic,strong) UILabel *pageLabel;
@property(nonatomic,strong) UIButton *previousButton;
@property(nonatomic,strong) UIButton *nextButton;
- (void)showApps:(UIButton *)sender;
- (void)loadPicker;
- (void)quickFavorites:(UILongPressGestureRecognizer *)recognizer;
- (void)pickerModeChanged:(UISegmentedControl *)sender;
- (void)toggleFavorite:(PPOPickerRowButton *)sender;
- (NSDictionary *)rowForButton:(PPOPickerRowButton *)sender;
- (void)launchSelected:(UIButton *)sender;
- (void)launchNormalFromRow:(PPOPickerRowButton *)sender;
- (void)updateLaunchButton;
- (void)renderApps;
- (void)closeApps:(id)sender;
- (void)changePage:(UIButton *)sender;
- (void)selectApp:(PPOPickerRowButton *)sender;
- (void)inspectAPI:(UIButton *)sender;
@end

@implementation PPOHandleTarget {
    PPOInteractionIntent _intent;
    uint64_t _panIntent;
}
- (NSArray<NSDictionary *> *)apps { return self.picker.apps; }
- (NSString *)selectedIdentifier { return self.picker.selectedIdentifier; }
- (NSUInteger)saveEpoch { return self.picker.selectionGeneration; }
- (BOOL)selectionSaving { return self.picker.selectionSaving; }
- (void)cancelOpening {
    _intent.cancel(); self.pendingApplication = nil; self.pendingCapability = nil;
    self.hostInspectionPending = NO;
}
- (void)openFloatingApp:(UIButton *)sender {
    (void)sender;
    if (self.hostInspectionInFlight) { ppoStatus.text = @"Se finalizează cererea anterioară…"; return; }
    [self cancelOpening];
    uint64_t intent = _intent.begin(false);
    [self inspectSelectedForIntent:intent];
}
- (void)inspectSelectedForIntent:(uint64_t)intent {
    if (!_intent.current(intent)) return;
    if (self.hostInspectionInFlight) { _intent.cancel(); ppoStatus.text = @"Se finalizează cererea anterioară…"; return; }
    if (self.launchInProgress || self.selectionSaving || self.hostInspectionPending) return;
    NSDictionary *selected = nil;
    for (NSDictionary *app in self.apps) {
        if ([app[@"bundleIdentifier"] isEqual:self.selectedIdentifier]) { selected = app; break; }
    }
    if (!selected) { ppoStatus.text = @"Selectează aplicația din listă"; return; }
    if (!PPOSceneApplicationIdentifierAllowed(self.selectedIdentifier)) {
        ppoStatus.text = @"Aplicația nu poate fi deschisă în fereastră"; return;
    }
    if (self.hostSessions.session && !self.hostSessions.session.finished) {
        ppoStatus.text = @"Închide întâi fereastra activă"; return;
    }
    NSString *identifier = [self.selectedIdentifier copy];
    NSUInteger epoch = self.saveEpoch;
    NSDictionary *chosen = [selected copy];
    self.hostInspectionPending = YES; self.hostInspectionInFlight = YES; [self updateLaunchButton];
    ppoStatus.text = @"Se deschide aplicația…";
    dispatch_async(PPOFileQueue(), ^{
        @autoreleasepool {
            NSError *error = nil;
            NSDictionary *response = nil;
            @try {
                response = PPOBridgeSend(@"inspect-scene", identifier, &error);
                PPOWriteCapabilityObservation(identifier, response, error);
            } @catch (NSException *exception) {
                (void)exception; response = nil;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                self.hostInspectionInFlight = NO;
                if (!_intent.current(intent)) return;
                self.hostInspectionPending = NO; [self updateLaunchButton];
                if (epoch != self.saveEpoch || ![identifier isEqual:self.selectedIdentifier] || !PPOOverlayAllowed()) return;
                if (![response[@"status"] isEqual:@"inspected"]) {
                    // A missing response can also mean a malformed or wrong-nonce
                    // reply. Preserve the baseline only for an explicit, validated
                    // unsupported response; never infer permission from timeout.
                    if (PPOOwnedApplicationAllowed(identifier) &&
                        [response[@"status"] isEqual:@"unsupported"]) {
                        [self openPreparedApplication:chosen capability:nil intent:intent]; return;
                    }
                    ppoStatus.text = response ? PPOBridgeFailureMessage(response) : @"Verificarea ferestrei nu este disponibilă";
                    return;
                }
                NSDictionary *capability = response[@"sceneCapability"];
                if (!PPOOwnedAdmissionSnapshot(identifier, capability, NSProcessInfo.processInfo.systemUptime)) {
                    ppoStatus.text = [capability[@"status"] isEqual:@"ineligible"]
                        ? @"Aplicația nu declară suportul necesar pentru ferestre"
                        : @"Suportul pentru fereastră nu poate fi verificat";
                    return;
                }
                [self openPreparedApplication:chosen capability:capability intent:intent];
            });
        }
    });
}
- (void)openPreparedApplication:(NSDictionary *)selected capability:(NSDictionary *)capability intent:(uint64_t)intent {
    if (!_intent.current(intent)) return;
    if (!PPOOverlayAllowed() || self.launchInProgress || self.selectionSaving) return;
    NSString *identifier = [selected[@"bundleIdentifier"] copy];
    if (![identifier isEqual:self.selectedIdentifier]) return;
    if (!PPOOwnedAdmissionSnapshot(identifier, capability, NSProcessInfo.processInfo.systemUptime)) {
        ppoStatus.text = @"Datele ferestrei nu pot fi validate"; return;
    }
    if (_intent.held(intent)) {
        self.pendingApplication = [selected copy]; self.pendingCapability = [capability copy];
        return; // Gesture cancellation must discard this before any private scene creation.
    }
    if (!_intent.consume(intent)) return;
    if (!self.hostSessions) self.hostSessions = [PPOHostSessionSlot new];
    PPOOwnedSafariTrial *candidate = [PPOOwnedSafariTrial new];
    [candidate configurePresentationWithPreferences:ppoPreferences];
    candidate.presentationDidChange = ^{ PPOApplyOverlayLayout(); };
    NSError *error = nil;
    if (![self.hostSessions adopt:candidate error:&error]) {
        ppoStatus.text = error.code == EBUSY ? @"Închide întâi fereastra activă"
            : @"Închiderea anterioară este neconfirmată; oprește proba";
        return;
    }
    ppoStatus.text = [candidate openInScene:ppoWindow.windowScene
        bundleIdentifier:identifier displayName:selected[@"name"] capability:capability];
    if (!candidate.finished) {
        [self hideChooser];
    }
    [self touchHandle];
}

- (void)updateLaunchButton {
    self.launchButton.enabled = !self.selectionSaving && !self.launchInProgress && !self.hostInspectionPending &&
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
                // An unknown opener result blocks further launches for this process,
                // including other targets; selection changes do not retry it.
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
- (void)launchNormalFromRow:(PPOPickerRowButton *)sender {
    NSDictionary *row = [self rowForButton:sender]; [self launchNormalRow:row];
}
- (void)launchNormalRow:(NSDictionary *)row {
    if (!row || ![row[@"available"] boolValue] || !PPOOverlayAllowed() || ppoWindow.hidden ||
        !UIApplication.sharedApplication.protectedDataAvailable || self.launchInProgress || self.launchStopped) return;
    NSString *identifier = [row[@"bundleIdentifier"] copy];
    if (!PPOSceneApplicationIdentifierAllowed(identifier)) return;
    self.launchInProgress = YES; [self closeChooser]; ppoStatus.text = @"Se deschide pe tot ecranul…";
    dispatch_async(PPOFileQueue(), ^{
        NSDictionary *response = PPOBridgeSend(@"launch", identifier, NULL);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.launchInProgress = NO; self.launchStopped = !response;
            ppoStatus.text = [response[@"status"] isEqual:@"accepted"] ? @"Aplicație deschisă"
                : (response ? PPOBridgeFailureMessage(response) : @"Serviciu indisponibil; rezultat necunoscut");
        });
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
                NSLog(@"[PPO 1.0.2] metadata-report=%@", saved ? @"saved" : @"write-failed");
            } @catch (NSException *exception) {
                NSLog(@"[PPO 1.0.2] metadata-exception=%@", exception.name);
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                ppoStatus.text = saved ? @"Raport scenă salvat (Filza)" : @"Raport API: eroare";
            });
        }
    });
}
- (PPOOwnedSafariTrial *)activeDrawer {
    id session = self.hostSessions.session;
    if (![session isKindOfClass:PPOOwnedSafariTrial.class] || [session isFinished]) return nil;
    return session;
}
- (void)touchHandle {
    ppoLastInteraction = NSProcessInfo.processInfo.systemUptime;
    BOOL explicitNub = ppoNubState.manualNubbed();
    ppoNubState.reveal(); ppoHandleNubbed = NO;
    PPOApplyOverlayLayout();
    if (explicitNub) PPORecordInterfaceEvent(@"manual-nub-revealed");
}
- (void)closeChooser { [self cancelOpening]; [self hideChooser]; }
- (void)hideChooser {
    [self cancelQuickChoosing]; self.handlingPan = NO;
    [self.picker closeList]; self.renderGeneration++;
    self.listView.hidden = YES;
    ppoExpanded = NO; ppoChooserProgress = 0; ppoPanel.hidden = YES;
    PPOApplyOverlayLayout();
}
- (void)showChooser:(NSInteger)mode {
    if (!PPOOverlayAllowed()) return;
    [self closeChooser];
    [self touchHandle];
    self.pickerMode = MAX(0, MIN(2, mode));
    ppoExpanded = YES; ppoChooserProgress = 1;
    [self.picker requestListFavoritesOnly:self.pickerMode == 2]; self.page = 0;
    PPOApplyOverlayLayout();
    [self loadPicker];
}
- (void)tapped:(id)sender {
    (void)sender;
    if (!PPOOverlayAllowed()) return;
    [self touchHandle];
    if (ppoExpanded) { [self closeChooser]; return; }
    PPOOwnedSafariTrial *active = [self activeDrawer];
    if (active) {
        [active finishDrawerOpen:active.drawerProgress < 0.5];
        [UIView animateWithDuration:0.22 animations:^{ PPOApplyOverlayLayout(); }]; return;
    }
    if (self.selectedIdentifier && self.apps.count) { [self openFloatingApp:nil]; return; }
    [self showChooser:0];
}
- (void)panned:(UIPanGestureRecognizer *)recognizer {
    BOOL terminal = recognizer.state == UIGestureRecognizerStateEnded ||
        recognizer.state == UIGestureRecognizerStateCancelled || recognizer.state == UIGestureRecognizerStateFailed;
    BOOL cancelled = recognizer.state != UIGestureRecognizerStateEnded;
    if (recognizer.state == UIGestureRecognizerStateBegan) self.handlingPan = YES;
    if (terminal) self.handlingPan = NO;
    if (!ppoWindow || !PPOOverlayAllowed()) {
        ppoNubState.cancelGesture(); [self cancelOpening]; self.handlingPan = NO; return;
    }
    // Ignore late/duplicate events after a completed or externally cancelled pan.
    // An invalid sample from a live gesture is still handled once below.
    if (recognizer.state != UIGestureRecognizerStateBegan && ppoNubState.mode() == PPOHandlePanMode::Inactive) return;
    ppoLastInteraction = NSProcessInfo.processInfo.systemUptime;
    CGPoint delta = [recognizer translationInView:ppoWindow];
    CGPoint velocity = [recognizer velocityInView:ppoWindow];
    PPOOwnedSafariTrial *active = ppoExpanded ? nil : [self activeDrawer];
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [self touchHandle];
        self.panDirectionCommitted = NO; self.verticalPan = NO;
        self.panTargetsHost = active != nil;
        self.panStartProgress = active ? active.drawerProgress : ppoChooserProgress;
        // An intentional user drag starts at the actual public handle, including
        // any temporary keyboard shift; notification-driven layout never writes preferences.
        self.panStartCenterY = ppoWindow.windowScene.coordinateSpace.bounds.origin.y + CGRectGetMidY(ppoHandle.frame);
        self.panStartRatio = [ppoPreferences[@"handleYRatio"] doubleValue];
        [self cancelOpening]; _panIntent = 0;
        ppoNubState.begin(PPOChosenEdge(),true,!ppoExpanded && (!active || active.drawerProgress == 0));
    }
    PPOHandlePanMode mode = ppoNubState.update(delta.x,delta.y,velocity.x,velocity.y);
    if (mode == PPOHandlePanMode::Inactive) {
        [self closeChooser]; self.handlingPan = NO;
        if (self.panTargetsHost && active) [active setDrawerProgress:0];
        PPOApplyOverlayLayout(); PPORecordInterfaceEvent(@"pan-invalidated"); return;
    }
    if (mode == PPOHandlePanMode::Pending) {
        if (terminal) { ppoNubState.finish(delta.x,delta.y,velocity.x,velocity.y,cancelled); [self cancelOpening]; }
        return;
    }
    if (mode == PPOHandlePanMode::Outward) {
        // A direction-locked outward gesture never enters the inspector/owner path.
        [self cancelOpening];
        if (terminal) {
            BOOL nubbed = ppoNubState.finish(delta.x,delta.y,velocity.x,velocity.y,cancelled);
            ppoHandleNubbed = ppoNubState.manualNubbed();
            [UIView animateWithDuration:0.18 animations:^{ PPOApplyOverlayLayout(); }];
            if (nubbed) {
                ppoManualNubCount = MIN(ppoManualNubCount+1,(NSUInteger)1000000);
                PPORecordInterfaceEvent(@"manual-nub-committed");
            }
        }
        return;
    }
    if (mode == PPOHandlePanMode::Vertical) {
        self.verticalPan = YES;
        if ((recognizer.state == UIGestureRecognizerStateChanged || recognizer.state == UIGestureRecognizerStateEnded) &&
            fabs(delta.y) >= PPOHandleNubState::DirectionDistance) {
            double ratio = 0;
            CGRect screen = ppoWindow.windowScene.coordinateSpace.bounds;
            if (PPOEdgeDrawerYRatio({screen.origin.x,screen.origin.y,screen.size.width,screen.size.height},
                {ppoEdgeLayout.usable.y-screen.origin.y,ppoEdgeLayout.usable.x-screen.origin.x,
                CGRectGetMaxY(screen)-(ppoEdgeLayout.usable.y+ppoEdgeLayout.usable.height),
                CGRectGetMaxX(screen)-(ppoEdgeLayout.usable.x+ppoEdgeLayout.usable.width)},
                [ppoPreferences[@"handleSize"] doubleValue],self.panStartCenterY+delta.y,&ratio)) {
                NSMutableDictionary *updated = [ppoPreferences mutableCopy]; updated[@"handleYRatio"] = @(ratio);
                ppoPreferences = [updated copy]; PPOApplyOverlayLayout();
                if (recognizer.state == UIGestureRecognizerStateEnded && [ppoPreferences[@"rememberPosition"] boolValue])
                    dispatch_async(PPOPreferenceQueue(), ^{ PPOUserPreferencesWriteChanges(@{@"handleYRatio": @(ratio)}, NULL); });
            }
        }
        if (terminal) {
            ppoNubState.finish(delta.x,delta.y,velocity.x,velocity.y,cancelled);
            if (cancelled) {
                NSMutableDictionary *updated = [ppoPreferences mutableCopy]; updated[@"handleYRatio"] = @(self.panStartRatio);
                ppoPreferences = [updated copy]; PPOApplyOverlayLayout();
            }
            PPORecordInterfaceEvent(@"handle-positioned");
        }
        return;
    }
    if (!self.panDirectionCommitted && terminal && cancelled) {
        ppoNubState.finish(delta.x,delta.y,velocity.x,velocity.y,true);
        [self closeChooser]; return;
    }
    if (!self.panDirectionCommitted) {
        self.panDirectionCommitted = YES;
        // Only an inward/ordinary drawer decision may begin metadata inspection.
        if (!active && !ppoExpanded) {
            if (self.selectedIdentifier && self.apps.count) {
                _panIntent = _intent.begin(true); [self inspectSelectedForIntent:_panIntent];
                self.panTargetsHost = YES; self.panStartProgress = 0;
            } else { [self showChooser:0]; ppoChooserProgress = 0; self.panStartProgress = 0; }
        }
    }
    active = [self activeDrawer];
    double travel = self.panTargetsHost && active ? active.drawerTravel : ppoEdgeLayout.travel;
    double progress = self.panStartProgress;
    if (PPOEdgeDrawerProgress(PPOChosenEdge(),self.panStartProgress,delta.x,travel,&progress)) {
        if (self.panTargetsHost) { if (active) { [active setDrawerProgress:progress]; PPOApplyOverlayLayout(); } }
        else { ppoChooserProgress = progress; PPOApplyOverlayLayout(); }
    }
    if (terminal) {
        ppoNubState.finish(delta.x,delta.y,velocity.x,velocity.y,cancelled);
        bool open = false;
        if (!cancelled) PPOEdgeDrawerFinish(PPOChosenEdge(),progress,velocity.x,&open);
        if (self.panTargetsHost && active) [active finishDrawerOpen:open];
        else if (self.panTargetsHost) {
            if (open && _intent.commit(_panIntent)) {
                NSDictionary *prepared = self.pendingApplication, *capability = self.pendingCapability;
                self.pendingApplication = nil; self.pendingCapability = nil;
                if (prepared) [self openPreparedApplication:prepared capability:capability intent:_panIntent];
            } else [self cancelOpening];
        } else if (!open) [self closeChooser];
        else { ppoChooserProgress = 1; PPOApplyOverlayLayout(); }
        [self touchHandle];
    }
}
- (void)showApps:(UIButton *)sender { (void)sender; [self showChooser:0]; }
- (void)cancelQuickChoosing {
    [ppoClassicView dismiss];
    if (self.classicRequested) {
        self.classicRequested = NO; ppoExpanded = NO; ppoChooserProgress = 0;
        [self.picker closeList]; self.renderGeneration++;
    }
    self.hoveredButton.transform = CGAffineTransformIdentity;
    self.hoveredButton = nil; self.quickDragSource = nil;
    self.quickChoosing = NO; self.quickDragging = NO; self.feedback = nil;
    [self.quickDropTarget removeFromSuperview]; self.quickDropTarget = nil;
    [self.quickDropInstruction removeFromSuperview]; self.quickDropInstruction = nil;
    [self.quickDragBadge removeFromSuperview]; self.quickDragBadge = nil;
}
- (void)beginQuickDragAtPoint:(CGPoint)point {
    NSDictionary *row = [self rowForButton:self.quickDragSource];
    if (!row || ![row[@"available"] boolValue] || !ppoController || ppoWindow.hidden) return;
    CGRect bounds = ppoController.view.bounds;
    if (!std::isfinite(bounds.size.width) || !std::isfinite(bounds.size.height) ||
        !std::isfinite(point.x) || !std::isfinite(point.y) || bounds.size.width < 100 || bounds.size.height < 100) return;
    self.quickDragging = YES;
    self.hoveredButton.transform = CGAffineTransformIdentity; self.hoveredButton = nil;
    UIView *target = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMidX(bounds)-50, CGRectGetMidY(bounds)-50, 100, 100)];
    target.userInteractionEnabled = NO; target.layer.cornerRadius = 12;
    target.backgroundColor = [UIColor.systemBackgroundColor colorWithAlphaComponent:0.88];
    CAShapeLayer *outline = [CAShapeLayer layer]; outline.frame = target.bounds;
    outline.path = [UIBezierPath bezierPathWithRoundedRect:target.bounds cornerRadius:12].CGPath;
    outline.fillColor = UIColor.clearColor.CGColor; outline.strokeColor = UIColor.labelColor.CGColor;
    outline.lineWidth = 2; outline.lineDashPattern = @[@5, @5]; [target.layer addSublayer:outline];
    [ppoController.view addSubview:target]; self.quickDropTarget = target;
    UILabel *instruction = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMidX(bounds)-100, CGRectGetMaxY(target.frame)+8, 200, 48)];
    instruction.userInteractionEnabled = NO; instruction.numberOfLines = 2; instruction.textAlignment = NSTextAlignmentCenter;
    instruction.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold]; instruction.textColor = UIColor.labelColor;
    instruction.text = @"Glisează în chenar\nDeschide pe tot ecranul";
    instruction.hidden = [ppoPreferences[@"hideLabels"] boolValue];
    [ppoController.view addSubview:instruction]; self.quickDropInstruction = instruction;
    UILabel *badge = [[UILabel alloc] initWithFrame:CGRectMake(0,0,56,56)];
    badge.userInteractionEnabled = NO; badge.textAlignment = NSTextAlignmentCenter;
    badge.font = [UIFont systemFontOfSize:26 weight:UIFontWeightSemibold]; badge.textColor = UIColor.labelColor;
    badge.backgroundColor = UIColor.secondarySystemBackgroundColor; badge.layer.cornerRadius = 14; badge.clipsToBounds = YES;
    NSString *name = row[@"name"];
    badge.text = [name isKindOfClass:NSString.class] && name.length
        ? [name substringWithRange:[name rangeOfComposedCharacterSequenceAtIndex:0]] : @"◉";
    [ppoController.view addSubview:badge]; self.quickDragBadge = badge;
    [self.feedback selectionChanged]; [self updateQuickDragAtPoint:point];
}
- (void)updateQuickDragAtPoint:(CGPoint)point {
    if (!self.quickDragging || !self.quickDragBadge || !self.quickDropTarget) return;
    CGRect bounds = ppoController.view.bounds;
    self.quickDragBadge.center = CGPointMake(MAX(28,MIN(CGRectGetMaxX(bounds)-28,point.x)),
        MAX(28,MIN(CGRectGetMaxY(bounds)-28,point.y)));
    self.quickDropTarget.alpha = CGRectContainsPoint(self.quickDropTarget.frame,point) ? 1 : 0.65;
}
- (void)quickFavorites:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) [self showClassicChooser];
    if (!self.classicRequested) return;
    CGPoint point = [recognizer locationInView:ppoController.view];
    if (recognizer.state == UIGestureRecognizerStateBegan || recognizer.state == UIGestureRecognizerStateChanged)
        [ppoClassicView updateGestureAtPoint:point];
    if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled ||
        recognizer.state == UIGestureRecognizerStateFailed) {
        NSUInteger generation = self.renderGeneration;
        [ppoClassicView endGestureAtPoint:point cancelled:recognizer.state != UIGestureRecognizerStateEnded];
        self.quickChoosing = NO;
        if (self.classicRequested && generation == self.renderGeneration) [self closeChooser];
    }
}
- (void)loadPicker {
    if (!ppoExpanded || !self.picker.listRequested) return;
    PPOPickerTicket *ticket = [self.picker beginLoad];
    self.pickerMessage = nil;
    [self renderApps];
    if (self.picker.listRequested) { self.listView.hidden = self.classicRequested; ppoPanel.hidden = self.classicRequested; }
    if (!ticket) return; // Coalesce an in-flight load; its result uses current mode/visibility.
    dispatch_async(PPOFileQueue(), ^{
        @autoreleasepool {
            NSArray *apps = nil, *favorites = nil;
            NSDictionary *selected = nil;
            NSString *message = nil;
            @try {
                NSDictionary *refresh = PPOBridgeSend(@"refresh", nil, NULL);
                if (![refresh[@"status"] isEqual:@"refreshed"]) {
                    message = refresh ? PPOBridgeFailureMessage(refresh) : @"Serviciul PPO nu răspunde";
                } else {
                    apps = PPOAppsFromData(PPOReadBoundedFile(PPOAppsPath, 2 * 1024 * 1024, NULL), NULL);
                    if (apps) {
                        selected = PPOSelectionFromData(PPOReadBoundedFile(PPOSelectionPath, 16384, NULL));
                        NSError *favoriteError = nil;
                        favorites = PPOFavoritesLoad(PPOFavoritesDirectory, &favoriteError);
                        PPOWritePickerObservation(@"load", favorites.count, favorites != nil, favoriteError);
                    } else message = @"Lista nu este disponibilă";
                }
            } @catch (NSException *exception) {
                (void)exception; apps = nil; message = @"Lista nu este disponibilă";
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (![self.picker finishLoad:ticket apps:apps selection:selected favorites:favorites]) return;
                self.pickerMessage = message;
                [self updateLaunchButton];
                if (!ppoExpanded || !self.picker.listRequested) return;
                [self renderApps];
                if (self.picker.listRequested) { self.listView.hidden = self.classicRequested; ppoPanel.hidden = self.classicRequested; }
            });
        }
    });
}
- (NSArray<NSDictionary *> *)projectedRows {
    NSArray *rows = self.picker.rows;
    if (self.pickerMode == 1) {
        NSMutableArray *recent = [NSMutableArray array];
        NSMutableArray *identifiers = [NSMutableArray arrayWithArray:ppoPreferences[@"recentIdentifiers"] ?: @[]];
        if (self.selectedIdentifier && ![identifiers containsObject:self.selectedIdentifier]) [identifiers insertObject:self.selectedIdentifier atIndex:0];
        for (NSString *identifier in identifiers) {
            for (NSDictionary *row in rows) if ([row[@"bundleIdentifier"] isEqual:identifier]) { [recent addObject:row]; break; }
            if (recent.count >= [ppoPreferences[@"recentAppsCount"] unsignedIntegerValue]) break;
        }
        rows = recent;
    }
    return rows;
}
- (void)restoreCachedPicker {
    if (self.cacheRestoreStarted) return;
    self.cacheRestoreStarted = YES;
    PPOPickerTicket *ticket = [self.picker beginLoad];
    if (!ticket) return;
    dispatch_async(PPOFileQueue(), ^{
        @autoreleasepool {
            NSArray *apps = PPOAppsFromData(PPOReadBoundedFile(PPOAppsPath,2*1024*1024,NULL),NULL);
            NSDictionary *selection = PPOSelectionFromData(PPOReadBoundedFile(PPOSelectionPath,16384,NULL));
            NSArray *favorites = PPOFavoritesLoad(PPOFavoritesDirectory,NULL);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (![self.picker finishLoad:ticket apps:apps selection:selection favorites:favorites]) return;
                PPOApplyOverlayLayout();
                if (ppoExpanded && self.picker.listRequested) [self loadPicker];
            });
        }
    });
}
- (void)showClassicChooser {
    if (!PPOOverlayAllowed() || ppoWindow.hidden) return;
    [self closeChooser];
    self.classicRequested = YES; self.quickChoosing = YES;
    self.pickerMode = [ppoPreferences[@"quickSwitchMode"] isEqual:@"favorites"] ? 2 : 1;
    [self.picker requestListFavoritesOnly:self.pickerMode == 2];
    ppoExpanded = YES; ppoChooserProgress = 0;
    [self touchHandle]; [self loadPicker];
}
- (void)classicChoice:(NSString *)identifier generation:(uint64_t)generation normal:(BOOL)normal {
    if (!self.classicRequested || !ppoExpanded || !self.picker.listRequested || !ppoClassicView.visible ||
        generation != self.renderGeneration || !PPOOverlayAllowed() || ppoWindow.hidden) return;
    for (NSDictionary *row in self.listRows) {
        if ([row[@"bundleIdentifier"] isEqual:identifier] && [row[@"available"] boolValue]) {
            if (normal) [self launchNormalRow:row]; else [self selectApplicationRow:row];
            return;
        }
    }
}
- (void)closeClassicWindow:(id)sender {
    (void)sender; [self cancelOpening]; [[self activeDrawer] close]; [self touchHandle];
}
- (void)outsideTapped:(id)sender {
    (void)sender; [self closeChooser]; [[self activeDrawer] finishDrawerOpen:NO];
    [UIView animateWithDuration:0.22 animations:^{ [self touchHandle]; }];
}
- (void)showAllApplications:(UITapGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateRecognized) [self showChooser:0];
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)recognizer shouldReceiveTouch:(UITouch *)touch {
    (void)recognizer;
    return !ppoClassicClose || ![touch.view isDescendantOfView:ppoClassicClose];
}
- (void)renderApps {
    if (!self.classicRequested && self.quickChoosing && (self.hoveredButton || self.quickDragSource)) [self cancelQuickChoosing];
    @try {
    if (self.classicRequested) {
        NSArray *projection = [self projectedRows];
        if (self.quickChoosing && ppoClassicView.visible) {
            // Never substitute a refreshed row under a held finger. A changed
            // projection cancels; an identical refresh preserves its generation.
            if (![projection isEqual:self.listRows]) [self closeChooser];
            return;
        }
        self.listRows = projection; self.renderGeneration++;
        ppoPanel.hidden = YES; self.listView.hidden = YES;
        CGRect screen = ppoWindow.windowScene.coordinateSpace.bounds;
        UIEdgeInsets insets = ppoCompactInsets;
        ppoClassicView.hapticFeedbackEnabled = [ppoPreferences[@"hapticFeedback"] boolValue];
        BOOL left = CGRectGetMidX(ppoHandle.frame) < screen.size.width/2;
        if (![ppoClassicView presentRows:self.listRows generation:self.renderGeneration screen:screen insets:insets
            leftEdge:left handleCenterY:screen.origin.y+CGRectGetMidY(ppoHandle.frame)
            scale:[ppoPreferences[@"quickSwitchScale"] doubleValue] dark:!ppoLightTheme
            hideInstructions:[ppoPreferences[@"hideLabels"] boolValue]]) {
            if (!self.picker.loading) ppoStatus.text = @"Alege favoritele în Configurări sau atinge de două ori mânerul pentru toate aplicațiile";
        }
        PPOApplyOverlayLayout(); return;
    }

    if (!self.listView) {
        UIView *panel = [[UIView alloc] initWithFrame:ppoPanel.bounds];
        panel.layer.cornerRadius = 12; panel.clipsToBounds = YES;
        UIButton *back = [UIButton buttonWithType:UIButtonTypeSystem];
        back.frame = CGRectMake(8, 4, 104, 44);
        [back setTitle:@"✕ Închide" forState:UIControlStateNormal];
        [back addTarget:self action:@selector(closeApps:) forControlEvents:UIControlEventTouchUpInside];
        [panel addSubview:back];
        UILabel *pageLabel = [[UILabel alloc] initWithFrame:CGRectMake(104, 4, 106, 32)];
        pageLabel.font = [UIFont systemFontOfSize:11]; pageLabel.textAlignment = NSTextAlignmentRight;
        [panel addSubview:pageLabel];
        UISegmentedControl *modes = [[UISegmentedControl alloc] initWithItems:@[@"Toate", @"Recente", @"★"]];
        modes.frame = CGRectMake(8, 40, PPOOpenWidth - 16, 32);
        [modes addTarget:self action:@selector(pickerModeChanged:) forControlEvents:UIControlEventValueChanged];
        [panel addSubview:modes]; self.pickerModes = modes;
        UILabel *status = [[UILabel alloc] initWithFrame:CGRectMake(8, 76, PPOOpenWidth - 16, 22)];
        status.font = [UIFont systemFontOfSize:10]; status.numberOfLines = 2;
        [panel addSubview:status]; self.pickerStatus = status;
        UIScrollView *scroll = [[UIScrollView alloc] initWithFrame:CGRectMake(6, 102, PPOOpenWidth - 12, 190)];
        [panel addSubview:scroll];
        UIButton *previous = [UIButton buttonWithType:UIButtonTypeSystem];
        previous.frame = CGRectMake(8, 300, 94, 36); previous.tag = -1;
        [previous setTitle:@"◀ Anterior" forState:UIControlStateNormal];
        [previous addTarget:self action:@selector(changePage:) forControlEvents:UIControlEventTouchUpInside];
        [panel addSubview:previous];
        UIButton *next = [UIButton buttonWithType:UIButtonTypeSystem];
        next.frame = CGRectMake(112, 300, 98, 36); next.tag = 1;
        [next setTitle:@"Următor ▶" forState:UIControlStateNormal];
        [next addTarget:self action:@selector(changePage:) forControlEvents:UIControlEventTouchUpInside];
        [panel addSubview:next];
        [ppoPanel addSubview:panel];
        self.listView = panel; self.listScroll = scroll; self.pageLabel = pageLabel;
        self.previousButton = previous; self.nextButton = next;
    }
    NSArray *rows = [self projectedRows];
    self.listRows = rows; self.renderGeneration++;
    [self layoutPicker];
    UIColor *foreground = ppoLightTheme ? UIColor.blackColor : UIColor.whiteColor;
    self.listView.backgroundColor = ppoPanel.backgroundColor;
    self.pageLabel.textColor = foreground; self.pickerStatus.textColor = foreground;
    self.pickerModes.selectedSegmentIndex = self.pickerMode;
    self.pickerModes.overrideUserInterfaceStyle = ppoLightTheme ? UIUserInterfaceStyleLight : UIUserInterfaceStyleDark;
    self.pickerStatus.text = self.picker.loading ? @"Se încarcă aplicațiile…"
        : (self.picker.favoritesSaving ? @"Se salvează preferatele…"
        : (self.pickerMessage ?: (self.picker.favoritesReadable ? @"Atinge ☆ pentru preferate (max. 16)" : @"Preferatele nu sunt disponibile")));
    for (UIView *view in self.listView.subviews)
        if ([view isKindOfClass:UIButton.class]) [(UIButton *)view setTitleColor:foreground forState:UIControlStateNormal];
    for (UIView *view in [self.listScroll.subviews copy])
        if ([view isKindOfClass:UIButton.class]) [view removeFromSuperview];
    NSUInteger pages = (self.listRows.count + 24) / 25;
    if (!pages || self.page >= pages) self.page = 0;
    self.previousButton.enabled = self.page > 0; self.nextButton.enabled = self.page + 1 < pages;
    self.pageLabel.text = pages ? [NSString stringWithFormat:@"%lu/%lu · %lu",
        (unsigned long)self.page + 1, (unsigned long)pages, (unsigned long)self.listRows.count] : @"0 aplicații";
    CGFloat y = 0;
    for (NSUInteger i = self.page * 25; i < MIN(self.page * 25 + 25, self.listRows.count); i++) {
        NSDictionary *app = self.listRows[i]; NSString *identifier = app[@"bundleIdentifier"];
        PPOPickerRowButton *button = [PPOPickerRowButton new];
        button.frame = CGRectMake(2, y, PPOOpenWidth - 70, 46); button.restingFrame = button.frame;
        button.boundIdentifier = identifier; button.boundGeneration = self.renderGeneration;
        button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        button.titleLabel.numberOfLines = 2; button.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
        button.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        NSString *mark = [identifier isEqual:self.selectedIdentifier] ? @"✓ " : @"";
        NSString *label = app[@"name"];
        [button setTitle:[NSString stringWithFormat:@"%@%@%@", mark, label,
            [app[@"available"] boolValue] ? @"" : @" · indisponibilă"] forState:UIControlStateNormal];
        button.accessibilityLabel = app[@"name"];
        [button setTitleColor:foreground forState:UIControlStateNormal];
        button.enabled = [app[@"available"] boolValue] && PPOSceneApplicationIdentifierAllowed(identifier);
        [button addTarget:self action:@selector(selectApp:) forControlEvents:UIControlEventTouchUpInside];
        __weak PPOHandleTarget *weakTarget = self;
        __weak PPOPickerRowButton *weakButton = button;
        UIAction *normal = [UIAction actionWithTitle:@"Deschide pe tot ecranul" image:nil identifier:nil
            handler:^(__kindof UIAction *action) { (void)action; [weakTarget launchNormalFromRow:weakButton]; }];
        button.menu = [UIMenu menuWithChildren:@[normal]];
        [self.listScroll addSubview:button];
        PPOPickerRowButton *star = [PPOPickerRowButton new];
        star.frame = CGRectMake(PPOOpenWidth - 64, y, 44, 46);
        star.boundIdentifier = identifier; star.boundGeneration = self.renderGeneration;
        BOOL favorite = [app[@"favorite"] boolValue];
        [star setTitle:favorite ? @"★" : @"☆" forState:UIControlStateNormal];
        [star setTitleColor:foreground forState:UIControlStateNormal];
        star.accessibilityLabel = [NSString stringWithFormat:favorite ? @"Elimină %@ din preferate" : @"Adaugă %@ la preferate", app[@"name"]];
        star.enabled = self.picker.favoritesReadable && !self.picker.favoritesSaving && !self.picker.loading &&
            PPOSceneApplicationIdentifierAllowed(identifier);
        [star addTarget:self action:@selector(toggleFavorite:) forControlEvents:UIControlEventTouchUpInside];
        [self.listScroll addSubview:star]; y += 48;
    }
    self.listScroll.contentSize = CGSizeMake(PPOOpenWidth - 16, y); self.listScroll.contentOffset = CGPointZero;
    } @catch (NSException *exception) {
        (void)exception; [self.picker closeList]; self.renderGeneration++;
        self.listView.hidden = YES; ppoPanel.hidden = !ppoExpanded;
        ppoStatus.text = @"Lista nu poate fi afișată";
    }
}
- (NSDictionary *)rowForButton:(PPOPickerRowButton *)sender {
    if (![sender isKindOfClass:PPOPickerRowButton.class] || sender.boundGeneration != self.renderGeneration ||
        !ppoExpanded || !self.picker.listRequested || self.listView.hidden) return nil;
    for (NSDictionary *row in self.listRows)
        if ([row[@"bundleIdentifier"] isEqual:sender.boundIdentifier]) return row;
    return nil;
}
- (void)pickerModeChanged:(UISegmentedControl *)sender {
    if (!ppoExpanded || !self.picker.listRequested || self.listView.hidden) return;
    self.pickerMode = sender.selectedSegmentIndex;
    [self.picker requestListFavoritesOnly:self.pickerMode == 2]; self.page = 0;
    [self renderApps];
}
- (void)closeApps:(id)sender { (void)sender; [self closeChooser]; }
- (void)changePage:(UIButton *)sender {
    if (!self.picker.listRequested || self.listView.hidden) return;
    NSInteger next = (NSInteger)self.page + sender.tag;
    NSUInteger pages = (self.listRows.count + 24) / 25;
    if (next < 0 || (NSUInteger)next >= pages) return;
    self.page = (NSUInteger)next; [self renderApps];
}
- (void)toggleFavorite:(PPOPickerRowButton *)sender {
    NSDictionary *row = [self rowForButton:sender]; if (!row) return;
    PPOPickerTicket *ticket = [self.picker beginFavoriteToggle:row[@"bundleIdentifier"]];
    if (!ticket) { self.pickerMessage = @"Limita este de 16 preferate sau lista este ocupată"; [self renderApps]; return; }
    self.pickerMessage = nil; [self renderApps];
    dispatch_async(PPOFileQueue(), ^{
        @autoreleasepool {
            BOOL saved = NO;
            @try {
                NSError *error = nil;
                saved = PPOFavoritesCommit(PPOFavoritesDirectory, ticket.expectedFavorites, ticket.replacementFavorites, &error);
                PPOWritePickerObservation(@"save", saved ? ticket.replacementFavorites.count : ticket.expectedFavorites.count, saved, error);
            }
            @catch (NSException *exception) { (void)exception; }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (![self.picker finishFavorite:ticket saved:saved]) return;
                self.pickerMessage = saved ? nil : @"Preferata nu a fost salvată; redeschide lista";
                if (ppoExpanded && self.picker.listRequested) [self renderApps];
            });
        }
    });
}
- (void)selectApp:(PPOPickerRowButton *)sender {
    NSDictionary *row = [self rowForButton:sender]; if (!row || ![row[@"available"] boolValue]) return;
    [self selectApplicationRow:row];
}
- (void)selectApplicationRow:(NSDictionary *)row {
    if (!PPOOverlayAllowed() || ![row[@"available"] boolValue]) return;
    PPOPickerTicket *ticket = [self.picker beginSelection:row[@"bundleIdentifier"]]; if (!ticket) return;
    [self cancelOpening]; uint64_t intent = _intent.begin(false);
    [self updateLaunchButton]; [self hideChooser]; ppoStatus.text = @"Se salvează selecția…";
    dispatch_async(PPOFileQueue(), ^{
        @autoreleasepool {
            BOOL saved = NO;
            @try {
                NSData *data = PPOSelectionData(ticket.selection, NULL);
                NSString *directory = PPOSelectionPath.stringByDeletingLastPathComponent;
                if (data && [NSFileManager.defaultManager createDirectoryAtPath:directory
                    withIntermediateDirectories:YES attributes:nil error:NULL])
                    saved = [data writeToFile:PPOSelectionPath options:NSDataWritingAtomic error:NULL];
            } @catch (NSException *exception) { (void)exception; }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (![self.picker finishSelection:ticket saved:saved]) return;
                ppoStatus.text = saved ? [NSString stringWithFormat:@"Selectat: %@", ticket.selection[@"name"]] : @"Selecție nesalvată";
                [self updateLaunchButton];
                if (saved && _intent.ready(intent) && PPOOverlayAllowed()) {
                    NSMutableArray *recent = [NSMutableArray arrayWithArray:ppoPreferences[@"recentIdentifiers"] ?: @[]];
                    [recent removeObject:ticket.selection[@"bundleIdentifier"]];
                    [recent insertObject:ticket.selection[@"bundleIdentifier"] atIndex:0];
                    if (recent.count > 16) [recent removeObjectsInRange:NSMakeRange(16, recent.count - 16)];
                    NSArray *snapshot = [recent copy];
                    NSMutableDictionary *updated = [ppoPreferences mutableCopy]; updated[@"recentIdentifiers"] = snapshot;
                    ppoPreferences = [updated copy];
                    dispatch_async(PPOPreferenceQueue(), ^{ PPOUserPreferencesWriteChanges(@{@"recentIdentifiers":snapshot}, NULL); });
                    PPOOwnedSafariTrial *active = [self activeDrawer];
                    if (active) [active close];
                    if (!self.hostSessions.session || self.hostSessions.session.replacementAllowed) [self inspectSelectedForIntent:intent];
                    else { [self showChooser:self.pickerMode]; ppoStatus.text = @"Așteaptă închiderea ferestrei; apoi atinge aplicația"; }
                }
            });
        }
    });
}
- (void)layoutPicker {
    if (!self.listView) return;
    CGFloat width = ppoPanel.bounds.size.width, height = ppoPanel.bounds.size.height;
    self.listView.frame = ppoPanel.bounds;
    self.pickerModes.frame = CGRectMake(8, 48, width - 16, 36);
    self.pageLabel.frame = CGRectMake(width - 130, 4, 120, 40);
    self.pickerStatus.frame = CGRectMake(10, 88, width - 20, 36);
    self.listScroll.frame = CGRectMake(8, 128, width - 16, MAX(44, height - 190));
    self.previousButton.frame = CGRectMake(8, height - 54, (width - 24)/2, 46);
    self.nextButton.frame = CGRectMake(width/2 + 4, height - 54, (width - 24)/2, 46);
}
@end

static PPOHandleTarget *ppoTarget;

static void PPOApplyOverlayLayout(void) {
    if (!ppoWindow || !ppoPreferences) return;
    CGRect screen = ppoWindow.windowScene.coordinateSpace.bounds;
    CGRect previousScreen = ppoWindow.frame, previousTouch = ppoHandle.frame;
    UIEdgeInsets previousBand = ppoCompactInsets;
    UIEdgeInsets insets = ppoController.view.safeAreaInsets;
    CGRect status = ppoWindow.windowScene.statusBarManager.statusBarFrame;
    insets.top = MAX(insets.top, status.size.height);
    // Full-scene public safe area has no floating-window feedback.
    if (!PPOEdgeDrawerMakeLayout({screen.origin.x,screen.origin.y,screen.size.width,screen.size.height},
        {insets.top,insets.left,insets.bottom,insets.right}, PPOChosenEdge(),
        [ppoPreferences[@"handleYRatio"] doubleValue], [ppoPreferences[@"handleSize"] doubleValue],
        ppoChooserProgress, &ppoEdgeLayout)) { ppoWindow.hidden = YES; return; }
    if (!CGRectEqualToRect(ppoWindow.frame,screen)) ppoWindow.frame = screen;
    CGRect rootFrame = CGRectMake(0,0,screen.size.width,screen.size.height);
    if (!CGRectEqualToRect(ppoController.view.frame,rootFrame)) ppoController.view.frame = rootFrame;
    PPOOpenWidth = ppoEdgeLayout.openDrawer.width;
    CGRect drawer = PPOCGRect(ppoEdgeLayout.drawer); drawer.origin.x -= screen.origin.x; drawer.origin.y -= screen.origin.y;
    ppoPanel.frame = drawer; ppoPanel.hidden = !ppoExpanded || ppoTarget.classicRequested;
    CGRect touch = PPOCGRect(ppoEdgeLayout.touchHandle); touch.origin.x -= screen.origin.x; touch.origin.y -= screen.origin.y;
    BOOL left = PPOChosenEdge() == PPOEdgeDrawerSide::Left;
    // Original-style 80-point capsule protrudes beyond a 50-point edge strip.
    // The actual touch width remains at least the geometry policy's44 points.
    PPOOwnedSafariTrial *active = [ppoTarget activeDrawer];
    double progress = active.classicLayout ? std::clamp(active.drawerProgress,0.0,1.0) : 0;
    touch.size.width = 50 + 30*progress;
    touch.origin.x = left ? (screen.size.width-80)*progress : (screen.size.width-50)*(1-progress);
    CGRect desired = touch; desired.origin.x += screen.origin.x; desired.origin.y += screen.origin.y;
    CGRect keyboard = ppoKeyboardMonitor ? ppoKeyboardMonitor.keyboardFrameInScene : CGRectNull;
    PPOKeyboardAvoidanceResult avoiding{};
    ppoCompactInsets = insets; ppoKeyboardAdjusted = NO; ppoKeyboardShiftY = 0;
    if (PPOKeyboardAvoidanceLayout({screen.origin.x,screen.origin.y,screen.size.width,screen.size.height},
        {insets.top,insets.left,insets.bottom,insets.right},
        {desired.origin.x,desired.origin.y,desired.size.width,desired.size.height},
        CGRectIsNull(keyboard) ? PPOHostRect{} : PPOHostRect{keyboard.origin.x,keyboard.origin.y,keyboard.size.width,keyboard.size.height},
        [ppoPreferences[@"keyboardAvoiding"] boolValue],ppoKeyboardMonitor.visible,&avoiding)) {
        touch.origin.y = avoiding.touchHandle.y-screen.origin.y;
        ppoCompactInsets = UIEdgeInsetsMake(avoiding.pickerInsets.top,avoiding.pickerInsets.left,
            avoiding.pickerInsets.bottom,avoiding.pickerInsets.right);
        ppoKeyboardAdjusted = avoiding.adjusted; ppoKeyboardShiftY = touch.origin.y-(desired.origin.y-screen.origin.y);
    }
    BOOL compactGeometryChanged = !CGRectEqualToRect(previousScreen,screen) ||
        !CGRectEqualToRect(previousTouch,touch) || !UIEdgeInsetsEqualToEdgeInsets(previousBand,ppoCompactInsets);
    ppoHandle.frame = touch;
    if (compactGeometryChanged && ppoTarget.quickChoosing && ppoClassicView.visible) [ppoTarget closeChooser];
    // The compact projection shares this public scene geometry. Refresh it when
    // safe areas, orientation or the handle position change; stale row frames
    // must not keep selecting an app at an old screen coordinate.
    if (ppoTarget.classicRequested && ppoClassicView.visible &&
        ![ppoClassicView relayoutWithScreen:screen insets:ppoCompactInsets
            leftEdge:CGRectGetMidX(touch) < screen.size.width/2
            handleCenterY:screen.origin.y+CGRectGetMidY(touch)]) {
        [ppoTarget closeChooser];
    }
    CGFloat height = [ppoPreferences[@"handleSize"] doubleValue];
    CGRect pill = CGRectMake(left ? -30*(1-progress) : 0, (touch.size.height-height)/2, 80, height);
    if (ppoHandleNubbed) pill.origin.x += left ? -40 : 40;
    ppoHandlePill.frame = pill;
    ppoHandlePill.layer.cornerRadius = ppoHandleNubbed ? 6 : MIN(17,height/2);
    ppoHandleBlur.frame = ppoHandlePill.bounds;
    ppoHandleIcon.frame = CGRectMake(left ? 42 : 14, (height-24)/2,24,24);
    ppoHandlePill.hidden = ppoTarget.classicRequested && ppoClassicView.visible;
    ppoClassicClose.hidden = progress < 0.99 || ppoTarget.classicRequested;
    ppoClassicClose.frame = CGRectMake(left ? 0 : 36,(touch.size.height-44)/2,44,44);
    ppoOutsideDismiss.frame = ppoController.view.bounds;
    CGRect visible = active ? active.drawerVisibleFrameInScene : CGRectNull;
    if (!CGRectIsNull(visible)) { visible.origin.x -= screen.origin.x; visible.origin.y -= screen.origin.y; }
    ((PPOOutsideControl *)ppoOutsideDismiss).excludedPanel = visible;
    ppoOutsideDismiss.hidden = !active.classicLayout || progress <= 0 || CGRectIsNull(visible);
    ppoOutsideDismiss.alpha = 0.5*progress;
    UIBezierPath *mask = [UIBezierPath bezierPathWithRect:ppoOutsideDismiss.bounds];
    if (!CGRectIsNull(visible)) [mask appendPath:[UIBezierPath bezierPathWithRoundedRect:visible cornerRadius:12]];
    ppoOutsideMask.frame = ppoOutsideDismiss.bounds; ppoOutsideMask.fillRule = kCAFillRuleEvenOdd;
    ppoOutsideMask.path = mask.CGPath;
    NSDictionary *symbols = @{@"com.apple.mobilesafari":@"safari", @"com.apple.DocumentsApp":@"folder",
        @"com.apple.mobilecal":@"calendar", @"com.apple.reminders":@"checklist", @"com.apple.MobileAddressBook":@"person.crop.circle"};
    NSString *symbol = symbols[ppoTarget.selectedIdentifier ?: @""] ?: @"app.fill";
    if (!ppoHandleIcon.image || ![symbol isEqual:ppoRenderedSymbol]) {
        ppoHandleIcon.image = [UIImage systemImageNamed:symbol]; ppoRenderedSymbol = symbol;
    }
    ppoHandleIcon.tintColor = UIColor.labelColor;
    ppoHandlePill.alpha = [ppoPreferences[@"handleOpacity"] doubleValue];
    ppoHandle.titleLabel.alpha = ppoHandleNubbed ? 0 : 1;
    NSString *appearance = ppoPreferences[@"appearance"];
    ppoLightTheme = [appearance isEqual:@"light"] || ([appearance isEqual:@"system"] &&
        ppoController.traitCollection.userInterfaceStyle != UIUserInterfaceStyleDark);
    UIUserInterfaceStyle style = [appearance isEqual:@"system"] ? UIUserInterfaceStyleUnspecified :
        (ppoLightTheme ? UIUserInterfaceStyleLight : UIUserInterfaceStyleDark);
    ppoController.overrideUserInterfaceStyle = style;
    UIColor *background = ppoLightTheme ? [UIColor colorWithWhite:0.96 alpha:0.96] : [UIColor colorWithWhite:0.08 alpha:0.96];
    ppoPanel.backgroundColor = background; ppoHandlePill.backgroundColor = UIColor.clearColor;
    if (ppoRenderedTheme != (NSInteger)ppoLightTheme) {
        ppoHandleBlur.effect = [UIBlurEffect effectWithStyle:ppoLightTheme ? UIBlurEffectStyleSystemMaterialLight : UIBlurEffectStyleSystemMaterialDark];
        ppoRenderedTheme = (NSInteger)ppoLightTheme;
    }
    [ppoHandle setTitle:@"" forState:UIControlStateNormal];
    [ppoHandle setTitleColor:ppoLightTheme ? UIColor.blackColor : UIColor.whiteColor forState:UIControlStateNormal];
    [ppoTarget layoutPicker];
}
static NSDictionary *ppoInterfacePending;
static BOOL ppoInterfaceWriting;
static NSMutableArray<NSDictionary *> *ppoInterfaceHistory;
static void PPOFlushInterfaceReport(void) {
    if (!NSThread.isMainThread || ppoInterfaceWriting || !ppoInterfacePending) return;
    NSDictionary *report = ppoInterfacePending; ppoInterfacePending = nil; ppoInterfaceWriting = YES;
    static dispatch_queue_t queue; static dispatch_once_t once;
    dispatch_once(&once, ^{ queue = dispatch_queue_create("com.renatasy83.ppo.interface-report",DISPATCH_QUEUE_SERIAL); });
    dispatch_async(queue, ^{
        @autoreleasepool {
            NSString *directory = @"/var/mobile/Library/Logs/PullOverPro";
            NSData *data = [NSJSONSerialization dataWithJSONObject:report options:NSJSONWritingPrettyPrinted error:NULL];
            if (data && [NSFileManager.defaultManager createDirectoryAtPath:directory
                withIntermediateDirectories:YES attributes:nil error:NULL])
                [data writeToFile:[directory stringByAppendingPathComponent:@"interface-1.0.2.json"]
                    options:NSDataWritingAtomic error:NULL];
        }
        dispatch_async(dispatch_get_main_queue(), ^{ ppoInterfaceWriting = NO; PPOFlushInterfaceReport(); });
    });
}
static void PPORecordInterfaceEvent(NSString *event) {
    if (!NSThread.isMainThread || !ppoWindow || !ppoPreferences) return;
    NSDictionary *sample = @{@"event":event, @"uptime":@(NSProcessInfo.processInfo.systemUptime),
        @"keyboardAvoiding":ppoPreferences[@"keyboardAvoiding"] ?: @NO,
        @"keyboardFrameKnown":@(ppoKeyboardMonitor.frameKnown), @"keyboardVisible":@(ppoKeyboardMonitor.visible),
        @"keyboardStatus":ppoKeyboardMonitor.status ?: @"unavailable", @"keyboardNotificationCount":@(ppoKeyboardMonitor.notificationCount),
        @"keyboardAdjusted":@(ppoKeyboardAdjusted), @"keyboardShiftY":@(ppoKeyboardShiftY),
        @"handleFrame":NSStringFromCGRect(ppoHandle.frame), @"configuredHandleYRatio":ppoPreferences[@"handleYRatio"] ?: @0.5,
        @"manualNubCount":@(ppoManualNubCount), @"manualNubbed":@(ppoNubState.manualNubbed()),
        @"handleNubbed":@(ppoHandleNubbed), @"quickChooserVisible":@(ppoClassicView.visible),
        @"drawerProgress":@([ppoTarget activeDrawer].drawerProgress)};
    if (!ppoInterfaceHistory) ppoInterfaceHistory = [NSMutableArray array];
    [ppoInterfaceHistory addObject:sample];
    if (ppoInterfaceHistory.count > 16) [ppoInterfaceHistory removeObjectAtIndex:1];
    ppoInterfacePending = @{@"schema":@1,@"version":@"1.0.2~rc3",@"lastObservation":sample,
        @"observations":[ppoInterfaceHistory copy],@"runtimeCompatibilityConfirmed":@NO,
        @"keyboardEventDeliveryVerified":@NO,@"appNativeGeometryChanged":@NO};
    PPOFlushInterfaceReport();
}
static void PPOKeyboardDidChange(void) {
    if (!NSThread.isMainThread || !ppoWindow) return;
    static CGRect previousFrame = CGRectNull; static BOOL previousKnown;
    CGRect frame = ppoKeyboardMonitor.keyboardFrameInScene;
    BOOL known = ppoKeyboardMonitor.frameKnown;
    BOOL changed = known != previousKnown || !CGRectEqualToRect(frame,previousFrame);
    previousFrame = frame; previousKnown = known;
    if (changed && [ppoPreferences[@"keyboardAvoiding"] boolValue]) {
        if (ppoTarget.handlingPan && ppoNubState.mode() == PPOHandlePanMode::Vertical) {
            NSMutableDictionary *updated = [ppoPreferences mutableCopy];
            updated[@"handleYRatio"] = @(ppoTarget.panStartRatio); ppoPreferences = [updated copy];
        }
        ppoNubState.cancelGesture(); [ppoTarget closeChooser];
    }
    PPOApplyOverlayLayout(); PPORecordInterfaceEvent(@"public-keyboard-observation");
}
static void PPORefreshOverlayVisibility(void) {
    if (!ppoWindow) return;
    @try {
        BOOL allowed = PPOOverlayAllowed() && UIApplication.sharedApplication.protectedDataAvailable &&
            ppoWindow.windowScene.activationState == UISceneActivationStateForegroundActive;
        NSDictionary *lock = PPOReadScreenLockState(objc_lookUpClass("SBLockScreenManager"), ppoFirmwareMatches);
        allowed = allowed && [lock[@"status"] isEqual:@"sampled"] && ![lock[@"locked"] boolValue] &&
            ![lock[@"waitingToLock"] boolValue];
        CGRect screen = ppoWindow.windowScene.coordinateSpace.bounds;
        if ([ppoPreferences[@"hideInLandscape"] boolValue] && screen.size.width > screen.size.height) allowed = NO;
        ppoWindow.hidden = !allowed;
        if (!allowed) [ppoTarget closeChooser];
        NSTimeInterval now = NSProcessInfo.processInfo.systemUptime;
        BOOL drawerOpen = ppoExpanded || [ppoTarget activeDrawer].drawerProgress > 0;
        if (ppoWasDrawerOpen && !drawerOpen) ppoLastInteraction = now;
        ppoWasDrawerOpen = drawerOpen;
        if (!allowed) { ppoNubState.cancelGesture(); ppoNubState.reveal(); }
        ppoHandleNubbed = ppoNubState.visible(allowed,drawerOpen,ppoTarget.handlingPan,ppoTarget.quickChoosing,
            [ppoPreferences[@"autoHideHandle"] boolValue],now,ppoLastInteraction,[ppoPreferences[@"autoHideDelay"] doubleValue]);
        PPOApplyOverlayLayout();
    } @catch (NSException *exception) { (void)exception; ppoWindow.hidden = YES; }
}
static void PPOBuildOverlay(UIWindowScene *scene) {
    UIWindow *window = [[PPOEdgeOverlayWindow alloc] initWithWindowScene:scene];
    window.frame = scene.coordinateSpace.bounds; window.windowLevel = UIWindowLevelStatusBar + 3;
    window.backgroundColor = UIColor.clearColor;
    UIViewController *controller = [UIViewController new];
    controller.view.backgroundColor = UIColor.clearColor; controller.view.clipsToBounds = YES;
    window.rootViewController = controller;
    // Allocate and retain our action target before any UIControl target is attached.
    PPOHandleTarget *target = [PPOHandleTarget new]; target.picker = [PPOPickerState new];
    UIView *panel = [[UIView alloc] initWithFrame:CGRectZero];
    panel.layer.cornerRadius = 18; panel.clipsToBounds = YES; panel.hidden = YES;
    [controller.view addSubview:panel];
    UIControl *outside = [[PPOOutsideControl alloc] initWithFrame:controller.view.bounds];
    outside.backgroundColor = UIColor.blackColor; outside.hidden = YES;
    CAShapeLayer *mask = [CAShapeLayer layer]; outside.layer.mask = mask;
    [outside addTarget:target action:@selector(outsideTapped:) forControlEvents:UIControlEventTouchUpInside];
    [controller.view insertSubview:outside atIndex:0];
    PPOClassicQuickSwitchView *classic = [[PPOClassicQuickSwitchView alloc] initWithFrame:controller.view.bounds];
    __weak PPOHandleTarget *weakTarget = target;
    classic.symbolProvider = ^UIImage *(NSString *identifier) {
        NSDictionary *symbols = @{@"com.apple.mobilesafari":@"safari", @"com.apple.DocumentsApp":@"folder",
            @"com.apple.mobilecal":@"calendar", @"com.apple.reminders":@"checklist", @"com.apple.MobileAddressBook":@"person.crop.circle"};
        NSString *symbol = symbols[identifier];
        return symbol ? [UIImage systemImageNamed:symbol] : nil;
    };
    classic.selectionHandler = ^(NSString *identifier,uint64_t generation) { [weakTarget classicChoice:identifier generation:generation normal:NO]; };
    classic.normalLaunchHandler = ^(NSString *identifier,uint64_t generation) { [weakTarget classicChoice:identifier generation:generation normal:YES]; };
    [controller.view addSubview:classic];
    UILabel *status = [[PPOEdgeStatusLabel alloc] initWithFrame:CGRectZero];
    status.numberOfLines = 2; status.font = [UIFont systemFontOfSize:13]; status.textAlignment = NSTextAlignmentCenter;
    status.textColor = UIColor.labelColor; status.backgroundColor = UIColor.secondarySystemBackgroundColor;
    status.layer.cornerRadius = 12; status.clipsToBounds = YES; status.hidden = YES;
    status.userInteractionEnabled = NO; [controller.view addSubview:status];
    // Hidden status data is reused by picker errors; no diagnostic controls in the user flow.
    UIButton *handle = [UIButton buttonWithType:UIButtonTypeCustom];
    UIView *pill = [UIView new]; pill.userInteractionEnabled = NO; pill.layer.cornerRadius = 17; pill.clipsToBounds = YES;
    UIVisualEffectView *blur = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterial]];
    blur.userInteractionEnabled = NO; [pill addSubview:blur];
    UIImageView *icon = [UIImageView new]; icon.contentMode = UIViewContentModeScaleAspectFit;
    [blur.contentView addSubview:icon]; [handle addSubview:pill];
    handle.titleLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightSemibold];
    handle.accessibilityLabel = @"PullOver Pro; glisează spre interior sau ține apăsat pentru aplicații";
    [handle addTarget:target action:@selector(tapped:) forControlEvents:UIControlEventTouchUpInside];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:target action:@selector(panned:)];
    pan.delegate = target; [handle addGestureRecognizer:pan];
    UILongPressGestureRecognizer *quick = [[UILongPressGestureRecognizer alloc] initWithTarget:target action:@selector(quickFavorites:)];
    quick.minimumPressDuration = 0.3; quick.delegate = target; [handle addGestureRecognizer:quick];
    UITapGestureRecognizer *allApps = [[UITapGestureRecognizer alloc] initWithTarget:target action:@selector(showAllApplications:)];
    allApps.numberOfTapsRequired = 2; allApps.delaysTouchesEnded = YES; allApps.delegate = target;
    [handle addGestureRecognizer:allApps];
    UIButton *classicClose = [UIButton buttonWithType:UIButtonTypeSystem];
    [classicClose setTitle:@"×" forState:UIControlStateNormal]; classicClose.titleLabel.font = [UIFont systemFontOfSize:24];
    classicClose.accessibilityLabel = @"Închide fereastra PullOver Pro"; classicClose.hidden = YES;
    [classicClose addTarget:target action:@selector(closeClassicWindow:) forControlEvents:UIControlEventTouchUpInside];
    [handle addSubview:classicClose];
    [pan requireGestureRecognizerToFail:quick];
    [controller.view addSubview:handle];
    dispatch_source_t visibilityTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,0,0,dispatch_get_main_queue());
    if (!visibilityTimer) { window.hidden = YES; return; }
    ppoVisibilityTimer = visibilityTimer;
    ppoWindow = window; ppoController = controller; ppoTarget = target; ppoPanel = panel;
    ppoStatus = status; ppoHandle = handle; ppoHandlePill = pill; ppoHandleBlur = blur; ppoHandleIcon = icon;
    ppoRenderedTheme = -1; ppoRenderedSymbol = nil;
    ppoClassicView = classic; ppoClassicClose = classicClose; ppoOutsideDismiss = outside; ppoOutsideMask = mask;
    ppoFirmwareMatches = [PPOSceneFrameworkIdentity()[@"matches"] boolValue];
    ppoLastInteraction = NSProcessInfo.processInfo.systemUptime; ppoWasDrawerOpen = NO;
    ppoKeyboardMonitor = [[PPOKeyboardMonitor alloc] initWithScene:scene changed:^{ PPOKeyboardDidChange(); }];
    PPOApplyOverlayLayout(); PPORefreshOverlayVisibility(); [target restoreCachedPicker];
    PPORecordInterfaceEvent(@"overlay-ready");
    dispatch_source_set_timer(ppoVisibilityTimer, dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC), NSEC_PER_SEC,NSEC_PER_MSEC*100);
    dispatch_source_set_event_handler(ppoVisibilityTimer, ^{ PPORefreshOverlayVisibility(); });
    dispatch_resume(ppoVisibilityTimer);
    [NSNotificationCenter.defaultCenter addObserverForName:@"SBDeviceLockStateChangedNotification" object:nil
        queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) {
            (void)note; ppoWindow.hidden = YES; [ppoTarget closeChooser];
            [ppoKeyboardMonitor resetFrameForReason:@"locked"];
            dispatch_async(dispatch_get_main_queue(), ^{ PPORefreshOverlayVisibility(); });
        }];
}

static BOOL ppoScheduled;
static BOOL ppoStopped;
static NSUInteger ppoAttempts;
static id ppoSceneObserver;

static BOOL PPOOverlayAllowed(void) {
    struct stat marker = {};
    return ppoPreferences && [ppoPreferences[@"enabled"] boolValue] &&
        lstat("/var/mobile/.ppo_disable", &marker) != 0 && errno == ENOENT;
}
static BOOL ppoPreferencesLoading, ppoPreferencesPending;
static void PPORequestPreferences(void) {
    if (!NSThread.isMainThread) { dispatch_async(dispatch_get_main_queue(), ^{ PPORequestPreferences(); }); return; }
    if (ppoPreferencesLoading) { ppoPreferencesPending = YES; return; }
    ppoPreferencesLoading = YES;
    dispatch_async(PPOPreferenceQueue(), ^{
        NSError *error = nil;
        NSDictionary *snapshot = PPOUserPreferencesRead(&error);
        dispatch_async(dispatch_get_main_queue(), ^{
            ppoPreferencesLoading = NO;
            if (ppoPreferencesPending) { ppoPreferencesPending = NO; PPORequestPreferences(); return; }
            if (error) return; // Preserve a known disabled/cache state on a storage error.
            NSDictionary *applied = snapshot;
            if (![snapshot[@"rememberPosition"] boolValue]) {
                NSMutableDictionary *runtime = [snapshot mutableCopy];
                runtime[@"handleYRatio"] = ppoPreferences[@"handleYRatio"] ?: @0.5;
                applied = [runtime copy]; // Ignore old persisted position without deleting it.
            }
            BOOL edgeChanged = ppoPreferences && ![applied[@"edge"] isEqual:ppoPreferences[@"edge"]];
            ppoPreferences = applied;
            if (!PPOOverlayAllowed() || edgeChanged) {
                ppoNubState.cancelGesture(); ppoNubState.reveal();
                [[ppoTarget activeDrawer] close]; [ppoTarget closeChooser];
            }
            if (ppoWindow) { PPOApplyOverlayLayout(); if (ppoExpanded) [ppoTarget loadPicker]; PPORefreshOverlayVisibility(); PPORecordInterfaceEvent(@"preferences-applied"); }
            else { ppoStopped = NO; ppoAttempts = 0; PPOScheduleOverlay(); }
        });
    });
}
static void PPOPreferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name,
    const void *object, CFDictionaryRef userInfo) {
    (void)center; (void)observer; (void)name; (void)object; (void)userInfo;
    dispatch_async(dispatch_get_main_queue(), ^{ [ppoTarget cancelQuickChoosing]; PPORequestPreferences(); });
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
                NSLog(@"[PPO 1.0.2] no-active-scene; stopped");
                ppoStopped = YES;
            }
        } @catch (NSException *exception) {
            // Catches synchronous ObjC exceptions only, not hangs or memory faults.
            NSLog(@"[PPO 1.0.2] ui-exception=%@; stopped", exception.name);
            ppoWindow.hidden = YES; [ppoTarget cancelOpening];
            if (ppoVisibilityTimer) { dispatch_source_cancel(ppoVisibilityTimer); ppoVisibilityTimer = nil; }
            [ppoKeyboardMonitor invalidate]; ppoKeyboardMonitor = nil;
            ppoWindow = nil; ppoController = nil; ppoTarget = nil;
            ppoPanel = nil; ppoStatus = nil; ppoHandle = nil; ppoHandlePill = nil; ppoHandleBlur = nil; ppoHandleIcon = nil; ppoClassicView = nil; ppoClassicClose = nil; ppoOutsideDismiss = nil; ppoOutsideMask = nil;
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
        // Public preference I/O is deferred; no UIKit or private scene method in ctor.
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL,
            PPOPreferencesChanged, (__bridge CFStringRef)PPOUserPreferencesChangedNotification,
            NULL, CFNotificationSuspensionBehaviorCoalesce);
        dispatch_async(dispatch_get_main_queue(), ^{
            ppoSceneObserver = [NSNotificationCenter.defaultCenter addObserverForName:UISceneDidActivateNotification
                object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) {
                    (void)note; PPOScheduleOverlay(); PPORefreshOverlayVisibility();
                }];
            PPORequestPreferences();
        });
    }
}
