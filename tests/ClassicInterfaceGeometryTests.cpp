#include "../PPOClassicInterfaceGeometry.h"
#include <cstdio>
#include <cstdlib>
#include <limits>
#include <random>

static unsigned checks;
static void Check(bool condition,const char *message) {
    checks++;
    if (!condition) { std::fprintf(stderr,"FAIL: %s\n",message); std::exit(1); }
}
static bool Near(double a,double b) { return std::abs(a-b)<=1e-8; }
static void Same(PPOHostRect a,PPOHostRect b,const char *message) {
    Check(Near(a.x,b.x)&&Near(a.y,b.y)&&Near(a.width,b.width)&&Near(a.height,b.height),message);
}
static void Cleared(const PPOClassicQuickSwitchLayout &l) {
    for (auto r : {l.screen,l.safe,l.list,l.visibleList,l.touchList,l.reservedHandle}) Same(r,{},"failed layout clears scene rectangles");
    for (std::size_t i=0;i<16;i++) {
        Same(l.rows[i],{},"failed layout clears rows");
        Same(l.rowTouches[i],{},"failed layout clears row targets");
        Check(l.itemIndices[i]==0,"failed layout clears row identities");
    }
    Check(l.count==0&&l.contentHeight==0&&l.initialScrollOffset==0&&!l.reversed&&!l.scrollable,
        "failed layout clears all state");
}
static void AppFits(PPOHostRect panel,PPOHostRect screen,PPOEdgeDrawerInsets insets,
    PPOEdgeDrawerSide side,double nativeWidth,double nativeHeight) {
    PPOHostRect safe{screen.x+insets.left,screen.y+insets.top,
        screen.width-insets.left-insets.right,screen.height-insets.top-insets.bottom};
    Check(panel.width>=240&&panel.height>=320,"classic app remains readable without a title toolbar");
    Check(panel.x>=safe.x-1e-8&&panel.y>=safe.y-1e-8&&panel.x+panel.width<=safe.x+safe.width+1e-8&&
        panel.y+panel.height<=safe.y+safe.height+1e-8,"classic app respects all safe boundaries");
    Check(Near(panel.width/nativeWidth,panel.height/nativeHeight),"all app pixels retain native aspect without subtracting a header");
    Check(panel.width<=screen.width-50+1e-8,"original edge strip restricts the app width");
    Check(Near(panel.width,std::min(screen.width-50,safe.width))||Near(panel.height,safe.height),
        "a real safe limit determines the scale");
    Check(side==PPOEdgeDrawerSide::Left?Near(panel.x,safe.x):Near(panel.x+panel.width,safe.x+safe.width),
        "incoming side anchors to its safe edge without mirroring app content");
    Check(Near(panel.y,std::clamp(screen.y+(screen.height-panel.height)/2,
        safe.y,safe.y+safe.height-panel.height)),"screen centering changes only when a safe boundary requires it");
}
static void QuickFits(const PPOClassicQuickSwitchLayout &l) {
    Check(l.count>=1&&l.count<=16&&l.list.width==80&&l.visibleList.width>=44,
        "compact list retains original width and a safe horizontal target");
    Check(l.contentHeight==l.count*34&&l.list.height<=l.contentHeight&&l.list.height>=34,
        "original row density is stable and a clipped viewport can still show one row");
    Check(l.list.y>=l.safe.y-1e-8&&l.list.y+l.list.height<=l.safe.y+l.safe.height+1e-8,
        "list viewport never overflows vertically");
    Check(l.initialScrollOffset>=0&&l.initialScrollOffset<=l.contentHeight-l.list.height&&
        l.scrollable==(l.list.height<l.contentHeight),"clipping and initial offset are internally consistent");
    Check(l.reversed?Near(l.initialScrollOffset,l.contentHeight-l.list.height):l.initialScrollOffset==0,
        "upward overflow initially shows the nearest original choice");
    const double x=l.visibleList.x+l.visibleList.width/2;
    for (std::size_t i=0;i<l.count;i++) {
        Same(l.rows[i],{0,static_cast<double>(i)*34,80,34},"visual rows are original34point content coordinates");
        Same(l.rowTouches[i],{0,static_cast<double>(i)*34-5,80,44},"expanded row targets provide padding with documented overlap");
        Check(l.itemIndices[i]==(l.reversed?l.count-1-i:i),"visual ordering preserves exact item identity");
        const double top=std::max(l.visibleList.y,l.list.y+l.rows[i].y-l.initialScrollOffset);
        const double bottom=std::min(l.visibleList.y+l.visibleList.height,
            l.list.y+l.rows[i].y+34-l.initialScrollOffset);
        if (bottom-top>1e-7) {
            std::size_t hit=999;
            bool ok=PPOClassicQuickSwitchItemAtPoint(l,x,(top+bottom)/2,l.initialScrollOffset,&hit)&&hit==l.itemIndices[i];
            Check(ok,"every actually visible row maps back to its own original item");
        }
    }
    std::size_t hit=999;
    Check(l.reservedHandle.height>=44&&l.reservedHandle.height<=72,
        "selected handle retains its complete configured touch height");
    const auto collision=PPOClassicDetail::Intersection(l.touchList,l.reservedHandle);
    Check(collision.width==0&&collision.height==0,
        "list hit padding never overlaps the separate selected-handle target");
    for (double y : {l.reservedHandle.y,l.reservedHandle.y+l.reservedHandle.height/2,
            l.reservedHandle.y+l.reservedHandle.height})
        Check(!PPOClassicQuickSwitchItemAtPoint(l,x,y,l.initialScrollOffset,&hit),
            "the handle band and boundary belong to the selected handle, never a quick row");
    for (std::size_t i=0;i<l.count;i++) {
        PPOHostRect rowTouch=l.rowTouches[i];
        rowTouch.x+=l.list.x; rowTouch.y+=l.list.y-l.initialScrollOffset;
        const auto actual=PPOClassicDetail::Intersection(rowTouch,l.touchList);
        const auto overlap=PPOClassicDetail::Intersection(actual,l.reservedHandle);
        Check(overlap.width==0&&overlap.height==0,
            "each visible expanded row target stays outside the selected handle at the initial scroll offset");
    }
    Check(!PPOClassicQuickSwitchItemAtPoint(l,l.touchList.x-0.01,l.touchList.y, l.initialScrollOffset,&hit)&&hit==0,
        "points outside the list do not capture an underlying app");
    Check(!PPOClassicQuickSwitchItemAtPoint(l,x,l.touchList.y-0.01,l.initialScrollOffset,&hit),
        "expanded targets remain bounded by the safe visible viewport");
}

