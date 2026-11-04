#import "PPOMessengerReturn.h"
#include "PPOMessengerReturnState.h"
#import <notify.h>
NSDictionary *PPOMessengerReturnSnapshot(void) {
    static int token=-1;
    if (token<0 && notify_register_check("com.renatasy83.ppo.messenger.return.v2",&token)!=NOTIFY_STATUS_OK)
        return @{@"state":@"unavailable",@"ready":@NO};
    uint64_t value=0;
    if (notify_get_state(token,&value)!=NOTIFY_STATUS_OK || (value>>48)!=0x5050 || ((value>>44)&15)!=2)
        return @{@"state":@"unavailable",@"ready":@NO};
    return @{@"state":@"sampled",@"transportSchema":@2,@"ready":@(PPOReturnReady(value,NSProcessInfo.processInfo.systemUptime)),
        @"phase":@((value>>40)&15),@"flags":@((value>>32)&255),@"sampleUptime":@(uint32_t(value))};
}
