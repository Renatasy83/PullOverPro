#import "../PPOScenePreflight.h"
#import <dispatch/dispatch.h>
#include <stdio.h>
#include <stdlib.h>

static NSArray *fixtureScenes;
static NSUInteger factoryCalls, enumerationCalls;
static BOOL throwEnumeration, nullStop;
static NSUInteger resolutionCalls;
static void Check(BOOL condition, const char *message) {
    if (!condition) { fprintf(stderr, "FAIL: %s\n", message); exit(1); }
}

@interface PPOFixtureIdentity : NSObject
@property(nonatomic,copy) NSString *bundleIdentifier;
@end
@implementation PPOFixtureIdentity
@end
@interface PPOFixtureDefinition : NSObject
@property(nonatomic,strong) id clientIdentity;
@end
@implementation PPOFixtureDefinition
@end
@interface PPOFixtureScene : NSObject
@property(nonatomic,strong) id clientHandle;
@property(nonatomic,strong) id definition;
@property(nonatomic,copy) NSString *identifier;
@end
@implementation PPOFixtureScene
@end
@interface PPOFixtureManager : NSObject
+ (id)sharedInstance;
- (void)enumerateScenesWithBlock:(void (^)(id, BOOL *))visit;
@end
@implementation PPOFixtureManager
+ (id)sharedInstance { factoryCalls++; return [self new]; }
- (void)enumerateScenesWithBlock:(void (^)(id, BOOL *))visit {
    enumerationCalls++;
    if (throwEnumeration) [NSException raise:@"FixtureException" format:@"fixture"];
    BOOL stop = NO;
    for (id scene in fixtureScenes) {
        visit(scene, nullStop ? NULL : &stop);
        if (stop) break;
    }
}
@end

@interface PPOBadFactory : PPOFixtureManager
@end
@implementation PPOBadFactory
+ (id)sharedInstance { factoryCalls++; return @"wrong receiver"; }
@end
@interface PPOBadEnumerator : NSObject
+ (id)sharedInstance;
- (void)enumerateScenesWithBlock:(int)value;
@end
@implementation PPOBadEnumerator
+ (id)sharedInstance { factoryCalls++; return [self new]; }
- (void)enumerateScenesWithBlock:(int)value { (void)value; enumerationCalls++; }
@end
@interface PPOBadIdentity : NSObject
- (int)bundleIdentifier;
@end
@implementation PPOBadIdentity
- (int)bundleIdentifier { abort(); }
@end

@interface PPOMissingIdentity : NSObject
+ (BOOL)resolveInstanceMethod:(SEL)selector;
@end
@implementation PPOMissingIdentity
+ (BOOL)resolveInstanceMethod:(SEL)selector { (void)selector; resolutionCalls++; return NO; }
@end

static PPOFixtureScene *Scene(NSString *bundle, NSString *definitionBundle, NSString *identifier) {
    PPOFixtureIdentity *handle = [PPOFixtureIdentity new]; handle.bundleIdentifier = bundle;
    PPOFixtureIdentity *identity = [PPOFixtureIdentity new]; identity.bundleIdentifier = definitionBundle;
    PPOFixtureDefinition *definition = [PPOFixtureDefinition new]; definition.clientIdentity = identity;
    PPOFixtureScene *scene = [PPOFixtureScene new];
    scene.clientHandle = handle; scene.definition = definition; scene.identifier = identifier;
    return scene;
}
static NSDictionary *Run(Class manager = PPOFixtureManager.class) {
    return PPOReadSceneSelection(manager, PPOFixtureScene.class, @"com.apple.mobilesafari");
}
static void State(NSString *state) {
    NSDictionary *report = Run();
    Check([report[@"state"] isEqual:state], state.UTF8String);
    Check(![report[@"hostingRequested"] boolValue], "no hosting is requested");
    if (![state isEqual:@"unique"]) Check(report[@"sceneIdentifier"] == nil, "no first-match fallback");
}

