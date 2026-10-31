#import "PPOOwnedSceneHost.h"
#import "PPOOwnedApplicationPolicy.h"
#import "PPOOwnedAdmission.h"
#import "tools/app-launch/PPOLaunchABI.h"
#import <objc/message.h>

// These typed declarations preserve ARC's +1 alloc/init method-family rules.
// Actual private receiver method tables are validated before every dispatch.
@protocol PPOHostAllocation <NSObject>
+ (instancetype)alloc;
@end
@protocol PPOWorkspaceInitialization <NSObject>
- (instancetype)initWithIdentifier:(id)identifier;
@end
@protocol PPOConfigurationInitialization <NSObject>
- (instancetype)initWithClientIdentity:(id)identity;
@end
@protocol PPOControllerInitialization <NSObject>
- (instancetype)initWithAdvancedConfiguration:(id)configuration;
@end

static NSMutableSet<PPOOwnedSceneHost *> *HostPins;
static Method HostMethod(Class cls, const char *name) {
    SEL selector = sel_registerName(name);
    for (NSUInteger depth = 0; cls && depth < 64; depth++, cls = class_getSuperclass(cls)) {
        unsigned count = 0;
        Method *methods = class_copyMethodList(cls, &count), found = NULL;
        for (unsigned i = 0; i < count; i++) {
            if (method_getName(methods[i]) == selector) { found = methods[i]; break; }
        }
        free(methods);
        if (found) return found;
    }
    return NULL;
}
static BOOL HostShape(Class cls, const char *name, const char *result, BOOL argument = NO) {
    Method method = HostMethod(cls, name);
    return method && method_getNumberOfArguments(method) == (argument ? 3u : 2u) &&
        PPOTypeMatches(method_copyReturnType(method), result) &&
        PPOTypeMatches(method_copyArgumentType(method, 0), @encode(id)) &&
        PPOTypeMatches(method_copyArgumentType(method, 1), @encode(SEL)) &&
        (!argument || PPOTypeMatches(method_copyArgumentType(method, 2), @encode(id)));
}
static id HostObject(id receiver, const char *name) {
    if (!receiver || !HostShape(object_getClass(receiver), name, @encode(id)))
        [NSException raise:@"PPOOwnedHostABI" format:@"getter"];
    return ((id (*)(id, SEL))objc_msgSend)(receiver, sel_registerName(name));
}
static bool HostFlag(id receiver, const char *name) {
    if (!receiver || !HostShape(object_getClass(receiver), name, @encode(bool)))
        [NSException raise:@"PPOOwnedHostABI" format:@"flag"];
    return ((bool (*)(id, SEL))objc_msgSend)(receiver, sel_registerName(name));
}
static void HostSet(id receiver, const char *name, id argument) {
    if (!receiver || !HostShape(object_getClass(receiver), name, @encode(void), YES))
        [NSException raise:@"PPOOwnedHostABI" format:@"setter"];
    ((void (*)(id, SEL, id))objc_msgSend)(receiver, sel_registerName(name), argument);
}
static void HostTell(id receiver, const char *name) {
    if (!receiver || !HostShape(object_getClass(receiver), name, @encode(void)))
        [NSException raise:@"PPOOwnedHostABI" format:@"operation"];
    ((void (*)(id, SEL))objc_msgSend)(receiver, sel_registerName(name));
}
static Class HostClass(NSDictionary *classes, NSString *name) {
    id value = classes[name];
    return value && object_isClass(value) ? (Class)value : Nil;
}
static BOOL HostText(id value) {
    return [value isKindOfClass:NSString.class] && [(NSString *)value length] > 0 &&
        [(NSString *)value length] <= 512;
}
static BOOL HostTextEquals(id value, NSString *expected) {
    return HostText(value) && [value isEqualToString:expected];
}
static BOOL HostConstructible(Class cls, const char *initializer) {
    return cls && HostShape(object_getClass((id)cls), "alloc", @encode(id)) &&
        HostShape(cls, initializer, @encode(id), YES);
}

