#import "TestContextInterfaces.h"
#import "../Tweak/ContextHostManager.h"
#import <stdio.h>
#import <stdlib.h>

static BOOL serviceAvailable = YES;
static BOOL duplicateLaunchResult = NO;
static NSError *launchError;
static NSUInteger launchRequests;
static NSDictionary *lastOptions;
static NSUInteger checks;

#define CHECK(condition) do { checks++; if (!(condition)) { \
    fprintf(stderr, "FAIL %s:%d: %s\n", __FILE__, __LINE__, #condition); abort(); \
} } while (0)

@implementation UIView
@end
@implementation UIColor
+ (instancetype)clearColor { return [self new]; }
- (id)copyWithZone:(NSZone *)zone { (void)zone; return self; }
@end
@implementation FBProcess
@end
@implementation FBSSceneSettings
@end
@implementation UIMutableApplicationSceneSettings
@end
@implementation UIMutableScenePresentationContext
@end
@implementation _UIScenePresenter
- (void)modifyPresentationContext:(void (^)(UIMutableScenePresentationContext *))block {
    UIMutableScenePresentationContext *context = [UIMutableScenePresentationContext new];
    block(context);
    CHECK(context.appearanceStyle == 2);
    CHECK(context.backgroundColorWhileNotHosting != nil);
}
- (void)activate {
    self.activations++;
    if (self.throwOnActivate) [NSException raise:@"FakeActivationFailure" format:@"test"];
}
- (void)deactivate {
    self.deactivations++;
    if (self.throwOnDeactivate) [NSException raise:@"FakeDeactivationFailure" format:@"test"];
}
- (void)invalidate {
    self.invalidations++;
    if (self.throwOnInvalidate) [NSException raise:@"FakeInvalidationFailure" format:@"test"];
    self.invalidated = YES;
}
@end
@implementation UIScenePresentationManager
- (_UIScenePresenter *)createPresenterWithIdentifier:(NSString *)identifier {
    CHECK([identifier isEqualToString:@"com.johndie.pulloverpro"]);
    self.creations++;
    return self.nextPresenter;
}
@end
@implementation FBScene
- (void)updateSettingsWithBlock:(void (^)(UIMutableApplicationSceneSettings *))block {
    UIMutableApplicationSceneSettings *change = [UIMutableApplicationSceneSettings new];
    change.foreground = self.settings.foreground;
    block(change);
    self.settings.foreground = change.foreground;
    if (change.foreground) self.foregroundWrites++;
    else self.backgroundWrites++;
}
@end
@implementation FBSceneManager
+ (instancetype)sharedInstance {
    static FBSceneManager *manager;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ manager = [self new]; });
    return manager;
}
- (NSSet *)scenesPassingTest:(BOOL (^)(FBScene *))test {
    NSMutableSet *matches = [NSMutableSet new];
    for (FBScene *scene in self.scenes) if (test(scene)) [matches addObject:scene];
    return matches;
}
@end
@implementation FBSSystemService
+ (instancetype)sharedService {
    static FBSSystemService *service;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ service = [self new]; });
    return serviceAvailable ? service : nil;
}
- (void)openApplication:(NSString *)bundleId options:(NSDictionary *)options withResult:(void (^)(NSError *))result {
    CHECK(bundleId.length > 0);
    launchRequests++;
    lastOptions = options;
    NSError *error = launchError;
    BOOL duplicate = duplicateLaunchResult;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        result(error);
        if (duplicate) result(error);
    });
}
@end

static FBScene *Scene(NSString *bundle, BOOL foreground, BOOL withPresenter, BOOL withView) {
    FBScene *scene = [FBScene new];
    scene.identifier = [NSString stringWithFormat:@"sceneID:%@-default", bundle];
    scene.clientProcess = [FBProcess new];
    scene.clientProcess.bundleIdentifier = bundle;
    scene.settings = [FBSSceneSettings new];
    scene.settings.foreground = foreground;
    scene.uiPresentationManager = [UIScenePresentationManager new];
    if (withPresenter) {
        _UIScenePresenter *presenter = [_UIScenePresenter new];
        if (withView) presenter.presentationView = [UIView new];
        scene.uiPresentationManager.nextPresenter = presenter;
    }
    return scene;
}

static void WaitUntil(BOOL (^done)(void)) {
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:3];
    while (!done() && deadline.timeIntervalSinceNow > 0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                               beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    }
    CHECK(done());
}

