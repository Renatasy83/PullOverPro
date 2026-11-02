#include "../PPOKeyboardAvoidance.h"
#include <cstdio>
#include <cstdlib>
#include <limits>
#include <random>

static unsigned checks;
static void Check(bool value,const char *message) {
    checks++;
    if (!value) { std::fprintf(stderr,"FAIL: %s\n",message); std::exit(1); }
}
static bool Near(double a,double b) { return std::abs(a-b)<=1e-8; }
static bool Same(PPOHostRect a,PPOHostRect b) {
    return a.x==b.x && a.y==b.y && a.width==b.width && a.height==b.height;
}
static bool Same(PPOEdgeDrawerInsets a,PPOEdgeDrawerInsets b) {
    return a.top==b.top && a.left==b.left && a.bottom==b.bottom && a.right==b.right;
}
static bool Intersects(PPOHostRect a,PPOHostRect b) {
    return std::max(a.x,b.x)<std::min(a.x+a.width,b.x+b.width) &&
        std::max(a.y,b.y)<std::min(a.y+a.height,b.y+b.height);
}
static void Original(const PPOKeyboardAvoidanceResult &r,PPOHostRect touch,PPOEdgeDrawerInsets insets) {
    Check(Same(r.touchHandle,touch),"no adjustment preserves the preferred rectangle exactly");
    Check(Same(r.pickerInsets,insets),"no adjustment preserves the original compact-list safe area");
    Check(r.centerY==touch.y+touch.height/2 && !r.adjusted && !r.keyboardRelevant,
        "no adjustment clears transient placement flags");
}
static void ValidDecision(PPOHostRect screen,PPOEdgeDrawerInsets insets,PPOHostRect touch,
    PPOHostRect keyboard,bool ok,const PPOKeyboardAvoidanceResult &r) {
    if (!ok) { Original(r,touch,insets); return; }
    Check(r.touchHandle.x==touch.x && r.touchHandle.width==touch.width && r.touchHandle.height==touch.height,
        "keyboard avoidance changes no horizontal coordinate, width or touch height");
    Check(r.touchHandle.width>=44 && r.touchHandle.height>=44,
        "physical hit target remains at least44points");
    Check(r.touchHandle.y>=screen.y+insets.top-1e-8 &&
        r.touchHandle.y+r.touchHandle.height<=screen.y+screen.height-insets.bottom+1e-8,
        "shifted handle remains inside the original vertical safe area");
    Check(Near(r.centerY,r.touchHandle.y+r.touchHandle.height/2),"center and rectangle agree");
    Check(r.adjusted==(r.touchHandle.y!=touch.y),"adjusted flag describes an actual y change");
    Check(r.pickerInsets.left==insets.left && r.pickerInsets.right==insets.right,
        "compact list keeps physical left/right safe insets");
    if (r.keyboardRelevant) {
        Check(!Intersects(r.touchHandle,keyboard),"a successful constrained decision cannot overlap the keyboard");
        Check(r.pickerInsets.top>=insets.top && r.pickerInsets.bottom>=insets.bottom,
            "compact chooser's safe vertical band never expands through an obstruction");
        Check(r.touchHandle.y>=screen.y+r.pickerInsets.top-1e-8 &&
            r.touchHandle.y+r.touchHandle.height<=screen.y+screen.height-r.pickerInsets.bottom+1e-8,
            "adjusted handle is anchored inside the chooser's chosen vertical band");
    }
    if (r.adjusted) Check(Intersects(touch,keyboard),"a handle that was not overlapped never moves");
}

