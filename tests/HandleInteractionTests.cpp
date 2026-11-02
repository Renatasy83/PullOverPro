#include "../PPOHandleInteraction.h"
#include "../PPOHandleNubState.h"
#include <cstdio>
#include <cstdlib>
#include <limits>
#include <random>

static unsigned checks;
static void Check(bool condition, const char *message) {
    ++checks;
    if (!condition) { std::fprintf(stderr,"FAIL: %s\n",message); std::exit(1); }
}
static bool Opens(PPOHandleAction action) {
    return action == PPOHandleAction::OpenSelected || action == PPOHandleAction::OpenChosen;
}
static double Inward(PPOEdgeDrawerSide side,double x) {
    return side == PPOEdgeDrawerSide::Left ? x : -x;
}

int main() {
    for (bool selected : {false,true}) for (bool nubbed : {false,true}) {
        PPOHandleInteraction state;
        Check(!state.revealed() && !state.panActive(),"initial handle has no second-step readiness");
        Check(state.tap(true,selected,false,false,nubbed) == PPOHandleAction::RevealChooser && state.revealed(),
            "first tap only reveals even when a selected app exists");
        Check(state.tap(true,selected,false,false,false) == (selected ? PPOHandleAction::OpenSelected : PPOHandleAction::RevealChooser),
            "only a distinct second tap with available selection may open it");
        Check(state.revealed() == !selected,"opening consumes readiness while empty selection keeps chooser");
        if (selected) Check(state.tap(true,true,false,false,false) == PPOHandleAction::RevealChooser,
            "a following tap after opening starts a fresh two-step sequence");
    }
    for (bool owned : {false,true}) for (bool opened : {false,true})
        for (bool revealed : {false,true}) for (bool nubbed : {false,true}) {
            PPOHandleInteraction state;
            if (revealed) state.longPress(true);
            const auto action=state.tap(true,true,owned,opened,nubbed);
            if (opened && !owned) Check(action==PPOHandleAction::None && !state.revealed(),
                "inconsistent owned-window flags fail closed");
            else if (nubbed) Check(action==PPOHandleAction::RevealChooser && state.revealed(),
                "nub reveal has priority even over a retained owned scene");
            else if (owned && (opened || revealed)) Check(action==PPOHandleAction::ToggleOwned && !state.revealed(),
                "open owned scene may retract, but retracted scene needs the revealed second tap");
            else Check(action==(revealed ? PPOHandleAction::OpenSelected : PPOHandleAction::RevealChooser),
                "an unopened selection needs separate handle reveal before opening");
        }
    for (bool selected : {false,true}) {
        PPOHandleInteraction state;
        Check(state.tap(true,selected,true,false,false)==PPOHandleAction::RevealChooser && state.revealed(),
            "first touch on retained retracted window only reveals choices");
        Check(state.tap(true,selected,true,false,false)==PPOHandleAction::ToggleOwned && !state.revealed(),
            "second separate touch may reopen the retained owned window");
        Check(state.tap(true,selected,true,true,false)==PPOHandleAction::ToggleOwned,
            "touching an already open owned window may retract it");
    }
    {
        PPOHandleInteraction state;
        Check(state.rowSelection(true,true) == PPOHandleAction::None,"hidden stale row is refused");
        Check(state.longPress(true) == PPOHandleAction::RevealChooser && state.revealed(),"long press reveals without opening");
        Check(state.rowSelection(true,false) == PPOHandleAction::None && state.revealed(),"unavailable row stays a chooser");
        Check(state.rowSelection(true,true) == PPOHandleAction::OpenChosen && !state.revealed(),"visible available row explicitly opens its frozen choice");
        Check(state.rowSelection(true,true) == PPOHandleAction::None,"duplicate row event cannot re-open after selection");
        state.longPress(true);
        Check(state.rowSelection(false,true) == PPOHandleAction::None && !state.revealed(),"disabled row clears readiness");
    }
    for (auto side : {PPOEdgeDrawerSide::Left,PPOEdgeDrawerSide::Right}) {
        for (bool owned : {false,true}) for (bool before : {false,true})
            for (bool opened : {false,true}) for (bool cancelled : {false,true}) {
                PPOHandleInteraction state;
                if (before) state.longPress(true);
                const auto ticket = state.beginPan(side,true,owned);
                Check(ticket != 0 && state.panActive() && state.revealed() == before,
                    "pan begin changes no readiness and issues a separate terminal ticket");
                Check(state.finishPan(ticket+1,opened,cancelled) == PPOHandleAction::None && state.panActive(),
                    "wrong terminal ticket cannot consume the current pan");
                const auto action = state.finishPan(ticket,opened,cancelled);
                Check(!Opens(action),"no committed/cancelled inward pan can request an application opening");
                if (owned) Check(action == PPOHandleAction::FinishOwnedGesture,
                    "owned pan completion is restricted to the already owned window");
                else Check(action == ((cancelled ? before : opened) ? PPOHandleAction::RevealChooser : PPOHandleAction::HideChooser),
                    "new-window pan chooses only reveal/hide including cancellation rollback");
                Check(state.revealed() == (cancelled ? before : (owned ? false : opened)),
                    "cancelled pan restores previous readiness; ordinary reveal commits only on release");
                Check(!state.panActive(),"terminal completion is consumed once");
                const bool after = state.revealed();
                Check(state.finishPan(ticket,true,false) == PPOHandleAction::None && state.revealed() == after,
                    "duplicate terminal cannot re-arm or request another action");
            }
        // Integration contract with the existing direction/nub policy: outward
        // and vertical decisions never issue a drawer policy ticket.
        for (int dx=-96;dx<=96;dx+=4) for (int dy=-96;dy<=96;dy+=4) {
            PPOHandleNubState direction;
            PPOHandleInteraction interaction;
            Check(direction.begin(side,true,true),"direction fixture starts closed");
            const auto mode=direction.update(Inward(side,dx),dy,0,0);
            std::uint64_t ticket=0;
            if (mode == PPOHandlePanMode::Drawer) ticket=interaction.beginPan(side,true,false);
            Check(!interaction.revealed(),"classifying/starting a drag never arms an immediate app tap");
            if (ticket) {
                const auto action=interaction.finishPan(ticket,true,false);
                Check(action == PPOHandleAction::RevealChooser && !Opens(action),
                    "an inward release routes only to chooser reveal");
            } else {
                Check(!interaction.panActive() && !interaction.revealed(),
                    "outward, vertical and pending samples never enter opening coordinator");
            }
        }
    }
    {
        PPOHandleInteraction state;
        const auto first=state.beginPan(PPOEdgeDrawerSide::Left,true,false);
        const auto second=state.beginPan(PPOEdgeDrawerSide::Left,true,false);
        Check(second>first && state.finishPan(first,true,false)==PPOHandleAction::None,
            "a newer pan makes the older terminal stale");
        Check(state.finishPan(second,true,false)==PPOHandleAction::RevealChooser,"newest terminal can reveal once");
        const auto pending=state.beginPan(PPOEdgeDrawerSide::Left,true,false);
        state.reset();
        Check(!state.revealed() && !state.panActive() && state.finishPan(pending,true,false)==PPOHandleAction::None,
            "lock/disable/edge reset prevents late reveal");
        state.longPress(true);
        Check(state.beginPan(static_cast<PPOEdgeDrawerSide>(55),true,false)==0 && !state.revealed(),
            "invalid edge fails closed and cannot keep a ready tap");
        state.longPress(true);
        Check(state.beginPan(PPOEdgeDrawerSide::Right,false,false)==0 && !state.revealed(),
            "disabled drag fails closed");
        Check(state.finishPan(0,true,false)==PPOHandleAction::None,"zero ticket is never usable");
        state.longPress(true);
        Check(state.tap(false,true,false,false,false)==PPOHandleAction::None && !state.revealed(),"disabled tap clears prior readiness");
        Check(state.longPress(false)==PPOHandleAction::None && !state.revealed(),"disabled long press cannot arm");
    }
    {
        const auto maximum=std::numeric_limits<std::uint64_t>::max();
        PPOHandleInteraction state(maximum-2);
        const auto last=state.beginPan(PPOEdgeDrawerSide::Left,true,false);
        Check(last==maximum-1,"last non-reserved pan ticket may be issued");
        Check(state.finishPan(last,true,false)==PPOHandleAction::RevealChooser,"last ticket still reveals only");
        Check(state.beginPan(PPOEdgeDrawerSide::Left,true,false)==0 && !state.revealed(),"exhaustion clears readiness without wrapping");
        for (unsigned i=0;i<20;i++) Check(state.beginPan(PPOEdgeDrawerSide::Right,true,false)==0,"exhausted pan counter stays unusable");
        Check(state.tap(true,true,false,false,false)==PPOHandleAction::RevealChooser,"counter exhaustion cannot manufacture selected-app readiness");
    }
    std::mt19937_64 random(0x504f50414eULL);
    for (unsigned round=0;round<2000;round++) {
        PPOHandleInteraction state;
        std::uint64_t ticket=0;
        for (unsigned step=0;step<100;step++) {
            const unsigned operation=static_cast<unsigned>(random()%7);
            const bool allowed=(random()%5)!=0, selected=random()%2, owned=random()%2, opened=owned && random()%2, nubbed=random()%2;
            const bool before=state.revealed();
            PPOHandleAction action=PPOHandleAction::None;
            if (operation==0) {
                action=state.tap(allowed,selected,owned,opened,nubbed);
                Check(action!=PPOHandleAction::OpenSelected || (allowed&&selected&&!owned&&!nubbed&&before),
                    "random selected opening always requires the prior revealed state and a distinct tap");
            } else if(operation==1) {
                action=state.longPress(allowed);
                Check(!Opens(action),"random long press never opens");
            } else if(operation==2) {
                action=state.rowSelection(allowed,selected);
                Check(action!=PPOHandleAction::OpenChosen || (allowed&&selected&&before),
                    "random row opening requires visible readiness and available explicit choice");
            } else if(operation==3) {
                ticket=state.beginPan(random()%2?PPOEdgeDrawerSide::Left:PPOEdgeDrawerSide::Right,allowed,owned);
                Check(!allowed || state.revealed()==before,"random pan begin cannot arm a first reveal");
            } else if(operation==4 || operation==5) {
                action=state.finishPan(operation==4?ticket:ticket+1,random()%2,random()%2);
                Check(!Opens(action),"random late/cancelled/completed pan never opens an app");
            } else {
                state.reset(); Check(!state.revealed()&&!state.panActive(),"random dismissal clears transient state");
            }
            Check(action!=PPOHandleAction::OpenSelected || operation==0,"only direct taps can open cached selected app");
            Check(action!=PPOHandleAction::OpenChosen || operation==2,"only direct row choices can open a new explicit choice");
        }
    }
    std::printf("Handle interaction tests passed: %u checks; public two-stage intent only, not UIKit or application hosting\n",checks);
}
