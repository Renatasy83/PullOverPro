// Modified 2026-11-23 by Renatasy83: stability corrections; original credits and GPL-3.0 retained.
#import "ContextHostManager.h"
#import "POLog.h"

static NSString *const kPresenterID = @"com.johndie.pulloverpro";
static NSString *const kHostingErrorDomain = @"com.johndie.pulloverpro.hosting";

static NSError *POLaunchError(NSInteger code, NSString *message) {
    return [NSError errorWithDomain:kHostingErrorDomain code:code
                           userInfo:@{NSLocalizedDescriptionKey: message}];
}

@implementation ContextHostManager {
    NSString *_bundleId;
    FBScene *_scene;
    _UIScenePresenter *_presenter;
    BOOL _weForegrounded;   // only send the app back if we brought it forward
}

+ (instancetype)sharedInstance {
    static ContextHostManager *shared;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ shared = [self new]; });
    return shared;
}

// Prefer the main scene when an app has several scenes.
- (FBScene *)sceneForBundleId:(NSString *)bundleId {
    Class managerClass = NSClassFromString(@"FBSceneManager");
    if (![bundleId isKindOfClass:NSString.class] || !bundleId.length ||
        ![managerClass respondsToSelector:@selector(sharedInstance)]) return nil;
    FBSceneManager *manager = [managerClass sharedInstance];
    if (![manager respondsToSelector:@selector(scenesPassingTest:)]) return nil;

    NSSet *scenes = [manager scenesPassingTest:^BOOL(FBScene *scene) {
        if (![scene respondsToSelector:@selector(clientProcess)]) return NO;
        FBProcess *process = scene.clientProcess;
        return [process respondsToSelector:@selector(bundleIdentifier)] &&
               [process.bundleIdentifier isEqualToString:bundleId];
    }];
    FBScene *best = nil;
    for (FBScene *scene in scenes) {
        if ([scene respondsToSelector:@selector(identifier)] &&
            [scene.identifier hasSuffix:@"-default"]) return scene;
        if (!best) best = scene;
    }
    return best;
}

- (void)openApplication:(NSString *)bundleId suspended:(BOOL)suspended
            completion:(void (^)(NSError *error))completion {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self openApplication:bundleId suspended:suspended completion:completion];
        });
        return;
    }
    // Serialize completion and suppress duplicate callbacks from a service.
    __block BOOL completed = NO;
    void (^finish)(NSError *) = ^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completed) return;
            completed = YES;
            if (completion) completion(error);
        });
    };
    if (![bundleId isKindOfClass:NSString.class] || !bundleId.length) {
        finish(POLaunchError(1, @"The application identifier is invalid."));
        return;
    }
    Class serviceClass = NSClassFromString(@"FBSSystemService");
    if (![serviceClass respondsToSelector:@selector(sharedService)]) {
        finish(POLaunchError(2, @"The application launch service is unavailable."));
        return;
    }
    @try {
        FBSSystemService *service = [serviceClass sharedService];
        if (![service respondsToSelector:@selector(openApplication:options:withResult:)]) {
            finish(POLaunchError(2, @"The application launch service is unavailable."));
            return;
        }
        NSDictionary *options = suspended ? @{@"__ActivateSuspended": @YES} : @{@"__UnlockDevice": @YES};
        [service openApplication:bundleId options:options withResult:^(NSError *error) {
            POLog(@"open %@ suspended=%d -> %@", bundleId, suspended, error ?: @"ok");
            finish(error);
        }];
    } @catch (NSException *exception) {
        (void)exception;
        POLog(@"open %@ failed: %@", bundleId, exception.name);
        finish(POLaunchError(3, @"The application launch request failed."));
    }
}

- (void)launchInBackground:(NSString *)bundleId {
    [self launchInBackground:bundleId completion:nil];
}

- (void)launchInBackground:(NSString *)bundleId completion:(void (^)(NSError *error))completion {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self launchInBackground:bundleId completion:completion];
        });
        return;
    }
    @try {
        if ([self sceneForBundleId:bundleId]) {
            if (completion) dispatch_async(dispatch_get_main_queue(), ^{ completion(nil); });
            return;
        }
    } @catch (NSException *exception) {
        (void)exception;
        POLog(@"scene lookup %@ failed: %@", bundleId, exception.name);
        if (completion) dispatch_async(dispatch_get_main_queue(), ^{
            completion(POLaunchError(4, @"The application scene could not be checked."));
        });
        return;
    }
    [self openApplication:bundleId suspended:YES completion:completion];
}

- (void)openFullScreen:(NSString *)bundleId {
    [self openApplication:bundleId suspended:NO completion:nil];
}

