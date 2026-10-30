#import "PPOScenePresenter.h"
#import "tools/app-launch/PPOLaunchABI.h"
#import <objc/message.h>

// Read method tables only: absence must not run dynamic method resolution.
static Method PPOMethod(Class cls, const char *name) {
    SEL selector = sel_registerName(name);
    for (NSUInteger depth = 0; cls && depth < 64; depth++, cls = class_getSuperclass(cls)) {
        unsigned count = 0;
        Method *list = class_copyMethodList(cls, &count), found = NULL;
        for (unsigned i = 0; i < count; i++) {
            if (method_getName(list[i]) == selector) { found = list[i]; break; }
        }
        free(list);
        if (found) return found;
    }
    return NULL;
}
static BOOL PPOShape(Class cls, const char *name, const char *result, BOOL argument = NO) {
    Method m = PPOMethod(cls, name);
    return m && method_getNumberOfArguments(m) == (argument ? 3u : 2u) &&
        PPOTypeMatches(method_copyReturnType(m), result) &&
        PPOTypeMatches(method_copyArgumentType(m, 0), @encode(id)) &&
        PPOTypeMatches(method_copyArgumentType(m, 1), @encode(SEL)) &&
        (!argument || PPOTypeMatches(method_copyArgumentType(m, 2), @encode(id)));
}
static BOOL PPOPresenterShape(Class cls) {
    return cls && PPOShape(cls, "identifier", @encode(id)) &&
        PPOShape(cls, "presentationView", @encode(id)) &&
        PPOShape(cls, "activate", @encode(void)) && PPOShape(cls, "invalidate", @encode(void)) &&
        PPOShape(cls, "isInvalidated", @encode(bool)) &&
        PPOShape(cls, "isActive", @encode(bool)) && PPOShape(cls, "isHosting", @encode(bool));
}
static id PPOObject(id receiver, const char *name) {
    if (!receiver || !PPOShape(object_getClass(receiver), name, @encode(id)))
        [NSException raise:@"PPOUnsupportedABI" format:@"getter"];
    return ((id (*)(id, SEL))objc_msgSend)(receiver, sel_registerName(name));
}
static void PPOTell(id receiver, const char *name) {
    if (!receiver || !PPOShape(object_getClass(receiver), name, @encode(void)))
        [NSException raise:@"PPOUnsupportedABI" format:@"operation"];
    ((void (*)(id, SEL))objc_msgSend)(receiver, sel_registerName(name));
}
static bool PPOFlag(id receiver, const char *name) {
    if (!receiver || !PPOShape(object_getClass(receiver), name, @encode(bool)))
        [NSException raise:@"PPOUnsupportedABI" format:@"state"];
    return ((bool (*)(id, SEL))objc_msgSend)(receiver, sel_registerName(name));
}
static BOOL PPOArgumentShape(Class cls, const char *name, const char *argument) {
    Method m = PPOMethod(cls, name);
    return m && method_getNumberOfArguments(m) == 3 &&
        PPOTypeMatches(method_copyReturnType(m), @encode(void)) &&
        PPOTypeMatches(method_copyArgumentType(m, 0), @encode(id)) &&
        PPOTypeMatches(method_copyArgumentType(m, 1), @encode(SEL)) &&
        PPOTypeMatches(method_copyArgumentType(m, 2), argument);
}
static void PPOContextFlag(id context) {
    if (!PPOArgumentShape(object_getClass(context), "_setVisibilityPropagationEnabled:", @encode(bool)))
        [NSException raise:@"PPOUnsupportedContext" format:@"setter"];
    ((void (*)(id, SEL, bool))objc_msgSend)(context,
        sel_registerName("_setVisibilityPropagationEnabled:"), true);
}

