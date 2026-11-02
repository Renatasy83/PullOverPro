#include "../PPOWindowLifetime.h"

#include <cstdio>
#include <cstdlib>
#include <initializer_list>
#include <limits>

static unsigned checks;
static void Check(bool condition, const char *message) {
    ++checks;
    if (!condition) {
        std::fprintf(stderr, "FAIL: %s\n", message);
        std::exit(1);
    }
}

static PPOWindowConditions Healthy(double now = 100.0) {
    PPOWindowConditions conditions;
    conditions.now = now;
    conditions.allowed = true;
    conditions.protectedDataAvailable = true;
    conditions.hostActive = true;
    conditions.lockKnown = true;
    conditions.sceneKnown = true;
    conditions.sceneValid = true;
    conditions.sceneActive = true;
    return conditions;
}

static void CheckLatched(PPOWindowLifetime &lifetime, PPOWindowStop reason,
                         double nextTime = 1000) {
    Check(lifetime.stopped(), "a safety closure latches stopped state");
    Check(lifetime.evaluate(Healthy(nextTime)) == reason,
          "healthy later observations cannot revive a closed policy");
    Check(!lifetime.keep(Healthy(nextTime)), "Keep cannot revive a closed policy");
    Check(!lifetime.start(nextTime), "start cannot revive a closed policy");
    Check(lifetime.evaluate(Healthy(nextTime)) == reason,
          "reentry and rejected operations preserve the original close reason");
}