- (BOOL)setScene:(FBScene *)scene foreground:(BOOL)foreground {
    if (![scene respondsToSelector:@selector(updateSettingsWithBlock:)]) return NO;
    [scene updateSettingsWithBlock:^(UIMutableApplicationSceneSettings *settings) {
        settings.foreground = foreground;
    }];
    return YES;
}

- (UIView *)hostViewForBundleID:(NSString *)bundleId {
    if (![NSThread isMainThread] || ![bundleId isKindOfClass:NSString.class] || !bundleId.length) return nil;
    @try {
        if (_presenter && [_bundleId isEqualToString:bundleId] &&
            [_presenter respondsToSelector:@selector(isInvalidated)] && !_presenter.invalidated &&
            [_presenter respondsToSelector:@selector(presentationView)] && _presenter.presentationView) {
            return _presenter.presentationView;
        }
        if (_bundleId) [self stopHostingForBundleID:_bundleId];

        FBScene *scene = [self sceneForBundleId:bundleId];
        if (![scene respondsToSelector:@selector(uiPresentationManager)] ||
            ![scene respondsToSelector:@selector(settings)]) return nil;
        FBSSceneSettings *settings = scene.settings;
        if (![settings respondsToSelector:@selector(isForeground)]) return nil;
        UIScenePresentationManager *manager = scene.uiPresentationManager;
        if (![manager respondsToSelector:@selector(createPresenterWithIdentifier:)]) return nil;
        BOOL bringForward = !settings.foreground;
        if (bringForward && ![scene respondsToSelector:@selector(updateSettingsWithBlock:)]) return nil;

        // Record the transaction BEFORE changing the scene. Cleanup must work
        // even when no presenter can be created, or a later operation fails.
        _bundleId = [bundleId copy];
        _scene = scene;
        _weForegrounded = bringForward;
        if (bringForward) [self setScene:scene foreground:YES];

        _presenter = [manager createPresenterWithIdentifier:kPresenterID];
        if (![_presenter respondsToSelector:@selector(modifyPresentationContext:)] ||
            ![_presenter respondsToSelector:@selector(activate)] ||
            ![_presenter respondsToSelector:@selector(invalidate)] ||
            ![_presenter respondsToSelector:@selector(isInvalidated)] ||
            ![_presenter respondsToSelector:@selector(presentationView)] || _presenter.invalidated) {
            [self stopHostingForBundleID:bundleId];
            return nil;
        }
        [_presenter modifyPresentationContext:^(UIMutableScenePresentationContext *context) {
            context.appearanceStyle = 2;   // live content, not a snapshot
            context.backgroundColorWhileNotHosting = UIColor.clearColor;
        }];
        [_presenter activate];
        UIView *view = _presenter.presentationView;
        if (!view || _presenter.invalidated) {
            [self stopHostingForBundleID:bundleId];
            return nil;
        }
        POLog(@"host %@: presenter=%@ view=%@ wasForeground=%d", bundleId, _presenter, view, !bringForward);
        return view;
    } @catch (NSException *exception) {
        (void)exception;
        POLog(@"host %@ failed: %@", bundleId, exception.name);
        [self stopHostingForBundleID:bundleId];
        return nil;
    }
}

- (void)stopHostingForBundleID:(NSString *)bundleId {
    if (![NSThread isMainThread]) {
        NSString *requestedBundle = [bundleId copy];
        dispatch_async(dispatch_get_main_queue(), ^{ [self stopHostingForBundleID:requestedBundle]; });
        return;
    }
    // A late callback belonging to an old app must not tear down the new one.
    if (!_bundleId || ![_bundleId isEqualToString:bundleId]) return;
    _UIScenePresenter *presenter = _presenter;
    FBScene *scene = _scene;
    BOOL restoreBackground = _weForegrounded;
    // Clear ownership first so repeated/reentrant cleanup is idempotent.
    _presenter = nil;
    _scene = nil;
    _bundleId = nil;
    _weForegrounded = NO;
    @try {
        if ([presenter respondsToSelector:@selector(deactivate)]) [presenter deactivate];
    } @catch (NSException *exception) {
        (void)exception;
        POLog(@"deactivate failed: %@", exception.name);
    }
    @try {
        if ([presenter respondsToSelector:@selector(invalidate)]) [presenter invalidate];
    } @catch (NSException *exception) {
        (void)exception;
        POLog(@"invalidate failed: %@", exception.name);
    }
    @try {
        if (scene && restoreBackground) [self setScene:scene foreground:NO];
    } @catch (NSException *exception) {
        (void)exception;
        POLog(@"scene restoration failed: %@", exception.name);
    }
}

- (BOOL)isHostViewHosting:(UIView *)hostView {
    if (![NSThread isMainThread]) return NO;
    return hostView && [_presenter respondsToSelector:@selector(isInvalidated)] && !_presenter.invalidated &&
           [_presenter respondsToSelector:@selector(presentationView)] && hostView == _presenter.presentationView;
}

@end
