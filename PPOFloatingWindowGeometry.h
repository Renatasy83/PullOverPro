#pragma once

#include "PPOHostGeometry.h"

// Public-window geometry only. No native app-frame mutation, state or clocks.
enum class PPOFloatingSize { Compact, Standard, Large };
struct PPOFloatingInsets { double top, left, bottom, right; };

inline constexpr double PPOFloatingHeaderHeight = 44;
inline constexpr double PPOFloatingMinWidth = 240;
inline constexpr double PPOFloatingMinHeight = 320;
inline constexpr double PPOFloatingMargin = 8;

namespace PPOFloatingGeometryDetail {
inline bool Coordinate(double value) noexcept {
    return std::isfinite(value) && std::abs(value) <= 32768;
}
inline bool Rect(PPOHostRect rect) noexcept {
    return Coordinate(rect.x) && Coordinate(rect.y) &&
        std::isfinite(rect.width) && std::isfinite(rect.height) &&
        rect.width > 0 && rect.height > 0 && rect.width <= 8192 && rect.height <= 8192 &&
        Coordinate(rect.x + rect.width) && Coordinate(rect.y + rect.height);
}
inline bool Preset(PPOFloatingSize size, double *width, double *height) noexcept {
    switch (size) {
        case PPOFloatingSize::Compact: *width = 260; *height = 420; return true;
        case PPOFloatingSize::Standard: *width = 300; *height = 480; return true;
        case PPOFloatingSize::Large: *width = 380; *height = 680; return true;
    }
    return false;
}
inline PPOHostRect Contained(double x, double y, double width, double height,
    PPOHostRect usable) noexcept {
    // Subtract dimensions first. When they are equal, (origin + size) - size
    // can round below origin and violate std::clamp's ordered-bound contract.
    return {std::clamp(x, usable.x, usable.x + (usable.width - width)),
        std::clamp(y, usable.y, usable.y + (usable.height - height)), width, height};
}
}

inline bool PPOFloatingUsable(PPOHostRect screen, PPOFloatingInsets insets,
    PPOHostRect *result) noexcept {
    if (!result) return false;
    *result = {};
    if (!PPOFloatingGeometryDetail::Rect(screen)) return false;
    for (double inset : {insets.top, insets.left, insets.bottom, insets.right})
        if (!std::isfinite(inset) || inset < 0 || inset > 8192) return false;
    PPOHostRect usable = {screen.x + insets.left + PPOFloatingMargin,
        screen.y + insets.top + PPOFloatingMargin,
        screen.width - insets.left - insets.right - 2 * PPOFloatingMargin,
        screen.height - insets.top - insets.bottom - 2 * PPOFloatingMargin};
    if (!PPOFloatingGeometryDetail::Rect(usable) ||
        usable.width < PPOFloatingMinWidth || usable.height < PPOFloatingMinHeight) return false;
    *result = usable;
    return true;
}

inline PPOFloatingSize PPOFloatingNextSize(PPOFloatingSize size) noexcept {
    switch (size) {
        case PPOFloatingSize::Compact: return PPOFloatingSize::Standard;
        case PPOFloatingSize::Standard: return PPOFloatingSize::Large;
        case PPOFloatingSize::Large: return PPOFloatingSize::Compact;
    }
    return PPOFloatingSize::Standard;
}

inline bool PPOFloatingInitial(PPOHostRect screen, PPOFloatingInsets insets,
    PPOFloatingSize size, PPOHostRect *result) noexcept {
    if (!result) return false;
    *result = {};
    PPOHostRect usable{};
    double width = 0, height = 0;
    if (!PPOFloatingUsable(screen, insets, &usable) ||
        !PPOFloatingGeometryDetail::Preset(size, &width, &height)) return false;
    width = std::min(width, usable.width); height = std::min(height, usable.height);
    *result = PPOFloatingGeometryDetail::Contained(usable.x + (usable.width - width) / 2,
        screen.y + 60, width, height, usable);
    return true;
}

inline bool PPOFloatingResize(PPOHostRect current, PPOHostRect screen,
    PPOFloatingInsets insets, PPOFloatingSize size, PPOHostRect *result) noexcept {
    if (!result) return false;
    *result = {};
    PPOHostRect usable{};
    double width = 0, height = 0;
    if (!PPOFloatingGeometryDetail::Rect(current) ||
        !PPOFloatingUsable(screen, insets, &usable) ||
        !PPOFloatingGeometryDetail::Preset(size, &width, &height)) return false;
    width = std::min(width, usable.width); height = std::min(height, usable.height);
    *result = PPOFloatingGeometryDetail::Contained(current.x + (current.width - width) / 2,
        current.y + (current.height - height) / 2, width, height, usable);
    return true;
}

inline bool PPOFloatingMove(PPOHostRect current, PPOHostRect screen,
    PPOFloatingInsets insets, double dx, double dy, PPOHostRect *result) noexcept {
    if (!result) return false;
    *result = {};
    PPOHostRect usable{};
    if (!PPOFloatingGeometryDetail::Rect(current) ||
        !PPOFloatingGeometryDetail::Coordinate(dx) || !PPOFloatingGeometryDetail::Coordinate(dy) ||
        !PPOFloatingUsable(screen, insets, &usable)) return false;
    double width = std::clamp(current.width, PPOFloatingMinWidth, usable.width);
    double height = std::clamp(current.height, PPOFloatingMinHeight, usable.height);
    *result = PPOFloatingGeometryDetail::Contained(current.x + dx, current.y + dy,
        width, height, usable);
    return true;
}
