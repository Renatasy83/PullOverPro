#pragma once

#include "PPOEdgeDrawerGeometry.h"
#include <algorithm>
#include <cmath>

// Public handle-gesture policy only. A Drawer decision is not scene admission;
// the caller must retain its independent intent, metadata and owner checks.
enum class PPOHandlePanMode { Inactive, Pending, Vertical, Drawer, Outward };

class PPOHandleNubState {
public:
    static constexpr double DirectionDistance = 6.0;
    static constexpr double DirectionVelocity = 80.0;
    static constexpr double NubDistance = 24.0;
    static constexpr double NubFlickDistance = 8.0;
    static constexpr double NubFlickVelocity = 450.0;
    static constexpr double MaximumAutoDelay = 30.0;

    // Capture the actual handle edge and whether its drawer was fully closed.
    // Once classified, direction/axis stay fixed until finish/cancellation. In
    // particular, reversing an outward closed drag never starts an app intent.
    bool begin(PPOEdgeDrawerSide side, bool allowed, bool drawerClosed) noexcept {
        cancelGesture();
        if (!allowed || !PPOEdgeDrawerDetail::Side(side)) return false;
        side_ = side; beganClosed_ = drawerClosed;
        mode_ = PPOHandlePanMode::Pending;
        return true;
    }

    PPOHandlePanMode update(double dx, double dy, double vx, double vy) noexcept {
        if (mode_ == PPOHandlePanMode::Inactive) return mode_;
        if (!sample(dx, dy, vx, vy)) { cancelGesture(); return mode_; }
        if (mode_ != PPOHandlePanMode::Pending) return mode_;

        // Prefer accumulated displacement to an instantaneous release velocity.
        // A tiny/noisy sample cannot choose a horizontal app-opening direction.
        double x = dx, y = dy;
        if (std::max(std::abs(x), std::abs(y)) < DirectionDistance) {
            if (std::max(std::abs(vx), std::abs(vy)) < DirectionVelocity) return mode_;
            x = vx; y = vy;
        }
        if (std::abs(y) > std::abs(x)) mode_ = PPOHandlePanMode::Vertical;
        else if (beganClosed_ && outward(x) > 0) mode_ = PPOHandlePanMode::Outward;
        else mode_ = PPOHandlePanMode::Drawer;
        return mode_;
    }

    // Only the terminal release can create a new explicit nub. Cancel/failure,
    // vertical/undecided/open-drawer gestures and strong inward counter-flicks
    // cannot commit one. This returns an event, not the current visibility.
    bool finish(double dx, double dy, double vx, double vy, bool cancelled) noexcept {
        if (cancelled) { cancelGesture(); return false; }
        const PPOHandlePanMode decided = update(dx, dy, vx, vy);
        const bool commit = decided == PPOHandlePanMode::Outward && beganClosed_ &&
            sample(dx, dy, vx, vy) && std::abs(dx) >= std::abs(dy) &&
            outward(vx) > -NubFlickVelocity &&
            (outward(dx) >= NubDistance ||
                (outward(dx) >= NubFlickDistance && outward(vx) >= NubFlickVelocity));
        cancelGesture();
        if (commit) manual_ = true;
        return commit;
    }

    void cancelGesture() noexcept {
        mode_ = PPOHandlePanMode::Inactive;
        beganClosed_ = false;
    }
    // Call for tap, long press, opening, disable/edge changes or explicit reveal.
    // Auto-hide sampling must not call this: it must preserve an explicit nub.
    void reveal() noexcept { manual_ = false; }
    bool manualNubbed() const noexcept { return manual_; }
    PPOHandlePanMode mode() const noexcept { return mode_; }

    bool visible(bool allowed, bool drawerOpen, bool handlingPan, bool quickChoosing,
        bool autoEnabled, double now, double lastInteraction, double delay) const noexcept {
        if (!allowed || drawerOpen || handlingPan || quickChoosing) return false;
        // A completed explicit drag does not depend on the auto-hide preference
        // or clock. Invalid auto timing can never manufacture an explicit nub.
        if (manual_) return true;
        if (!autoEnabled || !std::isfinite(now) || !std::isfinite(lastInteraction) ||
            !std::isfinite(delay) || now < 0 || lastInteraction < 0 ||
            now < lastInteraction || delay < 0 || delay > MaximumAutoDelay) return false;
        const double elapsed = now - lastInteraction;
        return std::isfinite(elapsed) && elapsed >= delay;
    }

private:
    static bool sample(double dx, double dy, double vx, double vy) noexcept {
        return PPOEdgeDrawerDetail::Coordinate(dx) && PPOEdgeDrawerDetail::Coordinate(dy) &&
            PPOEdgeDrawerDetail::Coordinate(vx) && PPOEdgeDrawerDetail::Coordinate(vy);
    }
    double outward(double value) const noexcept {
        return side_ == PPOEdgeDrawerSide::Right ? value : -value;
    }

    PPOHandlePanMode mode_ = PPOHandlePanMode::Inactive;
    PPOEdgeDrawerSide side_ = PPOEdgeDrawerSide::Right;
    bool beganClosed_ = false;
    bool manual_ = false;
};
