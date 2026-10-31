#import "../PPOOwnedSceneHost.h"
#import "../PPOOwnedApplicationPolicy.h"
#import "../PPOSceneCapability.h"
#import <dispatch/dispatch.h>
#import <objc/runtime.h>
#include <stdio.h>
#include <stdlib.h>

// Native ownership/ABI fixtures only. This does not execute UIKit scene creation.
static unsigned checks, workspaceInvalidations, controllerInvalidations, sourceInvalidations;
static unsigned constructors, resolutions, unsafeWorkspaceInvalidations, controllerDeallocations;
static BOOL delayedCleanup, failControllerInvalidate, throwControllerInvalidate, reenter;
static BOOL throwWorkspaceInvalidate, invalidWorkspaceList;
static BOOL badWorkspaceIdentity, prepopulatedWorkspace, wrongConfigWorkspace, wrongConfigIdentifier;
static BOOL aliasSource, wrongNewIdentity, wrongNewWorkspace, badComponentScene, badControllerView;
static BOOL unexpectedNewActive;
static BOOL badNewDefinition, badNewClientIdentity, badNewRole, wrongConfigClientIdentity;
static BOOL throwControllerInit, nilControllerInit, foreignControllerInit;
static unsigned workspaceConstructorFault, configurationConstructorFault;
static unsigned componentFault, componentReads, hostSceneReads, proxySceneReads, unknownProxySceneReads;
static BOOL directComponentScene;
static PPOOwnedSceneHost *current;
static id sourceScene;
static id requestedApplication;
static NSString *originalApplication, *childIdentifierOverride;
static NSMutableString *callerIdentifierMutation;
static NSDictionary *requestedCapability;
static NSMutableDictionary *callerCapabilityMutation;
static BOOL childSpecificationSubclass;
static unsigned customSpecificationReads;
static unsigned workspaceConstructions, sourceProbes;
static BOOL Prepare(id source) {
    return [current prepareScene:source forBundleIdentifier:requestedApplication capability:requestedCapability];
}
static void Check(BOOL condition, const char *message) {
    checks++;
    if (!condition) { fprintf(stderr, "FAIL: %s\n", message); exit(1); }
}

@interface OwnedFixtureClient : NSObject
@property(nonatomic,copy) NSString *bundleIdentifier;
@end
@implementation OwnedFixtureClient @end
@interface OwnedFixtureSpecification : NSObject
@property(nonatomic,copy) NSString *uiSceneSessionRole;
@end
@implementation OwnedFixtureSpecification @end
@interface OwnedFixtureSpecificationSubclass : OwnedFixtureSpecification @end
@implementation OwnedFixtureSpecificationSubclass
- (NSString *)uiSceneSessionRole { customSpecificationReads++; return [super uiSceneSessionRole]; }
@end
@interface OwnedFixtureDefinition : NSObject
@property(nonatomic,strong) id clientIdentity;
@property(nonatomic,strong) id specification;
@end
@implementation OwnedFixtureDefinition @end
@interface OwnedFixtureScene : NSObject
@property(nonatomic,strong) id definition;
@property(nonatomic,copy) NSString *identifier;
@property(nonatomic,copy) NSString *workspaceIdentifier;
@property(nonatomic) bool valid;
@property(nonatomic) bool active;
- (bool)isValid;
- (bool)isActive;
- (void)invalidate;
@end
@implementation OwnedFixtureScene
- (bool)isValid { if (self == sourceScene) sourceProbes++; return self.valid; }
- (bool)isActive { return self.active; }
- (void)invalidate {
    if (self == sourceScene) sourceInvalidations++;
    self.valid = false;
    self.active = false;
}
@end

