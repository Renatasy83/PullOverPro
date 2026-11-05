#import "PPOMessengerReturn.h"
#include "PPOMessengerReturnState.h"
#import <notify.h>
NSDictionary *PPOMessengerReturnSnapshot(void) {
    static int token=-1;
    if (token<0 && notify_register_check("com.renatasy83.ppo.messenger.return.v3",&token)!=NOTIFY_STATUS_OK)
        return @{@"state":@"unavailable",@"ready":@NO};
    uint64_t value=0;
    if (notify_get_state(token,&value)!=NOTIFY_STATUS_OK || (value>>48)!=0x5050 || ((value>>44)&15)!=3)
        return @{@"state":@"unavailable",@"ready":@NO};
    return @{@"state":@"sampled",@"transportSchema":@3,@"ready":@(PPOReturnReady(value,NSProcessInfo.processInfo.systemUptime)),
        @"phase":@((value>>40)&15),@"flags":@((value>>32)&255),@"sampleUptime":@(uint32_t(value))};
}
static void PollPrepared(unsigned remaining, void (^completion)(BOOL)) {
    if ([PPOMessengerReturnSnapshot()[@"ready"] boolValue]) { completion(YES);return; }
    if (!remaining) { completion(NO);return; }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_MSEC*50),dispatch_get_main_queue(),^{
        PollPrepared(remaining-1,completion);
    });
}
void PPOMessengerPrepareReturn(void (^completion)(BOOL)) {
    if (!completion) return;
    if (!NSThread.isMainThread) { dispatch_async(dispatch_get_main_queue(),^{ PPOMessengerPrepareReturn(completion); });return; }
    NSDictionary *snapshot=PPOMessengerReturnSnapshot();
    if ([snapshot[@"ready"] boolValue]) { completion(YES);return; }
    unsigned phase=[snapshot[@"phase"] unsignedIntValue];
    if (![snapshot[@"state"] isEqual:@"sampled"] || (phase!=1 && phase!=3) ||
        notify_post("com.renatasy83.ppo.messenger.return.prepare.v3")!=NOTIFY_STATUS_OK) { completion(NO);return; }
    PollPrepared(20,completion); // One explicit request, at most1second of asynchronous metadata polling.
}
