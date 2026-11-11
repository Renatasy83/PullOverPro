#import <Foundation/Foundation.h>
#import "../PPOMenuBinding.h"

#include <cstdio>
#include <cstdlib>
#include <thread>

static unsigned checks;
static void Check(BOOL value, const char *message) {
    ++checks;
    if (!value) { std::fprintf(stderr, "FAIL: %s\n", message); std::exit(1); }
}

// This is deliberately a copying setter rather than a UIKit imitation. Every
// copy has a different identity, while equal model values compare isEqual:YES.
@interface CopyingMenu : NSObject <NSCopying>
@property(nonatomic) NSUInteger value;
@end
@implementation CopyingMenu
- (id)copyWithZone:(NSZone *)zone {
    (void)zone;
    CopyingMenu *result = [CopyingMenu new]; result.value = self.value; return result;
}
- (BOOL)isEqual:(id)object {
    return [object isKindOfClass:CopyingMenu.class] && [(CopyingMenu *)object value] == self.value;
}
- (NSUInteger)hash { return self.value; }
@end

@interface DeallocMenu : CopyingMenu
@property(nonatomic,copy) void (^onDealloc)(void);
@end
@implementation DeallocMenu
- (void)dealloc { if (_onDealloc) _onDealloc(); }
@end

@interface CopyDestination : NSObject
@property(nonatomic,copy) CopyingMenu *menu;
@property(nonatomic) NSUInteger assignments;
@end
@implementation CopyDestination
@synthesize menu = _menu;
- (void)setMenu:(CopyingMenu *)menu { ++_assignments; _menu = [menu copy]; }
@end

static CopyingMenu *Menu(NSUInteger value) {
    CopyingMenu *result = [CopyingMenu new]; result.value = value; return result;
}
static void (^Setter(void))(id, id) {
    return ^(id destination, id source) { [(CopyDestination *)destination setMenu:source]; };
}