// FBSComponentScene is an NSProxy whose public class identity masquerades as
// FBScene. Model that behavior rather than treating hostScene as the raw scene.
@interface OwnedFixtureComponentScene : NSProxy {
    __weak OwnedFixtureScene *_rawScene;
}
- (instancetype)initWithScene:(OwnedFixtureScene *)scene;
- (id)scene;
@end
@implementation OwnedFixtureComponentScene
- (instancetype)initWithScene:(OwnedFixtureScene *)scene { _rawScene = scene; return self; }
- (Class)class { return [_rawScene class]; }
- (BOOL)isKindOfClass:(Class)cls { return [_rawScene isKindOfClass:cls]; }
- (id)scene {
    proxySceneReads++;
    if (componentFault == 9) [NSException raise:@"fixture" format:@"proxy-scene"];
    return _rawScene;
}
@end
@interface OwnedUnknownComponentScene : OwnedFixtureComponentScene @end
@implementation OwnedUnknownComponentScene
- (id)scene { unknownProxySceneReads++; return [super scene]; }
@end
@interface OwnedBadABIComponentScene : NSProxy
- (int)scene;
@end
@implementation OwnedBadABIComponentScene
- (int)scene { proxySceneReads++; abort(); }
- (Class)class { return OwnedFixtureScene.class; }
- (BOOL)isKindOfClass:(Class)cls { return cls == OwnedFixtureScene.class; }
@end
static int BadABIProxyScene(id receiver, SEL selector) {
    (void)receiver; (void)selector; proxySceneReads++; abort();
}
static Class UnknownBadABIProxyClass(void) {
    static Class cls;
    if (!cls) {
        cls = objc_allocateClassPair(OwnedFixtureComponentScene.class, "OwnedUnknownBadABIComponentScene", 0);
        Check(cls && class_addMethod(cls, @selector(scene), (IMP)BadABIProxyScene, "i@:"),
              "unknown-proxy ABI fixture is constructed");
        objc_registerClassPair(cls);
    }
    return cls;
}
@interface OwnedFixtureWorkspace : NSObject
@property(nonatomic,copy) NSString *identifier;
@property(nonatomic,strong) NSMutableArray *scenes;
- (instancetype)initWithIdentifier:(id)identifier;
- (id)workspaceIdentifier;
- (id)allScenes;
- (void)invalidate;
@end
static __weak OwnedFixtureWorkspace *lastWorkspace;
static OwnedFixtureWorkspace *foreignWorkspace;
@implementation OwnedFixtureWorkspace
@synthesize identifier = _identifier;
- (instancetype)initWithIdentifier:(id)identifier {
    workspaceConstructions++;
    if ((self = [super init])) {
        lastWorkspace = self;
        if (workspaceConstructorFault == 1) [NSException raise:@"fixture" format:@"workspace-init"];
        if (workspaceConstructorFault == 2) return nil;
        if (workspaceConstructorFault == 3) return (id)[NSObject new];
        _identifier = [identifier copy]; _scenes = [NSMutableArray array];
        if (prepopulatedWorkspace) [_scenes addObject:sourceScene];
    }
    return self;
}
- (NSString *)identifier { return badWorkspaceIdentity ? @"system.foreign" : _identifier; }
- (id)workspaceIdentifier { return self.identifier; }
- (id)allScenes { return invalidWorkspaceList ? (id)@"invalid-list" : [self.scenes copy]; }
- (void)invalidate {
    workspaceInvalidations++;
    if (self.scenes.count > 0) unsafeWorkspaceInvalidations++;
    if (throwWorkspaceInvalidate) [NSException raise:@"fixture" format:@"workspace-invalidate"];
}
@end
@interface OwnedFixtureConfiguration : NSObject
@property(nonatomic,strong) id clientIdentity;
@property(nonatomic,strong) id sceneWorkspace;
@property(nonatomic,copy) NSString *sceneIdentifier;
@property(nonatomic,strong) id sceneSpecification;
- (instancetype)initWithClientIdentity:(id)identity;
@end
static __weak OwnedFixtureConfiguration *lastConfiguration;
@implementation OwnedFixtureConfiguration
- (instancetype)initWithClientIdentity:(id)identity {
    if ((self = [super init])) {
        lastConfiguration = self;
        if (configurationConstructorFault == 1) [NSException raise:@"fixture" format:@"configuration-init"];
        if (configurationConstructorFault == 2) return nil;
        if (configurationConstructorFault == 3) return (id)[NSObject new];
        _clientIdentity = identity;
    }
    return self;
}
- (id)sceneWorkspace { return wrongConfigWorkspace ? foreignWorkspace : _sceneWorkspace; }
- (id)sceneIdentifier { return wrongConfigIdentifier ? @"system.foreign" : _sceneIdentifier; }
- (id)clientIdentity { return wrongConfigClientIdentity ? (id)@"wrong-client" : _clientIdentity; }
@end
@interface OwnedFixtureComponent : NSObject
@property(nonatomic,strong) id hostScene;
@end
@implementation OwnedFixtureComponent
@synthesize hostScene = _hostScene;
- (id)hostScene {
    hostSceneReads++;
    if (componentFault == 12) [NSException raise:@"fixture" format:@"host-scene"];
    return _hostScene;
}
@end
@interface OwnedFixtureViewController : NSObject @end
@implementation OwnedFixtureViewController @end
@interface OwnedFixtureController : NSObject
@property(nonatomic,strong) OwnedFixtureConfiguration *configuration;
@property(nonatomic,strong) OwnedFixtureScene *createdScene;
@property(nonatomic,strong) id component;
@property(nonatomic,strong) OwnedFixtureScene *foreignScene;
@property(nonatomic,strong) id view;
@property(nonatomic) BOOL invalidated;
- (instancetype)initWithAdvancedConfiguration:(id)configuration;
- (id)activationStateComponent;
- (id)sceneViewController;
- (void)invalidate;
@end
static __weak OwnedFixtureController *lastController;
@implementation OwnedFixtureController
- (instancetype)initWithAdvancedConfiguration:(id)configuration {
    constructors++;
    if ((self = [super init])) {
        lastController = self; _configuration = configuration;
        if (callerIdentifierMutation) [callerIdentifierMutation setString:@"com.apple.MobileAddressBook"];
        if (callerCapabilityMutation) {
            id identity = callerCapabilityMutation[@"bundleIdentifier"];
            if ([identity isKindOfClass:NSMutableString.class]) [identity setString:@"com.example.other"];
            id status = callerCapabilityMutation[@"status"];
            if ([status isKindOfClass:NSMutableString.class]) [status setString:@"ineligible"];
            callerCapabilityMutation[@"eligible"] = @NO;
            callerCapabilityMutation[@"observedUptime"] = @0;
        }
        if (throwControllerInit) [NSException raise:@"fixture" format:@"init"];
        if (nilControllerInit) return nil;
        if (foreignControllerInit) return (id)[NSObject new];
        _createdScene = aliasSource ? sourceScene : [OwnedFixtureScene new];
        if (!aliasSource) {
            _createdScene.identifier = wrongNewIdentity ? @"system.foreign" : [configuration sceneIdentifier];
            _createdScene.workspaceIdentifier = wrongNewWorkspace ? @"system.foreign" : [[configuration sceneWorkspace] workspaceIdentifier];
            _createdScene.valid = true;
            _createdScene.active = unexpectedNewActive;
            OwnedFixtureDefinition *definition = [OwnedFixtureDefinition new];
            definition.clientIdentity = [configuration clientIdentity];
            definition.specification = [configuration sceneSpecification];
            if (childSpecificationSubclass) {
                OwnedFixtureSpecification *other = [OwnedFixtureSpecificationSubclass new];
                other.uiSceneSessionRole = @"UIWindowSceneSessionRoleApplication";
                definition.specification = other;
            }
            if (badNewClientIdentity) {
                OwnedFixtureClient *other = [OwnedFixtureClient new]; other.bundleIdentifier = @"com.example.foreign";
                definition.clientIdentity = other;
            }
            if (childIdentifierOverride) {
                OwnedFixtureClient *other = [OwnedFixtureClient new]; other.bundleIdentifier = childIdentifierOverride;
                definition.clientIdentity = other;
            }
            if (badNewRole) {
                OwnedFixtureSpecification *other = [OwnedFixtureSpecification new]; other.uiSceneSessionRole = @"unverified-role";
                definition.specification = other;
            }
            _createdScene.definition = badNewDefinition ? (id)@"wrong-definition" : definition;
        }
        OwnedFixtureWorkspace *workspace = [configuration sceneWorkspace];
        [workspace.scenes addObject:_createdScene];
        _component = [OwnedFixtureComponent new];
        id hostScene = directComponentScene ? (id)_createdScene :
            [[OwnedFixtureComponentScene alloc] initWithScene:_createdScene];
        if (badComponentScene) hostScene = sourceScene;
        if (componentFault == 3) hostScene = nil;
        if (componentFault == 4 || componentFault == 8) {
            _foreignScene = [OwnedFixtureScene new];
            hostScene = componentFault == 4 ? (id)_foreignScene :
                [[OwnedFixtureComponentScene alloc] initWithScene:_foreignScene];
        }
        if (componentFault == 5) hostScene = [[OwnedUnknownComponentScene alloc] initWithScene:_createdScene];
        if (componentFault == 6) hostScene = [[OwnedFixtureComponentScene alloc] initWithScene:nil];
        if (componentFault == 7) hostScene = [[OwnedFixtureComponentScene alloc] initWithScene:sourceScene];
        if (componentFault == 10) hostScene = [OwnedBadABIComponentScene alloc];
        if (componentFault == 13) hostScene = [[UnknownBadABIProxyClass() alloc] initWithScene:_createdScene];
        [(OwnedFixtureComponent *)_component setHostScene:hostScene];
        if (componentFault == 1) _component = nil;
        if (componentFault == 2) _component = [NSObject new];
        _view = badControllerView ? (id)@"bad-view" : [OwnedFixtureViewController new];
        if (reenter) {
            reenter = NO;
            Check(![current close], "constructor reentry cannot close partial acquisition");
            Check(!Prepare(sourceScene), "constructor reentry cannot acquire twice");
            Check([[current sampleState][@"status"] isEqual:@"busy"],
                  "constructor reentry cannot sample a partially owned scene");
        }
    }
    return self;
}
- (id)activationStateComponent {
    componentReads++;
    if (componentFault == 11) [NSException raise:@"fixture" format:@"component"];
    return self.component;
}
- (id)sceneViewController { return self.view; }
- (void)invalidate {
    controllerInvalidations++;
    if (throwControllerInvalidate) [NSException raise:@"fixture" format:@"invalidate"];
    if (failControllerInvalidate) return;
    self.invalidated = YES;
    if (!delayedCleanup) {
        [self.createdScene invalidate];
        OwnedFixtureWorkspace *workspace = self.configuration.sceneWorkspace;
        [workspace.scenes removeObjectIdenticalTo:self.createdScene];
    }
}
- (void)dealloc { controllerDeallocations++; }
@end
@interface OwnedMissingClass : NSObject @end
@implementation OwnedMissingClass
+ (BOOL)resolveInstanceMethod:(SEL)selector { (void)selector; resolutions++; return NO; }
@end
@interface OwnedBadWorkspace : NSObject
- (int)initWithIdentifier:(id)identifier __attribute__((objc_method_family(none)));
@end
@implementation OwnedBadWorkspace
- (int)initWithIdentifier:(id)identifier { (void)identifier; abort(); }
@end
static NSDictionary *Classes(void) {
    return @{@"FBSceneWorkspace": OwnedFixtureWorkspace.class,
        @"_UISceneHostingControllerAdvancedConfiguration": OwnedFixtureConfiguration.class,
        @"_UISceneHostingController": OwnedFixtureController.class,
        @"FBScene": OwnedFixtureScene.class,
        @"FBSSceneDefinition": OwnedFixtureDefinition.class,
        @"UIApplicationSceneSpecification": OwnedFixtureSpecification.class,
        @"FBSSceneClientIdentity": OwnedFixtureClient.class,
        @"_UISceneHostingActivationStateHostComponent": OwnedFixtureComponent.class,
        @"FBSComponentScene": componentFault == 10 ? OwnedBadABIComponentScene.class : OwnedFixtureComponentScene.class,
        @"UIViewController": OwnedFixtureViewController.class};
}
static void Reset(void) {
    workspaceInvalidations = controllerInvalidations = sourceInvalidations = constructors = resolutions = 0;
    unsafeWorkspaceInvalidations = controllerDeallocations = 0;
    delayedCleanup = failControllerInvalidate = throwControllerInvalidate = reenter = NO;
    throwWorkspaceInvalidate = invalidWorkspaceList = NO;
    badWorkspaceIdentity = prepopulatedWorkspace = wrongConfigWorkspace = wrongConfigIdentifier = NO;
    aliasSource = wrongNewIdentity = wrongNewWorkspace = badComponentScene = badControllerView = NO;
    unexpectedNewActive = NO;
    badNewDefinition = badNewClientIdentity = badNewRole = wrongConfigClientIdentity = NO;
    throwControllerInit = nilControllerInit = foreignControllerInit = NO;
    workspaceConstructorFault = configurationConstructorFault = 0;
    componentFault = componentReads = hostSceneReads = proxySceneReads = unknownProxySceneReads = 0;
    directComponentScene = NO;
    requestedApplication = originalApplication = @"com.apple.mobilesafari";
    childIdentifierOverride = nil; callerIdentifierMutation = nil;
    requestedCapability = nil; callerCapabilityMutation = nil; childSpecificationSubclass = NO;
    customSpecificationReads = 0;
    workspaceConstructions = sourceProbes = 0;
    OwnedFixtureClient *client = [OwnedFixtureClient new]; client.bundleIdentifier = @"com.apple.mobilesafari";
    OwnedFixtureSpecification *spec = [OwnedFixtureSpecification new]; spec.uiSceneSessionRole = @"UIWindowSceneSessionRoleApplication";
    OwnedFixtureDefinition *definition = [OwnedFixtureDefinition new]; definition.clientIdentity = client; definition.specification = spec;
    OwnedFixtureScene *scene = [OwnedFixtureScene new]; scene.definition = definition;
    scene.identifier = @"system.source.safari"; scene.workspaceIdentifier = @"system.main.workspace"; scene.valid = true;
    scene.active = true;
    sourceScene = scene;
    foreignWorkspace = nil;
    current = [[PPOOwnedSceneHost alloc] initWithClasses:Classes()];
}
static void ResetForApplication(NSString *application) {
    Reset();
    requestedApplication = originalApplication = [application copy];
    OwnedFixtureDefinition *definition = [sourceScene definition];
    [(OwnedFixtureClient *)definition.clientIdentity setBundleIdentifier:originalApplication];
}
static NSDictionary *DynamicCapability(NSString *application, NSString *status = @"eligible") {
    return @{@"schema": @1, @"policy": @"installed-basic-multiscene-v1",
        @"bundleIdentifier": application, @"status": status,
        @"eligible": [status isEqual:@"eligible"] ? @YES : @NO,
        @"reason": [status isEqual:@"eligible"] ? @"declared-single-application-scene" :
            ([status isEqual:@"ineligible"] ? @"multiple-scenes-disabled" : @"manifest-unknown"),
        @"observedUptime": @(NSProcessInfo.processInfo.systemUptime)};
}
static void ResetDynamic(void) {
    ResetForApplication(@"com.example.sceneapp");
    requestedCapability = DynamicCapability(originalApplication);
}
static void SourceUnchanged(void) {
    OwnedFixtureScene *scene = sourceScene;
    OwnedFixtureDefinition *definition = scene.definition;
    Check(scene.valid && [scene.identifier isEqual:@"system.source.safari"] &&
          [scene.workspaceIdentifier isEqual:@"system.main.workspace"] && sourceInvalidations == 0 &&
          [[definition.clientIdentity bundleIdentifier] isEqual:originalApplication] &&
          [[definition.specification uiSceneSessionRole] isEqual:@"UIWindowSceneSessionRoleApplication"],
          "borrowed source scene is never modified or invalidated");
    Check(unsafeWorkspaceInvalidations == 0, "workspace is never invalidated while populated");
}
static void CompleteDeferredCleanup(void) {
    OwnedFixtureController *controller = lastController;
    Check(controller != nil, "pending controller is retained");
    [controller.createdScene invalidate];
    OwnedFixtureWorkspace *workspace = controller.configuration.sceneWorkspace;
    [workspace.scenes removeObjectIdenticalTo:controller.createdScene];
}
int main(void) {
    @autoreleasepool {
        Reset();
        Check(Prepare(sourceScene), "creates one independently owned scene");
        Check(current.viewController != nil && current.hostedScene != sourceScene && !current.poisoned,
              "owned view and distinct scene exposed after complete validation");
        Check(componentReads == 1 && hostSceneReads == 1 && proxySceneReads == 1,
              "component binding is read once and the exact known proxy is unwrapped once");
        id componentScene = [(OwnedFixtureComponent *)lastController.component hostScene];
        Check(componentScene != current.hostedScene &&
              [componentScene class] == OwnedFixtureScene.class &&
              [componentScene isKindOfClass:OwnedFixtureScene.class] &&
              object_getClass(componentScene) == OwnedFixtureComponentScene.class,
              "known NSProxy masquerades as FBScene without raw pointer identity");
        NSDictionary *binding = current.snapshot[@"componentBinding"];
        Check([binding[@"status"] isEqual:@"verified-proxy"] &&
              [binding[@"componentPresent"] boolValue] && [binding[@"expectedComponentClass"] boolValue] &&
              [binding[@"hostScenePresent"] boolValue] && [binding[@"proxyClassMatched"] boolValue] &&
              [binding[@"matchesCreatedScene"] boolValue] && ![binding[@"matchesBorrowedSource"] boolValue],
              "binding metadata records verified proxy ownership without publishing objects");
        unsigned bindingReads = componentReads + hostSceneReads + proxySceneReads;
        Check([current.snapshot[@"componentBinding"] isEqual:binding] &&
              componentReads + hostSceneReads + proxySceneReads == bindingReads,
              "snapshot publishes captured metadata without calling private getters again");
        Check([[current sampleState][@"status"] isEqual:@"sampled"] &&
              [current.snapshot[@"controllerVerified"] boolValue],
              "only completely verified scene ownership is sampled");
        Check(!Prepare(sourceScene) && constructors == 1, "one acquisition attempt per adapter");
        SourceUnchanged();
        Check([current close] && current.closed && controllerInvalidations == 1 && workspaceInvalidations == 1,
              "own controller invalidated then empty workspace released");
        Check([current close] && controllerInvalidations == 1 && workspaceInvalidations == 1,
              "confirmed cleanup is idempotent");
        SourceUnchanged();

        Reset(); directComponentScene = YES;
        Check(Prepare(sourceScene) && proxySceneReads == 0,
              "direct raw owned-scene identity remains accepted without proxy access");
        binding = current.snapshot[@"componentBinding"];
        Check([binding[@"status"] isEqual:@"verified-direct"] &&
              ![binding[@"proxyClassMatched"] boolValue] && [binding[@"matchesCreatedScene"] boolValue] &&
              ![binding[@"matchesBorrowedSource"] boolValue],
              "direct binding reports raw scene ownership independently of proxy support");
        Check([current close], "direct identity fixture cleans only its own scene");
        SourceUnchanged();

        NSArray<NSString *> *bindingFailures = @[@"unused", @"component-missing", @"component-class-mismatch",
            @"host-scene-missing", @"unknown-host-scene-class", @"unknown-host-scene-class",
            @"host-scene-foreign", @"host-scene-foreign", @"host-scene-foreign", @"reading-proxy-scene",
            @"not-read", @"reading-component", @"reading-host-scene", @"unknown-host-scene-class"];
        for (unsigned failure = 1; failure <= 13; failure++) {
            Reset(); componentFault = failure;
            current = [[PPOOwnedSceneHost alloc] initWithClasses:Classes()];
            Check(!Prepare(sourceScene), "uncertain component binding refuses presentation");
            binding = current.snapshot[@"componentBinding"];
            Check([binding[@"status"] isEqual:bindingFailures[failure]],
                  "captured binding metadata distinguishes missing, foreign, proxy and throwing getters");
            Check(current.viewController == nil && current.hostedScene == nil &&
                  controllerInvalidations == 0 && workspaceInvalidations == 0,
                  "unverified component binding exposes no view and performs no private cleanup");
            if (failure == 10) {
                Check(constructors == 0 && proxySceneReads == 0 && current.closed && !current.poisoned,
                      "wrong-return ABI on exact injected proxy is rejected before framework construction");
            } else {
                Check(constructors == 1 && current.poisoned && !current.closed &&
                      lastController != nil && lastWorkspace != nil && controllerDeallocations == 0,
                      "uncertain component ownership retains private allocations in quarantine");
                Check(![current close] && ![current pollCleanup] && !Prepare(sourceScene) &&
                      controllerInvalidations == 0 && workspaceInvalidations == 0 && constructors == 1,
                      "quarantine blocks automatic retries and destructive cleanup");
            }
            if (failure == 1 || failure == 2)
                Check(hostSceneReads == 0 && proxySceneReads == 0,
                      "missing or wrong component is never asked for a host scene");
            if (failure == 5 || failure == 13)
                Check(proxySceneReads == 0 && unknownProxySceneReads == 0,
                      "unknown masquerading proxy or subclass is rejected before its scene getter");
            if (failure == 6 || failure == 7 || failure == 8) {
                Check([binding[@"matchesCreatedScene"] isEqual:@NO] &&
                      [binding[@"matchesBorrowedSource"] isEqual:@(failure == 7)],
                      "known proxy nil, borrowed and foreign targets cannot claim created ownership");
            }
            if (failure == 1 || failure == 2 || failure == 3 || failure == 5 || failure >= 9)
                Check(binding[@"matchesCreatedScene"] == NSNull.null,
                      "unread target comparison remains unknown instead of falsely confirmed");
            bindingReads = componentReads + hostSceneReads + proxySceneReads + unknownProxySceneReads;
            Check([current.snapshot[@"componentBinding"] isEqual:binding] &&
                  componentReads + hostSceneReads + proxySceneReads + unknownProxySceneReads == bindingReads,
                  "failed binding snapshots never retry any private getter");
            SourceUnchanged();
        }

        Reset(); delayedCleanup = YES;
        Check(Prepare(sourceScene), "pending-cleanup fixture prepares");
        Check(![current close] && !current.closed && controllerInvalidations == 1 && workspaceInvalidations == 0,
              "pending scene teardown retains populated workspace");
        Check(![current pollCleanup] && controllerInvalidations == 1 && lastWorkspace != nil,
              "pending polls do not invalidate controller or workspace again");
        CompleteDeferredCleanup();
        Check([current pollCleanup] && current.closed && workspaceInvalidations == 1,
              "later invalid-scene and empty-workspace confirmation permits cleanup");
        SourceUnchanged();

        Reset(); delayedCleanup = YES;
        Check(Prepare(sourceScene) && ![current close], "timeout fixture reaches pending cleanup");
        [current quarantineCleanup];
        Check(current.poisoned && !current.closed && workspaceInvalidations == 0,
              "timed-out cleanup is quarantined without workspace invalidation");
        Check(![current pollCleanup] && controllerInvalidations == 1,
              "quarantine is never retried automatically");
        SourceUnchanged();

        for (unsigned failure = 0; failure < 11; failure++) {
            Reset();
            badWorkspaceIdentity = failure == 0; prepopulatedWorkspace = failure == 1;
            aliasSource = failure == 2; wrongNewIdentity = failure == 3; wrongNewWorkspace = failure == 4;
            badComponentScene = failure == 5; badControllerView = failure == 6;
            unexpectedNewActive = failure == 7;
            badNewDefinition = failure == 8; badNewClientIdentity = failure == 9; badNewRole = failure == 10;
            Check(!Prepare(sourceScene), "identity/source/component/view mismatch refuses host");
            SourceUnchanged();
            if (failure == 1 || failure == 2 || failure == 3 || failure == 4 || failure == 5 || failure >= 8)
                Check(workspaceInvalidations == 0 && controllerInvalidations == 0,
                      "unverified namespace is retained without destructive cleanup");
            if (failure == 6 || failure == 7)
                Check(controllerInvalidations == 1 && workspaceInvalidations == 1 && current.closed && !current.poisoned,
                      "known-owned invalid view or unexpectedly active child is cleaned without presentation");
        }
        for (unsigned failure = 0; failure < 3; failure++) {
            Reset();
            throwControllerInit = failure == 0; nilControllerInit = failure == 1; foreignControllerInit = failure == 2;
            Check(!Prepare(sourceScene) && current.poisoned,
                  "partial/nil/replaced constructor result quarantines ownership");
            Check(controllerInvalidations == 0 && workspaceInvalidations == 0,
                  "uncertain constructor does not invalidate namespace or foreign result");
            Check(lastController != nil, "original allocated receiver remains retained in quarantine");
            SourceUnchanged();
        }
        for (unsigned constructor = 0; constructor < 2; constructor++) {
            for (unsigned failure = 1; failure <= 3; failure++) {
                Reset();
                if (constructor == 0) workspaceConstructorFault = failure;
                else configurationConstructorFault = failure;
                Check(!Prepare(sourceScene) && current.poisoned && constructors == 0,
                      "workspace/configuration partial initialization quarantines before controller construction");
                Check(workspaceInvalidations == 0 && controllerInvalidations == 0,
                      "unverified initialization keeps namespace untouched");
                Check(constructor == 0 ? lastWorkspace != nil : lastConfiguration != nil,
                      "original workspace/configuration receiver remains retained in quarantine");
                SourceUnchanged();
            }
        }
        for (unsigned failure = 0; failure < 3; failure++) {
            Reset();
            if (failure == 0) wrongConfigIdentifier = YES;
            else if (failure == 1) {
                foreignWorkspace = [[OwnedFixtureWorkspace alloc] initWithIdentifier:@"system.foreign.workspace"];
                [foreignWorkspace.scenes addObject:sourceScene];
                wrongConfigWorkspace = YES;
            } else wrongConfigClientIdentity = YES;
            Check(!Prepare(sourceScene) && constructors == 0,
                  "configuration readback mismatch refuses before controller construction");
            SourceUnchanged();
        }
        Reset();
        NSMutableDictionary *invalidClasses = [Classes() mutableCopy];
        invalidClasses[@"FBScene"] = @1;
        current = [[PPOOwnedSceneHost alloc] initWithClasses:invalidClasses];
        Check(!Prepare(sourceScene) && constructors == 0,
              "non-Class dependency rejected without framework construction");
        SourceUnchanged();
        for (unsigned failure = 0; failure < 2; failure++) {
            Reset();
            NSMutableDictionary *classes = [Classes() mutableCopy];
            classes[@"FBSceneWorkspace"] = failure ? OwnedBadWorkspace.class : OwnedMissingClass.class;
            current = [[PPOOwnedSceneHost alloc] initWithClasses:classes];
            Check(!Prepare(sourceScene) && constructors == 0 && resolutions == 0,
                  "missing/wrong constructor ABI rejected without resolution or controller creation");
            SourceUnchanged();
        }
        Reset();
        OwnedFixtureDefinition *definition = [sourceScene definition];
        [(OwnedFixtureClient *)definition.clientIdentity setBundleIdentifier:@"com.example.unlisted"];
        Check(!Prepare(sourceScene) && constructors == 0, "source identifier must match the selected expected app");
        Reset();
        definition = [sourceScene definition];
        [(OwnedFixtureSpecification *)definition.specification setUiSceneSessionRole:@"unverified-role"];
        Check(!Prepare(sourceScene) && constructors == 0, "unverified scene role refused");
        Reset();
        Check(!Prepare(nil) && constructors == 0 && current.closed,
              "nil source refuses without creating framework resources");
        SourceUnchanged();
        Reset();
        Check(!Prepare(@"wrong-source") && constructors == 0 && current.closed,
              "unexpected source receiver refuses before private dispatch");
        SourceUnchanged();
        Reset();
        [(OwnedFixtureScene *)sourceScene setValid:false];
        Check(!Prepare(sourceScene) && constructors == 0 && current.closed,
              "invalid source cannot create an owned scene");
        [(OwnedFixtureScene *)sourceScene setValid:true];
        SourceUnchanged();

        Reset(); reenter = YES;
        Check(Prepare(sourceScene) && constructors == 1, "constructor reentry cannot disrupt outer ownership");
        Check([current close], "reentry fixture closes"); SourceUnchanged();
        for (unsigned failure = 0; failure < 2; failure++) {
            Reset(); Check(Prepare(sourceScene), "cleanup-failure fixture prepares");
            throwControllerInvalidate = failure == 0;
            failControllerInvalidate = failure == 1;
            Check(![current close] && controllerInvalidations == 1 && workspaceInvalidations == 0,
                  "throwing or incomplete controller cleanup preserves populated workspace");
            if (failure == 0) Check(current.poisoned, "cleanup exception quarantines without retry");
            else [current quarantineCleanup];
            Check(![current close] && ![current pollCleanup] && controllerInvalidations == 1,
                  "unknown cleanup never repeats private invalidation");
            SourceUnchanged();
        }
        for (unsigned failure = 0; failure < 2; failure++) {
            Reset(); Check(Prepare(sourceScene), "workspace-cleanup failure fixture prepares");
            throwWorkspaceInvalidate = failure == 0;
            invalidWorkspaceList = failure == 1;
            Check(![current close] && current.poisoned && controllerInvalidations == 1,
                  "workspace invalidation exception or malformed list quarantines cleanup");
            unsigned attempts = workspaceInvalidations;
            Check(![current close] && ![current pollCleanup] && workspaceInvalidations == attempts &&
                  controllerInvalidations == 1, "unknown workspace cleanup is never repeated");
            SourceUnchanged();
        }
        Reset();
        __block BOOL worker = YES;
        dispatch_group_t group = dispatch_group_create();
        dispatch_group_async(group, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
            worker = Prepare(sourceScene);
            Check(![current close] && ![current pollCleanup] &&
                  [[current sampleState][@"status"] isEqual:@"wrong-thread"],
                  "wrong-thread cleanup and sampling are rejected");
            [current quarantineCleanup];
        });
        Check(dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 5)) == 0,
              "wrong-thread fixture completes");
        Check(!worker && !current.poisoned && constructors == 0 && controllerInvalidations == 0 && workspaceInvalidations == 0,
              "worker cannot acquire or mutate framework objects");
        Check(Prepare(sourceScene) && [current close], "worker rejection preserves valid main-thread attempt");
        SourceUnchanged();
        NSArray<NSString *> *eligible = @[@"com.apple.mobilesafari", @"com.apple.reminders", @"com.apple.MobileAddressBook"];
        for (NSString *application in eligible) {
            ResetForApplication(application);
            Check(PPOOwnedApplicationAllowed(application) && Prepare(sourceScene),
                  "each declared target preserves verified namespace and proxy binding");
            Check([current.snapshot[@"expectedBundleIdentifier"] isEqual:application],
                  "ownership proof retains the exact requested application");
            Check([current close] && current.closed && controllerInvalidations == 1 && workspaceInvalidations == 1,
                  "each eligible target cleans only its owned scene and empty workspace");
            SourceUnchanged();
            for (NSString *other in eligible) {
                if ([other isEqual:application]) continue;
                ResetForApplication(application); requestedApplication = other;
                Check(!Prepare(sourceScene) && workspaceConstructions == 0 && constructors == 0 && current.closed,
                      "an allowed but different selected app cannot borrow this source identity");
                SourceUnchanged();
                ResetForApplication(application); childIdentifierOverride = other;
                Check(!Prepare(sourceScene) && current.poisoned && !current.closed &&
                      controllerInvalidations == 0 && workspaceInvalidations == 0,
                      "an allowed but different returned child is quarantined without invalidation");
                SourceUnchanged();
            }
        }
        NSArray *ineligible = @[@"com.apple.Preferences", @"com.apple.springboard", @"com.apple.backboardd",
            @"com.example.unlisted", @"com.apple.reminders.extension", @"COM.APPLE.REMINDERS",
            @"com.apple.mobileaddressbook", @"", @1, NSNull.null];
        for (id application in ineligible) {
            Reset(); requestedApplication = application;
            Check(!PPOOwnedApplicationAllowed(application) && !Prepare(sourceScene) && current.closed &&
                  !current.poisoned && constructors == 0 && workspaceConstructions == 0 && sourceProbes == 0,
                  "unsupported or malformed requests are rejected before private source access or construction");
            SourceUnchanged();
        }
        Reset(); requestedApplication = nil;
        Check(!Prepare(sourceScene) && current.closed && workspaceConstructions == 0 && sourceProbes == 0,
              "nil requested identifier is rejected before touching a source");
        SourceUnchanged();
        Reset();
        NSMutableString *mutableRequest = [@"com.apple.mobilesafari" mutableCopy];
        requestedApplication = mutableRequest; callerIdentifierMutation = mutableRequest;
        Check(Prepare(sourceScene) && [mutableRequest isEqual:@"com.apple.MobileAddressBook"] &&
              [current.snapshot[@"expectedBundleIdentifier"] isEqual:@"com.apple.mobilesafari"],
              "caller mutation during private construction cannot change the copied expected identity");
        Check([current close], "copied identity fixture cleans its known Safari scene");
        SourceUnchanged();
        ResetDynamic();
        Check(Prepare(sourceScene) && [current.snapshot[@"admission"][@"basis"] isEqual:@"installed-info"] &&
              [current.snapshot[@"expectedBundleIdentifier"] isEqual:originalApplication],
              "a fresh bound capability admits a dynamic app under the same ownership proof");
        Check([current close] && current.closed && controllerInvalidations == 1 && workspaceInvalidations == 1,
              "dynamic scene releases only its verified controller and empty workspace");
        SourceUnchanged();
        for (unsigned failure = 0; failure < 5; failure++) {
            ResetDynamic();
            if (failure == 0) requestedCapability = nil;
            else if (failure == 1) requestedCapability = DynamicCapability(@"com.example.other");
            else if (failure == 2) requestedCapability = DynamicCapability(originalApplication, @"ineligible");
            else if (failure == 3) requestedCapability = DynamicCapability(originalApplication, @"unknown");
            else {
                NSMutableDictionary *stale = [requestedCapability mutableCopy];
                stale[@"observedUptime"] = @(NSProcessInfo.processInfo.systemUptime - 10);
                requestedCapability = stale;
            }
            Check(!Prepare(sourceScene) && current.closed && !current.poisoned && constructors == 0 &&
                  workspaceConstructions == 0 && sourceProbes == 0,
                  "missing, cross-app, negative, unknown and stale metadata refuse before private work");
            SourceUnchanged();
        }
        ResetForApplication(@"com.apple.reminders");
        requestedCapability = DynamicCapability(originalApplication, @"ineligible");
        Check(!Prepare(sourceScene) && current.closed && workspaceConstructions == 0 && sourceProbes == 0,
              "fresh explicit negative metadata overrides baseline admission before touching source");
        SourceUnchanged();
        ResetDynamic();
        OwnedFixtureDefinition *dynamicDefinition = [sourceScene definition];
        OwnedFixtureSpecification *custom = [OwnedFixtureSpecificationSubclass new];
        custom.uiSceneSessionRole = @"UIWindowSceneSessionRoleApplication";
        dynamicDefinition.specification = custom;
        Check(!Prepare(sourceScene) && current.closed && !current.poisoned && workspaceConstructions == 0 &&
              customSpecificationReads == 0,
              "dynamic source specification subclasses are rejected before their getters or construction");
        SourceUnchanged();
        ResetDynamic(); childSpecificationSubclass = YES;
        Check(!Prepare(sourceScene) && current.poisoned && !current.closed &&
              controllerInvalidations == 0 && workspaceInvalidations == 0 && current.viewController == nil &&
              customSpecificationReads == 0,
              "dynamic child specification subclass is quarantined before getters or unverified cleanup");
        SourceUnchanged();
        ResetForApplication(@"com.apple.reminders");
        dynamicDefinition = [sourceScene definition];
        custom = [OwnedFixtureSpecificationSubclass new];
        custom.uiSceneSessionRole = @"UIWindowSceneSessionRoleApplication";
        dynamicDefinition.specification = custom;
        Check(Prepare(sourceScene) && [current close],
              "existing baseline retains its previously validated kind-of-class specification behavior");
        SourceUnchanged();
        ResetDynamic();
        callerCapabilityMutation = [requestedCapability mutableCopy];
        callerCapabilityMutation[@"bundleIdentifier"] = [originalApplication mutableCopy];
        callerCapabilityMutation[@"status"] = [@"eligible" mutableCopy];
        requestedCapability = callerCapabilityMutation;
        Check(Prepare(sourceScene) && [callerCapabilityMutation[@"bundleIdentifier"] isEqual:@"com.example.other"] &&
              [current.snapshot[@"admission"][@"sceneCapability"][@"bundleIdentifier"] isEqual:originalApplication] &&
              [current.snapshot[@"admission"][@"sceneCapability"][@"status"] isEqual:@"eligible"],
              "caller mutation during construction cannot redirect or revoke the frozen admission descriptor");
        Check([current close], "frozen dynamic descriptor cleans its known owned scene");
        SourceUnchanged();
        for (unsigned cycle = 0; cycle < 100; cycle++) {
            @autoreleasepool {
                NSArray *targets = @[@"com.apple.mobilesafari", @"com.apple.reminders", @"com.apple.MobileAddressBook"];
                if (cycle % 4 == 3) ResetDynamic();
                else ResetForApplication(targets[cycle % targets.count]);
                Check(Prepare(sourceScene), "mixed targets each create a distinct owned scene");
                Check([current close] && current.closed && controllerInvalidations == 1 && workspaceInvalidations == 1,
                      "repeat releases only owned namespace after empty confirmation");
                SourceUnchanged();
            }
        }
        printf("Owned scene host tests passed: %u checks; native fixtures, not iOS scene hosting\n", checks);
    }
    return 0;
}
