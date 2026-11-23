#include "../Shared/POQuickSwitchGeometry.h"
#include <assert.h>
#include <stdio.h>

static void closeTo(double actual, double expected) { assert(fabs(actual - expected) < 0.00001); }
int main(void) {
    POQuickSwitchViewport result = POQuickSwitchMakeViewport(44, 810, 200, 34, 34, 5);
    closeTo(result.origin, 200); closeTo(result.height, 170); assert(!result.reversed);
    result = POQuickSwitchMakeViewport(44, 810, 720, 34, 34, 5);
    closeTo(result.origin, 584); closeTo(result.height, 170); assert(result.reversed);
    // Long favorites list is constrained to the usable area, in either direction.
    result = POQuickSwitchMakeViewport(44, 810, 120, 34, 34, 200);
    closeTo(result.origin, 120); closeTo(result.height, 690); assert(!result.reversed);
    result = POQuickSwitchMakeViewport(44, 810, 720, 34, 34, 200);
    closeTo(result.origin, 44); closeTo(result.height, 710); assert(result.reversed);
    // Converted scroll-view coordinates need not start at zero.
    result = POQuickSwitchMakeViewport(1044, 1810, 1720, 34, 34, 5);
    closeTo(result.origin, 1584); closeTo(result.height, 170); assert(result.reversed);
    // Offscreen handle and malformed/empty input never create an out-of-area viewport.
    result = POQuickSwitchMakeViewport(44, 810, -500, 34, 34, 200);
    closeTo(result.origin, 44); closeTo(result.height, 766);
    result = POQuickSwitchMakeViewport(44, 810, 900, 34, 34, 200);
    closeTo(result.origin, 44); closeTo(result.height, 766); assert(result.reversed);
    assert(POQuickSwitchMakeViewport(44, 810, 120, 34, 34, 0).height == 0);
    assert(POQuickSwitchMakeViewport(810, 44, 120, 34, 34, 10).height == 0);
    assert(POQuickSwitchMakeViewport(NAN, 810, 120, 34, 34, 10).height == 0);
    assert(POQuickSwitchMakeViewport(44, 810, 120, 34, INFINITY, 10).height == 0);
    assert(!POQuickSwitchValidRow(-1, 5));
    assert(!POQuickSwitchValidRow(0, 0));
    assert(POQuickSwitchValidRow(0, 5));
    assert(POQuickSwitchValidRow(4, 5));
    assert(!POQuickSwitchValidRow(5, 5));
    closeTo(POQuickSwitchScrollOffset(0, 3400, 500, 0, 1.0 / 30), 0);
    closeTo(POQuickSwitchScrollOffset(0, 3400, 500, 499, 1.0 / 30), 170.0 / 30);
    closeTo(POQuickSwitchScrollOffset(150, 3400, 500, 250, 1.0 / 30), 150);
    closeTo(POQuickSwitchScrollOffset(150, 3400, 500, 0, 1.0 / 30), 150 - 170.0 / 30);
    closeTo(POQuickSwitchScrollOffset(2900, 3400, 500, 499, 1.0 / 30), 2900);
    closeTo(POQuickSwitchScrollOffset(0, 100, 500, 499, 1.0 / 30), 0);
    closeTo(POQuickSwitchScrollOffset(0, 3400, 500, 499, 30), 17);
    closeTo(POQuickSwitchScrollOffset(0, 3400, 500, NAN, 1), 0);
    // A sustained edge hold reaches every row, including the last one.
    double offset = 0;
    for (int tick = 0; tick < 1000; tick++) offset = POQuickSwitchScrollOffset(offset, 3400, 500, 499, 1.0 / 30);
    closeTo(offset, 2900);
    for (int tick = 0; tick < 1000; tick++) offset = POQuickSwitchScrollOffset(offset, 3400, 500, 0, 1.0 / 30);
    closeTo(offset, 0);
    puts("PASS QuickSwitch geometry: viewport bounds, invalid rows, sustained autoscroll and edge clamps");
    return 0;
}
