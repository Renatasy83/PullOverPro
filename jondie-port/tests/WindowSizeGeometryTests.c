#include "../Shared/POWindowSizeGeometry.h"
#include <assert.h>
#include <float.h>
#include <stdio.h>

static void near(double actual, double expected) {
    assert(isfinite(actual));
    assert(fabs(actual - expected) <= 1e-9 * fmax(1, fabs(expected)));
}

static void assertFinite(POWindowSizeGeometry geometry) {
    const double values[] = { geometry.fraction, geometry.scale, geometry.maximumScale,
        geometry.maximumWidth, geometry.maximumHeight, geometry.pane.x, geometry.pane.y,
        geometry.pane.width, geometry.pane.height, geometry.grip.x, geometry.grip.y,
        geometry.grip.width, geometry.grip.height };
    for (unsigned i = 0; i < sizeof(values)/sizeof(values[0]); i++) assert(isfinite(values[i]));
    assert(geometry.fraction >= .55 && geometry.fraction <= 1);
}

static void assertFits(double nativeWidth, double nativeHeight, double viewportWidth,
                       double viewportHeight, double top, double bottom, double fraction) {
    POWindowSizeGeometry geometry = POWindowSizeMakeGeometry(nativeWidth, nativeHeight,
        viewportWidth, viewportHeight, top, bottom, fraction);
    assertFinite(geometry);
    assert(geometry.valid);
    near(geometry.pane.x - (viewportWidth - 50), 50); // Fully opened drawer offset.
    assert(geometry.pane.width <= viewportWidth - 50 + 1e-9);
    near(geometry.pane.width / geometry.pane.height, nativeWidth / nativeHeight);
    near(geometry.pane.y + geometry.pane.height / 2, viewportHeight / 2);
    assert(geometry.pane.y >= top - 1e-9);
    assert(geometry.grip.y + geometry.grip.height <= viewportHeight - bottom + 1e-9);
    assert(geometry.grip.x >= geometry.pane.x - 1e-9);
    near(geometry.grip.x + geometry.grip.width, geometry.pane.x + geometry.pane.width);
    near(geometry.grip.y, geometry.pane.y + geometry.pane.height + 2);
    near(geometry.grip.width, 44);
    near(geometry.grip.height, 18);
}

static void testBaselineAndBounds(void) {
    POWindowSizeGeometry maximum = POWindowSizeMakeGeometry(414, 896, 414, 896, 44, 34, 1);
    assert(maximum.valid);
    near(maximum.maximumScale, 364.0/414);
    near(maximum.pane.width, 364);
    near(maximum.pane.height, 787.7874396135266);
    near(maximum.pane.y, 54.1062801932367);
    POWindowSizeGeometry minimum = POWindowSizeMakeGeometry(414, 896, 414, 896, 44, 34, .55);
    near(minimum.pane.width, 200.2);
    near(minimum.pane.height, 433.28309178743964);
    near(POWindowSizeClampFraction(-DBL_MAX), .55);
    near(POWindowSizeClampFraction(DBL_MAX), 1);
    near(POWindowSizeClampFraction(NAN), 1);
    near(POWindowSizeClampFraction(INFINITY), 1);
    near(POWindowSizeClampFraction(-INFINITY), 1);
    for (unsigned step = 0; step <= 45; step++) {
        double fraction = .55 + step*.01;
        assertFits(414, 896, 414, 896, 44, 34, fraction);
        assertFits(375, 667, 375, 667, 20, 0, fraction);
        assertFits(393, 852, 393, 852, 59, 34, fraction);
        assertFits(414, 896, 500, 600, 30, 34, fraction); // Height-limited viewport.
    }
    POWindowSizeGeometry tallTop = POWindowSizeMakeGeometry(414, 896, 414, 896, 100, 34, 1);
    assert(tallTop.valid);
    near(tallTop.pane.y, 100);
    near(tallTop.pane.height, 696);
    POWindowSizeGeometry bottomLimited = POWindowSizeMakeGeometry(414, 896, 414, 896, 44, 120, 1);
    assert(bottomLimited.valid);
    near(bottomLimited.grip.y + bottomLimited.grip.height, 776);
}

