#pragma once

#include "PPOHostGeometry.h"

// Geometry for PPO's public edge chooser only. No app frames, lifetime or input
// routing state is changed. Points outside the handle/visible drawer pass through.
enum class PPOEdgeDrawerSide { Left, Right };
struct PPOEdgeDrawerInsets { double top, left, bottom, right; };
struct PPOEdgeDrawerLayout {
    PPOHostRect screen{}, usable{}, handle{}, touchHandle{};
    PPOHostRect openDrawer{}, closedDrawer{}, drawer{};
    double progress = 0, travel = 0;
};

inline constexpr double PPOEdgeDrawerHandleWidth = 20;
inline constexpr double PPOEdgeDrawerMinimumTouchSize = 44;
inline constexpr double PPOEdgeDrawerMaximumWidth = 340;
inline constexpr double PPOEdgeDrawerWidthFraction = 0.82;
inline constexpr double PPOEdgeDrawerVelocityThreshold = 450;

namespace PPOEdgeDrawerDetail {
inline bool Coordinate(double value) noexcept {
    return std::isfinite(value) && std::abs(value) <= 32768;
}
inline bool Rect(PPOHostRect value) noexcept {
    return Coordinate(value.x) && Coordinate(value.y) &&
        std::isfinite(value.width) && std::isfinite(value.height) &&
        value.width > 0 && value.height > 0 && value.width <= 8192 && value.height <= 8192 &&
        Coordinate(value.x + value.width) && Coordinate(value.y + value.height);
}
inline bool Side(PPOEdgeDrawerSide side) noexcept {
    return side == PPOEdgeDrawerSide::Left || side == PPOEdgeDrawerSide::Right;
}
inline bool Usable(PPOHostRect screen, PPOEdgeDrawerInsets insets, PPOHostRect *result) noexcept {
    *result = {};
    if (!Rect(screen)) return false;
    for (double inset : {insets.top, insets.left, insets.bottom, insets.right})
        if (!std::isfinite(inset) || inset < 0 || inset > 8192) return false;
    PPOHostRect usable{screen.x + insets.left, screen.y + insets.top,
        screen.width - insets.left - insets.right,
        screen.height - insets.top - insets.bottom};
    // Below this size the drawer cannot expose its controls/list reliably.
    if (!Rect(usable) || usable.width < 196 || usable.height < 160) return false;
    *result = usable;
    return true;
}
inline bool HandleHeight(double value) noexcept {
    return std::isfinite(value) && value >= 32 && value <= 72;
}
inline bool Contains(PPOHostRect rect, double x, double y) noexcept {
    return x >= rect.x && y >= rect.y && x < rect.x + rect.width && y < rect.y + rect.height;
}
}

inline bool PPOEdgeDrawerMakeLayout(PPOHostRect screen, PPOEdgeDrawerInsets insets,
    PPOEdgeDrawerSide side, double yRatio, double handleHeight, double progress,
    PPOEdgeDrawerLayout *result) noexcept {
    if (!result) return false;
    *result = {};
    PPOHostRect usable{};
    if (!PPOEdgeDrawerDetail::Usable(screen, insets, &usable) ||
        !PPOEdgeDrawerDetail::Side(side) || !std::isfinite(yRatio) ||
        !PPOEdgeDrawerDetail::HandleHeight(handleHeight) || !std::isfinite(progress)) return false;
    yRatio = std::clamp(yRatio, 0.0, 1.0);
    progress = std::clamp(progress, 0.0, 1.0);
    const double touchHeight = std::max(PPOEdgeDrawerMinimumTouchSize, handleHeight);
    const double centerY = usable.y + touchHeight / 2 + yRatio * (usable.height - touchHeight);
    const bool left = side == PPOEdgeDrawerSide::Left;
    const double width = std::min(PPOEdgeDrawerMaximumWidth, usable.width * PPOEdgeDrawerWidthFraction);
    const double openX = left ? usable.x : usable.x + (usable.width - width);
    const double closedX = left ? screen.x - width : screen.x + screen.width;
    result->screen = screen; result->usable = usable;
    result->handle = {left ? screen.x : screen.x + (screen.width - PPOEdgeDrawerHandleWidth),
        centerY - handleHeight / 2, PPOEdgeDrawerHandleWidth, handleHeight};
    result->touchHandle = {left ? screen.x : screen.x + (screen.width - PPOEdgeDrawerMinimumTouchSize),
        centerY - touchHeight / 2, PPOEdgeDrawerMinimumTouchSize, touchHeight};
    result->openDrawer = {openX, usable.y, width, usable.height};
    result->closedDrawer = {closedX, usable.y, width, usable.height};
    // Exact endpoint assignment avoids residual visible slivers at progress zero.
    const double x = progress == 0 ? closedX : (progress == 1 ? openX : closedX + (openX - closedX) * progress);
    result->drawer = {x, usable.y, width, usable.height};
    result->progress = progress; result->travel = std::abs(openX - closedX);
    return true;
}

inline bool PPOEdgeDrawerProgress(PPOEdgeDrawerSide side, double startProgress,
    double translationX, double travel, double *result) noexcept {
    if (!result) return false;
    *result = 0;
    if (!PPOEdgeDrawerDetail::Side(side) || !std::isfinite(startProgress) ||
        startProgress < 0 || startProgress > 1 || !PPOEdgeDrawerDetail::Coordinate(translationX) ||
        !std::isfinite(travel) || travel <= 0 || travel > 16384) return false;
    const double inward = side == PPOEdgeDrawerSide::Left ? translationX : -translationX;
    *result = std::clamp(startProgress + inward / travel, 0.0, 1.0);
    return true;
}

