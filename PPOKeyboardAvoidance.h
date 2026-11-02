#pragma once

#include "PPOEdgeDrawerGeometry.h"

// Public overlay placement only. All rectangles are in the same scene space.
// Always pass the configured/preferred touch rectangle, never the last shifted
// result: hiding the keyboard then restores that preference without I/O/state.
struct PPOKeyboardAvoidanceResult {
    PPOHostRect touchHandle{};
    PPOEdgeDrawerInsets pickerInsets{};
    double centerY = 0;
    bool adjusted = false;
    bool keyboardRelevant = false;
};

inline constexpr double PPOKeyboardAvoidancePadding = 8;
// Verification tolerance for arithmetic produced by the existing public edge
// layout at a safe boundary. It never changes a preferred coordinate or permits
// an undersized/inverted free band.
inline constexpr double PPOKeyboardAvoidanceContainmentTolerance = 1e-8;

namespace PPOKeyboardAvoidanceDetail {
inline bool Intersects(PPOHostRect a, PPOHostRect b) noexcept {
    return a.x < b.x+b.width && a.x+a.width > b.x &&
        a.y < b.y+b.height && a.y+a.height > b.y;
}
inline bool HorizontalIntersection(PPOHostRect a, PPOHostRect b) noexcept {
    return a.x < b.x+b.width && a.x+a.width > b.x;
}
inline bool Original(PPOHostRect screen, PPOEdgeDrawerInsets insets,
    PPOHostRect touch, PPOHostRect *safe) noexcept {
    if (!PPOEdgeDrawerDetail::Usable(screen,insets,safe) ||
        !PPOEdgeDrawerDetail::Rect(touch) || touch.width < 44 || touch.height < 44 ||
        touch.x < screen.x-PPOKeyboardAvoidanceContainmentTolerance ||
        touch.x+touch.width > screen.x+screen.width+PPOKeyboardAvoidanceContainmentTolerance ||
        touch.y < safe->y-PPOKeyboardAvoidanceContainmentTolerance ||
        touch.y+touch.height > safe->y+safe->height+PPOKeyboardAvoidanceContainmentTolerance) return false;
    // Preserve the actual physical edge x/width supplied by the root. Horizontal
    // safe insets do not silently relocate an already valid left/right handle.
    return true;
}
inline PPOHostRect Intersection(PPOHostRect a, PPOHostRect b) noexcept {
    const double x=std::max(a.x,b.x), y=std::max(a.y,b.y);
    return {x,y,std::max(0.0,std::min(a.x+a.width,b.x+b.width)-x),
        std::max(0.0,std::min(a.y+a.height,b.y+b.height)-y)};
}
struct Band { double top=0, bottom=0, center=0; bool fits=false; };
inline Band MakeBand(double top,double bottom,double desiredCenter,double height) noexcept {
    Band band{top,bottom,desiredCenter,false};
    if (!std::isfinite(top) || !std::isfinite(bottom) || bottom-top < height) return band;
    band.center=std::clamp(desiredCenter,top+height/2,bottom-height/2);
    band.fits=true;
    return band;
}
}

// true: a valid public layout decision (possibly unchanged).
// false: invalid/transient data or no safe nonoverlap band. Once the original
// screen/handle is validated, false preserves that original handle/insets. The
// caller must skip keyboard adjustments on false; no app/frame/focus change is
// authorized. A false return before original validation leaves a cleared result.
// pickerInsets describe only the compact chooser's available vertical band;
// short bands may cause the existing chooser geometry to refuse/close. They
// must never replace the main scene/app/native-frame safe area.
inline bool PPOKeyboardAvoidanceLayout(PPOHostRect screen,PPOEdgeDrawerInsets insets,
    PPOHostRect desiredTouchHandle,PPOHostRect keyboardFrame,bool enabled,
    bool keyboardVisible,PPOKeyboardAvoidanceResult *result) noexcept {
    if (!result) return false;
    *result={};
    PPOHostRect safe{};
    if (!PPOKeyboardAvoidanceDetail::Original(screen,insets,desiredTouchHandle,&safe)) return false;
    result->touchHandle=desiredTouchHandle; result->pickerInsets=insets;
    result->centerY=desiredTouchHandle.y+desiredTouchHandle.height/2;
    if (!enabled || !keyboardVisible) return true; // Ignore stale hidden frames.
    if (!PPOEdgeDrawerDetail::Rect(keyboardFrame)) return false;
    const PPOHostRect keyboard=PPOKeyboardAvoidanceDetail::Intersection(screen,keyboardFrame);
    if (keyboard.width <= 0 || keyboard.height <= 0 ||
        !PPOKeyboardAvoidanceDetail::HorizontalIntersection(desiredTouchHandle,keyboard) ||
        keyboard.y >= safe.y+safe.height || keyboard.y+keyboard.height <= safe.y) return true;
    const bool overlap=PPOKeyboardAvoidanceDetail::Intersects(desiredTouchHandle,keyboard);
    const bool fullWidth=keyboard.x <= safe.x && keyboard.x+keyboard.width >= safe.x+safe.width;
    const bool bottomDocked=fullWidth && keyboard.y+keyboard.height >= safe.y+safe.height;
    const double preferred=result->centerY, height=desiredTouchHandle.height;
    PPOKeyboardAvoidanceDetail::Band selected{};
    if (bottomDocked) {
        // Keep the chooser out of a docked keyboard even when its handle is
        // already above it. Do not move a nonoverlapping handle just for padding.
        const double gap=overlap ? PPOKeyboardAvoidancePadding : 0;
        selected=PPOKeyboardAvoidanceDetail::MakeBand(safe.y,
            std::min(safe.y+safe.height,keyboard.y-gap),preferred,height);
    } else {
        // A floating/split-sized rectangle that misses the handle does not
        // justify moving it or shortening an otherwise usable chooser.
        if (!overlap) return true;
        const auto above=PPOKeyboardAvoidanceDetail::MakeBand(safe.y,
            std::min(safe.y+safe.height,keyboard.y-PPOKeyboardAvoidancePadding),preferred,height);
        const auto below=PPOKeyboardAvoidanceDetail::MakeBand(
            std::max(safe.y,keyboard.y+keyboard.height+PPOKeyboardAvoidancePadding),
            safe.y+safe.height,preferred,height);
        if (above.fits && below.fits)
            selected=std::abs(above.center-preferred) <= std::abs(below.center-preferred) ? above : below;
        else selected=above.fits ? above : below;
    }
    if (!selected.fits) return false;
    PPOHostRect adjusted=desiredTouchHandle;
    if (selected.center != preferred) adjusted.y=selected.center-height/2;
    if (!PPOEdgeDrawerDetail::Rect(adjusted) ||
        PPOKeyboardAvoidanceDetail::Intersects(adjusted,keyboard)) return false;
    result->touchHandle=adjusted; result->centerY=selected.center;
    result->pickerInsets.top=std::max(insets.top,selected.top-screen.y);
    result->pickerInsets.bottom=std::max(insets.bottom,screen.y+screen.height-selected.bottom);
    result->adjusted=adjusted.y != desiredTouchHandle.y;
    result->keyboardRelevant=true;
    return true;
}
