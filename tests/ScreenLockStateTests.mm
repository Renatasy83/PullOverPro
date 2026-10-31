#import "../PPOScreenLockState.h"
#import <dispatch/dispatch.h>
#import <objc/runtime.h>
#include <stdio.h>
#include <stdlib.h>

// Controlled native metadata/getter fixtures, not SpringBoard lock testing.
static unsigned checks, factoryReads, lockedReads, waitingReads, resolutions, constructions;
static unsigned exceptionAt;
static id existingManager;
static void Check(BOOL condition, const char *message) {
    checks++;
    if (!condition) { fprintf(stderr, "FAIL: %s\n", message); exit(1); }
}
static void MaybeThrow(unsigned stage) {
    if (exceptionAt == stage) [NSException raise:@"fixture" format:@"lock-read"];
}
@interface LockFixtureManager : NSObject
@property(nonatomic) bool locked;
@property(nonatomic) bool waiting;
+ (id)sharedInstanceIfExists;
- (bool)isUILocked;
- (bool)isWaitingToLockUI;
@end
@implementation LockFixtureManager
- (instancetype)init { constructions++; return [super init]; }
+ (id)sharedInstanceIfExists { factoryReads++; MaybeThrow(1); return existingManager; }
- (bool)isUILocked { lockedReads++; MaybeThrow(2); return self.locked; }
- (bool)isWaitingToLockUI { waitingReads++; MaybeThrow(3); return self.waiting; }
@end

@interface LockMissingManager : NSObject @end
@implementation LockMissingManager
+ (BOOL)resolveClassMethod:(SEL)selector { (void)selector; resolutions++; return NO; }
+ (BOOL)resolveInstanceMethod:(SEL)selector { (void)selector; resolutions++; return NO; }
@end

@interface LockMissingFlagManager : NSObject
+ (id)sharedInstanceIfExists;
- (bool)isUILocked;
@end
@implementation LockMissingFlagManager
+ (id)sharedInstanceIfExists { factoryReads++; return existingManager; }
- (bool)isUILocked { lockedReads++; return false; }
+ (BOOL)resolveInstanceMethod:(SEL)selector { (void)selector; resolutions++; return NO; }
@end

@interface LockBadFactoryManager : NSObject
+ (int)sharedInstanceIfExists;
- (bool)isUILocked;
- (bool)isWaitingToLockUI;
@end
@implementation LockBadFactoryManager
+ (int)sharedInstanceIfExists { factoryReads++; abort(); }
- (bool)isUILocked { lockedReads++; abort(); }
- (bool)isWaitingToLockUI { waitingReads++; abort(); }
@end

@interface LockBadFlagManager : NSObject
+ (id)sharedInstanceIfExists;
- (bool)isUILocked;
- (int)isWaitingToLockUI;
@end
@implementation LockBadFlagManager
+ (id)sharedInstanceIfExists { factoryReads++; return existingManager; }
- (bool)isUILocked { lockedReads++; return false; }
- (int)isWaitingToLockUI { waitingReads++; abort(); }
@end

