#pragma once

#include <cmath>

enum class PPOMessengerKeepStop { None, ClockInvalid, Limit };

// An additional absolute budget, not an authorization to Keep. The normal
// activation/render/15-second/lock/ownership policy remains independent.
// Start once BEFORE private owned-scene preparation. The companion observes
// its scope only afterwards, so its larger budget covers this root deadline.
class PPOMessengerKeepPolicy {
public:
    static constexpr double MaximumSeconds = 120.0;
    static constexpr double CompanionMaximumSeconds = 125.0;
    static constexpr double CleanupMarginSeconds = 5.0;
    static_assert(CompanionMaximumSeconds >= MaximumSeconds + CleanupMarginSeconds,
                  "Companion must retain a bounded cleanup margin after the root cap");

    // A duplicate cannot move the deadline, advance the clock or revive a
    // terminal policy. An invalid FIRST attempt is terminal as well.
    bool start(double now) noexcept {
        if (startAttempted_ || stopped()) return false;
        startAttempted_ = true;
        const double limit = now + MaximumSeconds;
        if (!std::isfinite(now) || now < 0 || !std::isfinite(limit) || limit <= now) {
            reason_ = PPOMessengerKeepStop::ClockInvalid;
            return false;
        }
        started_ = true;
        startedAt_ = lastTime_ = now;
        deadline_ = limit;
        return true;
    }

    PPOMessengerKeepStop evaluate(double now) noexcept {
        if (stopped()) return reason_;
        if (!started_ || !std::isfinite(now) || now < 0 || now < lastTime_)
            return stop(PPOMessengerKeepStop::ClockInvalid);
        lastTime_ = now;
        if (now >= deadline_) return stop(PPOMessengerKeepStop::Limit);
        return PPOMessengerKeepStop::None;
    }

    bool started() const noexcept { return started_; }
    bool stopped() const noexcept { return reason_ != PPOMessengerKeepStop::None; }
    PPOMessengerKeepStop reason() const noexcept { return reason_; }
    double startedAt() const noexcept { return startedAt_; }
    double deadline() const noexcept { return deadline_; }

private:
    PPOMessengerKeepStop stop(PPOMessengerKeepStop reason) noexcept {
        reason_ = reason;
        return reason_;
    }
    bool startAttempted_ = false;
    bool started_ = false;
    double startedAt_ = 0;
    double lastTime_ = 0;
    double deadline_ = 0;
    PPOMessengerKeepStop reason_ = PPOMessengerKeepStop::None;
};