int main() {
    const PPOHostRect screen{0,0,414,896};
    const PPOEdgeDrawerInsets insets{44,0,34,0};
    const PPOHostRect desired{364,431,50,44};
    PPOKeyboardAvoidanceResult r{};
    const PPOHostRect docked{0,600,414,296};
    Check(PPOKeyboardAvoidanceLayout(screen,insets,desired,docked,true,true,&r),"known phone docked keyboard");
    Check(Same(r.touchHandle,desired) && !r.adjusted && r.keyboardRelevant,
        "handle already above a docked keyboard stays at its configured location");
    Check(r.pickerInsets.top==44 && r.pickerInsets.bottom==296,
        "compact list cannot extend down into the docked keyboard even without handle movement");
    PPOHostRect low{364,760,50,44};
    Check(PPOKeyboardAvoidanceLayout(screen,insets,low,docked,true,true,&r),"low handle moves clear of keyboard");
    Check(Same(r.touchHandle,{364,548,50,44}) && r.centerY==570 && r.adjusted,
        "docked keyboard leaves an8point gap and keeps the full44point target above it");
    Check(r.pickerInsets.top==44 && r.pickerInsets.bottom==304,"docked picker uses the same chosen band");
    ValidDecision(screen,insets,low,docked,true,r);
    PPOHostRect almost{364,555,50,44};
    Check(PPOKeyboardAvoidanceLayout(screen,insets,almost,docked,true,true,&r)&&
        Same(r.touchHandle,almost)&&!r.adjusted,"existing onepoint clearance does not cause an unsolicited8point shift");

    const PPOHostRect floating{300,400,114,150};
    Check(PPOKeyboardAvoidanceLayout(screen,insets,desired,floating,true,true,&r),"overlapping floating keyboard");
    Check(Same(r.touchHandle,{364,348,50,44}) && r.centerY==370 && r.adjusted,
        "floating keyboard chooses the nearer free band above");
    Check(r.pickerInsets.bottom==504 && r.pickerInsets.top==44,"floating-above picker does not cross the keyboard");
    PPOHostRect lower{364,650,50,44}, lowFloating{300,600,114,100};
    Check(PPOKeyboardAvoidanceLayout(screen,insets,lower,lowFloating,true,true,&r),"floating keyboard can leave room below");
    Check(Same(r.touchHandle,{364,708,50,44}) && r.pickerInsets.top==708 && r.pickerInsets.bottom==34,
        "nearest free band below avoids an unnecessary large upward jump");
    PPOHostRect tie{364,428,50,44}, centered{300,400,114,100};
    Check(PPOKeyboardAvoidanceLayout(screen,insets,tie,centered,true,true,&r)&&r.centerY==370,
        "equidistant floating bands resolve deterministically above");
    PPOHostRect left{0,431,50,44};
    Check(PPOKeyboardAvoidanceLayout(screen,insets,left,floating,true,true,&r),"floating keyboard at the other edge");
    Original(r,left,insets);
    PPOHostRect above{364,100,50,44};
    Check(PPOKeyboardAvoidanceLayout(screen,insets,above,floating,true,true,&r),"floating keyboard misses this handle vertically");
    Original(r,above,insets);
    PPOHostRect touching{364,356,50,44};
    Check(PPOKeyboardAvoidanceLayout(screen,insets,touching,floating,true,true,&r),"touching boundary has no positive-area overlap");
    Original(r,touching,insets);
    PPOHostRect opened{0,650,80,44}, movedKeyboard{0,600,160,100};
    Check(PPOKeyboardAvoidanceLayout(screen,insets,opened,movedKeyboard,true,true,&r)&&
        r.touchHandle.x==0&&r.touchHandle.width==80&&r.touchHandle.y==708,
        "actual opposite-side open handle geometry is respected without a configured-edge assumption");

    // The root animates50..80point handle widths between edges. The keyboard
    // policy must use those actual rectangles, never a side/default-width guess.
    PPOHostRect sliding{280.25,431.125,63.5,44};
    Check(PPOKeyboardAvoidanceLayout(screen,insets,sliding,floating,true,true,&r)&&
        r.touchHandle.x==sliding.x&&r.touchHandle.width==sliding.width&&r.touchHandle.height==44&&r.adjusted,
        "intermediate drawer animation geometry remains shape-preserving");
    ValidDecision(screen,insets,sliding,floating,true,r);
    PPOHostRect exactlyLeft{314,400,50,150};
    Check(PPOKeyboardAvoidanceLayout(screen,insets,desired,exactlyLeft,true,true,&r),
        "horizontal edge contact does not count as an obstruction");
    Original(r,desired,insets);

    const double nan=std::numeric_limits<double>::quiet_NaN();
    const double inf=std::numeric_limits<double>::infinity();
    const PPOHostRect corrupt{nan,0,inf,0};
    for (bool enabled : {false,true}) for (bool visible : {false,true}) {
        if (enabled&&visible) continue;
        Check(PPOKeyboardAvoidanceLayout(screen,insets,low,corrupt,enabled,visible,&r),"disabled/hidden ignores stale corrupt keyboard data");
        Original(r,low,insets);
    }
    Check(PPOKeyboardAvoidanceLayout(screen,insets,low,docked,true,true,&r)&&r.adjusted,"show creates only a transient shift");
    Check(PPOKeyboardAvoidanceLayout(screen,insets,low,corrupt,true,false,&r),"hide restores from configured rectangle");
    Original(r,low,insets);
    Check(PPOKeyboardAvoidanceLayout(screen,insets,low,docked,false,true,&r),"preference toggle off restores despite a visible keyboard");
    Original(r,low,insets);
    for (PPOHostRect bad : {corrupt,PPOHostRect{0,600,414,0},PPOHostRect{0,600,0,296},
        PPOHostRect{0,600,-1,296},PPOHostRect{0,600,8193,296},PPOHostRect{32768,600,414,296}}) {
        Check(!PPOKeyboardAvoidanceLayout(screen,insets,desired,bad,true,true,&r),"visible invalid keyboard data refuses without moving");
        Original(r,desired,insets);
    }
    for (PPOHostRect outside : {PPOHostRect{0,896,414,296},PPOHostRect{0,-296,414,296},
        PPOHostRect{-300,600,200,296},PPOHostRect{414,400,100,100},PPOHostRect{0,880,414,16}}) {
        Check(PPOKeyboardAvoidanceLayout(screen,insets,desired,outside,true,true,&r),"offscreen/outside-safe keyboard needs no movement");
        Original(r,desired,insets);
    }
    for (PPOHostRect blocked : {PPOHostRect{0,44,414,852},PPOHostRect{300,0,114,896}}) {
        Check(!PPOKeyboardAvoidanceLayout(screen,insets,desired,blocked,true,true,&r),"no free44point band refuses without fabricating an unsafe position");
        Original(r,desired,insets);
    }
    Check(!PPOKeyboardAvoidanceLayout(screen,insets,desired,docked,true,true,nullptr),"null output refuses");
    for (PPOHostRect bad : {PPOHostRect{0,0,414,0},PPOHostRect{0,0,100,896},PPOHostRect{nan,0,414,896}}) {
        Check(!PPOKeyboardAvoidanceLayout(bad,insets,desired,docked,true,true,&r)&&Same(r.touchHandle,PPOHostRect{})&&
            Same(r.pickerInsets,PPOEdgeDrawerInsets{})&&r.centerY==0&&!r.adjusted&&!r.keyboardRelevant,
            "invalid scene clears all result state");
    }
    for (PPOHostRect bad : {PPOHostRect{364,431,43,44},PPOHostRect{364,431,50,43},
        PPOHostRect{365,431,50,44},PPOHostRect{364,43,50,44},PPOHostRect{364,819,50,44}}) {
        Check(!PPOKeyboardAvoidanceLayout(screen,insets,bad,docked,true,true,&r)&&Same(r.touchHandle,PPOHostRect{}),
            "invalid or inaccessible preferred targets are not silently repaired");
    }
    for (PPOEdgeDrawerInsets bad : {PPOEdgeDrawerInsets{-1,0,34,0},PPOEdgeDrawerInsets{44,nan,34,0},
        PPOEdgeDrawerInsets{600,0,400,0},PPOEdgeDrawerInsets{44,300,34,300}}) {
        Check(!PPOKeyboardAvoidanceLayout(screen,bad,desired,docked,true,true,&r)&&Same(r.touchHandle,PPOHostRect{}),
            "invalid scene insets clear the output before keyboard work");
    }

    // Coordinate translations must commute with the decision. Also exercise
    // left/right physical strips and inset screens, including an80point handle.
    for (double ox : {-100.0,0.0,130.0}) for (double oy : {-250.0,0.0,90.0})
    for (double width : {50.0,80.0}) for (bool onLeft : {false,true}) {
        PPOHostRect translated{ox,oy,414,896};
        PPOHostRect touch{onLeft?ox:ox+414-width,oy+760,width,44};
        PPOHostRect keyboard{ox,oy+600,414,296};
        Check(PPOKeyboardAvoidanceLayout(translated,insets,touch,keyboard,true,true,&r),"translated physical edge with docked keyboard");
        Check(r.touchHandle.x==touch.x&&r.touchHandle.width==width&&Near(r.touchHandle.y,oy+548)&&
            Near(r.centerY,oy+570)&&r.pickerInsets.bottom==304,
            "screen origins cannot be confused with local root coordinates");
        ValidDecision(translated,insets,touch,keyboard,true,r);
    }
    const PPOHostRect landscape{10,20,844,390};
    const PPOEdgeDrawerInsets landscapeInsets{0,44,21,44};
    for (PPOHostRect touch : {PPOHostRect{10,320,50,44},PPOHostRect{774,320,80,44}}) {
        const PPOHostRect keyboard{10,220,844,190};
        Check(PPOKeyboardAvoidanceLayout(landscape,landscapeInsets,touch,keyboard,true,true,&r),"landscape inset physical strip");
        Check(r.touchHandle.x==touch.x&&Near(r.touchHandle.y,168)&&r.pickerInsets.left==44&&r.pickerInsets.right==44,
            "keyboard movement preserves actual edge x despite horizontal safe insets");
        ValidDecision(landscape,landscapeInsets,touch,keyboard,true,r);
    }
    // A full-width undocked rectangle behaves like a floating keyboard; a
    // preferred target below it need not be moved all the way to the top.
    PPOHostRect middle{0,400,414,100}, belowMiddle{364,650,50,44};
    Check(PPOKeyboardAvoidanceLayout(screen,insets,belowMiddle,middle,true,true,&r),"fullwidth but undocked keyboard");
    Original(r,belowMiddle,insets);

    // Production-layout safe endpoints can differ by an ulp when screen
    // conversions and insets contain fractions. Preserve that exact preferred
    // target instead of suppressing avoidance at the bottom endpoint.
    const PPOHostRect fractionalScene{15.724000000000004,-1.4200000000000017,414,896};
    const PPOEdgeDrawerInsets fractionalInsets{44.1,0,34.1,0};
    for (auto side : {PPOEdgeDrawerSide::Left,PPOEdgeDrawerSide::Right})
    for (double ratio : {0.0,0.25,0.5,0.75,1.0}) {
        PPOEdgeDrawerLayout layout{};
        Check(PPOEdgeDrawerMakeLayout(fractionalScene,fractionalInsets,side,ratio,34,0,&layout),
            "production edge layout accepts fractional coordinates and endpoint ratios");
        Check(PPOKeyboardAvoidanceLayout(fractionalScene,fractionalInsets,layout.touchHandle,corrupt,false,false,&r),
            "valid production handle is not rejected by safe-boundary rounding");
        Original(r,layout.touchHandle,fractionalInsets);
        const PPOHostRect keyboard{fractionalScene.x,fractionalScene.y+600,414,296};
        const bool ok=PPOKeyboardAvoidanceLayout(fractionalScene,fractionalInsets,layout.touchHandle,keyboard,true,true,&r);
        Check(ok,"fractional scene can avoid a normal docked keyboard");
        ValidDecision(fractionalScene,fractionalInsets,layout.touchHandle,keyboard,ok,r);
    }
    // A whole-strip obstruction still cannot invent a tiny/inverted free band.
    const PPOHostRect tinyBandKeyboard{0,44+44-1e-9,414,852};
    Check(!PPOKeyboardAvoidanceLayout(screen,insets,desired,tinyBandKeyboard,true,true,&r),
        "containment tolerance is not used to permit an undersized free band");
    Original(r,desired,insets);

    std::mt19937_64 random(0x4b4559424f415244ULL);
    for (unsigned i=0;i<40000;i++) {
        const double ox=static_cast<int>(random()%401)-200,oy=static_cast<int>(random()%601)-300;
        const double sw=320+random()%1001,sh=390+random()%1301;
        const PPOHostRect scene{ox,oy,sw,sh};
        const PPOEdgeDrawerInsets safe{static_cast<double>(random()%60),static_cast<double>(random()%30),
            static_cast<double>(random()%50),static_cast<double>(random()%30)};
        const double th=44+random()%29,tw=(random()%2)?50:80;
        const double sy=scene.y+safe.top,eh=scene.height-safe.top-safe.bottom;
        const double ty=sy+static_cast<double>(random()%10001)/10000*(eh-th);
        const PPOHostRect touch{random()%2?scene.x:scene.x+sw-tw,ty,tw,th};
        PPOHostRect keyboard{};
        if (i%3==0) {
            const double top=scene.y+random()%static_cast<unsigned>(sh);
            keyboard={scene.x,top,sw,scene.y+sh-top};
        } else {
            const double kw=44+random()%static_cast<unsigned>(sw),kh=20+random()%static_cast<unsigned>(sh);
            keyboard={scene.x+static_cast<double>(random()%static_cast<unsigned>(sw+200))-100,
                scene.y+static_cast<double>(random()%static_cast<unsigned>(sh+200))-100,kw,kh};
        }
        const bool ok=PPOKeyboardAvoidanceLayout(scene,safe,touch,keyboard,true,true,&r);
        ValidDecision(scene,safe,touch,keyboard,ok,r);
        PPOKeyboardAvoidanceResult off{};
        Check(PPOKeyboardAvoidanceLayout(scene,safe,touch,corrupt,false,true,&off),"preference off ignores all generated keyboard frames");
        Original(off,touch,safe);
        const auto saved=r;
        PPOKeyboardAvoidanceResult again{};
        Check(PPOKeyboardAvoidanceLayout(scene,safe,touch,keyboard,true,true,&again)==ok&&
            Same(again.touchHandle,saved.touchHandle)&&Same(again.pickerInsets,saved.pickerInsets)&&
            again.centerY==saved.centerY&&again.adjusted==saved.adjusted&&again.keyboardRelevant==saved.keyboardRelevant,
            "identical preferred input gives a deterministic result without accumulated displacement");
        Check(PPOKeyboardAvoidanceLayout(scene,safe,touch,keyboard,true,false,&off),"every keyboard hide can restore the configured target");
        Original(off,touch,safe);
    }
    std::printf("Keyboard avoidance tests passed: %u checks; public geometry only, not UIKit keyboard delivery\n",checks);
}
