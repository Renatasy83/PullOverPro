#include "../PPOMessengerKeepPolicy.h"
#include "../PPOWindowLifetime.h"
#include <cstdio>
#include <cstdlib>
#include <initializer_list>
#include <limits>

static unsigned checks;
static void Check(bool ok, const char *message) {
    ++checks;
    if (!ok) { std::fprintf(stderr, "FAIL: %s\n", message); std::exit(1); }
}
static void CheckLatched(PPOMessengerKeepPolicy &policy, PPOMessengerKeepStop expected) {
    Check(policy.stopped() && policy.reason() == expected, "terminal reason retained");
    Check(!policy.start(10000), "terminal budget cannot restart");
    Check(policy.evaluate(0) == expected &&
          policy.evaluate(std::numeric_limits<double>::quiet_NaN()) == expected,
          "later clocks cannot change a latched terminal outcome");
}
static PPOWindowConditions Healthy(double now) {
    PPOWindowConditions c;
    c.now=now;c.allowed=true;c.protectedDataAvailable=true;c.hostActive=true;
    c.lockKnown=true;c.sceneKnown=true;c.sceneValid=true;c.sceneActive=true;c.renderReady=true;
    return c;
}
// Production root ordering: normal safety/15-second policy first, then the
// independent absolute Messenger budget. No UIKit or copied policy decisions.
static bool EvaluateBoth(PPOWindowLifetime &normal, PPOMessengerKeepPolicy &budget,
                         const PPOWindowConditions &conditions) {
    return normal.evaluate(conditions)==PPOWindowStop::None &&
        budget.evaluate(conditions.now)==PPOMessengerKeepStop::None;
}

