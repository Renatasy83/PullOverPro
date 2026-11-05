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
    Check(s.capture(true,true) && !s.capture(true,true),"capture original window exactly once");
    Check(PPOReturnReady(s.packed(100),100) && PPOReturnReady(s.packed(100),130),"ready covers bounded age");
    Check(!PPOReturnReady(s.packed(100),130.001) && !PPOReturnReady(s.packed(100),99.999),"stale/future state rejected");
    Check(!s.migration(false,true,true,true,false) && s.phase==PPOReturnPhase::Captured,"foreign scenes never become owned migration");
    Check(!s.migration(true,true,true,false,false) && s.phase==PPOReturnPhase::Captured,"same original scene cannot count as migration");
    Check(!PPOReturnReady(s.packed(100),100),"observing owned scope consumes readiness");
    Check(!s.migration(true,true,false,true,true) && s.phase==PPOReturnPhase::Captured,"unattached current root waits without restoring stale baseline");
    Check(s.migration(true,true,true,true,true) && s.phase==PPOReturnPhase::Migrated && (s.flags&16),"legitimate replacement root allowed only when same window currently owns it");
    Check(!PPOReturnReady(s.packed(100),100),"migration cannot authorize a second trial");
    for(unsigned mask=0;mask<128;mask++) {
        bool a=mask&1,b=mask&2,c=mask&4,d=mask&8,e=mask&16,f=mask&32,g=mask&64;
        Check(s.canRestore(a,b,c,d,e,f,g)==(mask==127),"every independent current-window/root restoration gate must hold");
    }
    s.finish(true);Check(s.phase==PPOReturnPhase::Restored && (s.flags&8),"verified return terminal and reported");
    Check(!s.canRestore(true,true,true,true,true,true,true) && !s.migration(true,true,true,true,true) && !s.capture(true,true),"no replay after completion");
    PPOReturnState refused;refused.capture(true,true);
    Check(!refused.migration(true,false,true,true,true) && refused.phase==PPOReturnPhase::Refused && (refused.flags&128),"replacement window is refused even with a valid-looking root");
    Check(!refused.canRestore(true,true,true,true,true,true,true),"refused window identity cannot be revived");
    PPOReturnState stable;stable.capture(true,true);
    Check(stable.migration(true,true,true,true,false) && !(stable.flags&16),"unchanged root remains supported");
    stable.finish(false);Check(stable.phase==PPOReturnPhase::Refused && !(stable.flags&8),"failed ownership/readback cannot claim return");
    for(double now : {-1.0,std::numeric_limits<double>::quiet_NaN(),std::numeric_limits<double>::infinity(),4294967296.0})
        Check(s.packed(now)==0,"invalid producer clock not published");
    PPOReturnState captured;captured.capture(true,true);uint64_t valid=captured.packed(200);
    Check(!PPOReturnReady((valid&~(uint64_t(15)<<44))|(uint64_t(1)<<44),200),"old v1 root-mismatch semantics cannot authorize v3 trial");
    Check(!PPOReturnReady((valid&~(uint64_t(15)<<44))|(uint64_t(2)<<44),200),"old one-shot v2 cannot authorize v3 repeat protocol");
    Check(!PPOReturnReady((valid&~(uint64_t(15)<<44))|(uint64_t(3)<<44),200),"old v3 twenty-second companion cannot authorize bounded long Keep");
    for (unsigned mask=0;mask<256;mask++) {
        PPOReturnState cycle;cycle.capture(true,true);cycle.migration(true,true,true,true,false);cycle.finish(true);
        auto ticket=cycle.generation;
        bool ok=cycle.prepare(mask&1,mask&2,mask&4,mask&8,mask&16,mask&32,mask&64,mask&128);
        Check(ok==(mask==255),"all eight explicit rearm gates are required independently");
        Check(ok?(cycle.generation==ticket+1 && cycle.phase==PPOReturnPhase::Captured && cycle.flags==1):
            (cycle.generation==ticket && cycle.phase==PPOReturnPhase::Restored && cycle.flags==15),"denied preparation preserves completed evidence");
    }
    for (unsigned phase=0;phase<5;phase++) {
        PPOReturnState state;state.phase=PPOReturnPhase(phase);state.flags=phase==1?1:15;
        Check(!state.acceptsScopeEvent(false),"late lifecycle event from disconnected old scope cannot consume new readiness");
        Check(state.acceptsScopeEvent(true)==(phase==1 || phase==2),"only connected active capture/migration consumes scope event");
        Check(state.prepare(true,true,true,true,true,true,true,true)==(phase==1 || phase==3),"never rearm waiting, active migration or refused state");
    }
    for (unsigned flag : {32u,64u,128u}) {
        PPOReturnState state;state.phase=PPOReturnPhase::Restored;state.flags=15|flag;
        Check(!state.prepare(true,true,true,true,true,true,true,true),"deferred visibility, exception or refusal cannot rearm");
    }
    PPOReturnState exhausted;exhausted.phase=PPOReturnPhase::Restored;exhausted.flags=15;exhausted.generation=UINT64_MAX;
    Check(!exhausted.prepare(true,true,true,true,true,true,true,true),"generation exhaustion cannot wrap");
    PPOReturnState repeat;repeat.capture(true,true);
    for (unsigned cycle=0;cycle<100;cycle++) {
        uint64_t ticket=repeat.generation;
        Check(repeat.acceptsTimer(ticket,true) && !repeat.acceptsTimer(ticket,false),"cancelled timer callback cannot act even in same generation");
        Check(!repeat.acceptsDisconnect(ticket,true,false),"stale/foreign closing scene rejected before migration");
        Check(repeat.acceptsDisconnect(ticket,false,true),"exact captured window may identify its actual closing scope");
        Check(repeat.migration(true,true,true,true,false),"fresh cycle migration");
        Check(repeat.acceptsDisconnect(ticket,true,false) && !repeat.acceptsDisconnect(ticket,false,true),"migrated cycle only accepts exact moved scene");
        repeat.finish(true);
        Check(!repeat.acceptsDisconnect(ticket,true,true),"duplicate callback after completion rejected");
        Check(repeat.prepare(true,true,true,true,true,true,true,true),"explicit verified repeat preparation");
        Check(!repeat.acceptsDisconnect(ticket,true,true),"queued previous-generation callback rejected after rearm");
        Check(!repeat.acceptsTimer(ticket,true) && repeat.acceptsTimer(repeat.generation,true),"old timer callback cannot expire or cancel the next cycle");
        Check(!repeat.acceptsDisconnect(repeat.generation,true,false),"old notification arriving after rearm rejected by scene/window association");
        Check(PPOReturnReady(repeat.packed(500),500),"repeat readiness freshly published");
    }
    for(unsigned bit=44;bit<64;bit++) Check(!PPOReturnReady(valid^(uint64_t(1)<<bit),200),"wrong signature/schema rejected");
    Check(!PPOReturnReady(0,200),"uninitialized channel not ready");
    std::printf("Messenger return state tests passed: %u checks; explicit repeat preparation and stale callback rejection, not UIKit restoration\n",checks);
}