int main() {
    {
        PPOWindowLifetime lifetime;
        Check(!lifetime.kept() && !lifetime.observedActive() && !lifetime.stopped(),
              "new policy has no implicit Keep, activation or close");
        Check(lifetime.start(100), "a finite monotonic origin starts once");
        Check(lifetime.evaluate(Healthy(100)) == PPOWindowStop::None,
              "a valid active scene is admitted at the origin");
        Check(lifetime.observedActive(), "activation is remembered after observation");
        Check(lifetime.evaluate(Healthy(114.999)) == PPOWindowStop::None,
              "the timed window remains open before its deadline");
        Check(!lifetime.start(114.999), "a duplicate start cannot extend the deadline");
        Check(lifetime.evaluate(Healthy(115)) == PPOWindowStop::Timeout,
              "the unextended deadline closes exactly at 15 seconds");
        CheckLatched(lifetime, PPOWindowStop::Timeout);
    }
    for (double elapsed : {15.0, 15.001, 10000.0}) {
        PPOWindowLifetime lifetime;
        Check(lifetime.start(100), "deadline fixture starts");
        Check(!lifetime.keep(Healthy(100 + elapsed)),
              "Keep at or after an expired deadline is refused");
        Check(!lifetime.kept(), "an expired request never records Keep");
        CheckLatched(lifetime, PPOWindowStop::Timeout, 20000);
    }
    {
        PPOWindowLifetime lifetime;
        Check(lifetime.start(100), "Keep fixture starts");
        Check(lifetime.keep(Healthy(114.999)), "explicit Keep before the deadline succeeds");
        Check(lifetime.kept() && lifetime.observedActive() && !lifetime.stopped(),
              "Keep records an active healthy session");
        for (double elapsed : {15.0, 100.0, 3600.0, 36000000.0}) {
            Check(lifetime.evaluate(Healthy(100 + elapsed)) == PPOWindowStop::None,
                  "a kept healthy window has no former timed deadline");
            Check(lifetime.keep(Healthy(100 + elapsed)),
                  "duplicate Keep is idempotent while all guards remain healthy");
        }
        auto inactive = Healthy(36000200);
        inactive.sceneActive = false;
        Check(lifetime.evaluate(inactive) == PPOWindowStop::SceneInactive,
              "Keep never suppresses loss of an activated scene");
        CheckLatched(lifetime, PPOWindowStop::SceneInactive, 36000300);
    }
    {
        PPOWindowLifetime lifetime;
        Check(lifetime.start(100), "startup grace fixture starts");
        auto inactive = Healthy(100);
        inactive.sceneActive = false;
        Check(lifetime.evaluate(inactive) == PPOWindowStop::None,
              "a valid inactive scene gets a bounded startup grace");
        Check(!lifetime.keep(inactive) && !lifetime.kept() && !lifetime.stopped(),
              "an unactivated scene cannot be kept, even within grace");
        inactive.now = 101.999;
        Check(lifetime.evaluate(inactive) == PPOWindowStop::None,
              "startup grace remains open just before its boundary");
        inactive.now = 102;
        Check(lifetime.evaluate(inactive) == PPOWindowStop::ActivationTimeout,
              "an inactive scene closes at the two-second grace boundary");
        CheckLatched(lifetime, PPOWindowStop::ActivationTimeout);
    }
    {
        PPOWindowLifetime lifetime;
        Check(lifetime.start(100), "late activation fixture starts");
        auto conditions = Healthy(101.999);
        conditions.sceneActive = false;
        Check(lifetime.evaluate(conditions) == PPOWindowStop::None,
              "late activation can occur during the bounded grace");
        conditions.sceneActive = true;
        conditions.now = 102;
        Check(lifetime.evaluate(conditions) == PPOWindowStop::None,
              "a currently active scene at the boundary is valid");
        conditions.sceneActive = false;
        Check(lifetime.evaluate(conditions) == PPOWindowStop::SceneInactive,
              "a scene that activated cannot receive a second startup grace");
        CheckLatched(lifetime, PPOWindowStop::SceneInactive);
    }
    {
        PPOWindowLifetime lifetime;
        Check(lifetime.start(100), "Keep after startup fixture starts");
        auto inactive = Healthy(101);
        inactive.sceneActive = false;
        Check(!lifetime.keep(inactive) && !lifetime.stopped(),
              "an early inactive Keep request is refused without consuming activation grace");
        Check(lifetime.keep(Healthy(101.5)) && lifetime.kept(),
              "a later currently active observation can accept explicit Keep");
        Check(lifetime.evaluate(Healthy(1000)) == PPOWindowStop::None,
              "successful post-activation Keep removes the original timed deadline");
    }
    for (bool unknown : {false, true}) {
        PPOWindowLifetime lifetime;
        Check(lifetime.start(100), "untrusted startup scene fixture starts");
        auto conditions = Healthy(100.1);
        conditions.sceneActive = false;
        conditions.sceneKnown = !unknown;
        conditions.sceneValid = false;
        const auto expected = unknown ? PPOWindowStop::SceneUnknown : PPOWindowStop::SceneInvalid;
        Check(lifetime.evaluate(conditions) == expected,
              "activation grace never admits unknown or invalid scene observations");
        CheckLatched(lifetime, expected);
    }

    // Each row changes a single safety observation. Exercise it at the timed
    // deadline and far into Keep mode, so elapsed time cannot mask a failure.
    struct GuardFailure {
        bool PPOWindowConditions::*field;
        bool value;
        PPOWindowStop expected;
    };
    const GuardFailure failures[] = {
        {&PPOWindowConditions::allowed, false, PPOWindowStop::Disabled},
        {&PPOWindowConditions::protectedDataAvailable, false, PPOWindowStop::ProtectedDataUnavailable},
        {&PPOWindowConditions::hostActive, false, PPOWindowStop::HostInactive},
        {&PPOWindowConditions::lockKnown, false, PPOWindowStop::LockUnknown},
        {&PPOWindowConditions::locked, true, PPOWindowStop::Locked},
        {&PPOWindowConditions::waitingToLock, true, PPOWindowStop::Locked},
        {&PPOWindowConditions::sceneKnown, false, PPOWindowStop::SceneUnknown},
        {&PPOWindowConditions::sceneValid, false, PPOWindowStop::SceneInvalid},
        {&PPOWindowConditions::sceneActive, false, PPOWindowStop::SceneInactive}
    };
    for (const auto &failure : failures) {
        for (bool keep : {false, true}) {
            PPOWindowLifetime lifetime;
            Check(lifetime.start(100), "safety failure fixture starts");
            Check(lifetime.evaluate(Healthy()) == PPOWindowStop::None,
                  "safety fixture first observes an active scene");
            if (keep) Check(lifetime.keep(Healthy(101)), "safety fixture enters Keep");
            auto conditions = Healthy(keep ? 100000 : 115);
            conditions.*(failure.field) = failure.value;
            Check(lifetime.evaluate(conditions) == failure.expected,
                  "every safety failure closes both timed and kept modes before timeout");
            CheckLatched(lifetime, failure.expected, 200000);
        }
        PPOWindowLifetime lifetime;
        Check(lifetime.start(100), "same-turn Keep rejection fixture starts");
        Check(lifetime.evaluate(Healthy()) == PPOWindowStop::None,
              "same-turn fixture has activated");
        auto conditions = Healthy(114.999);
        conditions.*(failure.field) = failure.value;
        Check(!lifetime.keep(conditions) && !lifetime.kept(),
              "Keep in the same turn as a safety failure cannot escape closure");
        CheckLatched(lifetime, failure.expected);
    }
    {
        PPOWindowLifetime lifetime;
        Check(lifetime.start(100), "precedence fixture starts");
        PPOWindowConditions unavailable;
        unavailable.now = 115;
        unavailable.locked = true;
        Check(lifetime.evaluate(unavailable) == PPOWindowStop::Disabled,
              "disable wins when many failures coincide with the deadline");
        CheckLatched(lifetime, PPOWindowStop::Disabled);
    }
    {
        PPOWindowLifetime lifetime;
        Check(lifetime.start(100), "unknown lock precedence fixture starts");
        auto conditions = Healthy(115);
        conditions.lockKnown = false;
        conditions.locked = true;
        conditions.sceneKnown = false;
        Check(lifetime.evaluate(conditions) == PPOWindowStop::LockUnknown,
              "unknown lock evidence is never represented as a verified locked state");
        CheckLatched(lifetime, PPOWindowStop::LockUnknown);
    }

    const double badClocks[] = {-1, std::numeric_limits<double>::infinity(),
        -std::numeric_limits<double>::infinity(), std::numeric_limits<double>::quiet_NaN()};
    for (double bad : badClocks) {
        PPOWindowLifetime lifetime;
        Check(!lifetime.start(bad), "invalid start clocks are refused");
        CheckLatched(lifetime, PPOWindowStop::ClockInvalid);
    }
    for (double bad : badClocks) {
        PPOWindowLifetime lifetime;
        Check(lifetime.start(100), "invalid subsequent clock fixture starts");
        Check(lifetime.keep(Healthy(101)), "clock fixture enters Keep");
        Check(lifetime.evaluate(Healthy(bad)) == PPOWindowStop::ClockInvalid,
              "Keep cannot bypass invalid or regressing clock observations");
        CheckLatched(lifetime, PPOWindowStop::ClockInvalid);
    }
    {
        PPOWindowLifetime lifetime;
        Check(lifetime.start(100), "clock regression fixture starts");
        Check(lifetime.evaluate(Healthy(105)) == PPOWindowStop::None,
              "forward clock step is valid");
        Check(lifetime.evaluate(Healthy(105)) == PPOWindowStop::None,
              "same-timestamp events are allowed");
        Check(lifetime.evaluate(Healthy(104.999)) == PPOWindowStop::ClockInvalid,
              "clock regression closes even when still after the start time");
        CheckLatched(lifetime, PPOWindowStop::ClockInvalid);
    }
    {
        PPOWindowLifetime lifetime;
        Check(lifetime.evaluate(Healthy()) == PPOWindowStop::ClockInvalid,
              "evaluating before start fails closed");
        CheckLatched(lifetime, PPOWindowStop::ClockInvalid);
    }
    {
        PPOWindowLifetime lifetime;
        Check(!lifetime.keep(Healthy()), "Keep before start cannot initialize a session");
        Check(!lifetime.kept() && !lifetime.observedActive(),
              "pre-start failure cannot claim Keep or activation");
        CheckLatched(lifetime, PPOWindowStop::ClockInvalid);
    }
    {
        PPOWindowLifetime lifetime;
        Check(lifetime.start(0), "zero uptime is a valid finite origin");
        Check(lifetime.keep(Healthy(0)), "Keep at the origin requires a currently active scene");
        Check(lifetime.evaluate(Healthy(std::numeric_limits<double>::max())) == PPOWindowStop::None,
              "elapsed-time arithmetic remains finite at the maximum finite nonnegative clock");
    }

    {
        PPOWindowLifetime cold;
        Check(cold.startForApplicationIdentity(100), "cold identity startup has its own bounded grace");
        auto pending = Healthy(100); pending.sceneActive = false;
        Check(cold.evaluate(pending) == PPOWindowStop::None && !cold.keep(pending), "inactive cold startup cannot enter Keep");
        pending.now = 107.999;
        Check(cold.evaluate(pending) == PPOWindowStop::None, "cold startup remains responsive within eight seconds");
        pending.now = 108;
        Check(cold.evaluate(pending) == PPOWindowStop::ActivationTimeout, "cold inactive startup times out at the bound");
        CheckLatched(cold, PPOWindowStop::ActivationTimeout, 108);
    }
    {
        PPOWindowLifetime cold; Check(cold.startForApplicationIdentity(100), "render startup fixture starts");
        auto active = Healthy(100.2);
        Check(cold.evaluate(active) == PPOWindowStop::None && !cold.keep(active) && !cold.observedRendered(),
              "an active flag without render layers cannot keep a cold black window indefinitely");
        active.now = 108;
        Check(cold.evaluate(active) == PPOWindowStop::ColdRenderTimeout, "cold rendering has the same bounded deadline");
        CheckLatched(cold, PPOWindowStop::ColdRenderTimeout, 108);
    }
    {
        PPOWindowLifetime cold; Check(cold.startForApplicationIdentity(100), "successful cold fixture starts");
        auto active = Healthy(107.9); active.renderReady = true;
        Check(cold.keep(active) && cold.observedRendered(), "active cold rendering can enter configured Keep before deadline");
        active.now = 1000; active.renderReady = false;
        Check(cold.evaluate(active) == PPOWindowStop::None, "startup render proof is latched and not a per-frame pixel guarantee");
        active.locked = true;
        Check(cold.evaluate(active) == PPOWindowStop::Locked, "cold Keep retains the lock stop guard");
    }
    for (unsigned failure = 0; failure < 4; failure++) {
        PPOWindowLifetime cold; Check(cold.startForApplicationIdentity(100), "cold immediate closure fixture starts");
        auto pending = Healthy(100.1); pending.sceneActive = false;
        PPOWindowStop expected;
        if (failure == 0) { pending.allowed = false; expected = PPOWindowStop::Disabled; }
        else if (failure == 1) { pending.locked = true; expected = PPOWindowStop::Locked; }
        else if (failure == 2) { pending.protectedDataAvailable = false; expected = PPOWindowStop::ProtectedDataUnavailable; }
        else { pending.sceneValid = false; expected = PPOWindowStop::SceneInvalid; }
        Check(cold.evaluate(pending) == expected, "cold grace never delays disable/lock/protected-data/invalidation");
    }
    std::printf("Window lifetime tests passed: %u checks; native policy only, not iOS lifecycle\n", checks);
    return 0;
}
