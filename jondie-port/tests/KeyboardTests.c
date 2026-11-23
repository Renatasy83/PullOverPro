#include "../Shared/POKeyboardGeometry.h"
#include <assert.h>
#include <stdio.h>

static void near(double actual, double expected) { assert(fabs(actual-expected) < 0.0001); }
int main(void) {
    PORect h = {340, 640, 50, 34}, k = {0, 600, 390, 244};
    near(POKeyboardAvoidanceOffset(h,k,0,0,800,44),82);
    h.x = 0; // Either edge has the same vertical behavior.
    near(POKeyboardAvoidanceOffset(h,k,0,0,800,44),82);
    h.y = 200;
    near(POKeyboardAvoidanceOffset(h,k,100,0,800,44),100);
    h = (PORect){0,640,50,34};
    k.x = 100; k.width = 200; // Floating keyboard on the other side.
    near(POKeyboardAvoidanceOffset(h,k,0,0,800,44),0);
    k = (PORect){0,600,390,244};
    near(POKeyboardAvoidanceOffset(h,k,20,0,60,44),60); // Scroll range.
    k.y = 40; k.height = 804;
    near(POKeyboardAvoidanceOffset(h,k,0,0,800,44),588); // Keep below safe top.
    k.height = 0;
    near(POKeyboardAvoidanceOffset(h,k,20,0,800,44),20);
    k.height = NAN;
    near(POKeyboardAvoidanceOffset(h,k,20,0,800,44),20);
    puts("keyboard geometry tests passed");
}
