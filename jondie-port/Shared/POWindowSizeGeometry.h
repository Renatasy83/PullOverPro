// Modified 2026-11-24 by Renatasy83: aspect-preserving window sizing; GPL-3.0.
#ifndef PO_WINDOW_SIZE_GEOMETRY_H
#define PO_WINDOW_SIZE_GEOMETRY_H

#include <stdbool.h>
#include <math.h>

static const double POWindowSizeMinimumFraction = 0.55;
static const double POWindowSizeDefaultFraction = 1.0;

typedef struct {
    double x, y, width, height;
} POWindowSizeRect;

typedef struct {
    bool valid;
    POWindowSizeRect pane;
    POWindowSizeRect grip;
    double fraction;
    double scale;
    double maximumScale;
    double maximumWidth;
    double maximumHeight;
} POWindowSizeGeometry;

static inline double POWindowSizeClampFraction(double fraction) {
    if (!isfinite(fraction)) return POWindowSizeDefaultFraction;
    return fmax(POWindowSizeMinimumFraction, fmin(POWindowSizeDefaultFraction, fraction));
}

// Coordinates are in the drawer's logical scroll-content space. UIKit must
// convert gesture deltas into that same space before calling the pan helper.
// Insets are distances from the viewport edges, not absolute coordinates.
static inline POWindowSizeGeometry POWindowSizeMakeGeometry(double nativeWidth,
                                                            double nativeHeight,
                                                            double viewportWidth,
                                                            double viewportHeight,
                                                            double safeTopInset,
                                                            double safeBottomInset,
                                                            double fraction) {
    POWindowSizeGeometry result = { .fraction = POWindowSizeClampFraction(fraction) };
    if (!isfinite(nativeWidth) || !isfinite(nativeHeight) ||
        !isfinite(viewportWidth) || !isfinite(viewportHeight) ||
        !isfinite(safeTopInset) || !isfinite(safeBottomInset) ||
        nativeWidth <= 0 || nativeHeight <= 0 || viewportWidth <= 50 || viewportHeight <= 0 ||
        safeTopInset < 0 || safeBottomInset < 0) return result;

    const double gripWidth = 44, gripHeight = 18, gripGap = 2;
    const double centerY = viewportHeight / 2;
    const double halfHeight = fmin(centerY - safeTopInset,
                                  centerY - safeBottomInset - gripHeight - gripGap);
    if (halfHeight <= 0) return result;
    const double maximumScale = fmin((viewportWidth - 50) / nativeWidth,
                                     (2 * halfHeight) / nativeHeight);
    if (!isfinite(maximumScale) || maximumScale <= 0) return result;
    const double maximumWidth = nativeWidth * maximumScale;
    const double maximumHeight = nativeHeight * maximumScale;
    // Keep the whole grip usable even at the smallest supported fraction.
    if (!isfinite(maximumWidth) || !isfinite(maximumHeight) || maximumHeight <= 0 ||
        maximumWidth * POWindowSizeMinimumFraction < gripWidth) return result;

    const double scale = maximumScale * result.fraction;
    const double width = nativeWidth * scale;
    const double height = nativeHeight * scale;
    const double top = centerY - height / 2;
    const double right = viewportWidth + width;
    const double bottom = top + height;
    const double gripBottom = bottom + gripGap + gripHeight;
    if (!isfinite(scale) || !isfinite(width) || !isfinite(height) || !isfinite(top) ||
        !isfinite(right) || !isfinite(bottom) || !isfinite(gripBottom) || width <= 0 || height <= 0) return result;

    result.valid = true;
    result.scale = scale;
    result.maximumScale = maximumScale;
    result.maximumWidth = maximumWidth;
    result.maximumHeight = maximumHeight;
    result.pane = (POWindowSizeRect){viewportWidth, top, width, height};
    result.grip = (POWindowSizeRect){right - gripWidth, bottom + gripGap, gripWidth, gripHeight};
    return result;
}

// The pane is vertically centered, so its bottom corner moves by half of its
// height change. Project the total translation onto that corner's derivative.
// Always pass the fraction captured at gesture begin, never the last result:
// returning from a clamp then follows the total translation without drift.
static inline double POWindowSizeFractionForTranslation(double initialFraction,
                                                        double dx, double dy,
                                                        double maximumWidth,
                                                        double maximumHeight) {
    const double initial = POWindowSizeClampFraction(initialFraction);
    if (!isfinite(dx) || !isfinite(dy) || !isfinite(maximumWidth) || !isfinite(maximumHeight) ||
        maximumWidth <= 0 || maximumHeight <= 0) return initial;
    const double verticalDerivative = maximumHeight / 2;
    const double magnitude = fmax(maximumWidth, verticalDerivative);
    // Geometry produced above always has magnitude >= 80. Reject sub-point
    // invalid geometry rather than divide huge gesture values by tiny inputs.
    if (magnitude < 1) return initial;
    const double ux = maximumWidth / magnitude;
    const double uy = verticalDerivative / magnitude;
    const double delta = ((dx / magnitude) * ux + (dy / magnitude) * uy) / (ux * ux + uy * uy);
    if (isnan(delta)) return initial;
    if (isinf(delta)) return delta > 0 ? POWindowSizeDefaultFraction : POWindowSizeMinimumFraction;
    return POWindowSizeClampFraction(initial + delta);
}

#endif
