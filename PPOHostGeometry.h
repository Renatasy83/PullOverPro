#pragma once
#include <algorithm>
#include <cmath>

struct PPOHostRect { double x, y, width, height; };
struct PPOHostFit { double scale, centerX, centerY; };

// Coordinates belong to PPO's wrapper, not the private presentation view.
inline bool PPOHostFitRect(PPOHostRect native, PPOHostRect viewport, PPOHostFit *result) {
    if (!result) return false;
    *result = {};
    for (double v : {native.x, native.y, native.width, native.height,
                     viewport.x, viewport.y, viewport.width, viewport.height})
        if (!std::isfinite(v) || std::abs(v) > 32768) return false;
    if (native.width <= 0 || native.height <= 0 || native.width > 8192 || native.height > 8192 ||
        viewport.width <= 0 || viewport.height <= 0 || viewport.width > 8192 || viewport.height > 8192)
        return false;
    const double scale = std::min(viewport.width / native.width, viewport.height / native.height);
    if (!std::isfinite(scale) || scale <= 0 || scale > 8192) return false;
    *result = {scale, viewport.x + viewport.width / 2, viewport.y + viewport.height / 2};
    return true;
}
