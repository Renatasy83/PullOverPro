#pragma once

#include "PPOEdgeDrawerGeometry.h"
#include <array>
#include <cstddef>

// Pure geometry for the original compact interface. All rectangles are scene
// coordinates except quick-switch rows/touches, which are content-local.
// The private app view is never sized or mutated by these helpers.
inline constexpr double PPOClassicEdgeStrip = 50;
inline constexpr double PPOClassicPillWidth = 80;
inline constexpr double PPOClassicPillHeight = 34;
inline constexpr double PPOClassicRowHeight = 34;
inline constexpr double PPOClassicTouchHeight = 44;
inline constexpr std::size_t PPOClassicMaximumItems = 16;

struct PPOClassicHandleLayout {
    PPOHostRect pill{}, touch{};
    double centerY = 0;
};

struct PPOClassicQuickSwitchLayout {
    PPOHostRect screen{}, safe{}, list{}, visibleList{}, touchList{};
    std::array<PPOHostRect, PPOClassicMaximumItems> rows{}, rowTouches{};
    std::array<std::size_t, PPOClassicMaximumItems> itemIndices{};
    std::size_t count = 0;
    double contentHeight = 0, initialScrollOffset = 0;
    bool reversed = false, scrollable = false;
};

namespace PPOClassicDetail {
inline PPOHostRect Intersection(PPOHostRect a, PPOHostRect b) noexcept {
    const double x = std::max(a.x,b.x), y = std::max(a.y,b.y);
    const double right = std::min(a.x+a.width,b.x+b.width);
    const double bottom = std::min(a.y+a.height,b.y+b.height);
    return right > x && bottom > y ? PPOHostRect{x,y,right-x,bottom-y} : PPOHostRect{};
}
inline bool Contains(PPOHostRect outer, PPOHostRect inner) noexcept {
    return inner.x >= outer.x && inner.y >= outer.y &&
        inner.x+inner.width <= outer.x+outer.width &&
        inner.y+inner.height <= outer.y+outer.height;
}
inline bool Same(PPOHostRect a, PPOHostRect b) noexcept {
    return a.x == b.x && a.y == b.y && a.width == b.width && a.height == b.height;
}
}

inline bool PPOClassicMakeHandle(PPOHostRect screen, PPOEdgeDrawerInsets insets,
    PPOEdgeDrawerSide side, double yRatio, PPOClassicHandleLayout *result) noexcept {
    if (!result) return false;
    *result = {};
    PPOHostRect safe{};
    if (!PPOEdgeDrawerDetail::Usable(screen,insets,&safe) ||
        !PPOEdgeDrawerDetail::Side(side) || !std::isfinite(yRatio)) return false;
    yRatio = std::clamp(yRatio,0.0,1.0);
    const double center = safe.y+PPOClassicTouchHeight/2+
        yRatio*(safe.height-PPOClassicTouchHeight);
    const bool left = side == PPOEdgeDrawerSide::Left;
    PPOClassicHandleLayout value{};
    value.touch = {left ? screen.x : screen.x+screen.width-PPOClassicEdgeStrip,
        center-PPOClassicTouchHeight/2,PPOClassicEdgeStrip,PPOClassicTouchHeight};
    value.pill = {left ? screen.x-30 : screen.x+screen.width-PPOClassicEdgeStrip,
        center-PPOClassicPillHeight/2,PPOClassicPillWidth,PPOClassicPillHeight};
    value.centerY = center;
    if (!PPOEdgeDrawerDetail::Rect(value.touch) || !PPOEdgeDrawerDetail::Rect(value.pill)) return false;
    *result = value;
    return true;
}