@interface PPOScenePresenter ()
@property(nonatomic,strong) id presenter;
@property(nonatomic,strong,readwrite) id presentationView;
@property(nonatomic,copy,readwrite) NSString *state;
@property(nonatomic,readwrite) BOOL poisoned;
@property(nonatomic,assign) Class managerClass;
@property(nonatomic,assign) Class presenterClass;
@property(nonatomic,assign) Class viewClass;
@property(nonatomic,copy) NSString *identifier;
@property(nonatomic) BOOL owned;
@property(nonatomic) BOOL attempted;
@property(nonatomic) BOOL busy;
@property(nonatomic) BOOL invalidateReturned;
@property(nonatomic) BOOL lastActive;
@property(nonatomic) BOOL lastHosting;
@property(nonatomic) BOOL visibilityAttempted;
@property(nonatomic) BOOL visibilityConfigured;
@property(nonatomic,strong) NSNumber *visibilityInitiallyEnabled;
@end
@implementation PPOScenePresenter
- (instancetype)initWithManagerClass:(Class)managerClass presenterClass:(Class)presenterClass
                          viewClass:(Class)viewClass {
    if ((self = [super init])) {
        _managerClass = managerClass; _presenterClass = presenterClass; _viewClass = viewClass;
        _state = @"idle";
    }
    return self;
}
- (BOOL)prepareScene:(id)scene {
    if (!NSThread.isMainThread || self.busy || self.attempted || self.poisoned) return NO;
    self.attempted = YES; self.busy = YES;
    @try {
        if (!scene || !self.managerClass || !self.viewClass ||
            !PPOShape(object_getClass(scene), "uiPresentationManager", @encode(id)) ||
            !PPOShape(self.managerClass, "createPresenterWithIdentifier:", @encode(id), YES) ||
            !PPOPresenterShape(self.presenterClass)) {
            self.state = @"unsupported-abi"; return NO;
        }
        id manager = PPOObject(scene, "uiPresentationManager");
        if (![manager isKindOfClass:self.managerClass] ||
            !PPOShape(object_getClass(manager), "createPresenterWithIdentifier:", @encode(id), YES)) {
            self.state = @"unsupported-manager"; return NO;
        }
        self.identifier = [@"com.renatasy83.ppo." stringByAppendingString:NSUUID.UUID.UUIDString];
        self.state = @"creating";
        // Objective-C create... is a +0 method (not alloc/new/copy/init family).
        // Exact23A355 implementation: UIKitCore 0x1897b79e0. Never use priorities.
        self.presenter = ((id (*)(id, SEL, id))objc_msgSend)(manager,
            sel_registerName("createPresenterWithIdentifier:"), self.identifier);
        if (!self.presenter) { self.state = @"no-presenter"; return NO; }
        if (![self.presenter isKindOfClass:self.presenterClass] ||
            !PPOPresenterShape(object_getClass(self.presenter)) ||
            ![PPOObject(self.presenter, "identifier") isEqual:self.identifier]) {
            // Ownership cannot be proved: retain, never mutate the foreign object.
            self.poisoned = YES; self.state = @"unverified-presenter"; return NO;
        }
        self.owned = YES;
        if (PPOFlag(self.presenter, "isInvalidated")) {
            self.state = @"already-invalidated"; return NO;
        }
        id view = PPOObject(self.presenter, "presentationView");
        if (![view isKindOfClass:self.viewClass]) { self.state = @"invalid-view"; return NO; }
        self.presentationView = view;
        self.state = @"prepared";
        return YES;
    } @catch (NSException *exception) {
        (void)exception;
        self.state = @"prepare-exception";
        // Factory may have thrown after partially mutating its owner. Do not retry.
        if (!self.owned) self.poisoned = YES;
        return NO;
    } @finally {
        self.busy = NO;
        if (![self.state isEqual:@"prepared"] && self.owned) {
            NSString *failure = self.state;
            if ([self close]) self.state = failure;
        }
    }
}
- (BOOL)enableVisibilityPropagationWithContextClass:(Class)contextClass
                               mutableContextClass:(Class)mutableContextClass {
    if (!NSThread.isMainThread || self.busy || self.poisoned || !self.owned ||
        self.visibilityAttempted || ![self.state isEqual:@"prepared"]) return NO;
    self.visibilityAttempted = YES; self.busy = YES;
    BOOL success = NO;
    __block BOOL accepting = NO;
    @try {
        if (PPOFlag(self.presenter, "isInvalidated")) {
            self.state = @"visibility-presenter-invalidated";
        } else if (!contextClass || !mutableContextClass ||
            !PPOShape(object_getClass(self.presenter), "presentationContext", @encode(id)) ||
            !PPOArgumentShape(object_getClass(self.presenter), "modifyPresentationContext:", "@?")) {
            self.state = @"unsupported-visibility-abi";
        } else {
            id original = PPOObject(self.presenter, "presentationContext");
            if (![original isKindOfClass:contextClass] ||
                !PPOShape(object_getClass(original), "_isVisibilityPropagationEnabled", @encode(bool))) {
                self.state = @"unsupported-visibility-context";
            } else {
                self.visibilityInitiallyEnabled = @(PPOFlag(original, "_isVisibilityPropagationEnabled"));
                if (self.visibilityInitiallyEnabled.boolValue) {
                    self.visibilityConfigured = YES;
                    return YES;
                }
                __block NSUInteger callbacks = 0;
                __block BOOL changed = NO;
                accepting = YES;
                void (^configure)(id) = ^(id context) {
                    // Reject asynchronous/retained callbacks without touching any
                    // context. Exact firmware invokes one callback synchronously.
                    if (!NSThread.isMainThread || !accepting) return;
                    callbacks++;
                    if (callbacks != 1 || context == original ||
                        ![context isKindOfClass:mutableContextClass])
                        [NSException raise:@"PPOUnsupportedContext" format:@"callback"];
                    PPOContextFlag(context);
                    changed = YES;
                };
                ((void (*)(id, SEL, void (^)(id)))objc_msgSend)(self.presenter,
                    sel_registerName("modifyPresentationContext:"), configure);
                accepting = NO;
                id updated = PPOObject(self.presenter, "presentationContext");
                success = callbacks == 1 && changed && updated != original &&
                    [updated isKindOfClass:contextClass] &&
                    PPOFlag(updated, "_isVisibilityPropagationEnabled");
                if (!success) self.state = @"visibility-readback-failed";
            }
        }
        self.visibilityConfigured = success;
    } @catch (NSException *exception) {
        (void)exception; self.state = @"visibility-configuration-exception";
    } @finally { accepting = NO; self.busy = NO; }
    if (!success) {
        NSString *failure = self.state;
        if ([self close]) self.state = failure;
    }
    return success;
}
- (BOOL)activate {
    if (!NSThread.isMainThread || self.busy || self.poisoned ||
        ![self.state isEqual:@"prepared"]) return NO;
    self.busy = YES;
    BOOL success = NO;
    @try {
        PPOTell(self.presenter, "activate");
        self.lastActive = PPOFlag(self.presenter, "isActive");
        self.lastHosting = PPOFlag(self.presenter, "isHosting");
        // Hosting can update asynchronously. Neither flag proves visible pixels.
        self.state = @"activate-returned"; success = YES;
    } @catch (NSException *exception) {
        (void)exception; self.state = @"activate-exception";
    } @finally { self.busy = NO; }
    if (!success) {
        NSString *failure = self.state;
        if ([self close]) self.state = failure;
    }
    return success;
}
- (BOOL)close {
    if (!NSThread.isMainThread || self.busy) return NO;
    if (!self.presenter) return !self.poisoned;
    if (!self.owned || self.poisoned) return NO;
    self.busy = YES;
    @try {
        // Only PPO's own presenter. Never FBScene.invalidate/destroy, never an
        // existing presenter, never the shared UIScenePresentationManager.
        PPOTell(self.presenter, "invalidate");
        self.invalidateReturned = YES;
        if (!PPOFlag(self.presenter, "isInvalidated")) {
            self.poisoned = YES; self.state = @"invalidation-unconfirmed"; return NO;
        }
        self.presentationView = nil; self.presenter = nil; self.owned = NO;
        self.state = @"closed";
        return YES;
    } @catch (NSException *exception) {
        (void)exception;
        self.poisoned = YES; self.state = @"close-exception"; return NO;
    } @finally { self.busy = NO; }
}
- (NSDictionary *)sampleState {
    if (!NSThread.isMainThread) return @{@"status": @"wrong-thread"};
    if (self.busy) return @{@"status": @"busy"};
    if (!self.presenter || !self.owned) return @{@"status": @"no-owned-presenter"};
    self.busy = YES;
    @try {
        return @{@"status": @"sampled", @"active": @(PPOFlag(self.presenter, "isActive")),
            @"hosting": @(PPOFlag(self.presenter, "isHosting")),
            @"invalidated": @(PPOFlag(self.presenter, "isInvalidated")),
            @"visibilityPropagationConfigured": @(self.visibilityConfigured)};
    } @catch (NSException *exception) {
        (void)exception; return @{@"status": @"sample-exception"};
    } @finally { self.busy = NO; }
}
- (NSDictionary *)snapshot {
    return @{@"state": self.state, @"poisoned": @(self.poisoned),
        @"owned": @(self.owned), @"invalidateReturned": @(self.invalidateReturned),
        @"activeAfterActivation": @(self.lastActive), @"hostingAfterActivation": @(self.lastHosting),
        @"visibilityConfigurationAttempted": @(self.visibilityAttempted),
        @"visibilityPropagationConfigured": @(self.visibilityConfigured),
        @"visibilityPropagationInitiallyEnabled": self.visibilityInitiallyEnabled ?: (id)NSNull.null,
        @"visiblePixelsVerified": @NO, @"inputRoutingVerified": @NO,
        @"systemPresentationRestoredVerified": @NO};
}
@end