static void testPanProjection(void) {
    POWindowSizeGeometry g = POWindowSizeMakeGeometry(414, 896, 414, 896, 44, 34, .7);
    double w = g.maximumWidth, halfHeight = g.maximumHeight/2;
    near(POWindowSizeFractionForTranslation(.7, w*.15, halfHeight*.15, w, g.maximumHeight), .85);
    near(POWindowSizeFractionForTranslation(.7, -w*.15, -halfHeight*.15, w, g.maximumHeight), .55);
    // A perpendicular translation cannot change the least-squares scale.
    near(POWindowSizeFractionForTranslation(.7, halfHeight*.2, -w*.2, w, g.maximumHeight), .7);
    double horizontal = POWindowSizeFractionForTranslation(.7, 40, 0, w, g.maximumHeight);
    double vertical = POWindowSizeFractionForTranslation(.7, 0, 40, w, g.maximumHeight);
    assert(horizontal > .7 && vertical > .7);
    // Each projected point must minimize distance to the actual corner path.
    const double translations[][2] = {{40,0},{0,40},{40,30},{-20,10}};
    for (unsigned i = 0; i < sizeof(translations)/sizeof(translations[0]); i++) {
        double dx = translations[i][0], dy = translations[i][1];
        double answer = POWindowSizeFractionForTranslation(.7, dx, dy, w, g.maximumHeight);
        double delta = answer - .7;
        double cost = pow(dx - w*delta, 2) + pow(dy - halfHeight*delta, 2);
        for (int direction = -1; direction <= 1; direction += 2) {
            double alternative = delta + direction*.001;
            double otherCost = pow(dx - w*alternative, 2) + pow(dy - halfHeight*alternative, 2);
            assert(cost <= otherCost + 1e-9);
        }
    }
    near(POWindowSizeFractionForTranslation(.95, w*.2, halfHeight*.2, w, g.maximumHeight), 1);
    near(POWindowSizeFractionForTranslation(.95, w*.01, halfHeight*.01, w, g.maximumHeight), .96);
    // A complete gesture may cross both clamps and return to its origin.
    // Total translation zero must restore the captured initial fraction.
    near(POWindowSizeFractionForTranslation(.7, -w, -halfHeight, w, g.maximumHeight), .55);
    near(POWindowSizeFractionForTranslation(.7, w, halfHeight, w, g.maximumHeight), 1);
    near(POWindowSizeFractionForTranslation(.7, 0, 0, w, g.maximumHeight), .7);
    // Equivalent screen drags after the caller converts left-handed mirroring
    // to logical coordinates. This does not simulate UIKit conversion itself.
    double rightScreenDX = 40, leftScreenDX = -40;
    near(POWindowSizeFractionForTranslation(.7, rightScreenDX, 30, w, g.maximumHeight),
         POWindowSizeFractionForTranslation(.7, -leftScreenDX, 30, w, g.maximumHeight));
    near(POWindowSizeFractionForTranslation(.7, NAN, 0, w, g.maximumHeight), .7);
    near(POWindowSizeFractionForTranslation(.7, 0, INFINITY, w, g.maximumHeight), .7);
    near(POWindowSizeFractionForTranslation(.7, 40, 30, 0, g.maximumHeight), .7);
    near(POWindowSizeFractionForTranslation(.7, 40, 30, DBL_MIN, DBL_MIN), .7);
    near(POWindowSizeFractionForTranslation(.7, DBL_MAX, DBL_MAX, w, g.maximumHeight), 1);
    near(POWindowSizeFractionForTranslation(.7, -DBL_MAX, -DBL_MAX, w, g.maximumHeight), .55);
    near(POWindowSizeFractionForTranslation(.7, DBL_MAX, DBL_MAX, DBL_MAX, DBL_MAX), 1);
}

static void testInvalidGeometry(void) {
    const double invalid[][6] = {
        {0,896,414,896,44,34}, {-1,896,414,896,44,34}, {414,0,414,896,44,34},
        {414,896,50,896,44,34}, {414,896,100,896,44,34}, {414,896,414,0,44,34},
        {414,896,414,896,450,34}, {414,896,414,896,44,450},
        {414,896,414,896,-1,34}, {414,896,414,896,44,-1},
        {NAN,896,414,896,44,34}, {414,INFINITY,414,896,44,34},
        {414,896,NAN,896,44,34}, {414,896,414,INFINITY,44,34},
        {414,896,414,896,NAN,34}, {414,896,414,896,44,INFINITY},
        {DBL_MIN,DBL_MIN,DBL_MAX,DBL_MAX,0,0},
        {414,896,DBL_MAX,DBL_MAX,0,0}, {DBL_MAX,DBL_MIN,414,896,0,0}
    };
    for (unsigned i = 0; i < sizeof(invalid)/sizeof(invalid[0]); i++) {
        POWindowSizeGeometry g = POWindowSizeMakeGeometry(invalid[i][0], invalid[i][1],
            invalid[i][2], invalid[i][3], invalid[i][4], invalid[i][5], NAN);
        assertFinite(g);
        assert(!g.valid);
        near(g.scale, 0); // Caller must not apply unusable geometry.
    }
}

int main(void) {
    testBaselineAndBounds();
    testPanProjection();
    testInvalidGeometry();
    puts("PASS window-size geometry: baseline/aspect/safe-area, pan projection, clamp reversal, mirroring inputs and invalid values");
}