int main() {
    const PPOHostRect phone{0,0,414,896};
    const PPOEdgeDrawerInsets safe{44,0,34,0};
    PPOClassicHandleLayout handle{};
    Check(PPOClassicMakeHandle(phone,safe,PPOEdgeDrawerSide::Right,0.5,&handle),"phone handle layout");
    Same(handle.touch,{364,431,50,44},"phone handle has a50point edge strip and44point touch height");
    Same(handle.pill,{364,436,80,34},"right pill protrudes30points as in the original");
    Check(handle.centerY==453,"safe handle center uses the supplied ratio");
    Check(PPOClassicMakeHandle(phone,safe,PPOEdgeDrawerSide::Left,0.5,&handle),"left handle layout");
    Same(handle.pill,{-30,436,80,34},"left geometry mirrors coordinates without a content transform");
    Check(PPOClassicMakeHandle(phone,safe,PPOEdgeDrawerSide::Right,-1,&handle)&&handle.centerY==66,
        "finite out-of-range handle ratios clamp to the safe top");
    Check(PPOClassicMakeHandle(phone,safe,PPOEdgeDrawerSide::Right,2,&handle)&&handle.centerY==840,
        "finite out-of-range handle ratios clamp to the safe bottom");

    PPOHostRect panel{};
    Check(PPOClassicAppPanelFrame(phone,safe,PPOEdgeDrawerSide::Right,414,896,&panel),"classic phone app frame");
    Same(panel,{50,54.106280193236714,364,787.7874396135266},"classic phone has original aspect and no44point toolbar");
    AppFits(panel,phone,safe,PPOEdgeDrawerSide::Right,414,896);
    Check(PPOClassicAppPanelFrame(phone,safe,PPOEdgeDrawerSide::Left,414,896,&panel),"left classic phone app frame");
    Check(Near(panel.x,0),"left content anchors normally rather than using a negative scale");

    PPOClassicQuickSwitchLayout quick{};
    Check(PPOClassicMakeQuickSwitch(phone,safe,PPOEdgeDrawerSide::Right,453,1,&quick),"one item list");
    Same(quick.list,{364,480,80,34},"first choice starts below the complete selected handle");
    Same(quick.visibleList,{364,480,50,34},"only physical50points are drawn on an ordinary edge");
    Check(!quick.reversed&&!quick.scrollable,"one item needs neither reverse nor scroll");
    QuickFits(quick);
    Check(PPOClassicMakeQuickSwitch(phone,safe,PPOEdgeDrawerSide::Right,453,5,&quick),"five item list");
    Same(quick.list,{364,480,80,170},"five choices are a compact170point list below the handle");
    Check(!quick.reversed,"five centered choices fit below");
    QuickFits(quick);
    Check(PPOClassicMakeQuickSwitch(phone,safe,PPOEdgeDrawerSide::Right,840,5,&quick),"near-bottom list");
    Same(quick.list,{364,643,80,170},"near-bottom choices extend above the complete handle target");
    Check(quick.reversed&&quick.itemIndices[4]==0,"nearest choice remains the original first favorite");
    std::size_t hit=99;
    Check(!PPOClassicQuickSwitchItemAtPoint(quick,389,840,0,&hit),"upward handle-center release belongs to the selected handle");
    Check(PPOClassicQuickSwitchItemAtPoint(quick,389,796,0,&hit)&&hit==0,"upward nearest visible row selects the first favorite");
    QuickFits(quick);
    Check(PPOClassicMakeQuickSwitch(phone,safe,PPOEdgeDrawerSide::Right,453,16,&quick),"sixteen centered choices");
    Same(quick.list,{364,44,80,382},"long lists clip above the reserved handle rather than crossing the status area");
    Check(quick.reversed&&quick.scrollable&&quick.initialScrollOffset==162,
        "clipped reverse list initially scrolls to the nearest choice");
    Check(PPOClassicQuickSwitchItemAtPoint(quick,389,409,162,&hit)&&hit==0,
        "the nearest visible choice stays adjacent to the reserved handle");
    QuickFits(quick);
    Check(PPOClassicQuickSwitchItemAtPoint(quick,389,quick.list.y+10,0,&hit)&&hit==15,
        "scrolling the reverse list reveals its other end with stable identities");

    const PPOHostRect landscape{100,-200,896,414};
    const PPOEdgeDrawerInsets landscapeSafe{0,44,21,44};
    Check(PPOClassicMakeQuickSwitch(landscape,landscapeSafe,PPOEdgeDrawerSide::Left,-100,16,&quick),
        "offset landscape with a horizontal safe inset");
    Check(quick.visibleList.x==144&&quick.visibleList.width==44,"notch-safe list shifts inward to retain44visiblepoints");
    QuickFits(quick);
    Check(PPOClassicAppPanelFrame(landscape,landscapeSafe,PPOEdgeDrawerSide::Right,896,414,&panel),
        "offset landscape app geometry");
    AppFits(panel,landscape,landscapeSafe,PPOEdgeDrawerSide::Right,896,414);

    const double nan=std::numeric_limits<double>::quiet_NaN(),inf=std::numeric_limits<double>::infinity();
    for (double invalid : {nan,inf,-inf}) {
        handle.centerY=42;
        Check(!PPOClassicMakeHandle(phone,safe,PPOEdgeDrawerSide::Left,invalid,&handle)&&handle.centerY==0,
            "nonfinite handle ratios fail closed and clear output");
        Check(!PPOClassicMakeQuickSwitch(phone,safe,PPOEdgeDrawerSide::Right,invalid,5,&quick),
            "nonfinite handle positions cannot define a chooser");
        Cleared(quick);
    }
    for (std::size_t count : {std::size_t(0),std::size_t(17),std::numeric_limits<std::size_t>::max()}) {
        Check(!PPOClassicMakeQuickSwitch(phone,safe,PPOEdgeDrawerSide::Right,453,count,&quick),
            "empty or unbounded item counts cannot become a view");
        Cleared(quick);
    }
    for (double invalid : {nan,inf,-inf,-1.0,0.0,31.999,8192.001}) {
        panel={1,2,3,4};
        Check(!PPOClassicAppPanelFrame(phone,safe,PPOEdgeDrawerSide::Right,invalid,896,&panel),
            "invalid native widths cannot resize an app panel");
        Same(panel,{},"invalid native geometry clears the panel");
        Check(!PPOClassicAppPanelFrame(phone,safe,PPOEdgeDrawerSide::Right,414,invalid,&panel),
            "invalid native heights cannot resize an app panel");
    }
    for (PPOHostRect screen : {PPOHostRect{nan,0,414,896},{0,inf,414,896},{0,0,-414,896},
            {0,0,414,0},{32768,0,414,896},{0,0,8193,896},{0,0,195,896},{0,0,414,159}}) {
        Check(!PPOClassicMakeQuickSwitch(screen,{},PPOEdgeDrawerSide::Left,50,5,&quick),"invalid screen is rejected");
        Cleared(quick);
        Check(!PPOClassicAppPanelFrame(screen,{},PPOEdgeDrawerSide::Left,414,896,&panel),"invalid screen cannot hold an app");
        Check(!PPOClassicMakeHandle(screen,{},PPOEdgeDrawerSide::Left,0.5,&handle),"invalid screen cannot hold a handle");
    }
    for (PPOEdgeDrawerInsets insets : {PPOEdgeDrawerInsets{nan,0,0,0},{0,inf,0,0},{0,0,-1,0},
            {0,0,0,inf},{500,0,500,0},{0,300,0,300}}) {
        Check(!PPOClassicMakeQuickSwitch(phone,insets,PPOEdgeDrawerSide::Left,453,5,&quick),"invalid safe area fails closed");
        Cleared(quick);
    }
    const auto badSide=static_cast<PPOEdgeDrawerSide>(999);
    Check(!PPOClassicMakeHandle(phone,safe,badSide,0.5,&handle)&&
        !PPOClassicMakeQuickSwitch(phone,safe,badSide,453,5,&quick)&&
        !PPOClassicAppPanelFrame(phone,safe,badSide,414,896,&panel),"unknown side has no implicit orientation");
    Check(!PPOClassicMakeHandle(phone,safe,PPOEdgeDrawerSide::Left,0.5,nullptr)&&
        !PPOClassicMakeQuickSwitch(phone,safe,PPOEdgeDrawerSide::Left,453,5,nullptr)&&
        !PPOClassicAppPanelFrame(phone,safe,PPOEdgeDrawerSide::Left,414,896,nullptr),"null outputs are safe");

    Check(PPOClassicMakeQuickSwitch(phone,safe,PPOEdgeDrawerSide::Right,453,1,&quick),"restore valid hit fixture");
    for (double invalid : {nan,inf,-inf,-1.0,0.001}) {
        Check(!PPOClassicQuickSwitchItemAtPoint(quick,389,497,invalid,&hit)&&hit==0,
            "single-row list rejects invalid or out-of-range scroll offset");
    }
    for (double invalid : {nan,inf,-inf})
        Check(!PPOClassicQuickSwitchItemAtPoint(quick,invalid,497,0,&hit)&&
            !PPOClassicQuickSwitchItemAtPoint(quick,389,invalid,0,&hit),"nonfinite hit points are ignored");
    Check(!PPOClassicQuickSwitchItemAtPoint(quick,389,497,0,nullptr),"null hit output is safe");
    for (unsigned problem=0;problem<8;problem++) {
        auto bad=quick;
        if (problem==0) bad.count=17;
        if (problem==1) bad.contentHeight=nan;
        if (problem==2) bad.touchList=phone;
        if (problem==3) bad.visibleList=phone;
        if (problem==4) bad.itemIndices[0]=16;
        if (problem==5) bad.rows[0].y=nan;
        if (problem==6) bad.rowTouches[0].height=340;
        if (problem==7) bad.list.height=nan;
        Check(!PPOClassicQuickSwitchItemAtPoint(bad,389,497,0,&hit)&&hit==0,"malformed cached layout cannot capture another region or item");
    }

    // Direct production API regression: the visual pill may grow to72points,
    // while the selected handle's entire touch band remains separately usable.
    for (auto side : {PPOEdgeDrawerSide::Left,PPOEdgeDrawerSide::Right})
        for (double height : {44.0,48.0,64.0,72.0})
            for (double center : {66.0,453.0,840.0})
                for (std::size_t count=1;count<=16;count++) {
                    Check(PPOClassicMakeQuickSwitch(phone,safe,side,center,count,&quick,height),
                        "all supported handle heights can retain a separate compact chooser");
                    Check(quick.reservedHandle.height==height,"the real handle height is used, not a44pt assumption");
                    QuickFits(quick);
                    for (double offset : {0.0,quick.contentHeight-quick.list.height}) {
                        const double x=quick.visibleList.x+quick.visibleList.width/2;
                        for (double y=quick.reservedHandle.y;y<=quick.reservedHandle.y+height;y+=0.5)
                            Check(!PPOClassicQuickSwitchItemAtPoint(quick,x,y,offset,&hit),
                                "scrolling either end cannot capture any point of the selected-handle band");
                    }
                }
    for (double height : {nan,inf,-inf,0.0,43.999,72.001,8192.0}) {
        Check(!PPOClassicMakeQuickSwitch(phone,safe,PPOEdgeDrawerSide::Right,453,5,&quick,height),
            "invalid selected-handle heights cannot define row hit regions");
        Cleared(quick);
    }
    Check(PPOClassicMakeQuickSwitch(phone,safe,PPOEdgeDrawerSide::Right,453,5,&quick),"reserved-band mutation fixture");
    for (unsigned fault=0;fault<5;fault++) {
        auto bad=quick;
        if(fault==0)bad.reservedHandle.height=0;
        if(fault==1)bad.reservedHandle.y=nan;
        if(fault==2)bad.reservedHandle.x+=1;
        if(fault==3)bad.reservedHandle.y=bad.list.y;
        if(fault==4)bad.touchList.y=bad.reservedHandle.y;
        Check(!PPOClassicQuickSwitchItemAtPoint(bad,389,497,0,&hit),
            "malformed cached reserved bands cannot redirect an explicit selected-handle tap");
    }

    std::mt19937_64 random(0x5030434c41535349ULL);
    for (unsigned iteration=0;iteration<12000;iteration++) {
        const double width=320+random()%800,height=568+random()%900;
        const PPOHostRect screen{static_cast<double>(static_cast<int>(random()%1001)-500),
            static_cast<double>(static_cast<int>(random()%1001)-500),width,height};
        const PPOEdgeDrawerInsets insets{static_cast<double>(random()%61),static_cast<double>(random()%31),
            static_cast<double>(random()%61),static_cast<double>(random()%31)};
        const double ratio=(static_cast<double>(random()%3001)-1000)/1000;
        const std::size_t count=1+random()%16;
        for (auto side : {PPOEdgeDrawerSide::Left,PPOEdgeDrawerSide::Right}) {
            Check(PPOClassicMakeHandle(screen,insets,side,ratio,&handle),"random bounded handle layout");
            Check(handle.touch.width>=44&&handle.touch.height>=44&&handle.touch.y>=screen.y+insets.top-1e-8&&
                handle.touch.y+handle.touch.height<=screen.y+screen.height-insets.bottom+1e-8,"random handle remains reachable");
            Check(PPOClassicAppPanelFrame(screen,insets,side,width,height,&panel),"random native-aspect app panel");
            AppFits(panel,screen,insets,side,width,height);
            const double actualTouchHeight=44+random()%29;
            Check(PPOClassicMakeQuickSwitch(screen,insets,side,handle.centerY,count,&quick,actualTouchHeight),"random bounded compact list and actual44to72point handle");
            QuickFits(quick);
        }
    }
    std::printf("Classic interface geometry tests passed: %u checks; original-style public geometry, not UIKit rendering\n",checks);
    return 0;
}
