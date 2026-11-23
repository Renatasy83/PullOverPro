#ifndef PO_KEYBOARD_GEOMETRY_H
#define PO_KEYBOARD_GEOMETRY_H

#include <math.h>

typedef struct { double x, y, width, height; } PORect;

// All rectangles are in the controller's coordinates. The handle rectangle is
// its natural position before keyboard avoidance; offsets are scroll offsets.
static inline double POKeyboardAvoidanceOffset(PORect handle, PORect keyboard,
                                               double original, double minimum,
                                               double maximum, double safeTop) {
    if (!isfinite(original) || !isfinite(minimum) || !isfinite(maximum) ||
        !isfinite(safeTop) || !isfinite(handle.x) || !isfinite(handle.y) ||
        !isfinite(handle.width) || !isfinite(handle.height) ||
        !isfinite(keyboard.x) || !isfinite(keyboard.y) ||
        !isfinite(keyboard.width) || !isfinite(keyboard.height)) return original;
    maximum = fmax(minimum, maximum);
    double result = fmax(minimum, fmin(original, maximum));
    if (keyboard.width <= 0 || keyboard.height <= 0 || handle.width <= 0 || handle.height <= 0 ||
        handle.x + handle.width <= keyboard.x || keyboard.x + keyboard.width <= handle.x ||
        handle.y >= keyboard.y + keyboard.height || handle.y + handle.height <= keyboard.y) return result;
    const double gap = 8.0;
    double shift = handle.y + handle.height + gap - keyboard.y;
    double safeMaximum = original + fmax(0.0, handle.y - safeTop - gap);
    return fmax(minimum, fmin(fmin(maximum, safeMaximum), original + shift));
}

#endif
