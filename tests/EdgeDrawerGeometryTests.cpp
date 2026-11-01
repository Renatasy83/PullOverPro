#include "../PPOEdgeDrawerGeometry.h"
#include <cstdio>
#include <cstdlib>
#include <limits>
#include <random>

static unsigned checks;
static void Check(bool value, const char *message) {
    checks++;
    if (!value) { std::fprintf(stderr, "FAIL: %s\n", message); std::exit(1); }
}
static bool Near(double a, double b) { return std::abs(a - b) <= 1e-8; }
static void Same(PPOHostRect a, PPOHostRect b, const char *message) {
    Check(Near(a.x,b.x) && Near(a.y,b.y) && Near(a.width,b.width) && Near(a.height,b.height), message);
}
static void Cleared(const PPOEdgeDrawerLayout &layout) {
    for (PPOHostRect rect : {layout.screen,layout.usable,layout.handle,layout.touchHandle,
            layout.openDrawer,layout.closedDrawer,layout.drawer}) Same(rect, {}, "failed layout clears every rectangle");
    Check(layout.progress == 0 && layout.travel == 0, "failed layout clears gesture metadata");
}
static void Fits(const PPOEdgeDrawerLayout &layout) {
    const PPOHostRect s = layout.screen, u = layout.usable, t = layout.touchHandle;
    Check(layout.handle.width == 20 && t.width >= 44 && t.height >= 44,
        "visual nub stays narrow while the full hit target is reachable");
    Check(t.x >= s.x - 1e-8 && t.x+t.width <= s.x+s.width+1e-8 &&
        t.y >= u.y-1e-8 && t.y+t.height <= u.y+u.height+1e-8,
        "handle touch target stays within screen and vertical safe area");
    const PPOHostRect o=layout.openDrawer;
    Check(o.x >= u.x-1e-8 && o.y == u.y && o.x+o.width <= u.x+u.width+1e-8 && o.height == u.height,
        "expanded drawer controls lie inside the safe working bounds");
    Check(o.width > 0 && o.width <= 340 && o.width <= u.width*0.82+1e-8 &&
        layout.drawer.width == o.width && layout.drawer.height == o.height,
        "partial translation never resizes or collapses the chooser content");
    Check(layout.travel > 0 && layout.progress >= 0 && layout.progress <= 1 &&
        std::isfinite(layout.drawer.x) && std::isfinite(layout.drawer.y),
        "animation always has finite bounded progress and nonzero travel");
    const double centerX=t.x+t.width/2, centerY=t.y+t.height/2;
    Check(PPOEdgeDrawerHit(layout,centerX,centerY), "the handle always remains hittable");
    Check(!PPOEdgeDrawerHit(layout,s.x-1,s.y+s.height/2) &&
        !PPOEdgeDrawerHit(layout,s.x+s.width,s.y+s.height/2), "offscreen points never consume underlying touches");
}
static void AppFits(PPOHostRect frame, PPOHostRect screen, PPOEdgeDrawerInsets insets,
    double nativeWidth, double nativeHeight) {
    const double x=screen.x+insets.left+8, y=screen.y+insets.top+8;
    const double width=screen.width-insets.left-insets.right-16;
    const double height=screen.height-insets.top-insets.bottom-16;
    Check(std::isfinite(frame.x) && std::isfinite(frame.y) && std::isfinite(frame.width) &&
        std::isfinite(frame.height) && frame.width>=240 && frame.height>=320,
        "large app panel has finite geometry and reachable minimum controls");
    Check(frame.x>=x-1e-8 && frame.y>=y-1e-8 && frame.x+frame.width<=x+width+1e-8 &&
        frame.y+frame.height<=y+height+1e-8,"large app panel stays inside safe area plus eight-point margin");
    Check(frame.width<=screen.width-50+1e-8,"large app drawer retains the original edge strip");
    Check(Near(frame.width/nativeWidth,(frame.height-44)/nativeHeight),
        "viewport beneath controls preserves native aspect without app geometry mutation");
    Check(Near(frame.x+frame.width/2,x+width/2) && Near(frame.y+frame.height/2,y+height/2),
        "large app panel is centered independently of scene coordinate origin");
    Check(Near(frame.width,std::min(screen.width-50,width)) || Near(frame.height,height),
        "large app panel uses the limiting safe width or height without arbitrary extra scaling");
}
int main() {
    const PPOHostRect phone{0,0,414,896};
    const PPOEdgeDrawerInsets safe{44,0,34,0};
    PPOEdgeDrawerLayout left{},right{};
    Check(PPOEdgeDrawerMakeLayout(phone,safe,PPOEdgeDrawerSide::Left,0.5,48,0,&left), "left closed phone layout");
    Same(left.handle,{0,429,20,48}, "left visual nub sits at the physical edge");
    Same(left.touchHandle,{0,429,44,48}, "left hit target extends inward");
    Same(left.openDrawer,{0,44,339.48,818}, "phone drawer respects width fraction and vertical safe area");
    Same(left.closedDrawer,{-339.48,44,339.48,818}, "closed left chooser is fully offscreen");
    Same(left.drawer,left.closedDrawer,"closed animation endpoint is exact");
    Check(Near(left.travel,339.48), "ordinary phone travel equals drawer width");
    Check(PPOEdgeDrawerMakeLayout(phone,safe,PPOEdgeDrawerSide::Right,0.5,48,1,&right), "right open phone layout");
    Same(right.handle,{394,429,20,48}, "right visual nub sits at the physical edge");
    Same(right.touchHandle,{370,429,44,48}, "right hit target extends inward");
    Same(right.openDrawer,{74.52,44,339.48,818}, "right chooser anchors to the safe right edge");
    Same(right.closedDrawer,{414,44,339.48,818}, "closed right chooser is fully offscreen");
    Same(right.drawer,right.openDrawer,"open animation endpoint is exact");
    Fits(left); Fits(right);
    Check(!PPOEdgeDrawerHit(left,200,100) && !PPOEdgeDrawerHit(left,0,428.999),
        "collapsed chooser does not install a full-screen backdrop hit region");
    Check(PPOEdgeDrawerHit(right,100,100) && !PPOEdgeDrawerHit(right,50,100) &&
        !PPOEdgeDrawerHit(right,200,43.999), "expanded chooser only consumes visible content and its handle");

    const PPOHostRect landscape{100,-200,896,414};
    const PPOEdgeDrawerInsets landscapeSafe{0,44,21,44};
    Check(PPOEdgeDrawerMakeLayout(landscape,landscapeSafe,PPOEdgeDrawerSide::Left,0,32,0.25,&left),
        "offset landscape layout with horizontal safe insets");
    Same(left.touchHandle,{100,-200,44,44},"short visual handle still has a44point safe touch height");
    Same(left.handle,{100,-194,20,32},"short visual handle is centered inside its touch area");
    Same(left.openDrawer,{144,-200,340,393},"large screens use the340point maximum");
    Same(left.closedDrawer,{-240,-200,340,393},"closed frame is outside the physical edge despite safe inset");
    Same(left.drawer,{-144,-200,340,393},"partial progress uses full inset-aware travel");
    Check(left.travel == 384,"side safe inset increases total reveal distance");
    Fits(left);
    double ratio=9, progress=9;
    Check(PPOEdgeDrawerYRatio(landscape,landscapeSafe,32,left.handle.y+16,&ratio) && ratio==0,
        "persisted position ratio maps back from the bounded center");
    Check(PPOEdgeDrawerMakeLayout(landscape,landscapeSafe,PPOEdgeDrawerSide::Right,1,72,1,&right),
        "opposite edge and tallest visual handle fit at the bottom");
    Check(PPOEdgeDrawerYRatio(landscape,landscapeSafe,72,right.handle.y+36,&ratio) && Near(ratio,1),
        "bottom ratio round trip uses safe vertical travel");
    Check(PPOEdgeDrawerYRatio(phone,safe,48,-32768,&ratio) && ratio==0 &&
        PPOEdgeDrawerYRatio(phone,safe,48,32768,&ratio) && ratio==1,
        "finite extreme handle drags clamp to reachable endpoints");

    for (PPOEdgeDrawerSide side : {PPOEdgeDrawerSide::Left,PPOEdgeDrawerSide::Right}) {
        const double sign=side==PPOEdgeDrawerSide::Left ? 1 : -1;
        Check(PPOEdgeDrawerProgress(side,0,sign*96,384,&progress) && progress==0.25,
            "inward cumulative UIKit translation advances progress on either edge");
        Check(PPOEdgeDrawerProgress(side,1,-sign*192,384,&progress) && progress==0.5,
            "outward translation retracts from the captured open origin");
        Check(PPOEdgeDrawerProgress(side,0,sign*32768,384,&progress) && progress==1 &&
            PPOEdgeDrawerProgress(side,1,-sign*32768,384,&progress) && progress==0,
            "large finite translation clamps without moving content dimensions");
        bool open=true;
        Check(PPOEdgeDrawerFinish(side,0.1,sign*450,&open) && open,
            "decisive inward flick reveals even before halfway");
        Check(PPOEdgeDrawerFinish(side,0.9,-sign*450,&open) && !open,
            "decisive outward flick closes even after halfway");
        Check(PPOEdgeDrawerFinish(side,0.499999,sign*449.999,&open) && !open &&
            PPOEdgeDrawerFinish(side,0.5,-sign*449.999,&open) && open,
            "slow release uses the deterministic halfway threshold");
    }
    Check(PPOEdgeDrawerMakeLayout(phone,safe,PPOEdgeDrawerSide::Left,-999,48,-1,&left) &&
        left.progress==0 && Near(left.touchHandle.y,44), "finite layout cache values normalize to endpoints");
    Check(PPOEdgeDrawerMakeLayout(phone,safe,PPOEdgeDrawerSide::Right,999,48,5,&right) &&
        right.progress==1 && Near(right.touchHandle.y+right.touchHandle.height,862),
        "finite upper cache values clamp rather than moving controls offscreen");
    Check(PPOEdgeDrawerMakeLayout({0,0,196,160},{},PPOEdgeDrawerSide::Left,0.5,72,1,&left),
        "exact documented minimum working bounds remain usable");
    Fits(left);

    const double nan=std::numeric_limits<double>::quiet_NaN(), inf=std::numeric_limits<double>::infinity();
    const PPOEdgeDrawerSide badSide=static_cast<PPOEdgeDrawerSide>(-1);
    const PPOEdgeDrawerLayout sentinel=right;
    for (PPOHostRect bad : {PPOHostRect{nan,0,414,896},{0,inf,414,896},{0,0,0,896},
        {0,0,414,-1},{0,0,8192.1,896},{0,0,414,inf},{32768,0,414,896},
        {-32769,0,414,896},{0,0,195.99,896},{0,0,414,159.99}}) {
        left=sentinel;
        Check(!PPOEdgeDrawerMakeLayout(bad,{},PPOEdgeDrawerSide::Left,0.5,48,0,&left),
            "invalid or too-small screen refuses layout"); Cleared(left);
    }
    for (PPOEdgeDrawerInsets bad : {PPOEdgeDrawerInsets{nan,0,0,0},{0,inf,0,0},{0,0,-1,0},
        {0,0,0,8193},{500,0,500,0},{0,110,0,110}}) {
        left=sentinel;
        Check(!PPOEdgeDrawerMakeLayout(phone,bad,PPOEdgeDrawerSide::Left,0.5,48,0,&left),
            "unsafe insets refuse layout"); Cleared(left);
        ratio=9; Check(!PPOEdgeDrawerYRatio(phone,bad,48,400,&ratio) && ratio==0,
            "position persistence cannot bypass unsafe insets");
    }
    for (double bad : {nan,inf,-inf}) {
        left=sentinel; Check(!PPOEdgeDrawerMakeLayout(phone,safe,PPOEdgeDrawerSide::Left,bad,48,0,&left),
            "nonfinite ratio refuses layout"); Cleared(left);
        left=sentinel; Check(!PPOEdgeDrawerMakeLayout(phone,safe,PPOEdgeDrawerSide::Left,0.5,48,bad,&left),
            "nonfinite progress refuses layout"); Cleared(left);
    }
    for (double bad : {nan,inf,-inf,31.99,72.01,0.0}) {
        left=sentinel; Check(!PPOEdgeDrawerMakeLayout(phone,safe,PPOEdgeDrawerSide::Left,0.5,bad,0,&left),
            "unsupported handle size refuses layout"); Cleared(left);
        ratio=9; Check(!PPOEdgeDrawerYRatio(phone,safe,bad,400,&ratio) && ratio==0,
            "position inverse preserves handle bounds");
    }
    left=sentinel; Check(!PPOEdgeDrawerMakeLayout(phone,safe,badSide,0.5,48,0,&left),"unknown side is refused");
    Cleared(left);
    Check(!PPOEdgeDrawerMakeLayout(phone,safe,PPOEdgeDrawerSide::Left,0.5,48,0,nullptr),"null layout output is refused");
    for (double bad : {nan,inf,-inf,-0.0001,1.0001}) {
        progress=9; Check(!PPOEdgeDrawerProgress(PPOEdgeDrawerSide::Left,bad,10,340,&progress) && progress==0,
            "gesture start must be a valid captured progress");
        bool open=true; Check(!PPOEdgeDrawerFinish(PPOEdgeDrawerSide::Left,bad,0,&open) && !open,
            "invalid release progress cannot open the chooser");
    }
    for (double bad : {nan,inf,-inf,-32768.01,32768.01}) {
        progress=9; Check(!PPOEdgeDrawerProgress(PPOEdgeDrawerSide::Left,0,bad,340,&progress) && progress==0,
            "nonfinite or unbounded pan translation is refused");
        bool open=true; Check(!PPOEdgeDrawerFinish(PPOEdgeDrawerSide::Left,0.5,bad,&open) && !open,
            "nonfinite or unbounded release velocity is refused");
        ratio=9; Check(!PPOEdgeDrawerYRatio(phone,safe,48,bad,&ratio) && ratio==0,
            "invalid touch coordinates cannot become stored position");
    }
    for (double bad : {nan,inf,-inf,0.0,-1.0,16384.01}) {
        progress=9; Check(!PPOEdgeDrawerProgress(PPOEdgeDrawerSide::Left,0,10,bad,&progress) && progress==0,
            "gesture travel must be positive and bounded");
    }
    bool open=true;
    Check(!PPOEdgeDrawerProgress(badSide,0,10,340,&progress) && progress==0 &&
        !PPOEdgeDrawerFinish(badSide,0,0,&open) && !open,"invalid edge cannot reverse gesture meaning");
    Check(!PPOEdgeDrawerProgress(PPOEdgeDrawerSide::Left,0,10,340,nullptr) &&
        !PPOEdgeDrawerFinish(PPOEdgeDrawerSide::Left,0,0,nullptr) &&
        !PPOEdgeDrawerYRatio(phone,safe,48,400,nullptr),"null scalar outputs are refused");
    Check(!PPOEdgeDrawerHit({},0,0) && !PPOEdgeDrawerHit(sentinel,nan,450) &&
        !PPOEdgeDrawerHit(sentinel,400,inf),"empty layouts and nonfinite points never consume input");
    for (unsigned field=0;field<5;field++) {
        PPOEdgeDrawerLayout forged=sentinel;
        if(field==0)forged.progress=nan;
        else if(field==1)forged.screen.width=-1;
        else if(field==2)forged.touchHandle.width=inf;
        else if(field==3)forged.drawer.width=341;
        else forged.drawer.x=nan;
        Check(!PPOEdgeDrawerHit(forged,400,450),"malformed hit geometry fails closed");
    }

    double translation=9, travel=9;
    const PPOHostRect panel{57,60,300,480};
    Check(PPOEdgeDrawerPanelTranslation(phone,panel,PPOEdgeDrawerSide::Left,0,&translation,&travel) &&
        translation==-357 && travel==357,"owned panel slides fully beyond left physical edge");
    Check(PPOEdgeDrawerPanelTranslation(phone,panel,PPOEdgeDrawerSide::Right,0,&translation,&travel) &&
        translation==357 && travel==357,"owned panel slides fully beyond right physical edge");
    Check(PPOEdgeDrawerPanelTranslation(phone,panel,PPOEdgeDrawerSide::Right,0.25,&translation,&travel) &&
        translation==267.75 && travel==357,"owned panel translates proportionally without resize");
    Check(PPOEdgeDrawerPanelTranslation(phone,panel,PPOEdgeDrawerSide::Left,1,&translation,&travel) &&
        translation==0 && travel==357,"owned panel open endpoint has an exact identity transform");
    for(PPOEdgeDrawerSide side : {PPOEdgeDrawerSide::Left,PPOEdgeDrawerSide::Right}) {
        Check(PPOEdgeDrawerPanelTranslation(landscape,{144,-180,380,320},side,0,&translation,&travel),
            "contained offset panel supports landscape translation");
        const double x=144+translation;
        Check(side==PPOEdgeDrawerSide::Left ? x+380<=100 : x>=996,
            "the translated panel is fully offscreen despite offsets");
    }
    for(PPOHostRect badPanel : {PPOHostRect{nan,60,300,480},{57,inf,300,480},{57,60,0,480},
        {57,60,300,-1},{57,60,inf,480},{-0.001,60,300,480},{57,-0.001,300,480},
        {114.001,60,300,480},{57,416.001,300,480}}) {
        translation=9;travel=9;
        Check(!PPOEdgeDrawerPanelTranslation(phone,badPanel,PPOEdgeDrawerSide::Right,0.5,&translation,&travel) &&
            translation==0 && travel==0,"invalid or uncontained owned panel cannot acquire a transform");
    }
    for(double bad : {nan,inf,-inf,-0.0001,1.0001}) {
        translation=9;travel=9;
        Check(!PPOEdgeDrawerPanelTranslation(phone,panel,PPOEdgeDrawerSide::Left,bad,&translation,&travel) &&
            translation==0 && travel==0,"owned-panel progress is strict and fail-closed");
    }
    translation=9;travel=9;
    Check(!PPOEdgeDrawerPanelTranslation({},panel,PPOEdgeDrawerSide::Left,0,&translation,&travel) &&
        translation==0 && travel==0,"invalid working screen cannot transform an owned panel");
    translation=9;travel=9;
    Check(!PPOEdgeDrawerPanelTranslation(phone,panel,badSide,0,&translation,&travel) &&
        translation==0 && travel==0,"unknown edge cannot transform an owned panel");
    translation=9;travel=9;
    Check(!PPOEdgeDrawerPanelTranslation(phone,panel,PPOEdgeDrawerSide::Left,0,nullptr,&travel) && travel==0 &&
        !PPOEdgeDrawerPanelTranslation(phone,panel,PPOEdgeDrawerSide::Left,0,&translation,nullptr) && translation==0,
        "partial null transform outputs are refused and valid outputs cleared");
    translation=9;
    Check(!PPOEdgeDrawerPanelTranslation(phone,panel,PPOEdgeDrawerSide::Left,0,&translation,&translation) && translation==0,
        "aliased transform outputs cannot overwrite each other silently");

    PPOHostRect appFrame{};
    Check(PPOEdgeDrawerAppFrame(phone,safe,414,896,&appFrame),"original-style iPhone app drawer frame");
    Same(appFrame,{31.881696428571416,52,350.23660714285717,802},
        "phone viewport is height-limited beneath its44point controls");
    AppFits(appFrame,phone,safe,414,896);
    Check(PPOEdgeDrawerAppFrame({0,0,414,1200},{},414,896,&appFrame),
        "tall screen permits the full original-style width");
    Same(appFrame,{25,184.10628019323673,364,831.7874396135265},
        "width-limited drawer leaves exactly the50point edge strip");
    AppFits(appFrame,{0,0,414,1200},{},414,896);
    Check(PPOEdgeDrawerAppFrame(landscape,landscapeSafe,896,414,&appFrame),
        "landscape native viewport respects horizontal safe insets and header");
    Same(appFrame,{187.6521739130435,-192,720.695652173913,377},
        "offset landscape result retains native aspect and safe control margin");
    AppFits(appFrame,landscape,landscapeSafe,896,414);
    const PPOHostRect offsetPhone{-400,200,414,896};
    Check(PPOEdgeDrawerAppFrame(offsetPhone,safe,414,896,&appFrame),"offset phone app panel");
    Same(appFrame,{-368.11830357142856,252,350.23660714285717,802},
        "scene origin translates a panel without changing its content dimensions");
    AppFits(appFrame,offsetPhone,safe,414,896);
    Check(PPOEdgeDrawerAppFrame({0,0,290,336},{},240,276,&appFrame),
        "exact hosting minima remain reachable under the original strip and margins");
    Same(appFrame,{25,8,240,320},"minimum app viewport includes44point controls");
    Check(!PPOEdgeDrawerAppFrame(phone,safe,414,896,nullptr),"null app output is refused");
    for(double bad : {nan,inf,-inf,0.0,31.999,8192.001}) {
        appFrame=panel;
        Check(!PPOEdgeDrawerAppFrame(phone,safe,bad,896,&appFrame),"invalid native width refuses app geometry");
        Same(appFrame,{},"invalid native width clears app frame");
        appFrame=panel;
        Check(!PPOEdgeDrawerAppFrame(phone,safe,414,bad,&appFrame),"invalid native height refuses app geometry");
        Same(appFrame,{},"invalid native height clears app frame");
    }
    for(PPOHostRect bad : {PPOHostRect{nan,0,414,896},{0,inf,414,896},{0,0,0,896},
        {0,0,414,inf},{32768,0,414,896},{0,0,8192.01,896},{0,0,289.999,336},
        {0,0,290,335.999},{0,0,100,896},{0,0,414,100}}) {
        appFrame=panel;
        Check(!PPOEdgeDrawerAppFrame(bad,{},240,276,&appFrame),"invalid or below-minimum screen refuses app geometry");
        Same(appFrame,{},"unsafe screen clears app frame");
    }
    for(PPOEdgeDrawerInsets bad : {PPOEdgeDrawerInsets{nan,0,0,0},{0,inf,0,0},{0,0,-1,0},
        {0,0,0,8193},{500,0,500,0},{0,90,0,90},{300,0,300,0}}) {
        appFrame=panel;
        Check(!PPOEdgeDrawerAppFrame(phone,bad,414,896,&appFrame),"unsafe or overconstrained insets refuse app geometry");
        Same(appFrame,{},"unsafe insets clear app frame");
    }
    for(double size : {32.0,8192.0}) {
        Check(PPOEdgeDrawerAppFrame(phone,safe,size,size,&appFrame),"inclusive native dimension bounds remain valid");
        AppFits(appFrame,phone,safe,size,size);
    }
    for(PPOHostRect native : {PPOHostRect{0,0,32,8192},{0,0,8192,32}}) {
        appFrame=panel;
        Check(!PPOEdgeDrawerAppFrame(phone,safe,native.width,native.height,&appFrame),
            "unusable native aspect cannot shrink below hosting control minimums");
        Same(appFrame,{},"unusable native aspect clears app frame");
    }
    std::mt19937_64 appRandom(0x50504f415050ULL);
    std::uniform_real_distribution<double> appWidth(800,1800),appHeight(800,2200),
        appOffset(-500,500),appInset(0,45),nativeWidth(320,1000),nativeAspect(1.6,2.4);
    for(unsigned i=0;i<12000;i++) {
        const PPOHostRect screen{appOffset(appRandom),appOffset(appRandom),appWidth(appRandom),appHeight(appRandom)};
        const PPOEdgeDrawerInsets insets{appInset(appRandom),appInset(appRandom),appInset(appRandom),appInset(appRandom)};
        const double width=nativeWidth(appRandom),height=width*nativeAspect(appRandom);
        Check(PPOEdgeDrawerAppFrame(screen,insets,width,height,&appFrame),"random native-aspect app panel fits the bounded working screen");
        AppFits(appFrame,screen,insets,width,height);
        for(PPOEdgeDrawerSide side : {PPOEdgeDrawerSide::Left,PPOEdgeDrawerSide::Right}) {
            Check(PPOEdgeDrawerPanelTranslation(screen,appFrame,side,0,&translation,&travel),
                "large app panel composes with either retained-panel closing transform");
            Check(side==PPOEdgeDrawerSide::Left ? appFrame.x+translation+appFrame.width<=screen.x+1e-8 :
                appFrame.x+translation>=screen.x+screen.width-1e-8,
                "a large app viewport can fully close without resizing its geometry");
            Check(PPOEdgeDrawerPanelTranslation(screen,appFrame,side,1,&translation,&travel) && translation==0,
                "restoring a large app viewport has exact identity transform");
        }
    }

    // Randomized invariant checks combine screen offsets, landscape insets,
    // handle placements and drag release. They exercise the production policy.
    std::mt19937_64 random(0x50504f45444745ULL);
    std::uniform_real_distribution<double> width(320,1800),height(320,2200),offset(-500,500),
        inset(0,45),unit(0,1),pan(-2400,2400),speed(-1400,1400),handleHeight(32,72);
    for(unsigned i=0;i<12000;i++) {
        PPOHostRect screen{offset(random),offset(random),width(random),height(random)};
        PPOEdgeDrawerInsets insets{inset(random),inset(random),inset(random),inset(random)};
        const auto side=(i%2)==0 ? PPOEdgeDrawerSide::Left : PPOEdgeDrawerSide::Right;
        const double y=unit(random), h=handleHeight(random), start=unit(random);
        PPOEdgeDrawerLayout layout{};
        Check(PPOEdgeDrawerMakeLayout(screen,insets,side,y,h,start,&layout),"random finite working screen produces layout");
        Fits(layout);
        Check(PPOEdgeDrawerYRatio(screen,insets,h,layout.handle.y+h/2,&ratio) && Near(ratio,y),
            "random handle position round trip preserves normalized placement");
        const double panTranslation=pan(random), velocity=speed(random);
        Check(PPOEdgeDrawerProgress(side,start,panTranslation,layout.travel,&progress),"random pan produces bounded progress");
        Check(progress>=0 && progress<=1,"random progress is normalized");
        PPOEdgeDrawerLayout moved{};
        Check(PPOEdgeDrawerMakeLayout(screen,insets,side,y,h,progress,&moved),"random cumulative translation redraws chooser");
        Fits(moved);
        Check(PPOEdgeDrawerFinish(side,progress,velocity,&open),"random release selects a valid endpoint");
        const double inward=side==PPOEdgeDrawerSide::Left ? velocity : -velocity;
        if(inward>=450)Check(open,"inward flick always opens");
        else if(inward<=-450)Check(!open,"outward flick always closes");
        else Check(open==(progress>=0.5),"slow release follows halfway rule");
        Check(PPOEdgeDrawerMakeLayout(screen,insets,side,y,h,open?1:0,&layout),"release settles on exact endpoint");
        Same(layout.drawer,open?layout.openDrawer:layout.closedDrawer,"settled geometry has no animation residue");
        const double midX=screen.x+screen.width/2,midY=screen.y+screen.height/2;
        const bool inHandle=midX>=layout.touchHandle.x && midX<layout.touchHandle.x+layout.touchHandle.width &&
            midY>=layout.touchHandle.y && midY<layout.touchHandle.y+layout.touchHandle.height;
        const bool inPanel=open && midX>=layout.openDrawer.x && midX<layout.openDrawer.x+layout.openDrawer.width &&
            midY>=layout.openDrawer.y && midY<layout.openDrawer.y+layout.openDrawer.height;
        Check(PPOEdgeDrawerHit(layout,midX,midY)==(inHandle||inPanel),
            "center-screen hit depends on real chooser geometry rather than full-window bounds");
        const PPOHostRect base{layout.openDrawer.x+4,layout.openDrawer.y+4,
            layout.openDrawer.width-8,layout.openDrawer.height-8};
        Check(PPOEdgeDrawerPanelTranslation(screen,base,side,progress,&translation,&travel) && travel>0,
            "random public base panel supports bounded drawer translation");
        Check(Near(std::abs(translation),(1-progress)*travel),
            "translation is proportional while source viewport dimensions remain independent");
        Check(PPOEdgeDrawerPanelTranslation(screen,base,side,0,&translation,&travel),"random collapsed owned panel transform");
        Check(side==PPOEdgeDrawerSide::Left ? base.x+translation+base.width<=screen.x+1e-8 :
            base.x+translation>=screen.x+screen.width-1e-8,"collapsed public panel has no onscreen content sliver");
        Check(PPOEdgeDrawerPanelTranslation(screen,base,side,1,&translation,&travel) && translation==0,
            "random restored owned panel has exact identity transform");
    }
    std::printf("Edge drawer geometry tests passed: %u checks; public chooser layout/gesture/hit policy, not UIKit rendering\n",checks);
    return 0;
}