int main() {
    using Stop = PPOMessengerKeepStop;
    {
        PPOMessengerKeepPolicy policy;
        Check(!policy.started() && !policy.stopped(), "new budget is not started");
        Check(policy.evaluate(0) == Stop::ClockInvalid, "evaluation before pre-prepare start fails closed");
        CheckLatched(policy, Stop::ClockInvalid);
    }
    for (double epoch : {0.0, 1.25, 100.0, 1000000.0, 1000000000.0, 4294967000.0}) {
        PPOMessengerKeepPolicy policy;
        Check(policy.start(epoch) && policy.started(), "valid nonnegative start");
        Check(policy.startedAt() == epoch && policy.deadline() == epoch + 120.0,
              "fixed root cap is measured from pre-prepare epoch");
        Check(policy.evaluate(epoch) == Stop::None, "equal initial clock allowed");
        Check(policy.evaluate(epoch + 14.0) == Stop::None, "budget permits early explicit Keep decision");
        Check(policy.evaluate(epoch + 15.0) == Stop::None,
              "this additional budget does not implement the independent normal15second policy");
        Check(policy.evaluate(epoch + 20.0) == Stop::None, "bounded Keep budget can cross old companion ceiling");
        Check(policy.evaluate(epoch + 119.0) == Stop::None, "budget remains live just before cap");
        Check(policy.evaluate(epoch + 120.0) == Stop::Limit, "root closes at exact absolute cap");
        CheckLatched(policy, Stop::Limit);
    }
    {
        PPOMessengerKeepPolicy policy;
        Check(policy.start(100), "repeat-press fixture start");
        for (unsigned press = 0; press < 100; ++press) {
            double now = 101.0 + double(press) / 10.0;
            Check(policy.evaluate(now) == Stop::None, "healthy early Keep decision");
            Check(!policy.start(now), "repeated Keep must not reset budget epoch");
            Check(policy.deadline() == 220.0 && policy.startedAt() == 100.0,
                  "one hundred repeated requests retain original absolute deadline");
        }
        Check(!policy.start(std::numeric_limits<double>::quiet_NaN()),
              "invalid duplicate also cannot alter active budget");
        Check(policy.evaluate(111.0) == Stop::None && policy.deadline() == 220.0,
              "rejected duplicate does not corrupt active clock or deadline");
        Check(policy.evaluate(220.0) == Stop::Limit, "repeated presses never extend final cap");
    }
    for (double invalid : {-1.0, -std::numeric_limits<double>::infinity(),
            std::numeric_limits<double>::infinity(), std::numeric_limits<double>::quiet_NaN(),
            std::numeric_limits<double>::max()}) {
        PPOMessengerKeepPolicy policy;
        Check(!policy.start(invalid), "invalid or unrepresentable first budget start rejected");
        Check(!policy.started(), "failed first attempt never becomes started");
        CheckLatched(policy, Stop::ClockInvalid);
    }
    for (double invalid : {-1.0, 99.999, -std::numeric_limits<double>::infinity(),
            std::numeric_limits<double>::infinity(), std::numeric_limits<double>::quiet_NaN()}) {
        PPOMessengerKeepPolicy policy;
        Check(policy.start(100), "bad-evaluation fixture start");
        Check(policy.evaluate(invalid) == Stop::ClockInvalid, "negative, nonfinite or backward observation fails closed");
        CheckLatched(policy, Stop::ClockInvalid);
    }
    {
        PPOMessengerKeepPolicy policy;
        Check(policy.start(100) && policy.evaluate(110) == Stop::None, "advance initial clock");
        Check(policy.evaluate(109) == Stop::ClockInvalid, "backward clock after a healthy observation rejected");
        CheckLatched(policy, Stop::ClockInvalid);
    }
    {
        PPOMessengerKeepPolicy policy;
        Check(policy.start(100), "large finite jump fixture");
        Check(policy.evaluate(std::numeric_limits<double>::max()) == Stop::Limit,
              "finite future jump closes instead of extending a budget");
        CheckLatched(policy, Stop::Limit);
    }
    // These cross-process clocks use the same system-uptime epoch. The root
    // caller must establish its cap before creating the owned scope: merely
    // starting at window-shown would not establish this ordering guarantee.
    for (double rootEpoch : {0.0, 1.25, 100.0, 1000000.0, 1000000000.0}) {
        for (double preparationDelay : {0.0, 0.25, 2.0, 20.0, 119.0, 120.0, 1200.0}) {
            PPOMessengerKeepPolicy root;
            Check(root.start(rootEpoch), "ordering fixture root pre-prepare stamp");
            double scopeStart = rootEpoch + preparationDelay;
            double agentDeadline = scopeStart + PPOMessengerKeepPolicy::CompanionMaximumSeconds;
            Check(root.deadline() + PPOMessengerKeepPolicy::CleanupMarginSeconds <= agentDeadline,
                  "scope-start companion deadline covers root absolute cap and cleanup margin");
            Check(root.evaluate(scopeStart) == (preparationDelay >= 120.0 ? Stop::Limit : Stop::None),
                  "slow preparation consumes rather than restarts root budget");
        }
    }
    {
        double hypotheticalLateRootStamp = 100.0, earlierScopeStamp = 94.0;
        Check(earlierScopeStamp + PPOMessengerKeepPolicy::CompanionMaximumSeconds <
              hypotheticalLateRootStamp + PPOMessengerKeepPolicy::MaximumSeconds,
              "late window-shown root stamp would invalidate the cleanup guarantee");
    }
    {
        PPOMessengerKeepPolicy budget;PPOWindowLifetime normal;
        Check(budget.start(100) && normal.start(100), "composed timed start");
        Check(EvaluateBoth(normal,budget,Healthy(100)), "composed initial active state");
        Check(EvaluateBoth(normal,budget,Healthy(114.999)), "default healthy before15seconds");
        Check(!EvaluateBoth(normal,budget,Healthy(115)), "default still closes at15seconds");
        Check(normal.evaluate(Healthy(116))==PPOWindowStop::Timeout && !budget.stopped(),
              "default deadline wins without consuming absolute120second budget");
    }
    {
        PPOMessengerKeepPolicy budget;PPOWindowLifetime normal;
        Check(budget.start(100) && normal.start(100) && EvaluateBoth(normal,budget,Healthy(100)),
              "composed explicit Keep start");
        Check(budget.evaluate(114)==Stop::None && normal.keep(Healthy(114)),
              "explicit Keep before normal deadline accepted under live absolute cap");
        for (double now : {115.0,120.0,130.0,180.0,219.0}) {
            Check(EvaluateBoth(normal,budget,Healthy(now)), "explicit bounded Keep survives15/old20second bounds");
            Check(normal.keep(Healthy(now)) && budget.deadline()==220.0,
                  "duplicate generic Keep cannot reset the independent absolute budget");
        }
        Check(!EvaluateBoth(normal,budget,Healthy(220)) && budget.reason()==Stop::Limit,
              "kept generic lifetime is still stopped by root120second absolute cap");
    }
    for (double requestTime : {115.0,115.001,120.0}) {
        PPOMessengerKeepPolicy budget;PPOWindowLifetime normal;
        Check(budget.start(100) && normal.start(100) && EvaluateBoth(normal,budget,Healthy(100)),
              "late Keep fixture initialized");
        Check(budget.evaluate(requestTime)==Stop::None && !normal.keep(Healthy(requestTime)),
              "live120second cap cannot bypass already elapsed15second default deadline");
        Check(!normal.kept() && normal.evaluate(Healthy(requestTime))==PPOWindowStop::Timeout,
              "late Keep refusal is terminal and cannot enable kept mode");
    }
    {
        PPOMessengerKeepPolicy budget;PPOWindowLifetime normal;
        Check(budget.start(100) && normal.start(100) && EvaluateBoth(normal,budget,Healthy(100)),
              "slow render probe fixture initialized");
        PPOWindowConditions beforeProbe=Healthy(114.9);
        Check(EvaluateBoth(normal,budget,beforeProbe), "request began before timed deadline");
        PPOWindowConditions refreshed=Healthy(115.1);
        Check(budget.evaluate(refreshed.now)==Stop::None && !normal.keep(refreshed),
              "fresh clock after render probe crosses15seconds and refuses late Keep");
        Check(!normal.kept() && budget.deadline()==220.0,
              "render observation latency does not grant Keep or restart absolute budget");
    }
    for (unsigned fault=0;fault<3;fault++) {
        PPOMessengerKeepPolicy budget;PPOWindowLifetime normal;
        Check(budget.start(100) && normal.start(100) && EvaluateBoth(normal,budget,Healthy(100)) &&
              normal.keep(Healthy(110)), "safety-closure kept fixture");
        PPOWindowConditions conditions=Healthy(220);
        PPOWindowStop expected=PPOWindowStop::None;
        if (fault==0) { conditions.locked=true;expected=PPOWindowStop::Locked; }
        if (fault==1) { conditions.allowed=false;expected=PPOWindowStop::Disabled; }
        if (fault==2) { conditions.sceneValid=false;expected=PPOWindowStop::SceneInvalid; }
        Check(!EvaluateBoth(normal,budget,conditions), "normal safety closure precedes coincident absolute limit");
        Check(normal.evaluate(Healthy(221))==expected && budget.reason()==Stop::None,
              "lock/disabled/invalid-scene cause preserved rather than overwritten by120second limit");
    }
    for (double preparationDelay : {2.0,20.0,110.0,119.0}) {
        PPOMessengerKeepPolicy budget;PPOWindowLifetime normal;
        double visibleAt=100.0+preparationDelay;
        Check(budget.start(100) && normal.start(visibleAt), "slow prepare retains pre-prepare absolute epoch");
        Check(EvaluateBoth(normal,budget,Healthy(visibleAt)), "visible start uses remaining absolute budget");
        Check(budget.deadline()==220.0, "visible start never grants fresh120seconds");
        if (preparationDelay==119.0)
            Check(!EvaluateBoth(normal,budget,Healthy(220)) && budget.reason()==Stop::Limit,
                  "late-visible window closes after remaining1second even within normal15second lifetime");
    }
    {
        PPOMessengerKeepPolicy budget;PPOWindowLifetime normal;
        Check(budget.start(100) && normal.start(120), "activation grace after slow preparation");
        PPOWindowConditions pending=Healthy(121.999);pending.sceneActive=false;
        Check(EvaluateBoth(normal,budget,pending), "normal2second activation grace is relative to visible start");
        pending.now=122.0;
        Check(!EvaluateBoth(normal,budget,pending) &&
              normal.evaluate(Healthy(123))==PPOWindowStop::ActivationTimeout,
              "slow private preparation does not reset or extend visible-start activation grace");
        Check(budget.deadline()==220.0 && budget.reason()==Stop::None,
              "activation timeout leaves original absolute deadline unchanged");
    }
    std::printf("Messenger bounded Keep policy tests passed: %u checks; absolute root cap and companion ordering only, not UIKit lifetime\n", checks);
}
