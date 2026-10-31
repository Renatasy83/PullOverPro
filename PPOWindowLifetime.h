#pragma once

#include <cmath>

// A decision policy only: no clock reads, UIKit, private APIs or side effects.
// The caller supplies one coherent main-thread observation for each decision.
struct PPOWindowConditions {
    double now = 0;
    bool allowed = false;
    bool protectedDataAvailable = false;
    bool hostActive = false;
    bool lockKnown = false;
    bool locked = false;
    bool waitingToLock = false;
    bool sceneKnown = false;
    bool sceneValid = false;
    bool sceneActive = false;
};

enum class PPOWindowStop {
    None,
    Disabled,
    ProtectedDataUnavailable,
    HostInactive,
    LockUnknown,
    Locked,
    SceneUnknown,
    SceneInvalid,
    SceneInactive,
    ActivationTimeout,
    ClockInvalid,
    Timeout
};

class PPOWindowLifetime {
public:
    static constexpr double TimedSeconds = 15.0;
    static constexpr double ActivationGraceSeconds = 2.0;

    // The first start attempt is final. A duplicate cannot reset a deadline or
    // revive a stopped session. Rejected duplicates preserve the current state.
    bool start(double now) noexcept {
        if (startAttempted_ || stopped()) return false;
        startAttempted_ = true;
        if (!std::isfinite(now) || now < 0) {
            reason_ = PPOWindowStop::ClockInvalid;
            return false;
        }
        started_ = true;
        startTime_ = lastTime_ = now;
        return true;
    }

    PPOWindowStop evaluate(const PPOWindowConditions &conditions) noexcept {
        if (stopped()) return reason_;
        if (!started_ || !std::isfinite(conditions.now) || conditions.now < lastTime_)
            return stop(PPOWindowStop::ClockInvalid);
        lastTime_ = conditions.now;

        // Safety closures precede the timed deadline, including when the user
        // requests Keep in the same turn as a lock/disable/scene transition.
        if (!conditions.allowed) return stop(PPOWindowStop::Disabled);
        if (!conditions.protectedDataAvailable)
            return stop(PPOWindowStop::ProtectedDataUnavailable);
        if (!conditions.hostActive) return stop(PPOWindowStop::HostInactive);
        if (!conditions.lockKnown) return stop(PPOWindowStop::LockUnknown);
        if (conditions.locked || conditions.waitingToLock)
            return stop(PPOWindowStop::Locked);
        if (!conditions.sceneKnown) return stop(PPOWindowStop::SceneUnknown);
        if (!conditions.sceneValid) return stop(PPOWindowStop::SceneInvalid);

        const double elapsed = conditions.now - startTime_;
        if (conditions.sceneActive) observedActive_ = true;
        else if (observedActive_) return stop(PPOWindowStop::SceneInactive);
        else if (elapsed >= ActivationGraceSeconds)
            return stop(PPOWindowStop::ActivationTimeout);

        if (!kept_ && elapsed >= TimedSeconds) return stop(PPOWindowStop::Timeout);
        return PPOWindowStop::None;
    }

    // Keep is explicit, never inferred from input/rendering. It removes only
    // the normal 15-second deadline; all safety conditions continue to apply.
    bool keep(const PPOWindowConditions &conditions) noexcept {
        if (evaluate(conditions) != PPOWindowStop::None || !conditions.sceneActive)
            return false;
        kept_ = true;
        return true;
    }

    bool kept() const noexcept { return kept_; }
    bool observedActive() const noexcept { return observedActive_; }
    bool stopped() const noexcept { return reason_ != PPOWindowStop::None; }

private:
    PPOWindowStop stop(PPOWindowStop reason) noexcept {
        reason_ = reason;
        return reason_;
    }

    bool startAttempted_ = false;
    bool started_ = false;
    bool kept_ = false;
    bool observedActive_ = false;
    double startTime_ = 0;
    double lastTime_ = 0;
    PPOWindowStop reason_ = PPOWindowStop::None;
};
