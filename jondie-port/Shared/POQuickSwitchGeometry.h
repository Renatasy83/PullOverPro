// Bounds calculations used by QuickSwitch. No UIKit/private APIs.
#ifndef PO_QUICKSWITCH_GEOMETRY_H
#define PO_QUICKSWITCH_GEOMETRY_H
#include <stdbool.h>
#include <stddef.h>
#include <math.h>

typedef struct {
    double origin;
    double height;
    bool reversed;
} POQuickSwitchViewport;

static inline POQuickSwitchViewport POQuickSwitchMakeViewport(double safeTop, double safeBottom,
                                                             double handleTop, double handleHeight,
                                                             double rowHeight, size_t count) {
    POQuickSwitchViewport result = {isfinite(safeTop) ? safeTop : 0, 0, false};
    if (!isfinite(safeTop) || !isfinite(safeBottom) || safeBottom <= safeTop ||
        !isfinite(handleTop) || !isfinite(handleHeight) || handleHeight <= 0 ||
        !isfinite(rowHeight) || rowHeight <= 0 || count == 0) return result;
    double anchorTop = fmax(safeTop, fmin(handleTop, safeBottom));
    double anchorBottom = fmax(safeTop, fmin(handleTop + handleHeight, safeBottom));
    double below = safeBottom - anchorTop;
    double above = anchorBottom - safeTop;
    double desired = rowHeight * (double)count;
    // Preserve the original down/up preference when the complete list fits.
    result.reversed = desired > below && (desired <= above || above > below);
    double available = result.reversed ? above : below;
    result.height = fmin(desired, available);
    result.origin = result.reversed ? anchorBottom - result.height : anchorTop;
    return result;
}

static inline bool POQuickSwitchValidRow(long row, size_t count) {
    return row >= 0 && (size_t)row < count;
}

// A long-press gesture owns the finger, so holding it at an edge scrolls the
// viewport. Limit each tick and stop exactly at either end of the list.
static inline double POQuickSwitchScrollOffset(double offset, double contentHeight,
                                                double viewportHeight, double fingerY,
                                                double tickSeconds) {
    if (!isfinite(offset) || !isfinite(contentHeight) || !isfinite(viewportHeight) ||
        !isfinite(fingerY) || !isfinite(tickSeconds) || viewportHeight <= 0 || tickSeconds <= 0) return 0;
    double maximum = fmax(0, contentHeight - viewportHeight);
    double edge = fmin(24, viewportHeight / 3);
    double velocity = fingerY < edge ? -170 : (fingerY > viewportHeight - edge ? 170 : 0);
    return fmax(0, fmin(maximum, offset + velocity * fmin(tickSeconds, 0.1)));
}
#endif
