#import "../PPOHostSessionSlot.h"
#import <dispatch/dispatch.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>

static unsigned checks, getterCalls;
static BOOL throwFinished, throwReplacement, reenter;
static PPOHostSessionSlot *slot;
static void Check(BOOL condition, const char *message) {
    checks++;
    if (!condition) { fprintf(stderr, "FAIL: %s\n", message); exit(1); }
}
@interface FixtureSession : NSObject <PPOHostedSession>
@property(nonatomic) BOOL done;
@property(nonatomic) BOOL clean;
@end
@implementation FixtureSession
- (BOOL)isFinished {
    getterCalls++;
    if (throwFinished) [NSException raise:@"fixture" format:@"finished"];
    if (reenter) {
        reenter = NO;
        NSError *error = nil;
        Check(![slot adopt:[FixtureSession new] error:&error] && error.code == EBUSY,
              "reentrant adoption cannot replace current session");
    }
    return self.done;
}
- (BOOL)replacementAllowed {
    getterCalls++;
    if (throwReplacement) [NSException raise:@"fixture" format:@"cleanup"];
    return self.clean;
}
@end
static FixtureSession *Fixture(BOOL done, BOOL clean) {
    FixtureSession *s = [FixtureSession new]; s.done = done; s.clean = clean; return s;
}
int main(void) {
    @autoreleasepool {
        Check(PPOHostApplicationAllowed(@"com.apple.mobilesafari"), "Safari allowed");
        Check(PPOHostApplicationAllowed(@"com.apple.Preferences"), "Settings allowed");
        for (id bad in @[@"com.apple.springboard", @"com.apple.backboardd", @"com.apple.preferences",
                         @"com.apple.mobilesafari.extra", @"com.example.app", @4])
            Check(!PPOHostApplicationAllowed(bad), "other/system/suffix/type target rejected");
        Check(!PPOHostApplicationAllowed(nil), "nil target rejected");
        slot = [PPOHostSessionSlot new]; NSError *error = nil;
        Check(![slot adopt:nil error:&error] && error.code == EINVAL, "nil candidate rejected");
        FixtureSession *first = Fixture(NO, NO), *second = Fixture(NO, NO);
        Check([slot adopt:first error:&error] && error == nil && slot.session == first,
              "candidate retained before opening");
        Check(![slot adopt:second error:&error] && error.code == EBUSY && slot.session == first,
              "not-yet-opened/current active session refuses replacement");
        Check(!slot.poisoned, "busy refusal does not poison a healthy session");
        Check(![slot adopt:first error:&error] && error.code == EINVAL, "same object cannot be readopted");
        first.done = first.clean = YES;
        reenter = YES;
        Check([slot adopt:second error:&error] && slot.session == second && error == nil,
              "confirmed cleanup allows explicit next session");
        second.done = YES; second.clean = NO;
        Check(![slot adopt:Fixture(NO, NO) error:&error] && error.code == EIO && slot.poisoned,
              "uncertain cleanup blocks adoption and poisons slot");
        second.clean = YES;
        Check(![slot adopt:Fixture(NO, NO) error:&error] && slot.session == second,
              "unknown cleanup never auto-recovers/retries");
        for (unsigned failure = 0; failure < 2; failure++) {
            slot = [PPOHostSessionSlot new]; first = Fixture(YES, YES);
            Check([slot adopt:first error:NULL], "initial slot fixture");
            throwFinished = failure == 0; throwReplacement = failure == 1;
            Check(![slot adopt:Fixture(NO, NO) error:&error] && slot.poisoned && slot.session == first,
                  "status exception fails closed and retains the old session");
            throwFinished = throwReplacement = NO;
        }
        slot = [PPOHostSessionSlot new];
        __weak FixtureSession *released;
        @autoreleasepool {
            first = Fixture(YES, YES);
            Check([slot adopt:first error:NULL], "safe early refusal can be replaced");
            released = first;
            first = nil;
            Check([slot adopt:Fixture(YES, YES) error:NULL], "replace a resource-free/clean session");
        }
        Check(released == nil, "old clean session is released after autorelease drainage");
        for (unsigned cycle = 0; cycle < 100; cycle++) {
            FixtureSession *s = Fixture(NO, NO);
            Check([slot adopt:s error:NULL], "repeat adopts only after prior cleanup");
            Check(![slot adopt:Fixture(NO, NO) error:NULL] && slot.session == s,
                  "repeat busy attempt cannot overwrite retained resources");
            s.done = s.clean = YES;
        }
        unsigned before = getterCalls;
        dispatch_group_t group = dispatch_group_create();
        dispatch_group_async(group, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
            NSError *worker = nil;
            Check(![slot adopt:Fixture(NO, NO) error:&worker] && worker.code == EDEADLK,
                  "worker adoption is refused");
        });
        Check(dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC)) == 0,
              "worker returns without main-thread blocking");
        Check(getterCalls == before, "worker does not inspect/release current UI session");
        printf("Host session slot tests passed: %u checks; Foundation ownership fixtures only\n", checks);
    }
    return 0;
}
