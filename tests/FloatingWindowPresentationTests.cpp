#include "../PPOFloatingWindowPresentation.h"
#include "../PPOWindowLifetime.h"

#include <cstdio>
#include <cstdlib>
#include <limits>
#include <random>
#include <type_traits>

static unsigned checks;
static unsigned mixedCycles;
static void Check(bool condition, const char *message) {
    ++checks;
    if (!condition) { std::fprintf(stderr, "FAIL: %s\n", message); std::exit(1); }
}
static bool Near(double left, double right) { return std::abs(left - right) < 1e-8; }
static void Same(PPOHostRect left, PPOHostRect right, const char *message) {
    Check(Near(left.x, right.x) && Near(left.y, right.y) &&
        Near(left.width, right.width) && Near(left.height, right.height), message);
}
static void Cleared(PPOHostRect value) { Same(value, {}, "failure clears the output rectangle"); }
struct Snapshot {
    bool started, minimized, stopped;
    PPOHostRect expanded;
};
static Snapshot Capture(const PPOFloatingWindowPresentation &policy) {
    return {policy.started(), policy.minimized(), policy.stopped(), policy.expandedFrame()};
}
static void Unchanged(const PPOFloatingWindowPresentation &policy, Snapshot before) {
    Check(policy.started() == before.started && policy.minimized() == before.minimized &&
        policy.stopped() == before.stopped, "rejected operation preserves presentation state");
    Same(policy.expandedFrame(), before.expanded, "rejected operation preserves saved expanded geometry");
}
template<class Operation>
static void Reject(PPOFloatingWindowPresentation &policy, Operation operation, const char *message) {
    const Snapshot before = Capture(policy);
    PPOHostRect out{1, 2, 3, 4};
    Check(!operation(&out), message);
    Cleared(out);
    Unchanged(policy, before);
}
static void Viewport(PPOHostRect expanded) {
    Check(expanded.width >= PPOFloatingMinWidth && expanded.height >= PPOFloatingMinHeight,
        "saved expanded dimensions retain a positive content viewport");
    const PPOHostRect native{0, 0, 414, 896};
    const PPOHostRect before = native;
    PPOHostFit fit{};
    const PPOHostRect viewport{0, 0, expanded.width, expanded.height - PPOFloatingHeaderHeight};
    Check(viewport.height > 0 && PPOHostFitRect(native, viewport, &fit),
        "saved positive viewport supports the existing native aspect fit");
    Check(fit.scale > 0 && native.width * fit.scale <= viewport.width + 1e-8 &&
        native.height * fit.scale <= viewport.height + 1e-8,
        "native 414 by 896 content fits below the saved expanded chrome");
    Same(native, before, "presentation transitions leave native app dimensions unchanged");
}
static void Fits(PPOHostRect rect, PPOHostRect screen, PPOFloatingInsets insets, bool bar) {
    PPOHostRect usable{};
    Check(PPOFloatingUsable(screen, insets, &usable), "fixture has usable bounds");
    Check(PPOFloatingGeometryDetail::Rect(rect), "successful geometry is a finite valid rectangle");
    Check(rect.width >= PPOFloatingMinWidth &&
        (bar ? rect.height == PPOFloatingHeaderHeight : rect.height >= PPOFloatingMinHeight),
        "bar and expanded heights use their distinct constraints");
    Check(rect.x >= usable.x - 1e-8 && rect.y >= usable.y - 1e-8 &&
        rect.x + rect.width <= usable.x + usable.width + 1e-8 &&
        rect.y + rect.height <= usable.y + usable.height + 1e-8,
        "public window is contained within safe insets and all margins");
    if (!bar) Viewport(rect);
}
static PPOWindowConditions Healthy(double now) {
    PPOWindowConditions value;
    value.now = now; value.allowed = true; value.protectedDataAvailable = true;
    value.hostActive = true; value.lockKnown = true; value.sceneKnown = true;
    value.sceneValid = true; value.sceneActive = true;
    return value;
}

