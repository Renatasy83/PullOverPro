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
    PPOHostRect screen{}, safe{}, list{}, visibleList{}, touchList{}, reservedHandle{};
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
    if (right <= x || bottom <= y) return {};
    double width=right-x,height=bottom-y;
    if(x+width>right)width=std::nextafter(width,0.0);
    if(y+height>bottom)height=std::nextafter(height,0.0);
    return {x,y,width,height};
}
inline bool Contains(PPOHostRect outer, PPOHostRect inner) noexcept {
    return inner.x >= outer.x && inner.y >= outer.y &&
        inner.x+inner.width <= outer.x+outer.width &&
        inner.y+inner.height <= outer.y+outer.height;
}
inline bool Same(PPOHostRect a, PPOHostRect b) noexcept {
    return a.x == b.x && a.y == b.y && a.width == b.width && a.height == b.height;
}
inline PPOHostRect ListTouchRect(PPOHostRect list, PPOHostRect safe, PPOHostRect reserved) noexcept {
    PPOHostRect touch = Intersection({list.x,list.y-5,list.width,list.height+10},safe);
    if (touch.width <= 0 || touch.height <= 0) return {};
    const double bottom = touch.y+touch.height;
    if (list.y >= reserved.y+reserved.height) {
        touch.y = std::max(touch.y,reserved.y+reserved.height);
        touch.height = bottom-touch.y;
    } else if (list.y+list.height <= reserved.y) {
        touch.height = std::min(bottom,reserved.y)-touch.y;
        // Arithmetic rounding must not leak an expanded hit target a fraction
        // into the handle's separate second-tap band.
        if (touch.y+touch.height > reserved.y) touch.height = std::nextafter(touch.height,0.0);
    } else return {};
    const double maximumBottom=std::min(safe.y+safe.height,
        list.y+list.height <= reserved.y ? reserved.y : safe.y+safe.height);
    if(touch.y+touch.height>maximumBottom)touch.height=std::nextafter(touch.height,0.0);
    return touch.height > 0 ? touch : PPOHostRect{};
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
    PPOClassicQuickSwitchLayout *result, double handleTouchHeight = PPOClassicTouchHeight) noexcept {
    if (!result) return false;
    *result = {};
    PPOHostRect safe{};
    if (!PPOEdgeDrawerDetail::Usable(screen,insets,&safe) ||
        !PPOEdgeDrawerDetail::Side(side) || !PPOEdgeDrawerDetail::Coordinate(handleCenterY) ||
        count == 0 || count > PPOClassicMaximumItems || !std::isfinite(handleTouchHeight) ||
        handleTouchHeight < PPOClassicTouchHeight || handleTouchHeight > 72) return false;
    handleCenterY = std::clamp(handleCenterY,safe.y+handleTouchHeight/2,
        safe.y+safe.height-handleTouchHeight/2);
    PPOClassicQuickSwitchLayout value{};
    value.screen = screen; value.safe = safe; value.count = count;
    value.contentHeight = static_cast<double>(count)*PPOClassicRowHeight;
    // The selected handle remains a distinct second-tap target. Reserve its
    // entire touch height, not just the visible34pt pill. A5pt separation also
    // keeps expanded44pt row hit padding outside that band.
    const double handleTop = handleCenterY-handleTouchHeight/2;
    const double handleBottom = handleCenterY+handleTouchHeight/2;
    const double belowStart = handleBottom+5;
    const double aboveEnd = handleTop-5;
    const double below = std::max(0.0,safe.y+safe.height-belowStart);
    const double above = std::max(0.0,aboveEnd-safe.y);
    value.reversed = value.contentHeight > below &&
        (value.contentHeight <= above || above >= below);
    const double available = value.reversed ? above : below;
    const double height = std::min(value.contentHeight,available);
    if (height < PPOClassicRowHeight) return false;
    const double y = value.reversed ? aboveEnd-height : belowStart;
    const bool left = side == PPOEdgeDrawerSide::Left;
    // Like the original pill, a normal list protrudes 30 points. With a large
    // horizontal safe inset, move it inward enough to retain44 visible points.
    const double x = left ? std::max(screen.x-30,safe.x+44-PPOClassicPillWidth)
        : std::min(screen.x+screen.width-PPOClassicEdgeStrip,safe.x+safe.width-44);
    value.reservedHandle = {x,handleTop,PPOClassicPillWidth,handleTouchHeight};
    value.list = {x,y,PPOClassicPillWidth,height};
    value.visibleList = PPOClassicDetail::Intersection(value.list,safe);
    value.touchList = PPOClassicDetail::ListTouchRect(value.list,safe,value.reservedHandle);
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
        !PPOEdgeDrawerDetail::Rect(layout.touchList) || !PPOEdgeDrawerDetail::Rect(layout.reservedHandle) ||
        layout.reservedHandle.x != layout.list.x || layout.reservedHandle.width != PPOClassicPillWidth ||
        layout.reservedHandle.height < PPOClassicTouchHeight || layout.reservedHandle.height > 72 ||
        layout.reservedHandle.y < layout.safe.y-1e-8 ||
        layout.reservedHandle.y+layout.reservedHandle.height > layout.safe.y+layout.safe.height+1e-8 ||
        !(layout.touchList.y+layout.touchList.height <= layout.reservedHandle.y+1e-8 ||
          layout.touchList.y >= layout.reservedHandle.y+layout.reservedHandle.height-1e-8) ||
        layout.list.width != PPOClassicPillWidth ||
        layout.contentHeight != static_cast<double>(layout.count)*PPOClassicRowHeight ||
        layout.list.height > layout.contentHeight || !std::isfinite(scrollOffset) || scrollOffset < 0 ||
        scrollOffset > layout.contentHeight-layout.list.height ||
        !PPOClassicDetail::Contains(layout.screen,layout.safe) ||
        !PPOClassicDetail::Contains(layout.screen,layout.visibleList) ||
        !PPOClassicDetail::Contains(layout.safe,layout.touchList) ||
        !PPOClassicDetail::Same(layout.visibleList,PPOClassicDetail::Intersection(layout.list,layout.safe)) ||
        !PPOClassicDetail::Same(layout.touchList,PPOClassicDetail::ListTouchRect(layout.list,layout.safe,layout.reservedHandle)) ||
        !PPOEdgeDrawerDetail::Coordinate(sceneX) || !PPOEdgeDrawerDetail::Coordinate(sceneY) ||
        !PPOEdgeDrawerDetail::Contains(layout.touchList,sceneX,sceneY) ||
        (sceneY >= layout.reservedHandle.y && sceneY <= layout.reservedHandle.y+layout.reservedHandle.height)) return false;
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
