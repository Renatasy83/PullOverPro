#include "../PPOFloatingWindowGeometry.h"
#include "../PPOWindowLifetime.h"
#include <cstdio>
#include <cstdlib>
#include <limits>
#include <random>

static unsigned checks;
static void Check(bool condition, const char *message) {
    checks++;
    if (!condition) { std::fprintf(stderr, "FAIL: %s\n", message); std::exit(1); }
}
static bool Near(double left, double right) { return std::abs(left - right) < 1e-8; }
static void Same(PPOHostRect left, PPOHostRect right, const char *message) {
    Check(Near(left.x, right.x) && Near(left.y, right.y) &&
        Near(left.width, right.width) && Near(left.height, right.height), message);
}
static void Cleared(PPOHostRect result) { Same(result, {}, "failure clears previous geometry"); }
static void Fits(PPOHostRect result, PPOHostRect screen, PPOFloatingInsets insets) {
    PPOHostRect usable{};
    Check(PPOFloatingUsable(screen, insets, &usable), "test result has a usable host screen");
    Check(std::isfinite(result.x) && std::isfinite(result.y) &&
        std::isfinite(result.width) && std::isfinite(result.height), "layout never emits nonfinite values");
    Check(result.width >= PPOFloatingMinWidth && result.height >= PPOFloatingMinHeight,
        "window keeps reachable minimum chrome/content dimensions");
    Check(result.x >= usable.x - 1e-8 && result.y >= usable.y - 1e-8 &&
        result.x + result.width <= usable.x + usable.width + 1e-8 &&
        result.y + result.height <= usable.y + usable.height + 1e-8,
        "whole window stays inside safe area plus margin");
    const PPOHostRect native = {0, 0, 414, 896};
    PPOHostRect before = native;
    PPOHostFit fit{};
    Check(PPOHostFitRect(native, {0, 0, result.width, result.height - PPOFloatingHeaderHeight}, &fit),
        "new public viewport admits the existing wrapper-only native aspect fit");
    Check(native.width * fit.scale <= result.width + 1e-8 &&
        native.height * fit.scale <= result.height - PPOFloatingHeaderHeight + 1e-8,
        "scaled app content stays inside the viewport below chrome");
    Same(native, before, "public viewport sizing does not change the native app frame");
}
static PPOWindowConditions Conditions(double now) {
    PPOWindowConditions value;
    value.now = now; value.allowed = true; value.protectedDataAvailable = true;
    value.hostActive = true; value.lockKnown = true; value.sceneKnown = true;
    value.sceneValid = true; value.sceneActive = true;
    return value;
}
int main() {
    const PPOHostRect phone{0, 0, 414, 896};
    const PPOFloatingInsets safe{44, 0, 34, 0};
    const PPOFloatingSize sizes[] = {PPOFloatingSize::Compact, PPOFloatingSize::Standard, PPOFloatingSize::Large};
    PPOHostRect result{};
    Check(PPOFloatingHeaderHeight == 44 && PPOFloatingMinWidth == 240 &&
        PPOFloatingMinHeight == 320 && PPOFloatingMargin == 8, "shared chrome constraints are stable");
    Check(PPOFloatingUsable(phone, safe, &result), "phone safe area is usable");
    Same(result, {8, 52, 398, 802}, "safe insets and all four margins are included once");
    Check(PPOFloatingInitial(phone, safe, PPOFloatingSize::Standard, &result), "standard initial window fits");
    Same(result, {57, 60, 300, 480}, "standard phone placement retains the tested opening position");
    Check(PPOFloatingInitial(phone, safe, PPOFloatingSize::Compact, &result), "compact initial window fits");
    Same(result, {77, 60, 260, 420}, "compact preset dimensions");
    Check(PPOFloatingInitial(phone, safe, PPOFloatingSize::Large, &result), "large initial window fits");
    Same(result, {17, 60, 380, 680}, "large preset dimensions");

    Check(PPOFloatingInitial({0, 0, 256, 336}, {}, PPOFloatingSize::Large, &result),
        "exact minimum available area is accepted");
    Same(result, {8, 8, 240, 320}, "presets shrink to the exact reachable minimum");
    for (PPOHostRect screen : {PPOHostRect{0,0,255.999,336}, {0,0,256,335.999}, {0,0,200,900}}) {
        result = {1,2,3,4};
        Check(!PPOFloatingInitial(screen, {}, PPOFloatingSize::Standard, &result),
            "screens below reachable chrome minimum are refused");
        Cleared(result);
    }
    Check(PPOFloatingInitial({100,-200,414,896}, safe, PPOFloatingSize::Standard, &result),
        "offset coordinate-space bounds are supported");
    Same(result, {157,-140,300,480}, "opening offset is relative to the host coordinate space");

    // Nonintegral coordinate spaces can expose cancellation when a preset is
    // constrained to exactly the usable width/height. The clamp bounds must
    // remain ordered rather than drifting below the usable origin by one ULP.
    const PPOHostRect fractional{-124.22481269885589, -112.1959482376041,
        327.3969627589865, 653.1343821602137};
    const PPOFloatingInsets fractionalInsets{12.3571256532947, 1.1654222512878631,
        8.5843410582375, 1.1543327077049215};
    PPOHostRect fractionalUsable{};
    Check(PPOFloatingUsable(fractional, fractionalInsets, &fractionalUsable),
        "fractional screen and safe insets remain usable");
    Check(PPOFloatingInitial(fractional, fractionalInsets, PPOFloatingSize::Large, &result),
        "large preset clamps to fractional usable dimensions");
    Check(result.x == fractionalUsable.x && result.y == fractionalUsable.y,
        "equal-size clamping has exact usable origins without cancellation");
    Fits(result, fractional, fractionalInsets);
    Check(PPOFloatingMove(result, fractional, fractionalInsets, -32768, -32768, &result),
        "fractional edge drag remains valid");
    Check(result.x == fractionalUsable.x && result.y == fractionalUsable.y,
        "edge drag preserves exact fractional clamp origins");

    PPOHostRect centered{350, 300, 300, 480};
    Check(PPOFloatingResize(centered, {0,0,1000,1200}, {}, PPOFloatingSize::Large, &result),
        "resize in a roomy screen succeeds");
    Check(Near(result.x + result.width/2, centered.x + centered.width/2) &&
        Near(result.y + result.height/2, centered.y + centered.height/2),
        "resizing preserves center when no boundary intervenes");
    Check(PPOFloatingMove({57,60,300,480}, phone, safe, 20, 30, &result), "ordinary drag succeeds");
    Same(result, {77,90,300,480}, "drag uses both deltas without resizing");
    Check(PPOFloatingMove(result, phone, safe, -20, -30, &result), "output may alias value-copied input");
    Same(result, {57,60,300,480}, "unclamped inverse drag returns the old frame");
    Check(PPOFloatingMove(result, phone, safe, -32768, -32768, &result), "finite extreme drags clamp");
    Same(result, {8,52,300,480}, "upper-left drag keeps entire chrome reachable");
    Check(PPOFloatingMove(result, phone, safe, 32768, 32768, &result), "opposite extreme drag clamps");
    Same(result, {106,374,300,480}, "lower-right drag keeps entire window in safe area");
    Check(PPOFloatingMove({0,0,8192,8192}, phone, safe, 0, 0, &result),
        "oversized existing public window shrinks into usable bounds");
    Same(result, {8,52,398,802}, "oversized dimensions do not escape screen bounds");
    Check(PPOFloatingMove({0,0,1,1}, phone, safe, 0, 0, &result),
        "positive small existing window normalizes to reachable minimum");
    Same(result, {8,52,240,320}, "normalization preserves minimum touch target space");

    const double nan = std::numeric_limits<double>::quiet_NaN();
    const double inf = std::numeric_limits<double>::infinity();
    for (PPOHostRect invalid : {PPOHostRect{nan,0,414,896}, {0,inf,414,896}, {0,0,0,896},
        {0,0,414,-1}, {0,0,8192.1,896}, {0,0,414,inf}, {32769,0,414,896},
        {0,-32769,414,896}, {32768,0,414,896}}) {
        result = {1,2,3,4};
        Check(!PPOFloatingInitial(invalid, {}, PPOFloatingSize::Standard, &result), "invalid host bounds refuse layout");
        Cleared(result);
        result = {1,2,3,4};
        Check(!PPOFloatingMove(invalid, phone, safe, 0, 0, &result), "invalid current bounds refuse drag");
        Cleared(result);
        result = {1,2,3,4};
        Check(!PPOFloatingResize(invalid, phone, safe, PPOFloatingSize::Compact, &result),
            "invalid current bounds refuse resize");
        Cleared(result);
    }
    for (PPOFloatingInsets invalid : {PPOFloatingInsets{nan,0,0,0}, {0,inf,0,0}, {0,0,-1,0},
        {0,0,0,8193}, {500,0,500,0}, {0,200,0,200}}) {
        result = {1,2,3,4};
        Check(!PPOFloatingUsable(phone, invalid, &result), "invalid or excessive safe insets refuse layout");
        Cleared(result);
        Check(!PPOFloatingResize({57,60,300,480}, phone, invalid, PPOFloatingSize::Large, &result),
            "resize does not bypass unsafe insets");
        Cleared(result);
    }
    for (double invalid : {nan,inf,-inf,32768.1,-32768.1}) {
        result = {1,2,3,4};
        Check(!PPOFloatingMove({57,60,300,480}, phone, safe, invalid, 0, &result), "invalid horizontal delta is rejected");
        Cleared(result);
        Check(!PPOFloatingMove({57,60,300,480}, phone, safe, 0, invalid, &result), "invalid vertical delta is rejected");
        Cleared(result);
    }
    const auto invalidSize = static_cast<PPOFloatingSize>(-1);
    Check(!PPOFloatingInitial(phone, safe, invalidSize, &result), "initial size enum must be known");
    Cleared(result);
    Check(!PPOFloatingResize({57,60,300,480}, phone, safe, invalidSize, &result), "resize size enum must be known");
    Cleared(result);
    Check(PPOFloatingNextSize(invalidSize) == PPOFloatingSize::Standard, "invalid cycle state recovers to standard");
    Check(PPOFloatingNextSize(PPOFloatingSize::Standard) == PPOFloatingSize::Large &&
        PPOFloatingNextSize(PPOFloatingSize::Large) == PPOFloatingSize::Compact &&
        PPOFloatingNextSize(PPOFloatingSize::Compact) == PPOFloatingSize::Standard, "size cycle follows the displayed order");
    Check(!PPOFloatingUsable(phone, safe, nullptr) &&
        !PPOFloatingInitial(phone, safe, PPOFloatingSize::Standard, nullptr) &&
        !PPOFloatingResize({57,60,300,480}, phone, safe, PPOFloatingSize::Large, nullptr) &&
        !PPOFloatingMove({57,60,300,480}, phone, safe, 0,0,nullptr), "all null output pointers are refused");

    for (double width : {256.,280.,320.,375.,414.,768.,1024.,8192.})
    for (double height : {336.,480.,667.,896.,1200.,8192.})
    for (double offset : {-1000.,0.,1000.})
    for (auto size : sizes) {
        PPOHostRect screen{offset,-offset,width,height};
        Check(PPOFloatingInitial(screen, {}, size, &result), "preset fits each valid screen grid case");
        Fits(result, screen, {});
        for (double delta : {-32768.,-1000.,0.,1000.,32768.}) {
            Check(PPOFloatingMove(result, screen, {}, delta, -delta, &result), "grid drag stays valid");
            Fits(result, screen, {});
            PPOHostRect before = result;
            Check(PPOFloatingMove(result, screen, {}, 0,0,&result), "clamped frame supports a zero drag");
            Same(result, before, "clamp is idempotent");
        }
    }

    std::mt19937 generator(0x504f504fU);
    std::uniform_real_distribution<double> delta(-2500,2500);
    Check(PPOFloatingInitial(phone, safe, PPOFloatingSize::Standard, &result), "sequence begins from a valid window");
    auto size = PPOFloatingSize::Standard;
    for (unsigned step = 0; step < 10000; step++) {
        if (step % 3 == 0) {
            size = PPOFloatingNextSize(size);
            Check(PPOFloatingResize(result, phone, safe, size, &result), "repeated preset resizing remains valid");
        } else Check(PPOFloatingMove(result, phone, safe, delta(generator),delta(generator),&result),
            "repeated drags remain valid after resizing");
        Fits(result, phone, safe);
    }

    // Layout actions never participate in the lifetime policy or reset its start.
    PPOWindowLifetime timed;
    Check(timed.start(100), "timed scene begins once");
    for (unsigned step = 1; step < 1500; step++) {
        Check(PPOFloatingMove(result, phone, safe, delta(generator),delta(generator),&result),
            "timed session can continue public geometry changes");
        Check(timed.evaluate(Conditions(100 + step/100.)) == PPOWindowStop::None,
            "interleaved geometry remains within the original timed interval");
    }
    Check(timed.evaluate(Conditions(115)) == PPOWindowStop::Timeout,
        "many geometry changes do not extend the exact fifteen-second deadline");
    Check(!timed.keep(Conditions(115)) && !timed.start(115), "geometry cannot revive a timed-out scene");
    PPOWindowLifetime kept;
    Check(kept.start(200) && kept.keep(Conditions(201)), "Keep is an independent explicit lifetime operation");
    for (unsigned step = 0; step < 300; step++) {
        size = PPOFloatingNextSize(size);
        Check(PPOFloatingResize(result, phone, safe, size, &result), "kept session supports repeated public resizes");
        Check(kept.evaluate(Conditions(202+step)) == PPOWindowStop::None, "kept lifetime remains independent of size");
    }
    auto locked = Conditions(502); locked.locked = true;
    Check(kept.evaluate(locked) == PPOWindowStop::Locked,
        "geometry and Keep do not bypass the device-lock safety closure");
    Check(PPOFloatingMove(result, phone, safe, 1,1,&result), "pure geometry can compute after policy closure");
    Check(kept.evaluate(Conditions(503)) == PPOWindowStop::Locked,
        "computing geometry cannot clear the terminal safety state");

    std::printf("Floating window geometry tests passed: %u checks; public geometry and lifetime fixtures, not UIKit rendering\n", checks);
}