@interface PPOOwnedSceneHost ()
@property(nonatomic,copy) NSDictionary<NSString *, id> *classes;
@property(nonatomic,strong,readwrite) id viewController;
@property(nonatomic,strong,readwrite) id hostedScene;
@property(nonatomic,copy,readwrite) NSString *state;
@property(nonatomic,readwrite) BOOL poisoned;
@property(nonatomic,readwrite) BOOL closed;
@property(nonatomic,strong) id sourceScene;
@property(nonatomic,copy) NSString *workspaceIdentifier;
@property(nonatomic,copy) NSString *sceneIdentifier;
@property(nonatomic,strong) id allocatedWorkspace;
@property(nonatomic,strong) id workspace;
@property(nonatomic,strong) id allocatedConfiguration;
@property(nonatomic,strong) id configuration;
@property(nonatomic,strong) id allocatedController;
@property(nonatomic,strong) id controller;
@property(nonatomic,strong) id component;
@property(nonatomic) BOOL attempted;
@property(nonatomic) BOOL busy;
@property(nonatomic) BOOL pinned;
@property(nonatomic) BOOL workspaceVerified;
@property(nonatomic) BOOL controllerVerified;
@property(nonatomic) BOOL controllerInvalidateAttempted;
@property(nonatomic) BOOL controllerInvalidateReturned;
@property(nonatomic) BOOL workspaceInvalidateAttempted;
@property(nonatomic) BOOL workspaceInvalidateReturned;
@property(nonatomic,copy) NSString *preparationFailure;
@property(nonatomic,copy) NSString *expectedBundleIdentifier;
@property(nonatomic,copy) NSDictionary *admission;
@property(nonatomic,copy) NSDictionary *componentBinding;
- (BOOL)classesSupported;
- (BOOL)finishCleanupIfPossible;
- (void)pin;
- (void)poisonWithState:(NSString *)state;
@end