// Preserve the original screen-centered, no-toolbar aspect ratio. Safe insets
// restrict the scale/origin only when the original rectangle would not fit.
// side denotes the incoming edge: a right drawer is anchored at the safe right.
inline bool PPOClassicAppPanelFrame(PPOHostRect screen, PPOEdgeDrawerInsets insets,
    PPOEdgeDrawerSide side, double nativeWidth, double nativeHeight,
    PPOHostRect *result) noexcept {
    if (!result) return false;
    *result = {};
    PPOHostRect safe{};
    if (!PPOEdgeDrawerDetail::Usable(screen,insets,&safe) ||
        !PPOEdgeDrawerDetail::Side(side) || !std::isfinite(nativeWidth) ||
        !std::isfinite(nativeHeight) || nativeWidth < 32 || nativeWidth > 8192 ||
        nativeHeight < 32 || nativeHeight > 8192) return false;
    const double maxWidth = std::min(screen.width-PPOClassicEdgeStrip,safe.width);
    double scale = std::min(maxWidth/nativeWidth,safe.height/nativeHeight);
    double width = nativeWidth*scale, height = nativeHeight*scale;
    if (width > maxWidth || height > safe.height) {
        scale = std::nextafter(scale,0.0);
        width = nativeWidth*scale; height = nativeHeight*scale;
    }
    if (!std::isfinite(scale) || scale <= 0 || width < 240 || height < 320 ||
        width > maxWidth || height > safe.height) return false;
    const double x = side == PPOEdgeDrawerSide::Left ? safe.x : safe.x+safe.width-width;
    const double y = std::clamp(screen.y+(screen.height-height)/2,
        safe.y,safe.y+safe.height-height);
    PPOHostRect panel{x,y,width,height};
    if (!PPOEdgeDrawerDetail::Rect(panel)) return false;
    // A bounded rounding tolerance is only for arithmetic verification, never
    // a second scale or a request to resize the native app's view.
    constexpr double epsilon = 1e-8;
    if (panel.x < safe.x-epsilon || panel.y < safe.y-epsilon ||
        panel.x+width > safe.x+safe.width+epsilon ||
        panel.y+height > safe.y+safe.height+epsilon) return false;
    *result = panel;
    return true;
}

inline bool PPOClassicMakeQuickSwitch(PPOHostRect screen, PPOEdgeDrawerInsets insets,
    PPOEdgeDrawerSide side, double handleCenterY, std::size_t count,
    PPOClassicQuickSwitchLayout *result) noexcept {
    if (!result) return false;
    *result = {};
    PPOHostRect safe{};
    if (!PPOEdgeDrawerDetail::Usable(screen,insets,&safe) ||
        !PPOEdgeDrawerDetail::Side(side) || !PPOEdgeDrawerDetail::Coordinate(handleCenterY) ||
        count == 0 || count > PPOClassicMaximumItems) return false;
    handleCenterY = std::clamp(handleCenterY,safe.y+PPOClassicTouchHeight/2,
        safe.y+safe.height-PPOClassicTouchHeight/2);
    PPOClassicQuickSwitchLayout value{};
    value.screen = screen; value.safe = safe; value.count = count;
    value.contentHeight = static_cast<double>(count)*PPOClassicRowHeight;
    const double handleTop = handleCenterY-PPOClassicPillHeight/2;
    const double handleBottom = handleCenterY+PPOClassicPillHeight/2;
    value.reversed = handleTop+value.contentHeight > safe.y+safe.height;
    const double available = value.reversed ? handleBottom-safe.y : safe.y+safe.height-handleTop;
    const double height = std::min(value.contentHeight,available);
    const double y = std::clamp(value.reversed ? handleBottom-height : handleTop,
        safe.y,safe.y+safe.height-height);
    const bool left = side == PPOEdgeDrawerSide::Left;
    // Like the original pill, a normal list protrudes 30 points. With a large
    // horizontal safe inset, move it inward enough to retain44 visible points.
    const double x = left ? std::max(screen.x-30,safe.x+44-PPOClassicPillWidth)
        : std::min(screen.x+screen.width-PPOClassicEdgeStrip,safe.x+safe.width-44);
    value.list = {x,y,PPOClassicPillWidth,height};
    value.visibleList = PPOClassicDetail::Intersection(value.list,safe);
    value.touchList = PPOClassicDetail::Intersection({value.list.x,value.list.y-5,
        value.list.width,value.list.height+10},safe);
    if (!PPOEdgeDrawerDetail::Rect(value.list) ||
        !PPOEdgeDrawerDetail::Rect(value.visibleList) ||
        !PPOEdgeDrawerDetail::Rect(value.touchList) || value.visibleList.width < 44) return false;
    value.scrollable = value.contentHeight > height;
    value.initialScrollOffset = value.reversed ? value.contentHeight-height : 0;
    for (std::size_t row = 0; row < count; row++) {
        const double rowY = static_cast<double>(row)*PPOClassicRowHeight;
        value.rows[row] = {0,rowY,PPOClassicPillWidth,PPOClassicRowHeight};
        // Original34pt density cannot give every interior row disjoint44pt
        // hits. Expanded boxes overlap; the hit helper resolves row pitch
        // deterministically and only selects an actually visible content row.
        value.rowTouches[row] = {0,rowY-5,PPOClassicPillWidth,PPOClassicTouchHeight};
        value.itemIndices[row] = value.reversed ? count-1-row : row;
    }
    *result = value;
    return true;
}