static void TestRollbackAndCleanup(void) {
    ContextHostManager *manager = [ContextHostManager new];
    FBScene *nilPresenter = Scene(@"test.nil-presenter", NO, NO, NO);
    [FBSceneManager sharedInstance].scenes = [NSSet setWithObject:nilPresenter];
    CHECK([manager hostViewForBundleID:@"test.nil-presenter"] == nil);
    CHECK(!nilPresenter.settings.foreground);
    CHECK(nilPresenter.foregroundWrites == 1 && nilPresenter.backgroundWrites == 1);
    [manager stopHostingForBundleID:@"test.nil-presenter"];
    CHECK(nilPresenter.backgroundWrites == 1);
    // Retry must still own the foreground transition, then roll it back again.
    CHECK([manager hostViewForBundleID:@"test.nil-presenter"] == nil);
    CHECK(nilPresenter.foregroundWrites == 2 && nilPresenter.backgroundWrites == 2);

    FBScene *nilView = Scene(@"test.nil-view", NO, YES, NO);
    [FBSceneManager sharedInstance].scenes = [NSSet setWithObject:nilView];
    CHECK([manager hostViewForBundleID:@"test.nil-view"] == nil);
    CHECK(!nilView.settings.foreground);
    CHECK(nilView.uiPresentationManager.nextPresenter.invalidations == 1);

    FBScene *activateThrows = Scene(@"test.exception", NO, YES, YES);
    activateThrows.uiPresentationManager.nextPresenter.throwOnActivate = YES;
    [FBSceneManager sharedInstance].scenes = [NSSet setWithObject:activateThrows];
    CHECK([manager hostViewForBundleID:@"test.exception"] == nil);
    CHECK(!activateThrows.settings.foreground);
    CHECK(activateThrows.uiPresentationManager.nextPresenter.invalidations == 1);

    FBScene *alreadyForeground = Scene(@"test.foreground", YES, YES, YES);
    [FBSceneManager sharedInstance].scenes = [NSSet setWithObject:alreadyForeground];
    CHECK([manager hostViewForBundleID:@"test.foreground"] != nil);
    [manager stopHostingForBundleID:@"test.foreground"];
    CHECK(alreadyForeground.settings.foreground);
    CHECK(alreadyForeground.foregroundWrites == 0 && alreadyForeground.backgroundWrites == 0);

    FBScene *a = Scene(@"test.a", NO, YES, YES);
    FBScene *b = Scene(@"test.b", NO, YES, YES);
    [FBSceneManager sharedInstance].scenes = [NSSet setWithObjects:a, b, nil];
    UIView *aView = [manager hostViewForBundleID:@"test.a"];
    CHECK(aView != nil && a.settings.foreground);
    CHECK([manager hostViewForBundleID:@"test.a"] == aView);
    CHECK(a.uiPresentationManager.creations == 1);
    UIView *bView = [manager hostViewForBundleID:@"test.b"];
    CHECK(bView != nil && !a.settings.foreground && b.settings.foreground);
    CHECK(a.uiPresentationManager.nextPresenter.invalidations == 1);
    [manager stopHostingForBundleID:@"test.a"];
    CHECK(b.settings.foreground && [manager isHostViewHosting:bView]);
    CHECK(![manager isHostViewHosting:aView]);
    b.uiPresentationManager.nextPresenter.throwOnDeactivate = YES;
    b.uiPresentationManager.nextPresenter.throwOnInvalidate = YES;
    [manager stopHostingForBundleID:@"test.b"];
    CHECK(!b.settings.foreground);
    CHECK(![manager isHostViewHosting:bView]);
    [manager stopHostingForBundleID:@"test.b"];
    CHECK(b.backgroundWrites == 1);
    CHECK(b.uiPresentationManager.nextPresenter.deactivations == 1);
    CHECK(b.uiPresentationManager.nextPresenter.invalidations == 1);
}

static void TestLaunchResults(void) {
    ContextHostManager *manager = [ContextHostManager new];
    [FBSceneManager sharedInstance].scenes = [NSSet set];
    __block NSUInteger callbacks = 0;
    __block NSError *result;
    serviceAvailable = NO;
    [manager launchInBackground:@"test.launch" completion:^(NSError *error) {
        CHECK(NSThread.isMainThread);
        result = error;
        callbacks++;
    }];
    CHECK(callbacks == 0);
    WaitUntil(^BOOL{ return callbacks == 1; });
    CHECK(result != nil && launchRequests == 0);

    serviceAvailable = YES;
    launchError = [NSError errorWithDomain:@"fake.launch" code:23 userInfo:nil];
    callbacks = 0;
    [manager launchInBackground:@"test.launch" completion:^(NSError *error) {
        CHECK(NSThread.isMainThread);
        result = error;
        callbacks++;
    }];
    WaitUntil(^BOOL{ return callbacks == 1; });
    CHECK(result == launchError && launchRequests == 1);
    CHECK([lastOptions[@"__ActivateSuspended"] boolValue]);

    FBScene *existing = Scene(@"test.existing", NO, YES, YES);
    [FBSceneManager sharedInstance].scenes = [NSSet setWithObject:existing];
    callbacks = 0;
    [manager launchInBackground:@"test.existing" completion:^(NSError *error) {
        CHECK(NSThread.isMainThread);
        result = error;
        callbacks++;
    }];
    CHECK(callbacks == 0);
    WaitUntil(^BOOL{ return callbacks == 1; });
    CHECK(result == nil && launchRequests == 1);

    callbacks = 0;
    [manager launchInBackground:@"" completion:^(NSError *error) { result = error; callbacks++; }];
    WaitUntil(^BOOL{ return callbacks == 1; });
    CHECK(result != nil && launchRequests == 1);

    launchError = nil;
    duplicateLaunchResult = YES;
    callbacks = 0;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        [manager launchInBackground:@"test.background" completion:^(NSError *error) {
            CHECK(NSThread.isMainThread);
            result = error;
            callbacks++;
        }];
    });
    WaitUntil(^BOOL{ return callbacks == 1; });
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    CHECK(callbacks == 1 && result == nil && launchRequests == 2);
    duplicateLaunchResult = NO;
    [manager openFullScreen:@"test.fullscreen"];
    CHECK([lastOptions[@"__UnlockDevice"] boolValue]);
}

int main(void) {
    @autoreleasepool {
        CHECK(NSThread.isMainThread);
        TestRollbackAndCleanup();
        TestLaunchResults();
        printf("ContextHostManager: %lu checks passed (production implementation, fake platform interfaces).\n", (unsigned long)checks);
    }
    return 0;
}
