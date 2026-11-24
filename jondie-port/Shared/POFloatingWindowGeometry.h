// Added 2026-11-24 by Renatasy83: movable owned-window geometry; GPL-3.0.
#ifndef PO_FLOATING_WINDOW_GEOMETRY_H
#define PO_FLOATING_WINDOW_GEOMETRY_H

#include "POWindowSizeGeometry.h"

// Position within the space left after fitting the complete window chrome.
// Unspecified is the classic drawer placement, not an invalid saved point.
typedef struct {
    bool specified;
    double x, y;
} POFloatingWindowPosition;

typedef struct {
    bool valid;
    POWindowSizeRect chrome;   // Logical scroll-content coordinates.
    POWindowSizeRect pane;     // Remaining rectangles are local to chrome.
    POWindowSizeRect titleBar;
    POWindowSizeRect grip;
    double fraction, scale, maximumScale, maximumWidth, maximumHeight;
    double pageOffset;
    double minimumOriginX, minimumOriginY, maximumOriginX, maximumOriginY;
    POFloatingWindowPosition position;
} POFloatingWindowGeometry;

static inline POFloatingWindowPosition POFloatingWindowNormalizePosition(POFloatingWindowPosition position) {
    if (!position.specified || !isfinite(position.x) || !isfinite(position.y))
        return (POFloatingWindowPosition){false, 0, 0};
    return (POFloatingWindowPosition){true, fmax(0, fmin(1, position.x)), fmax(0, fmin(1, position.y))};
}

static inline bool POFloatingWindowOriginRangesValid(POFloatingWindowGeometry geometry) {
    return geometry.valid && isfinite(geometry.pageOffset) &&
        isfinite(geometry.minimumOriginX) && isfinite(geometry.maximumOriginX) &&
        isfinite(geometry.minimumOriginY) && isfinite(geometry.maximumOriginY) &&
        geometry.minimumOriginX >= 0 && geometry.minimumOriginY >= 0 &&
        geometry.maximumOriginX >= geometry.minimumOriginX &&
        geometry.maximumOriginY >= geometry.minimumOriginY;
}

// The requested origin is in visible viewport coordinates, not scroll-content
// coordinates. Zero free space on an axis maps to zero without division.
static inline POFloatingWindowPosition POFloatingWindowPositionForOrigin(POFloatingWindowGeometry geometry,
                                                                        double viewportX, double viewportY) {
    if (!POFloatingWindowOriginRangesValid(geometry)) return (POFloatingWindowPosition){false, 0, 0};
    if (!isfinite(viewportX) || !isfinite(viewportY)) return POFloatingWindowNormalizePosition(geometry.position);
    const double x = fmax(geometry.minimumOriginX, fmin(geometry.maximumOriginX, viewportX));
    const double y = fmax(geometry.minimumOriginY, fmin(geometry.maximumOriginY, viewportY));
    const double rangeX = geometry.maximumOriginX - geometry.minimumOriginX;
    const double rangeY = geometry.maximumOriginY - geometry.minimumOriginY;
    return (POFloatingWindowPosition){true,
        rangeX > 0 ? (x - geometry.minimumOriginX) / rangeX : 0,
        rangeY > 0 ? (y - geometry.minimumOriginY) / rangeY : 0};
}

