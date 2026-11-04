#include "../PPOMessengerReturnState.h"
#include <cstdio>
#include <cstdlib>
#include <limits>
#include <initializer_list>
static unsigned checks;
static void Check(bool ok,const char *message) { checks++;if(!ok){std::fprintf(stderr,"FAIL: %s\n",message);std::exit(1);} }
int main() {
    PPOReturnState s;
    Check(!s.canRestore(true,true,true,true,true,true,true),"no restoration before captured migration");
    Check(!s.capture(false,true) && !s.capture(true,false),"no primary/root means no capture");
    Check(s.capture(true,true) && !s.capture(true,true),"capture original exactly once");
    Check(PPOReturnReady(s.packed(100),100) && PPOReturnReady(s.packed(100),130),"ready covers bounded age");
    Check(!PPOReturnReady(s.packed(100),130.001) && !PPOReturnReady(s.packed(100),99.999),"stale/future state rejected");
    Check(!s.migration(false,true,true) && s.phase==PPOReturnPhase::Captured,"foreign scenes never become owned migration");
    Check(!s.migration(true,true,false) && s.phase==PPOReturnPhase::Captured,"same original scene cannot count as migration");
    Check(!PPOReturnReady(s.packed(100),100),"observing owned scope consumes readiness even before a migration");
    Check(s.migration(true,true,true) && s.phase==PPOReturnPhase::Migrated,"same original window/root in distinct owned scene tracked");
    Check(!PPOReturnReady(s.packed(100),100),"a running migration cannot authorize another trial");
    for(unsigned mask=0;mask<128;mask++) {
        bool a=mask&1,b=mask&2,c=mask&4,d=mask&8,e=mask&16,f=mask&32,g=mask&64;
        Check(s.canRestore(a,b,c,d,e,f,g)==(mask==127),"every independent restoration gate must hold");
    }
    s.finish(true);Check(s.phase==PPOReturnPhase::Restored && (s.flags&8),"verified restoration is terminal and reported");
    Check(!s.canRestore(true,true,true,true,true,true,true) && !s.migration(true,true,true) && !s.capture(true,true),"no replay or second migration after completion");
    PPOReturnState refused;refused.capture(true,true);
    Check(!refused.migration(true,false,true) && refused.phase==PPOReturnPhase::Refused && (refused.flags&16),"different root/window refuses without touching it");
    Check(!refused.canRestore(true,true,true,true,true,true,true),"refused migration cannot be revived");
    PPOReturnState failure;failure.capture(true,true);failure.migration(true,true,true);failure.finish(false);
    Check(failure.phase==PPOReturnPhase::Refused && !(failure.flags&8),"failed readback never reports restoration");
    for(double now : { -1.0, std::numeric_limits<double>::quiet_NaN(), std::numeric_limits<double>::infinity(),4294967296.0 })
        Check(s.packed(now)==0,"invalid producer clock is not published");
    PPOReturnState captured;captured.capture(true,true);uint64_t valid=captured.packed(200);
    for(unsigned bit=44;bit<64;bit++) Check(!PPOReturnReady(valid^(uint64_t(1)<<bit),200),"wrong signature/schema is not accepted");
    Check(!PPOReturnReady(0,200),"uninitialized channel is not ready");
    std::printf("Messenger return state tests passed: %u checks; pure transition/transport policy, not UIKit window restoration\n",checks);
}