inline bool PPOEdgeDrawerFinish(PPOEdgeDrawerSide side, double progress,
    double velocityX, bool *open) noexcept {
    if (!open) return false;
    *open = false;
    if (!PPOEdgeDrawerDetail::Side(side) || !std::isfinite(progress) ||
        progress < 0 || progress > 1 || !PPOEdgeDrawerDetail::Coordinate(velocityX)) return false;
    const double inward = side == PPOEdgeDrawerSide::Left ? velocityX : -velocityX;
    *open = inward >= PPOEdgeDrawerVelocityThreshold ? true :
        (inward <= -PPOEdgeDrawerVelocityThreshold ? false : progress >= 0.5);
    return true;
}

inline bool PPOEdgeDrawerYRatio(PPOHostRect screen, PPOEdgeDrawerInsets insets,
    double handleHeight, double centerY, double *result) noexcept {
    if (!result) return false;
    *result = 0;
    PPOHostRect usable{};
    if (!PPOEdgeDrawerDetail::Usable(screen, insets, &usable) ||
        !PPOEdgeDrawerDetail::HandleHeight(handleHeight) || !PPOEdgeDrawerDetail::Coordinate(centerY)) return false;
    const double touchHeight = std::max(PPOEdgeDrawerMinimumTouchSize, handleHeight);
    *result = std::clamp((centerY - usable.y - touchHeight / 2) / (usable.height - touchHeight), 0.0, 1.0);
    return true;
}

// A retained public owned-window panel may use another width/height than the
// chooser. Slide that panel without changing its native app viewport or frame.
inline bool PPOEdgeDrawerPanelTranslation(PPOHostRect screen, PPOHostRect basePanel,
    PPOEdgeDrawerSide side, double progress, double *translation, double *travel) noexcept {
    if (translation) *translation = 0;
    if (travel) *travel = 0;
    if (!translation || !travel || translation == travel ||
        !PPOEdgeDrawerDetail::Rect(screen) || !PPOEdgeDrawerDetail::Rect(basePanel) ||
        !PPOEdgeDrawerDetail::Side(side) || !std::isfinite(progress) || progress < 0 || progress > 1 ||
        basePanel.x < screen.x || basePanel.y < screen.y ||
        basePanel.x + basePanel.width > screen.x + screen.width ||
        basePanel.y + basePanel.height > screen.y + screen.height) return false;
    const bool left = side == PPOEdgeDrawerSide::Left;
    *travel = left ? basePanel.x + basePanel.width - screen.x : screen.x + screen.width - basePanel.x;
    *translation = progress == 1 ? 0 : (1 - progress) * *travel * (left ? -1 : 1);
    return true;
}

// Original-style large drawer: fit a native-aspect public viewport below our
// 44-point controls, with an eight-point margin inside the captured safe area.
// This computes only PPO's panel rectangle. It never resizes a native app view.
inline bool PPOEdgeDrawerAppFrame(PPOHostRect screen, PPOEdgeDrawerInsets insets,
    double nativeWidth, double nativeHeight, PPOHostRect *result) noexcept {
    if (!result) return false;
    *result = {};
    PPOHostRect safe{};
    if (!PPOEdgeDrawerDetail::Usable(screen, insets, &safe) ||
        !std::isfinite(nativeWidth) || !std::isfinite(nativeHeight) ||
        nativeWidth < 32 || nativeWidth > 8192 || nativeHeight < 32 || nativeHeight > 8192)
        return false;
    constexpr double margin = 8, header = 44;
    const PPOHostRect usable{safe.x + margin, safe.y + margin,
        safe.width - 2 * margin, safe.height - 2 * margin};
    if (!PPOEdgeDrawerDetail::Rect(usable) || usable.width < 240 || usable.height < 320)
        return false;
    const double maximumWidth = std::min(screen.width - 50, usable.width);
    const double scale = std::min(maximumWidth / nativeWidth,
        (usable.height - header) / nativeHeight);
    const double width = nativeWidth * scale, height = nativeHeight * scale + header;
    if (!std::isfinite(scale) || scale <= 0 || width < 240 || height < 320)
        return false;
    const PPOHostRect panel{usable.x + (usable.width - width) / 2,
        usable.y + (usable.height - height) / 2, width, height};
    if (!PPOEdgeDrawerDetail::Rect(panel)) return false;
    *result = panel;
    return true;
}

inline bool PPOEdgeDrawerHit(const PPOEdgeDrawerLayout &layout, double x, double y) noexcept {
    if (!PPOEdgeDrawerDetail::Coordinate(x) || !PPOEdgeDrawerDetail::Coordinate(y) ||
        !PPOEdgeDrawerDetail::Rect(layout.screen) || !PPOEdgeDrawerDetail::Rect(layout.touchHandle) ||
        !std::isfinite(layout.progress) || layout.progress < 0 || layout.progress > 1 ||
        !std::isfinite(layout.drawer.x) || !std::isfinite(layout.drawer.y) ||
        !std::isfinite(layout.drawer.width) || !std::isfinite(layout.drawer.height) ||
        layout.drawer.width <= 0 || layout.drawer.width > 340 || layout.drawer.height <= 0 ||
        layout.drawer.height > 8192 || !PPOEdgeDrawerDetail::Contains(layout.screen, x, y)) return false;
    return PPOEdgeDrawerDetail::Contains(layout.touchHandle, x, y) ||
        (layout.progress > 0 && PPOEdgeDrawerDetail::Contains(layout.drawer, x, y));
}