inline bool PPOClassicQuickSwitchItemAtPoint(const PPOClassicQuickSwitchLayout &layout,
    double sceneX, double sceneY, double scrollOffset, std::size_t *itemIndex) noexcept {
    if (!itemIndex) return false;
    *itemIndex = 0;
    if (layout.count == 0 || layout.count > PPOClassicMaximumItems ||
        !PPOEdgeDrawerDetail::Rect(layout.screen) || !PPOEdgeDrawerDetail::Rect(layout.safe) ||
        !PPOEdgeDrawerDetail::Rect(layout.list) || !PPOEdgeDrawerDetail::Rect(layout.visibleList) ||
        !PPOEdgeDrawerDetail::Rect(layout.touchList) || layout.list.width != PPOClassicPillWidth ||
        layout.contentHeight != static_cast<double>(layout.count)*PPOClassicRowHeight ||
        layout.list.height > layout.contentHeight || !std::isfinite(scrollOffset) || scrollOffset < 0 ||
        scrollOffset > layout.contentHeight-layout.list.height ||
        !PPOClassicDetail::Contains(layout.screen,layout.safe) ||
        !PPOClassicDetail::Contains(layout.screen,layout.visibleList) ||
        !PPOClassicDetail::Contains(layout.safe,layout.touchList) ||
        !PPOClassicDetail::Same(layout.visibleList,PPOClassicDetail::Intersection(layout.list,layout.safe)) ||
        !PPOClassicDetail::Same(layout.touchList,PPOClassicDetail::Intersection({layout.list.x,layout.list.y-5,
            layout.list.width,layout.list.height+10},layout.safe)) ||
        !PPOEdgeDrawerDetail::Coordinate(sceneX) || !PPOEdgeDrawerDetail::Coordinate(sceneY) ||
        !PPOEdgeDrawerDetail::Contains(layout.touchList,sceneX,sceneY)) return false;
    const double contentY = std::clamp(sceneY-layout.list.y+scrollOffset,scrollOffset,
        std::nextafter(scrollOffset+layout.list.height,scrollOffset));
    const std::size_t row = static_cast<std::size_t>(std::floor(contentY/PPOClassicRowHeight));
    if (row >= layout.count) return false;
    const std::size_t expected = layout.reversed ? layout.count-1-row : row;
    const double rowY = static_cast<double>(row)*PPOClassicRowHeight;
    if (layout.itemIndices[row] != expected ||
        !PPOClassicDetail::Same(layout.rows[row],{0,rowY,PPOClassicPillWidth,PPOClassicRowHeight}) ||
        !PPOClassicDetail::Same(layout.rowTouches[row],{0,rowY-5,PPOClassicPillWidth,PPOClassicTouchHeight})) return false;
    *itemIndex = expected;
    return true;
}
