#pragma once

#include <cstdint>
#include <limits>

// Main-thread coordinator for public UI intent only. Worker callbacks carry
// opaque tickets; they do not mutate this state. This is neither authorization
// nor a substitute for selected-app, freshness, ownership or lifetime checks.
class PPOInteractionIntent {
public:
    // The optional seed makes exhaustion testable without a wrapping loop.
    explicit PPOInteractionIntent(std::uint64_t seed = 0) noexcept : generation_(seed) {}

    std::uint64_t begin(bool heldForGesture) noexcept {
        active_ = false; held_ = false;
        constexpr auto maximum = std::numeric_limits<std::uint64_t>::max();
        // Reserve the maximum as a permanent exhausted sentinel. Neither zero
        // nor the exhausted generation is ever issued as a usable ticket.
        if (generation_ >= maximum - 1) { generation_ = maximum; return 0; }
        ++generation_;
        active_ = true; held_ = heldForGesture;
        return generation_;
    }

    bool current(std::uint64_t ticket) const noexcept {
        return active_ && ticket != 0 && ticket == generation_;
    }

    bool ready(std::uint64_t ticket) const noexcept { return current(ticket) && !held_; }
    bool held(std::uint64_t ticket) const noexcept { return current(ticket) && held_; }

    bool commit(std::uint64_t ticket) noexcept {
        if (!held(ticket)) return false;
        held_ = false;
        return true;
    }

    bool consume(std::uint64_t ticket) noexcept {
        if (!ready(ticket)) return false;
        active_ = false; held_ = false;
        return true;
    }

    void cancel() noexcept { active_ = false; held_ = false; }

private:
    std::uint64_t generation_ = 0;
    bool active_ = false, held_ = false;
};