int main(void) { @autoreleasepool {
    Check(NSThread.isMainThread, "main-thread fixture");
    {
        PPOMenuBinding *binding = [PPOMenuBinding new]; NSObject *owner = [NSObject new];
        CopyDestination *destination = [CopyDestination new]; CopyingMenu *source = Menu(1);
        Check([binding bindSource:source owner:owner destination:destination setter:Setter()], "first original model is bound");
        Check(destination.assignments == 1 && destination.menu != source && [destination.menu isEqual:source],
            "the actual destination stores a distinct but equal copy");
        for (unsigned refresh = 0; refresh < 128; ++refresh)
            Check(![binding bindSource:source owner:owner destination:destination setter:Setter()],
                "unchanged refresh never reassigns a copied property");
        Check(destination.assignments == 1, "128 timer-like refreshes preserve one setter application");

        // Demonstrate the previous cross-property pointer assumption against
        // the same copy contract, without making it part of the new adapter.
        CopyDestination *oldDestination = [CopyDestination new];
        for (unsigned refresh = 0; refresh < 100; ++refresh)
            if (oldDestination.menu != source) oldDestination.menu = source;
        Check(oldDestination.assignments == 100, "destination/source pointer guard repeatedly reassigns copied models");

        CopyingMenu *equalRevision = Menu(1);
        Check(equalRevision != source && [equalRevision isEqual:source], "new source revision can be equal by value");
        Check([binding bindSource:equalRevision owner:owner destination:destination setter:Setter()] && destination.assignments == 2,
            "a distinct original source revision is applied despite equal contents");
        Check(![binding bindSource:equalRevision owner:owner destination:destination setter:Setter()], "new revision then stays stable");
        NSObject *replacementOwner = [NSObject new];
        Check([binding bindSource:equalRevision owner:replacementOwner destination:destination setter:Setter()] && destination.assignments == 3,
            "exact owner identity is part of the binding");
        CopyDestination *replacement = [CopyDestination new];
        Check([binding bindSource:equalRevision owner:replacementOwner destination:replacement setter:Setter()] && replacement.assignments == 1,
            "a replacement destination receives the original once");
        Check(![binding bindSource:equalRevision owner:replacementOwner destination:replacement setter:Setter()], "replacement is then stable");

        Check([binding bindSource:nil owner:owner destination:replacement setter:Setter()] && replacement.menu == nil,
            "missing source clears the current destination");
        Check(![binding bindSource:nil owner:replacementOwner destination:replacement setter:Setter()],
            "clear does not depend on the stale owner identity");
        Check(![binding bindSource:source owner:nil destination:replacement setter:Setter()] && replacement.assignments == 2,
            "missing owner canonicalizes to the same clear");
        Check([binding bindSource:source owner:owner destination:replacement setter:Setter()] && replacement.assignments == 3,
            "a valid model rebinds after clear");
        Check([binding bindSource:source owner:nil destination:replacement setter:Setter()] && replacement.assignments == 4 && replacement.menu == nil,
            "losing an owner clears a previously bound source");
        Check(![binding bindSource:nil owner:nil destination:replacement setter:Setter()], "repeated canonical clear does not reapply");
    }
    {
        PPOMenuBinding *binding = [PPOMenuBinding new]; NSObject *owner = [NSObject new];
        CopyingMenu *source = Menu(2); CopyDestination *destination = [CopyDestination new];
        Check(![binding bindSource:source owner:owner destination:destination setter:nil] && destination.assignments == 0,
            "missing setter cannot claim a binding");
        Check([binding bindSource:source owner:owner destination:destination setter:Setter()], "same request succeeds when a setter is supplied");
        CopyingMenu *revision = Menu(3);
        Check(![binding bindSource:revision owner:owner destination:destination setter:nil] && destination.menu.value == 2,
            "missing setter preserves the actual destination and previous successful cache");
        Check(![binding bindSource:source owner:owner destination:destination setter:Setter()], "denied request did not disturb the old successful binding");
        Check([binding bindSource:revision owner:owner destination:destination setter:Setter()], "denied new source is applied on a valid retry");
        Check(![binding bindSource:revision owner:owner destination:nil setter:Setter()], "missing destination invalidates without setter invocation");
        Check([binding bindSource:revision owner:owner destination:destination setter:Setter()] && destination.assignments == 3,
            "returning destination rebinds after invalidation");

        NSUInteger before = destination.assignments; bool backgroundResult = true;
        std::thread worker([&] { @autoreleasepool {
            backgroundResult = [binding bindSource:nil owner:nil destination:nil setter:Setter()];
        } }); worker.join();
        Check(!backgroundResult && destination.assignments == before, "wrong-thread call cannot clear UI or mutate binding state");
        Check(![binding bindSource:revision owner:owner destination:destination setter:Setter()], "successful cache survives wrong-thread invalidation request");
    }
    {
        PPOMenuBinding *binding = [PPOMenuBinding new]; __weak NSObject *weakOwner;
        CopyingMenu *source = Menu(4); CopyDestination *destination = [CopyDestination new];
        @autoreleasepool {
            NSObject *owner = [NSObject new]; weakOwner = owner;
            Check([binding bindSource:source owner:owner destination:destination setter:Setter()], "ephemeral owner can bind");
        }
        Check(weakOwner == nil, "binding does not retain its owner");
        Check([binding bindSource:source owner:weakOwner destination:destination setter:Setter()] && destination.menu == nil,
            "zeroed owner causes one canonical clear");
        Check(![binding bindSource:nil owner:nil destination:destination setter:Setter()], "owner-loss clear is stable");
    }
    {
        PPOMenuBinding *binding = [PPOMenuBinding new];
        __weak NSObject *weakOwner; __weak CopyDestination *weakDestination; __weak CopyingMenu *weakSource;
        @autoreleasepool {
            NSObject *owner = [NSObject new]; CopyDestination *destination = [CopyDestination new]; CopyingMenu *source = Menu(5);
            weakOwner = owner; weakDestination = destination; weakSource = source;
            Check([binding bindSource:source owner:owner destination:destination setter:Setter()], "weak-lifetime fixture bound");
        }
        Check(weakOwner == nil && weakDestination == nil, "cache retains neither owner nor destination");
        Check(weakSource != nil, "cache retains the original model independently of destination copies");
        Check(![binding bindSource:nil owner:nil destination:nil setter:nil], "no destination invalidates even without a setter");
        Check(weakSource == nil, "destination invalidation releases the original model");
    }
    {
        PPOMenuBinding *binding = [PPOMenuBinding new]; NSObject *owner = [NSObject new]; CopyingMenu *source = Menu(6);
        // A weak destination becomes nil before its address could be reused.
        // New destinations must bind even while source/owner identities persist.
        for (unsigned replacement = 0; replacement < 64; ++replacement) {
            __weak CopyDestination *weakDestination;
            @autoreleasepool {
                CopyDestination *destination = [CopyDestination new]; weakDestination = destination;
                Check([binding bindSource:source owner:owner destination:destination setter:Setter()], "each new destination binds once");
                Check(![binding bindSource:source owner:owner destination:destination setter:Setter()] && destination.assignments == 1,
                    "each replacement stays stable independently of copy identity");
            }
            Check(weakDestination == nil, "old destination lifetime is not prolonged by cache");
        }
    }
    {
        PPOMenuBinding *binding = [PPOMenuBinding new]; NSObject *owner = [NSObject new]; CopyDestination *destination = [CopyDestination new];
        CopyingMenu *source = Menu(7), *revision = Menu(8);
        Check([binding bindSource:source owner:owner destination:destination setter:Setter()], "exception fixture initially bound");
        BOOL caught = NO;
        @try {
            [binding bindSource:revision owner:owner destination:destination setter:^(id target, id model) {
                [(CopyDestination *)target setMenu:model];
                @throw [NSException exceptionWithName:@"PPOFixtureSetter" reason:@"partial application" userInfo:nil];
            }];
        } @catch (NSException *exception) { caught = [exception.name isEqual:@"PPOFixtureSetter"]; }
        Check(caught && destination.assignments == 2 && destination.menu.value == 8, "partially applied setter exception is propagated");
        Check([binding bindSource:revision owner:owner destination:destination setter:Setter()] && destination.assignments == 3,
            "unknown state after exception is retried, not claimed as bound");
        Check(![binding bindSource:revision owner:owner destination:destination setter:Setter()], "successful retry returns to stable binding");
    }
    {
        PPOMenuBinding *binding = [PPOMenuBinding new]; NSObject *owner = [NSObject new], *otherOwner = [NSObject new];
        CopyingMenu *source = Menu(9), *other = Menu(10); CopyDestination *destination = [CopyDestination new], *otherDestination = [CopyDestination new];
        __block NSUInteger nestedSetters = 0;
        void (^nested)(id,id) = ^(id target, id model) { ++nestedSetters; [(CopyDestination *)target setMenu:model]; };
        Check([binding bindSource:source owner:owner destination:destination setter:^(id target, id model) {
            Check(![binding bindSource:source owner:owner destination:destination setter:nested], "same-key reentry is denied without recursion");
            Check(![binding bindSource:other owner:otherOwner destination:otherDestination setter:nested], "different-key reentry is deferred to ordinary refresh");
            Check(![binding bindSource:nil owner:nil destination:nil setter:nil], "reentrant invalidation cannot overwrite an applying request");
            [(CopyDestination *)target setMenu:model];
        }], "outer setter commits once after guarded reentry");
        Check(nestedSetters == 0 && destination.assignments == 1 && otherDestination.assignments == 0, "no nested setter or unrelated destination mutation");
        Check(![binding bindSource:source owner:owner destination:destination setter:Setter()], "outer source cache survives reentrant clear attempt");
        Check([binding bindSource:other owner:otherOwner destination:otherDestination setter:Setter()] && otherDestination.assignments == 1,
            "next normal refresh applies the newly current request");
    }
    {
        PPOMenuBinding *binding = [PPOMenuBinding new]; NSObject *owner = [NSObject new]; CopyDestination *destination = [CopyDestination new];
        CopyingMenu *source = Menu(14), *revision = Menu(15); NSString *thrown = @"PPOFixtureObjectThrow";
        Check([binding bindSource:source owner:owner destination:destination setter:Setter()], "arbitrary-object exception fixture initially bound");
        BOOL caught = NO;
        @try {
            [binding bindSource:revision owner:owner destination:destination setter:^(id target, id model) {
                [(CopyDestination *)target setMenu:model];
                @throw thrown;
            }];
        } @catch (id object) { caught = object == thrown; }
        Check(caught && destination.assignments == 2 && destination.menu.value == 15,
            "legal non-NSException throw propagates after partial destination mutation");
        Check([binding bindSource:source owner:owner destination:destination setter:Setter()] && destination.assignments == 3 && destination.menu.value == 14,
            "old source must reapply after an arbitrary thrown object, never skip using stale success");
        Check(![binding bindSource:source owner:owner destination:destination setter:Setter()], "successful recovery restores stable binding");
    }
    {
        PPOMenuBinding *binding = [PPOMenuBinding new]; NSObject *owner = [NSObject new]; CopyDestination *destination = [CopyDestination new];
        CopyingMenu *source = Menu(11); __weak NSObject *weakCaptured;
        @autoreleasepool {
            NSObject *captured = [NSObject new]; weakCaptured = captured;
            Check([binding bindSource:source owner:owner destination:destination setter:^(id target, id model) {
                Check(captured != nil, "ephemeral setter capture is available during invocation");
                [(CopyDestination *)target setMenu:model];
            }], "setter capture fixture bound");
        }
        Check(weakCaptured == nil, "setter block and its captures are not retained by the adapter");
    }
    {
        PPOMenuBinding *binding = [PPOMenuBinding new]; NSObject *owner = [NSObject new]; CopyDestination *destination = [CopyDestination new];
        CopyingMenu *next = Menu(12); __weak PPOMenuBinding *weakBinding = binding;
        __block unsigned callbacks = 0; __block BOOL reentered = YES;
        @autoreleasepool {
            DeallocMenu *source = [DeallocMenu new]; source.value = 13;
            source.onDealloc = ^{
                ++callbacks;
                reentered = [weakBinding bindSource:next owner:owner destination:destination setter:Setter()];
            };
            Check([binding bindSource:source owner:owner destination:destination setter:Setter()], "deallocation reentry fixture bound");
        }
        Check(callbacks == 0, "original model remains retained until invalidation");
        Check(![binding bindSource:nil owner:nil destination:nil setter:nil], "invalidation needs no setter");
        Check(callbacks == 1 && !reentered && destination.assignments == 1,
            "model deallocation cannot reenter while cache is being invalidated");
        Check([binding bindSource:next owner:owner destination:destination setter:Setter()] && destination.assignments == 2,
            "next normal refresh reconciles after deallocation callback");
    }
    std::printf("Menu binding tests passed: %u checks; copied-property identity, weak lifetimes, retries and reentry, not UIKit menu routing\n", checks);
} return 0; }
