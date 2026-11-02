#include "../PPOHandleNubState.h"
#include <cstdio>
#include <cstdlib>
#include <limits>
#include <random>

static unsigned checks;
static void Check(bool condition, const char *message) {
    checks++;
    if (!condition) { std::fprintf(stderr, "FAIL: %s\n", message); std::exit(1); }
}
static double Out(PPOEdgeDrawerSide side, double value) {
    return side == PPOEdgeDrawerSide::Right ? value : -value;
}
static bool Nub(PPOHandleNubState &state, PPOEdgeDrawerSide side) {
    return state.begin(side, true, true) && state.finish(Out(side, 30), 0, 0, 0, false);
}

int main() {
    PPOHandleNubState idle;
    Check(idle.mode() == PPOHandlePanMode::Inactive && !idle.manualNubbed(), "initial state is expanded and inactive");
    Check(!idle.finish(100, 0, 1000, 0, false), "a terminal event cannot create a gesture");
    Check(!idle.begin(static_cast<PPOEdgeDrawerSide>(17), true, true), "unknown edge cannot start");
    Check(!idle.begin(PPOEdgeDrawerSide::Left, false, true), "disabled overlay cannot start");

    for (auto side : {PPOEdgeDrawerSide::Left, PPOEdgeDrawerSide::Right}) {
        PPOHandleNubState state;
        Check(state.begin(side, true, true), "closed overlay begins undecided");
        Check(state.mode() == PPOHandlePanMode::Pending, "begin does not authorize app inspection");
        Check(state.update(Out(side, 1), 1, Out(side, 79), 0) == PPOHandlePanMode::Pending,
            "below-slop displacement and velocity remain undecided");
        Check(!state.finish(Out(side, 1), 0, 0, 0, false) && !state.manualNubbed(), "small release remains expanded");

        Check(state.begin(side, true, true), "outward session begins");
        Check(state.update(Out(side, 6), 0, 0, 0) == PPOHandlePanMode::Outward, "closed outward direction excludes drawer opening");
        for (int dx = -120; dx <= 120; dx += 3)
            Check(state.update(Out(side, dx), 0, Out(side, -600), 0) == PPOHandlePanMode::Outward,
                "an outward gesture cannot change into an app-opening gesture after reversal");
        Check(!state.finish(Out(side, -80), 0, Out(side, -600), 0, false), "reversed final displacement cannot nub");
        Check(!state.manualNubbed(), "reversal keeps explicit nub clear");

        Check(Nub(state, side) && state.manualNubbed(), "24+ point outward drag commits explicit nub");
        Check(state.mode() == PPOHandlePanMode::Inactive, "terminal event clears transient gesture state");
        Check(!state.finish(Out(side, 30), 0, 0, 0, false) && state.manualNubbed(), "duplicate finish cannot re-emit or reveal committed nub");
        Check(state.visible(true, false, false, false, false, 0, 0, 5), "manual nub remains visible when auto-hide is disabled");
        Check(state.visible(true, false, false, false, true, 1, 1, 30), "auto delay does not postpone manual nub");
        Check(!state.visible(false, false, false, false, true, 100, 0, 1), "disable hides explicit nub");
        Check(!state.visible(true, true, false, false, true, 100, 0, 1), "an open drawer reveals the handle");
        Check(!state.visible(true, false, true, false, true, 100, 0, 1), "a pan reveals the handle");
        Check(!state.visible(true, false, false, true, true, 100, 0, 1), "quick switch reveals the handle");
        state.reveal(); Check(!state.manualNubbed(), "tap/long press/open may explicitly reveal");
        Check(!state.visible(true, false, false, false, false, 100, 0, 1), "revealed manual state cannot be recreated by disabled auto-hide");

        for (bool cancelled : {false, true}) {
            state.reveal(); Check(state.begin(side, true, true), "cancellation fixture begins");
            Check(state.update(Out(side, 30), 0, 0, 0) == PPOHandlePanMode::Outward, "outward fixture does not enter Drawer mode");
            Check(state.finish(Out(side, 30), 0, 0, 0, cancelled) == !cancelled, "only an ended release may commit");
        }
        state.reveal(); Check(state.begin(side, true, true), "failure fixture begins");
        state.cancelGesture(); Check(!state.finish(Out(side, 40), 0, 0, 0, false), "failure cannot be revived by a later finish");

        for (bool closed : {false, true}) {
            state.reveal(); Check(state.begin(side, true, closed), "vertical fixture begins");
            Check(state.update(0, 20, 0, 1000) == PPOHandlePanMode::Vertical, "vertical displacement cannot choose host opening");
            Check(state.update(Out(side, 80), 1, Out(side, 1000), 0) == PPOHandlePanMode::Vertical, "vertical axis remains fixed after horizontal reversal");
            Check(!state.finish(Out(side, 80), 1, Out(side, 1000), 0, false) && !state.manualNubbed(), "vertical gestures cannot commit nub or host direction");
        }
        state.reveal(); Check(state.begin(side, true, false), "already open drawer begins");
        Check(state.update(Out(side, 30), 0, 0, 0) == PPOHandlePanMode::Drawer, "outward motion closes an open drawer through existing drawer policy");
        Check(!state.finish(Out(side, 30), 0, 0, 0, false), "open-drawer close cannot simultaneously create explicit nub");
        Check(state.begin(side, true, true), "inward fixture begins");
        Check(state.update(Out(side, -30), 0, 0, 0) == PPOHandlePanMode::Drawer, "inward motion chooses existing guarded drawer path");
        Check(!state.finish(Out(side, 60), 0, Out(side, 1000), 0, false), "an inward-started gesture cannot become manual nub");

        for (double distance : {0.0, 7.999, 8.0, 12.0, 23.999, 24.0, 60.0})
            for (double velocity : {-600.0, -450.0, -449.0, 0.0, 449.0, 450.0, 600.0}) {
                state.reveal(); Check(state.begin(side, true, true), "threshold fixture starts");
                state.update(Out(side, 6), 0, 0, 0);
                const bool expected = velocity > -450 && (distance >= 24 || (distance >= 8 && velocity >= 450));
                Check(state.finish(Out(side, distance), 0, Out(side, velocity), 0, false) == expected,
                    "outward displacement/flick boundaries and strong opposing flick follow the public policy");
            }
    }

    // Automatic and explicit visibility have different sources. Timer sampling
    // cannot mutate manual state or grant a drawer-opening gesture.
    PPOHandleNubState automatic;
    for (int delay = 0; delay <= 30; delay++) for (int elapsed = 0; elapsed <= 40; elapsed++) {
        Check(automatic.visible(true, false, false, false, true, 100 + elapsed, 100, delay) == (elapsed >= delay),
            "automatic nub begins exactly at its normalized inactivity deadline");
        Check(!automatic.manualNubbed() && automatic.mode() == PPOHandlePanMode::Inactive,
            "timer never creates explicit state or a host-opening gesture");
        for (unsigned context = 0; context < 4; context++)
            Check(!automatic.visible(context != 0, context == 1, context == 2, context == 3, true,
                100 + elapsed, 100, delay), "disabled/open/active gestures suppress automatic nub");
    }
    const double nan = std::numeric_limits<double>::quiet_NaN(), inf = std::numeric_limits<double>::infinity();
    for (double bad : {nan, inf, -inf, -1.0}) {
        Check(!automatic.visible(true, false, false, false, true, bad, 0, 5), "invalid current auto clock cannot hide handle");
        Check(!automatic.visible(true, false, false, false, true, 100, bad, 5), "invalid interaction clock cannot hide handle");
        Check(!automatic.visible(true, false, false, false, true, 100, 0, bad), "invalid auto delay cannot hide handle");
    }
    Check(!automatic.visible(true, false, false, false, true, 100, 101, 5), "clock reversal cannot auto-nub");
    Check(!automatic.visible(true, false, false, false, true, 100, 0, 30.01), "unreviewed delay cannot auto-nub");
    for (auto side : {PPOEdgeDrawerSide::Left, PPOEdgeDrawerSide::Right})
        for (double bad : {nan, inf, -inf, -32769.0, 32769.0}) for (unsigned component = 0; component < 4; component++) {
            PPOHandleNubState invalid;
            Check(invalid.begin(side, true, true), "invalid sample fixture begins");
            double v[4] = {Out(side, 30), 0, Out(side, 500), 0}; v[component] = bad;
            Check(invalid.update(v[0], v[1], v[2], v[3]) == PPOHandlePanMode::Inactive &&
                !invalid.finish(Out(side, 30), 0, Out(side, 500), 0, false) && !invalid.manualNubbed(),
                "nonfinite/out-of-bounds displacement or velocity cancels without later revival");
        }

    // Replay varied reversals, vertical samples and terminal ordering. The
    // original classification alone controls whether a host intent is possible;
    // a later outward release is never substituted for a Drawer classification.
    std::mt19937_64 random(0x50504f4e55424cULL);
    for (unsigned iteration = 0; iteration < 24000; iteration++) {
        const auto side = iteration % 2 ? PPOEdgeDrawerSide::Left : PPOEdgeDrawerSide::Right;
        const bool closed = iteration % 3 != 0, cancelled = iteration % 5 == 0;
        PPOHandleNubState state;
        Check(state.begin(side, true, closed), "mixed fixture begins");
        const unsigned first = iteration % 3;
        const double dx = first == 0 ? Out(side, 12) : (first == 1 ? Out(side, -12) : 0);
        const double dy = first == 2 ? 20 : 0;
        const auto locked = state.update(dx, dy, 0, 0);
        const auto expected = first == 2 ? PPOHandlePanMode::Vertical :
            (closed && first == 0 ? PPOHandlePanMode::Outward : PPOHandlePanMode::Drawer);
        Check(locked == expected, "first deliberate axis/direction establishes the only transient mode");
        unsigned hostPreparations = 0;
        if (locked == PPOHandlePanMode::Drawer) hostPreparations++;
        for (unsigned n = 0; n < 12; n++) {
            const double x = static_cast<int>(random() % 481) - 240;
            const double y = static_cast<int>(random() % 481) - 240;
            const double vx = static_cast<int>(random() % 2401) - 1200;
            const double vy = static_cast<int>(random() % 2401) - 1200;
            Check(state.update(x, y, vx, vy) == locked, "valid reversal/noise never changes the locked gesture mode");
        }
        const bool nubbed = state.finish(Out(side, 40), 0, 0, 0, cancelled);
        Check(nubbed == (!cancelled && locked == PPOHandlePanMode::Outward), "only a noncancelled outward closed mode commits");
        Check(hostPreparations == (locked == PPOHandlePanMode::Drawer ? 1u : 0u),
            "outward and vertical gestures produce no host-preparation transition");
        Check(state.mode() == PPOHandlePanMode::Inactive && state.manualNubbed() == nubbed,
            "terminal state retains only actual explicit nub outcome");
        Check(!state.finish(Out(side, 40), 0, 0, 0, false), "out-of-order duplicate terminal event cannot commit");
        if (iteration % 2) state.reveal();
        Check(state.visible(true, false, false, false, false, 100, 100, 5) == (nubbed && iteration % 2 == 0),
            "explicit reveal and disabled auto preference preserve independent manual-state semantics");
    }
    std::printf("Handle nub state tests passed: %u checks; public gesture/visibility policy, not UIKit delivery\n", checks);
    return 0;
}