@implementation PPOOwnedSceneHost
- (instancetype)initWithClasses:(NSDictionary<NSString *, id> *)classes {
    if ((self = [super init])) {
        _classes = [classes copy]; _state = @"idle";
        _componentBinding = @{@"status": @"not-read",
            @"componentPresent": NSNull.null, @"expectedComponentClass": NSNull.null,
            @"hostScenePresent": NSNull.null, @"proxyClassMatched": NSNull.null,
            @"matchesCreatedScene": NSNull.null, @"matchesBorrowedSource": NSNull.null};
    }
    return self;
}
- (void)pin {
    if (!HostPins) HostPins = [NSMutableSet set];
    [HostPins addObject:self]; self.pinned = YES;
}
- (void)poisonWithState:(NSString *)state {
    self.poisoned = YES; self.state = state;
    // Do not clear/release unknown private allocations. In particular releasing
    // an unverified controller would run dealloc -> invalidate on its own scene.
}
- (BOOL)classesSupported {
    Class ws = HostClass(self.classes, @"FBSceneWorkspace");
    Class cfg = HostClass(self.classes, @"_UISceneHostingControllerAdvancedConfiguration");
    Class controller = HostClass(self.classes, @"_UISceneHostingController");
    Class scene = HostClass(self.classes, @"FBScene");
    Class definition = HostClass(self.classes, @"FBSSceneDefinition");
    Class specification = HostClass(self.classes, @"UIApplicationSceneSpecification");
    Class identity = HostClass(self.classes, @"FBSSceneClientIdentity");
    Class component = HostClass(self.classes, @"_UISceneHostingActivationStateHostComponent");
    Class componentScene = HostClass(self.classes, @"FBSComponentScene");
    return HostConstructible(ws, "initWithIdentifier:") &&
        HostShape(ws, "identifier", @encode(id)) && HostShape(ws, "allScenes", @encode(id)) &&
        HostShape(ws, "invalidate", @encode(void)) &&
        HostConstructible(cfg, "initWithClientIdentity:") &&
        HostShape(cfg, "setSceneWorkspace:", @encode(void), YES) &&
        HostShape(cfg, "setSceneIdentifier:", @encode(void), YES) &&
        HostShape(cfg, "setSceneSpecification:", @encode(void), YES) &&
        HostShape(cfg, "sceneWorkspace", @encode(id)) &&
        HostShape(cfg, "sceneIdentifier", @encode(id)) &&
        HostShape(cfg, "sceneSpecification", @encode(id)) &&
        HostShape(cfg, "clientIdentity", @encode(id)) &&
        HostConstructible(controller, "initWithAdvancedConfiguration:") &&
        HostShape(controller, "activationStateComponent", @encode(id)) &&
        HostShape(controller, "sceneViewController", @encode(id)) &&
        HostShape(controller, "invalidate", @encode(void)) &&
        scene && HostShape(scene, "definition", @encode(id)) &&
        HostShape(scene, "identifier", @encode(id)) && HostShape(scene, "workspaceIdentifier", @encode(id)) &&
        HostShape(scene, "isValid", @encode(bool)) && HostShape(scene, "isActive", @encode(bool)) &&
        definition && HostShape(definition, "clientIdentity", @encode(id)) &&
        HostShape(definition, "specification", @encode(id)) &&
        specification && HostShape(specification, "uiSceneSessionRole", @encode(id)) &&
        identity && HostShape(identity, "bundleIdentifier", @encode(id)) &&
        component && HostShape(component, "hostScene", @encode(id)) &&
        componentScene && HostShape(componentScene, "scene", @encode(id)) &&
        HostClass(self.classes, @"UIViewController");
}
- (BOOL)prepareScene:(id)source forBundleIdentifier:(NSString *)identifier
         capability:(NSDictionary *)capability {
    __attribute__((objc_precise_lifetime)) PPOOwnedSceneHost *keepAlive = self;
    (void)keepAlive;
    if (!NSThread.isMainThread || self.busy || self.attempted || self.poisoned || self.closed) return NO;
    self.attempted = YES; self.busy = YES;
    BOOL success = NO, cleanFailure = NO;
    @try {
        self.admission = PPOOwnedAdmissionSnapshot(identifier, capability,
            NSProcessInfo.processInfo.systemUptime);
        if (!self.admission) { self.state = @"application-not-eligible"; return NO; }
        self.expectedBundleIdentifier = self.admission[@"bundleIdentifier"];
        BOOL strictSpecification = !PPOOwnedApplicationAllowed(self.expectedBundleIdentifier);
        if (![self classesSupported]) { self.state = @"unsupported-owned-host-abi"; return NO; }
        if (![source isKindOfClass:HostClass(self.classes, @"FBScene")] || !HostFlag(source, "isValid")) {
            self.state = @"unexpected-source"; return NO;
        }
        id definition = HostObject(source, "definition");
        if (![definition isKindOfClass:HostClass(self.classes, @"FBSSceneDefinition")]) {
            self.state = @"unexpected-definition"; return NO;
        }
        id identity = HostObject(definition, "clientIdentity");
        id specification = HostObject(definition, "specification");
        id sourceIdentifier = HostObject(source, "identifier");
        if (strictSpecification && object_getClass(specification) !=
            HostClass(self.classes, @"UIApplicationSceneSpecification")) {
            self.state = @"unsupported-source-specification"; return NO;
        }
        if (![identity isKindOfClass:HostClass(self.classes, @"FBSSceneClientIdentity")] ||
            ![specification isKindOfClass:HostClass(self.classes, @"UIApplicationSceneSpecification")] ||
            !HostText(sourceIdentifier) ||
            !HostTextEquals(HostObject(identity, "bundleIdentifier"), self.expectedBundleIdentifier) ||
            !HostTextEquals(HostObject(specification, "uiSceneSessionRole"), @"UIWindowSceneSessionRoleApplication")) {
            self.state = @"unsupported-source"; return NO;
        }
        self.sourceScene = source;
        NSString *nonce = NSUUID.UUID.UUIDString;
        self.workspaceIdentifier = [@"com.renatasy83.ppo.workspace." stringByAppendingString:nonce];
        self.sceneIdentifier = [@"com.renatasy83.ppo.scene." stringByAppendingString:nonce];
        if ([sourceIdentifier isEqual:self.sceneIdentifier]) { self.state = @"namespace-conflict"; return NO; }
        [self pin]; // Pins self before the first potentially side-effectful allocation.
        Class wsClass = HostClass(self.classes, @"FBSceneWorkspace");
        self.allocatedWorkspace = [(Class<PPOHostAllocation>)wsClass alloc];
        if (![self.allocatedWorkspace isKindOfClass:wsClass] ||
            !HostShape(object_getClass(self.allocatedWorkspace), "initWithIdentifier:", @encode(id), YES)) {
            [self poisonWithState:@"unverified-workspace-allocation"]; return NO;
        }
        self.workspace = [(id<PPOWorkspaceInitialization>)self.allocatedWorkspace
            initWithIdentifier:self.workspaceIdentifier];
        if (self.workspace != self.allocatedWorkspace || ![self.workspace isKindOfClass:wsClass]) {
            [self poisonWithState:@"unverified-workspace-initializer"]; return NO;
        }
        id scenes = HostObject(self.workspace, "allScenes");
        if (!HostTextEquals(HostObject(self.workspace, "identifier"), self.workspaceIdentifier) ||
            ![scenes isKindOfClass:NSArray.class] || [scenes count] != 0) {
            [self poisonWithState:@"unverified-workspace-namespace"]; return NO;
        }
        self.workspaceVerified = YES;
        Class cfgClass = HostClass(self.classes, @"_UISceneHostingControllerAdvancedConfiguration");
        self.allocatedConfiguration = [(Class<PPOHostAllocation>)cfgClass alloc];
        if (![self.allocatedConfiguration isKindOfClass:cfgClass] ||
            !HostShape(object_getClass(self.allocatedConfiguration), "initWithClientIdentity:", @encode(id), YES)) {
            [self poisonWithState:@"unverified-configuration-allocation"]; return NO;
        }
        self.configuration = [(id<PPOConfigurationInitialization>)self.allocatedConfiguration
            initWithClientIdentity:identity];
        if (self.configuration != self.allocatedConfiguration || ![self.configuration isKindOfClass:cfgClass]) {
            [self poisonWithState:@"unverified-configuration-initializer"]; return NO;
        }
        HostSet(self.configuration, "setSceneWorkspace:", self.workspace);
        HostSet(self.configuration, "setSceneIdentifier:", self.sceneIdentifier);
        HostSet(self.configuration, "setSceneSpecification:", specification);
        if (HostObject(self.configuration, "sceneWorkspace") != self.workspace ||
            !HostTextEquals(HostObject(self.configuration, "sceneIdentifier"), self.sceneIdentifier) ||
            HostObject(self.configuration, "sceneSpecification") != specification ||
            HostObject(self.configuration, "clientIdentity") != identity) {
            cleanFailure = YES; self.state = @"configuration-readback-failed"; return NO;
        }
        Class controllerClass = HostClass(self.classes, @"_UISceneHostingController");
        self.allocatedController = [(Class<PPOHostAllocation>)controllerClass alloc];
        if (![self.allocatedController isKindOfClass:controllerClass] ||
            !HostShape(object_getClass(self.allocatedController), "initWithAdvancedConfiguration:", @encode(id), YES)) {
            [self poisonWithState:@"unverified-controller-allocation"]; return NO;
        }
        self.controller = [(id<PPOControllerInitialization>)self.allocatedController
            initWithAdvancedConfiguration:self.configuration];
        if (self.controller != self.allocatedController || ![self.controller isKindOfClass:controllerClass]) {
            [self poisonWithState:@"unverified-controller-initializer"]; return NO;
        }
        scenes = HostObject(self.workspace, "allScenes");
        if (![scenes isKindOfClass:NSArray.class] || [scenes count] != 1) {
            [self poisonWithState:@"unverified-created-scenes"]; return NO;
        }
        id child = [scenes objectAtIndex:0];
        if (child == source || ![child isKindOfClass:HostClass(self.classes, @"FBScene")] ||
            !HostTextEquals(HostObject(child, "identifier"), self.sceneIdentifier) ||
            !HostTextEquals(HostObject(child, "workspaceIdentifier"), self.workspaceIdentifier) ||
            !HostFlag(child, "isValid")) {
            [self poisonWithState:@"unverified-created-scene"]; return NO;
        }
        id childDefinition = HostObject(child, "definition");
        if (![childDefinition isKindOfClass:HostClass(self.classes, @"FBSSceneDefinition")]) {
            [self poisonWithState:@"unverified-created-definition"]; return NO;
        }
        id childIdentity = HostObject(childDefinition, "clientIdentity");
        id childSpecification = HostObject(childDefinition, "specification");
        if (strictSpecification && object_getClass(childSpecification) !=
            HostClass(self.classes, @"UIApplicationSceneSpecification")) {
            [self poisonWithState:@"unverified-created-specification"]; return NO;
        }
        if (![childIdentity isKindOfClass:HostClass(self.classes, @"FBSSceneClientIdentity")] ||
            ![childSpecification isKindOfClass:HostClass(self.classes, @"UIApplicationSceneSpecification")] ||
            !HostTextEquals(HostObject(childIdentity, "bundleIdentifier"), self.expectedBundleIdentifier) ||
            !HostTextEquals(HostObject(childSpecification, "uiSceneSessionRole"), @"UIWindowSceneSessionRoleApplication")) {
            [self poisonWithState:@"unverified-created-client"]; return NO;
        }
        // 23A355 components store FBSComponentScene, an NSProxy that forwards
        // class/isKindOfClass: to FBScene. hostScene returns that proxy, not
        // necessarily the raw workspace child. Check its actual runtime class
        // before using the explicit, ABI-checked scene getter to unwrap it.
        NSMutableDictionary *binding = [@{@"status": @"reading-component",
            @"componentPresent": NSNull.null, @"expectedComponentClass": NSNull.null,
            @"hostScenePresent": NSNull.null, @"proxyClassMatched": NSNull.null,
            @"matchesCreatedScene": NSNull.null, @"matchesBorrowedSource": NSNull.null} mutableCopy];
        self.componentBinding = binding;
        self.component = HostObject(self.controller, "activationStateComponent");
        binding[@"componentPresent"] = @(self.component != nil);
        BOOL componentClassMatches = [self.component isKindOfClass:
            HostClass(self.classes, @"_UISceneHostingActivationStateHostComponent")];
        binding[@"expectedComponentClass"] = @(componentClassMatches);
        if (!self.component || !componentClassMatches) {
            binding[@"status"] = self.component ? @"component-class-mismatch" : @"component-missing";
            self.componentBinding = binding;
            [self poisonWithState:@"unverified-controller-scene"]; return NO;
        }
        binding[@"status"] = @"reading-host-scene"; self.componentBinding = binding;
        id componentScene = HostObject(self.component, "hostScene");
        binding[@"hostScenePresent"] = @(componentScene != nil);
        BOOL proxyClassMatches = componentScene &&
            object_getClass(componentScene) == HostClass(self.classes, @"FBSComponentScene");
        binding[@"proxyClassMatched"] = @(proxyClassMatches);
        id boundScene = nil;
        if (componentScene == child) boundScene = child;
        else if (proxyClassMatches) {
            binding[@"status"] = @"reading-proxy-scene"; self.componentBinding = binding;
            boundScene = HostObject(componentScene, "scene");
        } else {
            binding[@"status"] = componentScene ? @"unknown-host-scene-class" : @"host-scene-missing";
            self.componentBinding = binding;
            [self poisonWithState:@"unverified-controller-scene"]; return NO;
        }
        binding[@"matchesCreatedScene"] = @(boundScene == child);
        binding[@"matchesBorrowedSource"] = @(boundScene == source);
        binding[@"status"] = boundScene == child ?
            (proxyClassMatches ? @"verified-proxy" : @"verified-direct") : @"host-scene-foreign";
        self.componentBinding = binding;
        if (boundScene != child) {
            [self poisonWithState:@"unverified-controller-scene"]; return NO;
        }
        self.hostedScene = child; self.controllerVerified = YES;
        if (HostFlag(child, "isActive")) {
            cleanFailure = YES; self.state = @"unexpected-active-before-attachment"; return NO;
        }
        id viewController = HostObject(self.controller, "sceneViewController");
        if (![viewController isKindOfClass:HostClass(self.classes, @"UIViewController")]) {
            cleanFailure = YES; self.state = @"invalid-owned-view-controller"; return NO;
        }
        self.viewController = viewController;
        self.state = @"prepared"; success = YES;
    } @catch (NSException *exception) {
        (void)exception;
        if (self.pinned) [self poisonWithState:@"owned-host-prepare-exception"];
        else self.state = @"source-read-exception";
    } @finally {
        self.busy = NO;
        if (!success && !self.pinned) { self.sourceScene = nil; self.closed = YES; }
        if (cleanFailure && !self.poisoned) {
            self.preparationFailure = self.state;
            [self close];
        }
    }
    return success;
}
- (BOOL)finishCleanupIfPossible {
    if (!self.workspaceVerified || !self.workspace || self.poisoned) return NO;
    if (self.allocatedController && (!self.controllerVerified || !self.controllerInvalidateReturned)) return NO;
    if (self.hostedScene && HostFlag(self.hostedScene, "isValid")) {
        self.state = @"cleanup-pending"; return NO;
    }
    id scenes = HostObject(self.workspace, "allScenes");
    if (![scenes isKindOfClass:NSArray.class]) {
        [self poisonWithState:@"cleanup-invalid-workspace-result"]; return NO;
    }
    if ([scenes count] != 0) { self.state = @"cleanup-pending"; return NO; }
    if (self.workspaceInvalidateAttempted) return self.closed;
    self.workspaceInvalidateAttempted = YES;
    HostTell(self.workspace, "invalidate");
    self.workspaceInvalidateReturned = YES;
    // Only after new child invalidation and an empty owned workspace can the
    // known owned controller be released (its dealloc invokes invalidate).
    self.viewController = nil; self.component = nil; self.hostedScene = nil;
    self.controller = nil; self.allocatedController = nil;
    self.configuration = nil; self.allocatedConfiguration = nil;
    self.workspace = nil; self.allocatedWorkspace = nil; self.sourceScene = nil;
    self.closed = YES; self.state = @"closed"; self.pinned = NO;
    __attribute__((objc_precise_lifetime)) PPOOwnedSceneHost *keepAlive = self;
    [HostPins removeObject:self];
    (void)keepAlive;
    return YES;
}
- (BOOL)close {
    __attribute__((objc_precise_lifetime)) PPOOwnedSceneHost *keepAlive = self;
    (void)keepAlive;
    if (!NSThread.isMainThread || self.busy || self.poisoned) return NO;
    if (self.closed) return YES;
    if (!self.attempted) { self.closed = YES; self.state = @"closed"; return YES; }
    self.busy = YES;
    @try {
        if (self.allocatedController && !self.controllerVerified) {
            [self poisonWithState:@"cleanup-unverified-controller"]; return NO;
        }
        if (self.controllerVerified && !self.controllerInvalidateAttempted) {
            self.controllerInvalidateAttempted = YES;
            HostTell(self.controller, "invalidate");
            self.controllerInvalidateReturned = YES;
        }
        return [self finishCleanupIfPossible];
    } @catch (NSException *exception) {
        (void)exception; [self poisonWithState:@"owned-host-cleanup-exception"]; return NO;
    } @finally { self.busy = NO; }
}
- (BOOL)pollCleanup {
    __attribute__((objc_precise_lifetime)) PPOOwnedSceneHost *keepAlive = self;
    (void)keepAlive;
    if (!NSThread.isMainThread || self.busy || self.poisoned) return NO;
    if (self.closed) return YES;
    if (!self.attempted || (self.allocatedController && !self.controllerInvalidateAttempted)) return NO;
    self.busy = YES;
    @try { return [self finishCleanupIfPossible]; }
    @catch (NSException *exception) {
        (void)exception; [self poisonWithState:@"owned-host-cleanup-exception"]; return NO;
    } @finally { self.busy = NO; }
}
- (void)quarantineCleanup {
    if (!NSThread.isMainThread || self.busy || self.closed || self.poisoned) return;
    [self poisonWithState:@"owned-host-cleanup-timeout"];
}
- (NSDictionary *)sampleState {
    if (!NSThread.isMainThread) return @{@"status": @"wrong-thread"};
    if (self.busy) return @{@"status": @"busy"};
    if (!self.controllerVerified || !self.hostedScene || self.closed || self.poisoned)
        return @{@"status": @"no-owned-scene"};
    self.busy = YES;
    @try {
        return @{@"status": @"sampled", @"active": @(HostFlag(self.hostedScene, "isActive")),
            @"valid": @(HostFlag(self.hostedScene, "isValid"))};
    } @catch (NSException *exception) {
        (void)exception; return @{@"status": @"sample-exception"};
    } @finally { self.busy = NO; }
}
- (NSDictionary *)snapshot {
    return @{@"state": self.state, @"poisoned": @(self.poisoned), @"closed": @(self.closed),
        @"pinned": @(self.pinned), @"workspaceVerified": @(self.workspaceVerified),
        @"controllerVerified": @(self.controllerVerified),
        @"controllerInvalidateAttempted": @(self.controllerInvalidateAttempted),
        @"controllerInvalidateReturned": @(self.controllerInvalidateReturned),
        @"workspaceInvalidateAttempted": @(self.workspaceInvalidateAttempted),
        @"workspaceInvalidateReturned": @(self.workspaceInvalidateReturned),
        @"componentBinding": self.componentBinding,
        @"expectedBundleIdentifier": self.expectedBundleIdentifier ?: (id)NSNull.null,
        @"admission": self.admission ?: (id)NSNull.null,
        @"preparationFailure": self.preparationFailure ?: (id)NSNull.null,
        @"borrowedSourceMutationRequested": @NO, @"runtimeCompatibilityConfirmed": @NO};
}
@end
