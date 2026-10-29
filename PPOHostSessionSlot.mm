#import "PPOHostSessionSlot.h"
#include <errno.h>

BOOL PPOHostApplicationAllowed(NSString *identifier) {
    return [identifier isKindOfClass:NSString.class] &&
        ([identifier isEqual:@"com.apple.mobilesafari"] ||
         [identifier isEqual:@"com.apple.Preferences"]);
}
static BOOL PPOHostSlotFailure(NSError **error, NSInteger code) {
    if (error) *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:code userInfo:nil];
    return NO;
}
@interface PPOHostSessionSlot ()
@property(nonatomic,strong,readwrite) id<PPOHostedSession> session;
@property(nonatomic,readwrite) BOOL poisoned;
@property(nonatomic) BOOL busy;
@end
@implementation PPOHostSessionSlot
- (BOOL)adopt:(id<PPOHostedSession>)candidate error:(NSError **)error {
    if (error) *error = nil;
    if (!NSThread.isMainThread) return PPOHostSlotFailure(error, EDEADLK);
    if (!candidate || candidate == self.session) return PPOHostSlotFailure(error, EINVAL);
    if (self.busy) return PPOHostSlotFailure(error, EBUSY);
    if (self.poisoned) return PPOHostSlotFailure(error, EIO);
    self.busy = YES;
    @try {
        if (self.session) {
            if (!self.session.finished) return PPOHostSlotFailure(error, EBUSY);
            if (!self.session.replacementAllowed) {
                self.poisoned = YES;
                return PPOHostSlotFailure(error, EIO);
            }
        }
        // Retain the candidate BEFORE opening: reentrant UI cannot adopt a
        // second session while the first is still being prepared.
        self.session = candidate;
        return YES;
    } @catch (NSException *exception) {
        (void)exception;
        self.poisoned = YES;
        return PPOHostSlotFailure(error, EIO);
    } @finally { self.busy = NO; }
}
@end
