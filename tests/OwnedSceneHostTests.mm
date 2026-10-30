#import "../PPOOwnedSceneHost.h"
#import <dispatch/dispatch.h>
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
static PPOOwnedSceneHost *current;
static id sourceScene;
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
- (bool)isValid { return self.valid; }
- (bool)isActive { return self.active; }
- (void)invalidate {
    if (self == sourceScene) sourceInvalidations++;
    self.valid = false;
    self.active = false;
}
@end
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
@implementation OwnedFixtureComponent @end
@interface OwnedFixtureViewController : NSObject @end
@implementation OwnedFixtureViewController @end
@interface OwnedFixtureController : NSObject
@property(nonatomic,strong) OwnedFixtureConfiguration *configuration;
@property(nonatomic,strong) OwnedFixtureScene *createdScene;
@property(nonatomic,strong) OwnedFixtureComponent *component;
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
            if (badNewClientIdentity) {
                OwnedFixtureClient *other = [OwnedFixtureClient new]; other.bundleIdentifier = @"com.example.foreign";
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
        _component = [OwnedFixtureComponent new]; _component.hostScene = badComponentScene ? sourceScene : _createdScene;
        _view = badControllerView ? (id)@"bad-view" : [OwnedFixtureViewController new];
        if (reenter) {
            reenter = NO;
            Check(![current close], "constructor reentry cannot close partial acquisition");
            Check(![current prepareScene:sourceScene], "constructor reentry cannot acquire twice");
            Check([[current sampleState][@"status"] isEqual:@"busy"],
                  "constructor reentry cannot sample a partially owned scene");
        }
    }
    return self;
}
- (id)activationStateComponent { return self.component; }
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
static void SourceUnchanged(void) {
    OwnedFixtureScene *scene = sourceScene;
    OwnedFixtureDefinition *definition = scene.definition;
    Check(scene.valid && [scene.identifier isEqual:@"system.source.safari"] &&
          [scene.workspaceIdentifier isEqual:@"system.main.workspace"] && sourceInvalidations == 0 &&
          [[definition.clientIdentity bundleIdentifier] isEqual:@"com.apple.mobilesafari"] &&
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
        Check([current prepareScene:sourceScene], "creates one independently owned scene");
        Check(current.viewController != nil && current.hostedScene != sourceScene && !current.poisoned,
              "owned view and distinct scene exposed after complete validation");
        Check([[current sampleState][@"status"] isEqual:@"sampled"] &&
              [current.snapshot[@"controllerVerified"] boolValue],
              "only completely verified scene ownership is sampled");
        Check(![current prepareScene:sourceScene] && constructors == 1, "one acquisition attempt per adapter");
        SourceUnchanged();
        Check([current close] && current.closed && controllerInvalidations == 1 && workspaceInvalidations == 1,
              "own controller invalidated then empty workspace released");
        Check([current close] && controllerInvalidations == 1 && workspaceInvalidations == 1,
              "confirmed cleanup is idempotent");
        SourceUnchanged();

        Reset(); delayedCleanup = YES;
        Check([current prepareScene:sourceScene], "pending-cleanup fixture prepares");
        Check(![current close] && !current.closed && controllerInvalidations == 1 && workspaceInvalidations == 0,
              "pending scene teardown retains populated workspace");
        Check(![current pollCleanup] && controllerInvalidations == 1 && lastWorkspace != nil,
              "pending polls do not invalidate controller or workspace again");
        CompleteDeferredCleanup();
        Check([current pollCleanup] && current.closed && workspaceInvalidations == 1,
              "later invalid-scene and empty-workspace confirmation permits cleanup");
        SourceUnchanged();

        Reset(); delayedCleanup = YES;
        Check([current prepareScene:sourceScene] && ![current close], "timeout fixture reaches pending cleanup");
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
            Check(![current prepareScene:sourceScene], "identity/source/component/view mismatch refuses host");
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
            Check(![current prepareScene:sourceScene] && current.poisoned,
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
                Check(![current prepareScene:sourceScene] && current.poisoned && constructors == 0,
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
            Check(![current prepareScene:sourceScene] && constructors == 0,
                  "configuration readback mismatch refuses before controller construction");
            SourceUnchanged();
        }
        Reset();
        NSMutableDictionary *invalidClasses = [Classes() mutableCopy];
        invalidClasses[@"FBScene"] = @1;
        current = [[PPOOwnedSceneHost alloc] initWithClasses:invalidClasses];
        Check(![current prepareScene:sourceScene] && constructors == 0,
              "non-Class dependency rejected without framework construction");
        SourceUnchanged();
        for (unsigned failure = 0; failure < 2; failure++) {
            Reset();
            NSMutableDictionary *classes = [Classes() mutableCopy];
            classes[@"FBSceneWorkspace"] = failure ? OwnedBadWorkspace.class : OwnedMissingClass.class;
            current = [[PPOOwnedSceneHost alloc] initWithClasses:classes];
            Check(![current prepareScene:sourceScene] && constructors == 0 && resolutions == 0,
                  "missing/wrong constructor ABI rejected without resolution or controller creation");
            SourceUnchanged();
        }
        Reset();
        OwnedFixtureDefinition *definition = [sourceScene definition];
        [(OwnedFixtureClient *)definition.clientIdentity setBundleIdentifier:@"com.example.unlisted"];
        Check(![current prepareScene:sourceScene] && constructors == 0, "non-Safari source refused");
        Reset();
        definition = [sourceScene definition];
        [(OwnedFixtureSpecification *)definition.specification setUiSceneSessionRole:@"unverified-role"];
        Check(![current prepareScene:sourceScene] && constructors == 0, "unverified scene role refused");
        Reset();
        Check(![current prepareScene:nil] && constructors == 0 && current.closed,
              "nil source refuses without creating framework resources");
        SourceUnchanged();
        Reset();
        Check(![current prepareScene:@"wrong-source"] && constructors == 0 && current.closed,
              "unexpected source receiver refuses before private dispatch");
        SourceUnchanged();
        Reset();
        [(OwnedFixtureScene *)sourceScene setValid:false];
        Check(![current prepareScene:sourceScene] && constructors == 0 && current.closed,
              "invalid source cannot create an owned scene");
        [(OwnedFixtureScene *)sourceScene setValid:true];
        SourceUnchanged();

        Reset(); reenter = YES;
        Check([current prepareScene:sourceScene] && constructors == 1, "constructor reentry cannot disrupt outer ownership");
        Check([current close], "reentry fixture closes"); SourceUnchanged();
        for (unsigned failure = 0; failure < 2; failure++) {
            Reset(); Check([current prepareScene:sourceScene], "cleanup-failure fixture prepares");
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
            Reset(); Check([current prepareScene:sourceScene], "workspace-cleanup failure fixture prepares");
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
            worker = [current prepareScene:sourceScene];
            Check(![current close] && ![current pollCleanup] &&
                  [[current sampleState][@"status"] isEqual:@"wrong-thread"],
                  "wrong-thread cleanup and sampling are rejected");
            [current quarantineCleanup];
        });
        Check(dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 5)) == 0,
              "wrong-thread fixture completes");
        Check(!worker && !current.poisoned && constructors == 0 && controllerInvalidations == 0 && workspaceInvalidations == 0,
              "worker cannot acquire or mutate framework objects");
        Check([current prepareScene:sourceScene] && [current close], "worker rejection preserves valid main-thread attempt");
        SourceUnchanged();
        for (unsigned cycle = 0; cycle < 100; cycle++) {
            @autoreleasepool {
                Reset(); Check([current prepareScene:sourceScene], "repeat creates distinct owned scene");
                Check([current close] && current.closed && controllerInvalidations == 1 && workspaceInvalidations == 1,
                      "repeat releases only owned namespace after empty confirmation");
                SourceUnchanged();
            }
        }
        printf("Owned scene host tests passed: %u checks; native fixtures, not iOS scene hosting\n", checks);
    }
    return 0;
}