int main(void) {
    @autoreleasepool {
        NSString *safari = @"com.apple.mobilesafari";
        fixtureScenes = @[]; State(@"not-found");
        fixtureScenes = @[Scene(@"com.apple.mobilesafari.extra", safari, @"suffix")]; State(@"not-found");
        fixtureScenes = @[Scene(@"other.app", @"other.app", @"unrelated"), Scene(safari, safari, @"exact")];
        NSDictionary *result = Run();
        Check([result[@"state"] isEqual:@"unique"] && [result[@"sceneIdentifier"] isEqual:@"exact"] &&
            [result[@"matched"] isEqual:@1], "exact identity across both chains");
        id selectedScene = nil;
        NSDictionary *lookup = PPOFindUniqueScene(PPOFixtureManager.class, PPOFixtureScene.class, safari, &selectedScene);
        Check([lookup[@"state"] isEqual:@"unique"] && selectedScene == fixtureScenes[1],
            "unique lookup returns exact instance after enumeration");
        fixtureScenes = @[Scene(@"com.apple.Preferences", @"com.apple.Preferences", @"settings")];
        NSDictionary *settings = PPOFindUniqueScene(PPOFixtureManager.class, PPOFixtureScene.class,
            @"com.apple.Preferences", &selectedScene);
        Check([settings[@"state"] isEqual:@"unique"] && selectedScene == fixtureScenes[0],
            "Settings uses the same exact dual-identity lookup");
        fixtureScenes = @[Scene(safari, safari, @"A"), Scene(safari, safari, @"B")]; State(@"ambiguous");
        PPOFindUniqueScene(PPOFixtureManager.class, PPOFixtureScene.class, safari, &selectedScene);
        Check(selectedScene == nil, "ambiguous lookup clears prior reference");
        PPOFixtureScene *same = Scene(safari, safari, @"A");
        fixtureScenes = @[same, same]; State(@"ambiguous");
        fixtureScenes = @[Scene(safari, @"other.app", @"conflict")]; State(@"conflicting-identity");
        fixtureScenes = @[Scene(safari, safari, nil)]; State(@"conflicting-identity");
        PPOFixtureScene *system = [PPOFixtureScene new];
        fixtureScenes = @[system, Scene(safari, safari, @"after-system")]; State(@"unique");
        PPOFixtureScene *bad = Scene(safari, safari, @"bad"); bad.clientHandle = [PPOBadIdentity new];
        fixtureScenes = @[bad]; State(@"unsupported-identity");
        bad.clientHandle = [PPOMissingIdentity new];
        resolutionCalls = 0;
        State(@"unsupported-identity");
        Check(resolutionCalls == 0, "missing getter does not invoke dynamic method resolution");
        fixtureScenes = @[@"not a scene"]; State(@"unexpected-scene");
        fixtureScenes = @[Scene(safari, safari, @"exact")];
        nullStop = YES; State(@"invalid-callback"); nullStop = NO;
        throwEnumeration = YES; State(@"scene-exception"); throwEnumeration = NO;
        NSMutableArray *many = [NSMutableArray array];
        for (NSUInteger i = 0; i < 300; i++) [many addObject:system];
        fixtureScenes = many;
        result = Run();
        Check([result[@"state"] isEqual:@"enumeration-limit"] &&
            [result[@"inspected"] unsignedIntegerValue] <= 256, "bounded callback work");
        factoryCalls = enumerationCalls = 0;
        result = Run(PPOBadEnumerator.class);
        Check([result[@"state"] isEqual:@"unsupported-abi"] && factoryCalls == 0 &&
            enumerationCalls == 0, "bad callback ABI rejected before getter call");
        result = Run(PPOBadFactory.class);
        Check([result[@"state"] isEqual:@"unsupported-manager"] && enumerationCalls == 0,
            "factory result checked before enumeration");
        result = PPOReadSceneSelection(PPOFixtureManager.class, PPOFixtureScene.class, @"com.apple.springboard");
        Check([result[@"state"] isEqual:@"invalid-application"], "restricted target rejected");
        dispatch_group_t group = dispatch_group_create();
        __block NSDictionary *worker = nil;
        NSUInteger before = factoryCalls;
        dispatch_group_async(group, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
            worker = Run();
        });
        Check(dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC)) == 0,
            "background guard is immediate");
        Check([worker[@"state"] isEqual:@"wrong-thread"] && factoryCalls == before,
            "no private getter calls from worker");
        NSDictionary *fingerprints = PPOSceneFrameworkIdentity();
        Check(![fingerprints[@"matches"] boolValue], "macOS fixtures cannot impersonate device frameworks");
        result = PPOScenePreflight(safari);
        Check([result[@"selection"][@"state"] isEqual:@"framework-mismatch"],
            "wrong framework prevents production lookup");
        printf("Scene preflight tests passed; native fixtures only, no private iOS methods called\n");
    }
    return 0;
}