// Insets are distances. Complete chrome (bar28+gap2, app, gap2+grip18)
// remains within the safe rectangle, including when an app grows after moving.
static inline POFloatingWindowGeometry POFloatingWindowMakeGeometry(double nativeWidth, double nativeHeight,
                                                                    double viewportWidth, double viewportHeight,
                                                                    double safeLeftInset, double safeTopInset,
                                                                    double safeRightInset, double safeBottomInset,
                                                                    double fraction, POFloatingWindowPosition position) {
    POFloatingWindowGeometry result = { .fraction = POWindowSizeClampFraction(fraction) };
    if (!isfinite(nativeWidth) || !isfinite(nativeHeight) ||
        !isfinite(viewportWidth) || !isfinite(viewportHeight) ||
        !isfinite(safeLeftInset) || !isfinite(safeTopInset) ||
        !isfinite(safeRightInset) || !isfinite(safeBottomInset) ||
        nativeWidth <= 0 || nativeHeight <= 0 || viewportWidth <= 50 || viewportHeight <= 50 ||
        safeLeftInset < 0 || safeTopInset < 0 || safeRightInset < 0 || safeBottomInset < 0) return result;
    const double safeRight = viewportWidth - safeRightInset;
    const double safeBottom = viewportHeight - safeBottomInset;
    const double safeWidth = safeRight - safeLeftInset;
    const double safeHeight = safeBottom - safeTopInset;
    const double pageOffset = viewportWidth - 50;
    const double pageEnd = pageOffset + viewportWidth;
    if (safeWidth <= 0 || safeHeight <= 50 || !isfinite(pageEnd)) return result;

    const double maximumScale = fmin(fmin(viewportWidth - 50, safeWidth) / nativeWidth,
                                     (safeHeight - 50) / nativeHeight);
    if (!isfinite(maximumScale) || maximumScale <= 0) return result;
    const double maximumWidth = nativeWidth * maximumScale;
    const double maximumHeight = nativeHeight * maximumScale;
    if (!isfinite(maximumWidth) || !isfinite(maximumHeight) || maximumHeight <= 0 ||
        maximumWidth * POWindowSizeMinimumFraction < 44) return result;

    const double scale = maximumScale * result.fraction;
    const double width = nativeWidth * scale;
    const double height = nativeHeight * scale;
    const double chromeHeight = height + 50;
    const double maximumOriginX = fmax(safeLeftInset, safeRight - width);
    const double maximumOriginY = fmax(safeTopInset, safeBottom - chromeHeight);
    const double freeX = maximumOriginX - safeLeftInset;
    const double freeY = maximumOriginY - safeTopInset;
    position = POFloatingWindowNormalizePosition(position);
    const double x = position.specified ? safeLeftInset + freeX * position.x
        : fmax(safeLeftInset, fmin(maximumOriginX, 50));
    const double y = position.specified ? safeTopInset + freeY * position.y : safeTopInset + freeY / 2;
    const double logicalX = pageOffset + x;
    if (!isfinite(scale) || !isfinite(width) || !isfinite(height) || !isfinite(chromeHeight) ||
        !isfinite(x) || !isfinite(y) || !isfinite(logicalX) || !isfinite(logicalX + width) ||
        !isfinite(y + chromeHeight) || width <= 0 || height <= 0) return result;

    result.valid = true;
    result.scale = scale;
    result.maximumScale = maximumScale;
    result.maximumWidth = maximumWidth;
    result.maximumHeight = maximumHeight;
    result.pageOffset = pageOffset;
    result.minimumOriginX = safeLeftInset;
    result.minimumOriginY = safeTopInset;
    result.maximumOriginX = maximumOriginX;
    result.maximumOriginY = maximumOriginY;
    result.chrome = (POWindowSizeRect){logicalX, y, width, chromeHeight};
    result.titleBar = (POWindowSizeRect){0, 0, width, 28};
    result.pane = (POWindowSizeRect){0, 30, width, height};
    result.grip = (POWindowSizeRect){width - 44, height + 32, 44, 18};
    result.position = POFloatingWindowPositionForOrigin(result, x, y);
    return result;
}

// Saturate finite translations before adding, avoiding overflow while keeping
// huge drags clamped to the reachable edge. Use captured-start geometry.
static inline double POFloatingWindowTranslatedOrigin(double start, double delta, double minimum, double maximum) {
    if (delta > maximum - start) return maximum;
    if (delta < minimum - start) return minimum;
    return start + delta;
}

static inline POFloatingWindowPosition POFloatingWindowMovePosition(POFloatingWindowGeometry startGeometry,
                                                                   double totalDx, double totalDy) {
    if (!POFloatingWindowOriginRangesValid(startGeometry)) return (POFloatingWindowPosition){false, 0, 0};
    POFloatingWindowPosition start = POFloatingWindowNormalizePosition(startGeometry.position);
    if (!start.specified || !isfinite(totalDx) || !isfinite(totalDy)) return start;
    const double x = startGeometry.minimumOriginX +
        (startGeometry.maximumOriginX - startGeometry.minimumOriginX) * start.x;
    const double y = startGeometry.minimumOriginY +
        (startGeometry.maximumOriginY - startGeometry.minimumOriginY) * start.y;
    return POFloatingWindowPositionForOrigin(startGeometry,
        POFloatingWindowTranslatedOrigin(x, totalDx, startGeometry.minimumOriginX, startGeometry.maximumOriginX),
        POFloatingWindowTranslatedOrigin(y, totalDy, startGeometry.minimumOriginY, startGeometry.maximumOriginY));
}

// A fixed top-left means the bottom-right corner moves by the entire height
// change. Parent-coordinate deltas must already account for window mirroring.
static inline double POFloatingWindowFractionForTranslation(double initialFraction, double dx, double dy,
                                                            double maximumWidth, double maximumHeight) {
    const double initial = POWindowSizeClampFraction(initialFraction);
    if (!isfinite(dx) || !isfinite(dy) || !isfinite(maximumWidth) || !isfinite(maximumHeight) ||
        maximumWidth <= 0 || maximumHeight <= 0) return initial;
    const double magnitude = fmax(maximumWidth, maximumHeight);
    if (magnitude < 1) return initial;
    const double ux = maximumWidth / magnitude, uy = maximumHeight / magnitude;
    const double delta = ((dx / magnitude) * ux + (dy / magnitude) * uy) / (ux * ux + uy * uy);
    if (isnan(delta)) return initial;
    if (isinf(delta)) return delta > 0 ? POWindowSizeDefaultFraction : POWindowSizeMinimumFraction;
    return POWindowSizeClampFraction(initial + delta);
}

#endif
