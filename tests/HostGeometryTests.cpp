#include "../PPOHostGeometry.h"
#include <cstdio>
#include <cstdlib>
#include <limits>
static unsigned checks;
static void Check(bool ok, const char *message) {
    checks++;
    if (!ok) { std::fprintf(stderr, "FAIL: %s\n", message); std::exit(1); }
}
static void Fit(PPOHostRect native, PPOHostRect viewport) {
    PPOHostFit result{};
    Check(PPOHostFitRect(native, viewport, &result), "finite positive rectangles fit");
    const double width = native.width * result.scale, height = native.height * result.scale;
    Check(width <= viewport.width + 1e-8 && height <= viewport.height + 1e-8,
          "scaled native rectangle stays in viewport");
    Check(std::abs(width - viewport.width) < 1e-8 || std::abs(height - viewport.height) < 1e-8,
          "aspect-fit uses one viewport dimension");
    // UIKit's bounds origin permits a native view offset without mutating it.
    const double nativeMidX = native.x + native.width / 2;
    const double mappedMidX = result.centerX + (nativeMidX - (native.x + native.width / 2)) * result.scale;
    Check(std::abs(mappedMidX - (viewport.x + viewport.width / 2)) < 1e-8 &&
          std::abs(result.centerY - (viewport.y + viewport.height / 2)) < 1e-8,
          "offset native bounds remain centered");
}
int main() {
    Fit({0,0,414,896}, {0,0,300,436});
    Fit({80,-20,414,896}, {12,44,300,436});
    Fit({0,0,896,414}, {0,0,300,436});
    for (unsigned i = 1; i <= 250; i++)
        Fit({double(i)-100, -double(i), double(i)*4+32, double(i)*7+32},
            {3,7,double(i%301)+100,double(i%401)+100});
    const double nan = std::numeric_limits<double>::quiet_NaN();
    const double inf = std::numeric_limits<double>::infinity();
    for (auto bad : {PPOHostRect{0,0,0,896}, {0,0,414,-1}, {nan,0,414,896},
                     {0,inf,414,896}, {0,0,9000,896}, {40000,0,414,896}}) {
        PPOHostFit result{9,9,9};
        Check(!PPOHostFitRect(bad, {0,0,300,436}, &result), "invalid native geometry rejected");
        Check(result.scale == 0, "invalid geometry clears stale fit");
    }
    PPOHostFit result{};
    Check(!PPOHostFitRect({0,0,414,896}, {0,0,0,436}, &result), "empty viewport rejected");
    Check(!PPOHostFitRect({0,0,414,896}, {0,nan,300,436}, &result), "invalid viewport rejected");
    Check(!PPOHostFitRect({0,0,414,896}, {0,0,300,436}, nullptr), "null output refused");
    std::printf("Host geometry tests passed: %u checks; aspect fit only, not UIKit rendering\n", checks);
}