int main() {
    static_assert(noexcept(PPOFloatingWindowPresentation{}.start()), "start is noexcept");
    static_assert(noexcept(PPOFloatingWindowPresentation{}.minimize({}, {}, {}, nullptr)), "minimize is noexcept");
    static_assert(noexcept(PPOFloatingWindowPresentation{}.restore({}, {}, {}, nullptr)), "restore is noexcept");
    static_assert(noexcept(PPOFloatingWindowPresentation{}.move({}, {}, {}, 0, 0, nullptr)), "move is noexcept");
    static_assert(noexcept(PPOFloatingWindowPresentation{}.stop()), "stop is noexcept");
    static_assert(std::is_same<decltype(PPOFloatingWindowPresentation{}.expandedFrame()), PPOHostRect>::value,
        "saved geometry uses the existing public rectangle type");
    const PPOHostRect phone{0, 0, 414, 896};
    const PPOFloatingInsets safe{44, 0, 34, 0};
    const PPOHostRect initial{57, 60, 300, 480};
    const PPOFloatingSize sizes[] = {PPOFloatingSize::Compact, PPOFloatingSize::Standard,
        PPOFloatingSize::Large};
    PPOHostRect out{};

    {
        PPOFloatingWindowPresentation policy;
        Check(!policy.started() && !policy.minimized() && !policy.stopped(), "new policy is unstarted");
        Cleared(policy.expandedFrame());
        Reject(policy, [&](PPOHostRect *p) { return policy.minimize(initial, phone, safe, p); },
            "minimize cannot initialize the policy");
        Reject(policy, [&](PPOHostRect *p) { return policy.restore({57,60,300,44}, phone, safe, p); },
            "restore cannot initialize the policy");
        Reject(policy, [&](PPOHostRect *p) { return policy.move(initial, phone, safe, 0, 0, p); },
            "move cannot initialize the policy");
        policy.stop();
        Check(policy.stopped() && !policy.started() && !policy.minimized(), "stop before start is terminal");
        Check(!policy.start(), "a stopped unstarted policy never revives");
        Reject(policy, [&](PPOHostRect *p) { return policy.minimize(initial, phone, safe, p); },
            "pre-start stop rejects minimize");
        policy.stop();
        Check(policy.stopped(), "duplicate stop remains terminal");
    }
    {
        PPOFloatingWindowPresentation policy;
        Check(policy.start() && policy.started() && !policy.minimized() && !policy.stopped(),
            "first start establishes expanded mode");
        Check(!policy.start(), "duplicate expanded start is refused");
        Reject(policy, [&](PPOHostRect *p) { return policy.restore({57,60,300,44}, phone, safe, p); },
            "restore requires minimized mode");
        const Snapshot first = Capture(policy);
        Check(!policy.minimize(initial, phone, safe, nullptr), "minimize refuses a null output");
        Check(!policy.move(initial, phone, safe, 0, 0, nullptr), "expanded move refuses a null output");
        Unchanged(policy, first);
        Check(policy.minimize(initial, phone, safe, &out), "expanded window minimizes");
        Same(out, {57,60,300,44}, "minimize keeps width and origin while collapsing to chrome");
        Same(policy.expandedFrame(), initial, "minimize saves the normalized expanded frame");
        Check(policy.started() && policy.minimized() && !policy.stopped(), "successful minimize switches mode");
        Viewport(policy.expandedFrame());
        Check(!policy.start(), "duplicate minimized start cannot expand the bar");
        Reject(policy, [&](PPOHostRect *p) { return policy.minimize(initial, phone, safe, p); },
            "duplicate minimize is refused");
        const Snapshot minimized = Capture(policy);
        Check(!policy.restore(out, phone, safe, nullptr) &&
            !policy.move(out, phone, safe, 0, 0, nullptr), "minimized operations reject null outputs");
        Unchanged(policy, minimized);
        Check(policy.move(out, phone, safe, 32768, 32768, &out), "bar moves to the lower right");
        Same(out, {106,810,300,44}, "bar reaches the bottom without promotion to expanded minimum height");
        Same(policy.expandedFrame(), initial, "const bar movement preserves the saved expanded frame");
        Check(policy.restore(out, phone, safe, &out), "bottom-edge bar restores");
        Same(out, {106,374,300,480}, "restore uses bar origin then clamps the whole expanded window");
        Same(policy.expandedFrame(), out, "restoration records its actual clamped expanded frame");
        Check(!policy.minimized() && policy.started() && !policy.stopped(), "successful restore switches mode");
        Fits(out, phone, safe, false);
        const auto saved = policy.expandedFrame();
        PPOHostRect expected{};
        Check(PPOFloatingMove(out, phone, safe, -23, -17, &expected), "expanded reference move succeeds");
        Check(policy.move(out, phone, safe, -23, -17, &out), "expanded presentation move delegates");
        Same(out, expected, "expanded movement matches the original geometry helper");
        Same(policy.expandedFrame(), saved, "expanded movement leaves the historical snapshot until minimize");
        policy.stop();
        Check(policy.stopped() && policy.started() && !policy.minimized(), "stop closes a started expanded policy");
        Same(policy.expandedFrame(), saved, "stop retains historical geometry for diagnostics");
        Check(!policy.start(), "stop prevents restart");
        Reject(policy, [&](PPOHostRect *p) { return policy.move(initial, phone, safe, 1, 1, p); },
            "stop rejects expanded movement");
        Reject(policy, [&](PPOHostRect *p) { return policy.minimize(initial, phone, safe, p); },
            "stop rejects minimize");
        Reject(policy, [&](PPOHostRect *p) { return policy.restore({57,60,300,44}, phone, safe, p); },
            "stop rejects restore");
    }

    for (auto size : sizes) {
        PPOFloatingWindowPresentation policy;
        PPOHostRect expanded{};
        Check(PPOFloatingInitial(phone, safe, size, &expanded) && policy.start(), "preset fixture starts");
        Check(policy.minimize(expanded, phone, safe, &out), "each preset minimizes");
        Same(policy.expandedFrame(), expanded, "each preset saves its existing dimensions");
        Same(out, {expanded.x, expanded.y, expanded.width,44}, "each bar preserves its preset width");
        Fits(out, phone, safe, true);
        Viewport(policy.expandedFrame());
        Check(policy.restore(out, phone, safe, &out), "each preset restores");
        Same(out, expanded, "restore preserves each preset's expanded dimensions and placement");
        Check(policy.minimize(out, phone, safe, &out), "restored preset may minimize again");
        const Snapshot saved = Capture(policy);
        policy.stop();
        Check(policy.started() && policy.stopped() && !policy.minimized(), "stop closes minimized mode");
        Same(policy.expandedFrame(), saved.expanded, "minimized close preserves its expanded snapshot");
        Check(!policy.start(), "minimized close cannot revive");
        Reject(policy, [&](PPOHostRect *p) { return policy.restore(out, phone, safe, p); },
            "closed bar cannot restore");
    }

    const PPOHostRect fractional{-124.22481269885589, -112.1959482376041,
        327.3969627589865, 653.1343821602137};
    const PPOFloatingInsets fractionalInsets{12.3571256532947, 1.1654222512878631,
        8.5843410582375, 1.1543327077049215};
    for (const auto screen : {phone, PPOHostRect{100,-200,414,896}, fractional,
            PPOHostRect{0,0,256,336}}) {
        const auto insets = screen.x == fractional.x ? fractionalInsets :
            (screen.width == 414 ? safe : PPOFloatingInsets{});
        for (auto size : sizes) {
            PPOFloatingWindowPresentation policy;
            PPOHostRect expanded{}, usable{};
            Check(PPOFloatingInitial(screen, insets, size, &expanded) && policy.start(),
                "fractional, offset and minimum fixture starts");
            Check(PPOFloatingUsable(screen, insets, &usable), "edge fixture usable area is valid");
            Check(policy.minimize(expanded, screen, insets, &out), "edge fixture minimizes");
            Fits(out, screen, insets, true);
            Viewport(policy.expandedFrame());
            Check(policy.move(out, screen, insets, -32768, -32768, &out), "bar clamps to fractional upper edge");
            Check(out.x == usable.x && out.y == usable.y, "upper-edge clamping has exact usable origins");
            Check(policy.move(out, screen, insets, 32768, 32768, &out), "bar clamps to fractional lower edge");
            Fits(out, screen, insets, true);
            Check(policy.restore(out, screen, insets, &out), "edge fixture restores from lower edge");
            Fits(out, screen, insets, false);
            Same(policy.expandedFrame(), out, "edge restoration updates historical geometry");
        }
    }
    {
        PPOFloatingWindowPresentation policy;
        Check(policy.start() && policy.minimize({2000,2000,300,480}, phone, safe, &out),
            "valid offscreen expanded geometry normalizes during minimize");
        Same(policy.expandedFrame(), {106,374,300,480}, "offscreen expanded snapshot uses original normalizer");
        Same(out, {106,810,300,44}, "offscreen bar uses the current origin with its own height clamp");
        Check(policy.restore(out, phone, safe, &out), "normalized offscreen bar restores");
        Fits(out, phone, safe, false);
    }
    for (const auto current : {PPOHostRect{0,0,1,1}, PPOHostRect{0,0,8192,8192}}) {
        PPOFloatingWindowPresentation policy;
        PPOHostRect normalized{};
        Check(PPOFloatingMove(current, phone, safe, 0, 0, &normalized) && policy.start(),
            "unusual valid expanded frame has original normalized reference");
        Check(policy.minimize(current, phone, safe, &out), "minimize normalizes positive small or oversized geometry");
        Same(policy.expandedFrame(), normalized, "saved dimensions match the original expanded normalization");
        Check(out.width == normalized.width && out.height == 44, "normalized width is shared with the bar");
        Check(policy.restore(out, phone, safe, &out), "normalized unusual geometry restores");
        Fits(out, phone, safe, false);
    }

    const double nan = std::numeric_limits<double>::quiet_NaN();
    const double inf = std::numeric_limits<double>::infinity();
    const PPOHostRect badRects[] = {{nan,0,300,480}, {0,inf,300,480}, {0,0,0,480},
        {0,0,300,-1}, {0,0,8192.1,480}, {0,0,300,inf}, {32769,0,300,480},
        {0,-32769,300,480}, {32768,0,300,480}};
    for (auto bad : badRects) {
        PPOFloatingWindowPresentation policy;
        Check(policy.start(), "invalid rectangle fixture starts");
        Reject(policy, [&](PPOHostRect *p) { return policy.minimize(bad, phone, safe, p); },
            "minimize rejects invalid expanded input");
        Reject(policy, [&](PPOHostRect *p) { return policy.move(bad, phone, safe, 0, 0, p); },
            "expanded move rejects invalid input");
        Reject(policy, [&](PPOHostRect *p) { return policy.minimize(initial, bad, safe, p); },
            "minimize rejects invalid screen bounds");
        Check(policy.minimize(initial, phone, safe, &out), "rejected minimize does not consume the transition");
        Reject(policy, [&](PPOHostRect *p) { return policy.restore(bad, phone, safe, p); },
            "restore rejects invalid bar input");
        Reject(policy, [&](PPOHostRect *p) { return policy.move(bad, phone, safe, 0, 0, p); },
            "minimized move rejects invalid input");
        Reject(policy, [&](PPOHostRect *p) { return policy.restore({57,60,300,44}, bad, safe, p); },
            "restore rejects invalid screen bounds");
        Reject(policy, [&](PPOHostRect *p) { return policy.move({57,60,300,44}, bad, safe, 0, 0, p); },
            "bar move rejects invalid screen bounds");
        Check(policy.restore({57,60,300,44}, phone, safe, &out), "rejected restoration remains retryable");
    }
    const PPOFloatingInsets badInsets[] = {{nan,0,0,0}, {0,inf,0,0}, {0,0,-1,0},
        {0,0,0,8193}, {500,0,500,0}, {0,200,0,200}};
    for (auto bad : badInsets) {
        PPOFloatingWindowPresentation policy;
        Check(policy.start(), "invalid inset fixture starts");
        Reject(policy, [&](PPOHostRect *p) { return policy.minimize(initial, phone, bad, p); },
            "minimize refuses invalid or excessive safe insets");
        Reject(policy, [&](PPOHostRect *p) { return policy.move(initial, phone, bad, 0, 0, p); },
            "expanded move refuses invalid or excessive safe insets");
        Check(policy.minimize(initial, phone, safe, &out), "inset fixture minimizes on valid bounds");
        Reject(policy, [&](PPOHostRect *p) { return policy.restore({57,60,300,44}, phone, bad, p); },
            "restore refuses invalid or excessive safe insets");
        Reject(policy, [&](PPOHostRect *p) { return policy.move({57,60,300,44}, phone, bad, 0, 0, p); },
            "bar move refuses invalid or excessive safe insets");
    }
    for (auto small : {PPOHostRect{0,0,255.999,336}, PPOHostRect{0,0,256,335.999},
            PPOHostRect{0,0,256,100}}) {
        PPOFloatingWindowPresentation policy;
        Check(policy.start(), "small-bounds fixture starts");
        Reject(policy, [&](PPOHostRect *p) { return policy.minimize(initial, small, {}, p); },
            "minimize still requires expanded minimum usable bounds");
        Check(policy.minimize(initial, phone, safe, &out), "small-bounds fixture minimizes on valid screen");
        Reject(policy, [&](PPOHostRect *p) { return policy.restore({57,60,300,44}, small, {}, p); },
            "restore refuses bounds below expanded usable minimum");
        Reject(policy, [&](PPOHostRect *p) { return policy.move({57,60,300,44}, small, {}, 0, 0, p); },
            "bar movement does not bypass expanded usable minimum");
    }
    for (double bad : {nan, inf, -inf, 32768.1, -32768.1}) {
        PPOFloatingWindowPresentation policy;
        Check(policy.start(), "invalid delta fixture starts");
        for (bool bar : {false, true}) {
            PPOHostRect current = bar ? PPOHostRect{57,60,300,44} : initial;
            if (bar) Check(policy.minimize(initial, phone, safe, &out), "delta fixture minimizes");
            Reject(policy, [&](PPOHostRect *p) { return policy.move(current, phone, safe, bad, 0, p); },
                "invalid horizontal delta is rejected in either mode");
            Reject(policy, [&](PPOHostRect *p) { return policy.move(current, phone, safe, 0, bad, p); },
                "invalid vertical delta is rejected in either mode");
        }
    }
    {
        PPOFloatingWindowPresentation policy;
        Check(policy.start() && policy.minimize(initial, phone, safe, &out), "bar validation fixture minimizes");
        for (auto bad : {PPOHostRect{57,60,300,43.999}, PPOHostRect{57,60,300,44.001},
                PPOHostRect{57,60,239.999,44}, PPOHostRect{57,60,299,44}, PPOHostRect{57,60,301,44}}) {
            Reject(policy, [&](PPOHostRect *p) { return policy.restore(bad, phone, safe, p); },
                "restore requires exact chrome height and the saved width");
            Reject(policy, [&](PPOHostRect *p) { return policy.move(bad, phone, safe, 0, 0, p); },
                "bar movement requires exact chrome height and the saved width");
        }
        for (auto bad : {PPOHostRect{nan,60,300,44}, PPOHostRect{57,nan,300,44},
                PPOHostRect{inf,60,300,44}, PPOHostRect{57,-inf,300,44},
                PPOHostRect{57,60,nan,44}, PPOHostRect{57,60,inf,44},
                PPOHostRect{57,60,0,44}, PPOHostRect{57,60,-1,44},
                PPOHostRect{57,60,8192.1,44}, PPOHostRect{32768,60,300,44},
                PPOHostRect{57,32768,300,44}, PPOHostRect{-32769,60,300,44}}) {
            Reject(policy, [&](PPOHostRect *p) { return policy.restore(bad, phone, safe, p); },
                "restore rejects malformed coordinates and widths on a height44 bar");
            Reject(policy, [&](PPOHostRect *p) { return policy.move(bad, phone, safe, 0, 0, p); },
                "bar movement rejects malformed coordinates and widths on a height44 bar");
        }
        const PPOHostRect narrow{0,0,280,700};
        Reject(policy, [&](PPOHostRect *p) { return policy.move({57,60,300,44}, narrow, {}, 1, 1, p); },
            "bar movement refuses oversized width without changing saved dimensions");
        Check(policy.restore({57,60,300,44}, narrow, {}, &out),
            "restore may normalize saved expanded dimensions after screen narrowing");
        Same(out, {8,60,264,480}, "narrow restoration clamps width consistently with the original helper");
        Same(policy.expandedFrame(), out, "narrow restoration refreshes saved dimensions");
        Check(policy.minimize(out, narrow, {}, &out), "new narrowed width can minimize");
        Check(policy.move(out, narrow, {}, 32768, 32768, &out), "bar movement works with refreshed narrow width");
        Fits(out, narrow, {}, true);
    }
    {
        PPOFloatingWindowPresentation policy;
        const PPOHostRect highScreen{0,32000,414,760};
        Check(policy.start() && policy.minimize({57,32008,300,480}, highScreen, {}, &out),
            "high coordinate-space fixture minimizes");
        Check(policy.move(out, highScreen, {}, 0, 32768, &out), "valid bar can reach high coordinate-space bottom");
        Check(out.y + out.height <= 32768 && out.y + 480 > 32768,
            "high bar is valid while a raw expanded candidate exceeds original validator limits");
        const auto bar = out;
        Reject(policy, [&](PPOHostRect *p) { return policy.restore(bar, highScreen, {}, p); },
            "original expanded validator rejects out-of-range restore candidate atomically");
        Check(policy.move(bar, highScreen, {}, 0, -1000, &out) &&
            policy.restore(out, highScreen, {}, &out), "rejected extreme restoration can move up and retry");
    }

    std::mt19937 generator(0x50524553U);
    std::uniform_real_distribution<double> delta(-2500,2500);
    for (auto screen : {phone, fractional, PPOHostRect{0,0,256,336}, PPOHostRect{100,-200,1024,1200}}) {
        const auto insets = screen.x == fractional.x ? fractionalInsets :
            (screen.width == phone.width ? safe : PPOFloatingInsets{});
        PPOFloatingWindowPresentation policy;
        PPOHostRect current{};
        auto size = PPOFloatingSize::Standard;
        Check(policy.start() && PPOFloatingInitial(screen, insets, size, &current), "mixed sequence starts");
        for (unsigned step = 0; step < 3000; ++step) {
            size = PPOFloatingNextSize(size);
            Check(PPOFloatingResize(current, screen, insets, size, &current),
                "preset resize remains an external expanded geometry operation");
            PPOHostRect normalized{};
            Check(PPOFloatingMove(current, screen, insets, 0, 0, &normalized), "mixed sequence normalizes expected snapshot");
            Check(policy.minimize(current, screen, insets, &current), "mixed resize minimizes");
            Same(policy.expandedFrame(), normalized, "next minimize captures the latest externally resized preset");
            const Snapshot saved = Capture(policy);
            Check(policy.move(current, screen, insets, delta(generator), delta(generator), &current),
                "mixed bar movement succeeds");
            Fits(current, screen, insets, true);
            Unchanged(policy, saved);
            Viewport(policy.expandedFrame());
            Check(policy.restore(current, screen, insets, &current), "mixed bar restores");
            Fits(current, screen, insets, false);
            Check(policy.move(current, screen, insets, delta(generator), delta(generator), &current),
                "mixed expanded movement succeeds");
            Fits(current, screen, insets, false);
            ++mixedCycles;
        }
    }

    {
        PPOWindowLifetime lifetime;
        PPOFloatingWindowPresentation policy;
        PPOHostRect current = initial;
        Check(lifetime.start(100) && policy.start(), "timed presentation and independent lifetime start once");
        for (unsigned step = 1; step <= 1499; ++step) {
            if (policy.minimized()) {
                Check(policy.move(current, phone, safe, delta(generator), delta(generator), &current),
                    "timed bar movement succeeds");
                Check(policy.restore(current, phone, safe, &current), "timed bar restores");
            } else Check(policy.minimize(current, phone, safe, &current), "timed expanded window minimizes");
            Check(lifetime.evaluate(Healthy(100 + step / 100.)) == PPOWindowStop::None,
                "presentation transitions leave the original lifetime open before fifteen seconds");
        }
        Check(policy.minimized(), "exact-deadline fixture is minimized");
        Check(lifetime.evaluate(Healthy(115)) == PPOWindowStop::Timeout,
            "minimizing and restoring never extend the exact fifteen-second deadline");
        Check(!lifetime.keep(Healthy(115)) && !lifetime.start(115), "presentation cannot revive an expired lifetime");
        Check(policy.minimized() && !policy.stopped(), "pure presentation does not latch the separate lifetime policy");
        policy.stop();
        Reject(policy, [&](PPOHostRect *p) { return policy.restore(current, phone, safe, p); },
            "caller close stops the presentation after lifetime expiration");
    }
    for (bool locked : {false, true}) {
        PPOWindowLifetime lifetime;
        PPOFloatingWindowPresentation policy;
        PPOHostRect current = initial;
        Check(lifetime.start(200) && lifetime.keep(Healthy(201)) && policy.start(), "kept presentation starts");
        for (unsigned step = 0; step < 300; ++step) {
            Check(policy.minimize(current, phone, safe, &current), "kept scene minimizes repeatedly");
            Check(policy.move(current, phone, safe, delta(generator), delta(generator), &current), "kept bar moves");
            Check(lifetime.evaluate(Healthy(202 + step)) == PPOWindowStop::None,
                "explicit Keep survives transitions beyond the original deadline");
            Check(policy.restore(current, phone, safe, &current), "kept scene restores repeatedly");
        }
        Check(policy.minimize(current, phone, safe, &current), "kept closure fixture is minimized");
        auto failure = Healthy(502);
        if (locked) failure.locked = true; else failure.sceneActive = false;
        const auto reason = locked ? PPOWindowStop::Locked : PPOWindowStop::SceneInactive;
        Check(lifetime.evaluate(failure) == reason, "Keep and minimized mode preserve lock and inactivity closures");
        Check(policy.restore(current, phone, safe, &current), "geometry remains an independent pure policy until caller stops");
        Check(lifetime.evaluate(Healthy(503)) == reason && !lifetime.keep(Healthy(503)),
            "restoration cannot clear the terminal independent lifetime failure");
        policy.stop();
        Reject(policy, [&](PPOHostRect *p) { return policy.minimize(current, phone, safe, p); },
            "caller safety closure terminally stops presentation");
    }
    std::printf("Floating presentation tests passed: %u checks; %u mixed resize/minimize/move/restore cycles; geometry and independent lifetime policy only\n",
        checks, mixedCycles);
    return 0;
}
