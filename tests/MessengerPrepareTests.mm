#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <notify.h>
#import "../PPOMessengerReturn.h"
#include "../PPOMessengerReturnState.h"
#include <cstdio>
#include <cstdlib>
#include <cstring>
static uint64_t published;
static unsigned posts, checks;
static bool postFails;
static void Check(bool value,const char *message) {
    ++checks;if(!value){std::fprintf(stderr,"FAIL: %s\n",message);std::exit(1);}
}
extern "C" uint32_t PPOReturnTestRegister(const char *name,int *token) {
    Check(std::strcmp(name,"com.renatasy83.ppo.messenger.return.v5")==0,"read only versioned companion channel");
    *token=17;return NOTIFY_STATUS_OK;
}
extern "C" uint32_t PPOReturnTestGet(int token,uint64_t *value) {
    Check(token==17,"registered token used");*value=published;return NOTIFY_STATUS_OK;
}
extern "C" uint32_t PPOReturnTestPost(const char *name) {
    Check(std::strcmp(name,"com.renatasy83.ppo.messenger.return.prepare.v5")==0,"only explicit prepare channel posted");
    ++posts;return postFails?NOTIFY_STATUS_FAILED:NOTIFY_STATUS_OK;
}
static void Pump(double seconds) {
    NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:seconds];
    while ([deadline timeIntervalSinceNow]>0) CFRunLoopRunInMode(kCFRunLoopDefaultMode,0.01,true);
}
static void Publish(PPOReturnPhase phase,unsigned flags,double age=0) {
    PPOReturnState state;state.phase=phase;state.flags=flags;
    published=state.packed(NSProcessInfo.processInfo.systemUptime-age);
}
static void Request(bool expected,bool delayed,bool reply) {
    unsigned before=posts;__block unsigned callbacks=0;__block bool result=!expected;
    if (reply) dispatch_after(dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_MSEC*80),dispatch_get_main_queue(),^{
        Publish(PPOReturnPhase::Captured,1);
    });
    PPOMessengerPrepareReturn(^(BOOL ready){++callbacks;result=ready;});
    if (delayed) {
        Check(callbacks==0,"pending request returns without blocking main thread");
        NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:3];
        while (!callbacks && [deadline timeIntervalSinceNow]>0) CFRunLoopRunInMode(kCFRunLoopDefaultMode,0.01,true);
    }
    Check(callbacks==1 && result==expected,"one bounded completion with actual outcome");
    Check(posts==before+(delayed || postFails?1:0),"no automatic prepare reposts");
    Pump(0.1);Check(callbacks==1,"no late duplicate completion");
}
int main() { @autoreleasepool {
    Check(NSThread.isMainThread,"main-queue fixture");
    Publish(PPOReturnPhase::Captured,1);Request(true,false,false);
    Publish(PPOReturnPhase::Restored,15);Request(true,true,true);
    Publish(PPOReturnPhase::Restored,15);Request(false,true,false);
    Publish(PPOReturnPhase::Captured,1,31);Request(true,true,true);
    Publish(PPOReturnPhase::Migrated,7);Request(false,false,false);
    Publish(PPOReturnPhase::Refused,129);Request(false,false,false);
    Publish(PPOReturnPhase::Captured,1);
    published=(published&~(uint64_t(15)<<44))|(uint64_t(4)<<44);
    Check(![PPOMessengerReturnSnapshot()[@"ready"] boolValue],"old schema4 state on new channel is unavailable");
    Request(false,false,false);
    published=0;Request(false,false,false);
    Publish(PPOReturnPhase::Restored,15);postFails=true;Request(false,false,false);postFails=false;
    std::printf("Messenger prepare client tests passed: %u checks; real main-queue scheduling with notify boundary stubs, not UIKit or daemon ownership\n",checks);
} }
