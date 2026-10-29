#import "../PPOSceneLayerProbe.h"
#import <dispatch/dispatch.h>
#include <stdio.h>
#include <stdlib.h>

static unsigned checks, calls, resolutions;
static BOOL throws;
static void Check(BOOL value, const char *message) {
    checks++;
    if (!value) { fprintf(stderr, "FAIL: %s\n", message); exit(1); }
}
@interface ProbeFixtureSettings : NSObject
@property(nonatomic) bool backgrounded;
- (bool)isBackgrounded;
@end
@implementation ProbeFixtureSettings
- (bool)isBackgrounded { calls++; return self.backgrounded; }
@end
@interface ProbeFixtureLayer : NSObject
@property(nonatomic) long long type;
@end
@implementation ProbeFixtureLayer
@end
@interface ProbeFixtureManager : NSObject
@property(nonatomic,strong) id layers;
@end
@implementation ProbeFixtureManager
@end
@interface ProbeFixtureScene : NSObject
@property(nonatomic,strong) id layerManager;
@property(nonatomic,strong) id settings;
@property(nonatomic) bool active;
- (bool)isActive;
@end
@implementation ProbeFixtureScene
- (bool)isActive {
    calls++;
    if (throws) [NSException raise:@"fixture" format:@"read"];
    return self.active;
}
@end
@interface ProbeMissingScene : NSObject
@end
@implementation ProbeMissingScene
+ (BOOL)resolveInstanceMethod:(SEL)selector { (void)selector; resolutions++; return NO; }
@end
@interface ProbeBadScene : NSObject
- (id)layerManager;
- (id)settings;
- (int)isActive;
@end
@implementation ProbeBadScene
- (id)layerManager { calls++; return nil; }
- (id)settings { calls++; return nil; }
- (int)isActive { calls++; return 1; }
@end
@interface ProbeBadLayer : NSObject
- (id)type;
@end
@implementation ProbeBadLayer
- (id)type { calls++; return @1; }
@end
static NSDictionary *Read(id scene, Class sceneClass = ProbeFixtureScene.class,
                          Class layerClass = ProbeFixtureLayer.class) {
    return PPOReadSceneLayerState(scene, sceneClass, ProbeFixtureManager.class,
                                 layerClass, ProbeFixtureSettings.class);
}
static void Status(NSDictionary *result, NSString *status) {
    Check([result[@"status"] isEqual:status], status.UTF8String);
}
int main(void) {
    @autoreleasepool {
        ProbeFixtureScene *scene = [ProbeFixtureScene new];
        ProbeFixtureManager *manager = [ProbeFixtureManager new];
        ProbeFixtureSettings *settings = [ProbeFixtureSettings new];
        scene.layerManager = manager; scene.settings = settings; scene.active = true;
        manager.layers = [NSOrderedSet orderedSet];
        NSDictionary *r = Read(scene);
        Status(r, @"sampled");
        Check([r[@"layerCount"] isEqual:@0] && [r[@"layerTypes"] count] == 0,
              "an empty source is an observation, not a probe failure");
        Check([r[@"sceneActive"] boolValue] && ![r[@"settingsBackgrounded"] boolValue],
              "source state reflects getters");
        ProbeFixtureLayer *one = [ProbeFixtureLayer new], *two = [ProbeFixtureLayer new];
        one.type = 1; two.type = 7;
        manager.layers = [NSOrderedSet orderedSetWithObjects:one, two, nil];
        r = Read(scene); Status(r, @"sampled");
        Check([r[@"layerTypes"] isEqual:@[@1, @7]], "bounded layer type values preserved");
        Check([r allKeys].count == 5, "no context/render identifiers or application data");
        settings.backgrounded = true; scene.active = false;
        manager.layers = [NSOrderedSet orderedSet];
        r = Read(scene); Status(r, @"sampled");
        Check([r[@"settingsBackgrounded"] boolValue] && ![r[@"sceneActive"] boolValue] &&
              [r[@"layerCount"] isEqual:@0], "transition is sampled rather than cached");
        Status(Read(nil), @"unexpected-scene");
        Status(Read(@1), @"unexpected-scene");
        Status(PPOReadSceneLayerState(scene, Nil, Nil, Nil, Nil), @"unexpected-scene");
        unsigned before = calls;
        Status(Read([ProbeMissingScene new], ProbeMissingScene.class), @"unsupported-scene-abi");
        Check(resolutions == 0 && calls == before, "missing ABI does not resolve or dispatch");
        Status(Read([ProbeBadScene new], ProbeBadScene.class), @"unsupported-scene-abi");
        Check(calls == before, "wrong bool ABI rejects before invoking object getters");
        scene.layerManager = @1;
        Status(Read(scene), @"unexpected-source-object"); scene.layerManager = manager;
        scene.settings = @1;
        Status(Read(scene), @"unexpected-source-object"); scene.settings = settings;
        manager.layers = @[]; Status(Read(scene), @"unexpected-layers");
        manager.layers = [NSOrderedSet orderedSetWithObject:@1];
        Status(Read(scene), @"unsupported-layer");
        manager.layers = [NSOrderedSet orderedSetWithObject:[ProbeBadLayer new]];
        before = calls; Status(Read(scene, ProbeFixtureScene.class, ProbeBadLayer.class), @"unsupported-layer");
        Check(calls == before, "wrong layer return ABI is not dispatched");
        NSMutableOrderedSet *many = [NSMutableOrderedSet orderedSet];
        for (unsigned i = 0; i < 33; i++) [many addObject:[ProbeFixtureLayer new]];
        manager.layers = many; r = Read(scene); Status(r, @"layer-limit");
        Check([r[@"layerCount"] isEqual:@33] && !r[@"layerTypes"], "oversized source not iterated");
        [many removeObjectAtIndex:32]; r = Read(scene); Status(r, @"sampled");
        Check([r[@"layerTypes"] count] == 32, "maximum bounded source accepted");
        throws = YES; Status(Read(scene), @"read-exception"); throws = NO;
        before = calls;
        dispatch_semaphore_t done = dispatch_semaphore_create(0);
        __block NSDictionary *offThread;
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
            offThread = Read(scene); dispatch_semaphore_signal(done);
        });
        Check(dispatch_semaphore_wait(done, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 5)) == 0,
              "background fixture completes");
        Status(offThread, @"wrong-thread");
        Check(calls == before, "wrong thread reads no source state");
        for (unsigned i = 0; i < 100; i++) {
            settings.backgrounded = i % 2;
            r = Read(scene); Status(r, @"sampled");
            Check([r[@"settingsBackgrounded"] boolValue] == settings.backgrounded,
                  "repeated samples preserve current value");
        }
        puts([[NSString stringWithFormat:@"Scene layer probe tests passed: %u checks", checks] UTF8String]);
    }
    return 0;
}