static int BadLockedFlag(id receiver, SEL selector) {
    (void)receiver; (void)selector; lockedReads++; abort();
}
static int BadWaitingFlag(id receiver, SEL selector) {
    (void)receiver; (void)selector; waitingReads++; abort();
}
static Class ActualBadFlagSubclass(BOOL waiting) {
    const char *name = waiting ? "LockActualBadWaiting" : "LockActualBadLocked";
    Class cls = objc_lookUpClass(name);
    if (!cls) {
        cls = objc_allocateClassPair(LockFixtureManager.class, name, 0);
        SEL selector = waiting ? @selector(isWaitingToLockUI) : @selector(isUILocked);
        IMP implementation = waiting ? (IMP)BadWaitingFlag : (IMP)BadLockedFlag;
        Check(cls && class_addMethod(cls, selector, implementation, "i@:"), "bad actual getter fixture registered");
        objc_registerClassPair(cls);
    }
    return cls;
}
static void Reset(void) {
    factoryReads = lockedReads = waitingReads = resolutions = constructions = exceptionAt = 0;
    existingManager = nil;
}
static unsigned Reads(void) { return factoryReads + lockedReads + waitingReads; }
static NSDictionary *Read(Class cls = LockFixtureManager.class, BOOL firmware = YES) {
    return PPOReadScreenLockState(cls, firmware);
}
static void Unknown(NSDictionary *result, NSString *status) {
    Check([result[@"status"] isEqual:status], status.UTF8String);
    Check(result[@"locked"] == NSNull.null && result[@"waitingToLock"] == NSNull.null,
          "unobserved flags remain unknown, never falsely unlocked");
    Check(result.count == 3, "failure diagnostics publish no manager or private data");
}
int main(void) {
    @autoreleasepool {
        Reset();
        LockFixtureManager *manager = [LockFixtureManager new];
        existingManager = manager;
        unsigned made = constructions;
        for (unsigned bits = 0; bits < 4; bits++) {
            manager.locked = (bits & 1) != 0; manager.waiting = (bits & 2) != 0;
            NSDictionary *result = Read();
            Check([result[@"status"] isEqual:@"sampled"], "known lock flags sampled");
            Check([result[@"locked"] isEqual:@(manager.locked)] &&
                  [result[@"waitingToLock"] isEqual:@(manager.waiting)],
                  "locked and waiting are read independently, not inferred from protected data");
            Check(result.count == 3, "sample contains only status and scalar flags");
        }
        Check(factoryReads == 4 && lockedReads == 4 && waitingReads == 4,
              "each requested observation rechecks existing state once");
        Check(constructions == made, "reader never constructs another manager");

        Reset();
        Unknown(Read(), @"manager-unavailable");
        Check(factoryReads == 1 && !lockedReads && !waitingReads && !constructions,
              "missing existing manager is not created or queried for flags");
        Reset(); existingManager = [NSObject new];
        Unknown(Read(), @"unexpected-manager");
        Check(factoryReads == 1 && !lockedReads && !waitingReads, "foreign receiver cannot receive lock flag messages");

        for (Class cls in @[LockMissingManager.class, LockMissingFlagManager.class,
                            LockBadFactoryManager.class, LockBadFlagManager.class]) {
            Reset();
            Unknown(Read(cls), @"unsupported-abi");
            Check(Reads() == 0 && resolutions == 0 && constructions == 0,
                  "missing or incompatible declared accessors refuse before any factory or resolution");
        }
        Reset(); Unknown(Read(Nil), @"unsupported-abi");
        Check(Reads() == 0 && resolutions == 0, "nil class refuses without dispatch");

        for (unsigned flag = 0; flag < 2; flag++) {
            Reset();
            existingManager = [ActualBadFlagSubclass(flag != 0) new];
            made = constructions;
            Unknown(Read(), @"unsupported-abi");
            Check(factoryReads == 1 && !lockedReads && !waitingReads,
                  "both actual getter ABIs checked before either flag can be invoked");
            Check(constructions == made, "actual subtype validation never creates a replacement manager");
        }

        for (unsigned stage = 1; stage <= 3; stage++) {
            Reset(); existingManager = [LockFixtureManager new]; exceptionAt = stage;
            Unknown(Read(), @"read-exception");
            Check(factoryReads == 1 && lockedReads == (stage >= 2 ? 1u : 0u) &&
                  waitingReads == (stage >= 3 ? 1u : 0u),
                  "exceptions contain partial reads without publishing a partial unlocked result");
        }

        Reset(); existingManager = [LockFixtureManager new];
        Unknown(Read(LockFixtureManager.class, NO), @"firmware-refused");
        Check(Reads() == 0, "firmware refusal precedes every private dispatch");
        __block NSDictionary *workerResult = nil;
        dispatch_group_t group = dispatch_group_create();
        dispatch_group_async(group, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
            workerResult = Read();
        });
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
        Unknown(workerResult, @"wrong-thread");
        Check(Reads() == 0, "worker thread cannot dispatch private getters");

        Reset(); manager = [LockFixtureManager new]; existingManager = manager; made = constructions;
        for (unsigned i = 0; i < 100; i++) {
            manager.locked = (i % 2) != 0; manager.waiting = (i % 3) != 0;
            NSDictionary *result = Read();
            Check([result[@"status"] isEqual:@"sampled"] &&
                  [result[@"locked"] isEqual:@(manager.locked)] &&
                  [result[@"waitingToLock"] isEqual:@(manager.waiting)],
                  "repeated observations neither cache nor conflate lock transitions");
        }
        Check(factoryReads == 100 && lockedReads == 100 && waitingReads == 100 && constructions == made,
              "repeated read-only observations do not allocate lock managers");
        printf("Screen lock state tests passed: %u checks; native fixtures, not device lock behavior\n", checks);
    }
    return 0;
}
