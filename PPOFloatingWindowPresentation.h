#pragma once

#include "PPOFloatingWindowGeometry.h"

// Public-window presentation geometry only. The caller owns the window,
// lifetime/activation guards and preset. No clock, UIKit or app-frame mutation.
class PPOFloatingWindowPresentation {
public:
    // One start establishes Expanded mode. Stop is terminal, including before
    // start; duplicate starts never change the mode or saved geometry.
    bool start() noexcept {
        if (started_ || stopped()) return false;
        started_ = true;
        mode_ = Mode::Expanded;
        return true;
    }

    bool minimize(PPOHostRect current, PPOHostRect screen, PPOFloatingInsets insets,
        PPOHostRect *out) noexcept {
        if (!out) return false;
        *out = {};
        if (!started_ || mode_ != Mode::Expanded) return false;
        PPOHostRect expanded{}, usable{};
        if (!PPOFloatingMove(current, screen, insets, 0, 0, &expanded) ||
            !PPOFloatingUsable(screen, insets, &usable)) return false;
        const PPOHostRect bar = PPOFloatingGeometryDetail::Contained(current.x, current.y,
            expanded.width, PPOFloatingHeaderHeight, usable);
        expandedFrame_ = expanded;
        mode_ = Mode::Minimized;
        *out = bar;
        return true;
    }

    bool restore(PPOHostRect currentBar, PPOHostRect screen, PPOFloatingInsets insets,
        PPOHostRect *out) noexcept {
        if (!out) return false;
        *out = {};
        if (!started_ || mode_ != Mode::Minimized || !barRect(currentBar) ||
            !PPOFloatingGeometryDetail::Rect(expandedFrame_) ||
            expandedFrame_.width < PPOFloatingMinWidth ||
            expandedFrame_.height < PPOFloatingMinHeight ||
            currentBar.width != expandedFrame_.width) return false;
        PPOHostRect restored{};
        if (!PPOFloatingMove({currentBar.x, currentBar.y,
                expandedFrame_.width, expandedFrame_.height}, screen, insets, 0, 0,
                &restored)) return false;
        expandedFrame_ = restored;
        mode_ = Mode::Expanded;
        *out = restored;
        return true;
    }

    bool move(PPOHostRect current, PPOHostRect screen, PPOFloatingInsets insets,
        double dx, double dy, PPOHostRect *out) const noexcept {
        if (!out) return false;
        *out = {};
        if (!started_ || stopped()) return false;
        if (mode_ == Mode::Expanded)
            return PPOFloatingMove(current, screen, insets, dx, dy, out);
        PPOHostRect usable{};
        if (!barRect(current) || current.width != expandedFrame_.width ||
            !PPOFloatingGeometryDetail::Coordinate(dx) ||
            !PPOFloatingGeometryDetail::Coordinate(dy) ||
            !PPOFloatingUsable(screen, insets, &usable) || current.width > usable.width)
            return false;
        // Refuse an oversized bar instead of changing its width independently
        // of the saved expanded dimensions. Restore may normalize both later.
        *out = PPOFloatingGeometryDetail::Contained(current.x + dx, current.y + dy,
            current.width, PPOFloatingHeaderHeight, usable);
        return true;
    }

    void stop() noexcept { mode_ = Mode::Stopped; }
    bool minimized() const noexcept { return mode_ == Mode::Minimized; }
    bool started() const noexcept { return started_; }
    bool stopped() const noexcept { return mode_ == Mode::Stopped; }

    // Last successful minimize/restore snapshot. Expanded moves and external
    // preset resizes are captured on the next minimize, not tracked here.
    PPOHostRect expandedFrame() const noexcept { return expandedFrame_; }

private:
    static bool barRect(PPOHostRect rect) noexcept {
        return PPOFloatingGeometryDetail::Rect(rect) &&
            rect.width >= PPOFloatingMinWidth && rect.height == PPOFloatingHeaderHeight;
    }
    enum class Mode { Unstarted, Expanded, Minimized, Stopped };
    bool started_ = false;
    Mode mode_ = Mode::Unstarted;
    PPOHostRect expandedFrame_{};
};
