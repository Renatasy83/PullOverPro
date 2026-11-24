#include "../Shared/POFloatingWindowGeometry.h"
#include <assert.h>
#include <float.h>
#include <stdio.h>

static const POFloatingWindowPosition unset = {false, 0, 0};
static void near(double actual, double expected) {
    assert(isfinite(actual));
    assert(fabs(actual - expected) <= 1e-9 * fmax(1, fabs(expected)));
}
static POFloatingWindowGeometry phone(double fraction, POFloatingWindowPosition position) {
    return POFloatingWindowMakeGeometry(414,896,414,896,0,44,0,34,fraction,position);
}
static void finiteGeometry(POFloatingWindowGeometry g) {
    const double values[] = {g.fraction,g.scale,g.maximumScale,g.maximumWidth,g.maximumHeight,g.pageOffset,
        g.minimumOriginX,g.minimumOriginY,g.maximumOriginX,g.maximumOriginY,g.position.x,g.position.y,
        g.chrome.x,g.chrome.y,g.chrome.width,g.chrome.height,g.pane.x,g.pane.y,g.pane.width,g.pane.height,
        g.titleBar.x,g.titleBar.y,g.titleBar.width,g.titleBar.height,g.grip.x,g.grip.y,g.grip.width,g.grip.height};
    for (unsigned i=0;i<sizeof(values)/sizeof(values[0]);i++) assert(isfinite(values[i]));
    assert(g.fraction>=.55 && g.fraction<=1);
}
static void fits(double nw,double nh,double vw,double vh,double left,double top,double right,double bottom,
                 double fraction,POFloatingWindowPosition position) {
    POFloatingWindowGeometry g=POFloatingWindowMakeGeometry(nw,nh,vw,vh,left,top,right,bottom,fraction,position);
    finiteGeometry(g); assert(g.valid);
    double x=g.chrome.x-g.pageOffset,y=g.chrome.y;
    assert(x>=left-1e-9 && x+g.chrome.width<=vw-right+1e-9);
    assert(y>=top-1e-9 && y+g.chrome.height<=vh-bottom+1e-9);
    near(g.pane.width/g.pane.height,nw/nh);
    near(g.pane.x,0); near(g.pane.y,30); near(g.titleBar.height,28);
    near(g.chrome.width,g.pane.width);near(g.chrome.height,g.pane.height+50);
    near(g.grip.x+g.grip.width,g.pane.width);near(g.grip.y,g.pane.y+g.pane.height+2);
    near(g.grip.y+g.grip.height,g.chrome.height);
    near(g.grip.width,44);near(g.grip.height,18);
    assert(g.position.specified && g.position.x>=0 && g.position.x<=1 && g.position.y>=0 && g.position.y<=1);
}
static void baselineAndSweep(void) {
    POFloatingWindowGeometry g=phone(1,unset);
    assert(g.valid);near(g.maximumScale,6.0/7);near(g.pane.width,354.8571428571429);
    near(g.pane.height,768);near(g.chrome.height,818);near(g.chrome.x,414);near(g.chrome.y,44);
    near(g.chrome.y+g.pane.y,74);near(g.chrome.y+g.grip.y+g.grip.height,862);
    near(g.position.y,0); // No free vertical space at maximum size.
    POFloatingWindowGeometry smaller=phone(.55,unset);
    near(smaller.chrome.x,414);near(smaller.chrome.y,216.8);near(smaller.pane.height,422.4);
    const POFloatingWindowPosition positions[]={{false,0,0},{true,0,0},{true,1,1},{true,.5,.5},{true,-2,3}};
    for(unsigned i=0;i<sizeof(positions)/sizeof(positions[0]);i++) {
        for(unsigned step=0;step<=45;step++) {
            double f=.55+step*.01;
            fits(414,896,414,896,0,44,0,34,f,positions[i]);
            fits(393,852,393,852,0,59,0,34,f,positions[i]);
            fits(375,667,375,667,0,20,0,0,f,positions[i]);
            fits(414,896,500,600,25,30,30,34,f,positions[i]);
        }
    }
}
static void normalizationAndMovement(void) {
    POFloatingWindowPosition p=POFloatingWindowNormalizePosition((POFloatingWindowPosition){true,-1,2});
    assert(p.specified);near(p.x,0);near(p.y,1);
    p=POFloatingWindowNormalizePosition((POFloatingWindowPosition){true,NAN,.5});
    assert(!p.specified);near(p.x,0);near(p.y,0);
    POFloatingWindowGeometry g=phone(.7,(POFloatingWindowPosition){true,.5,.5});
    double x=g.chrome.x-g.pageOffset,y=g.chrome.y;
    p=POFloatingWindowMovePosition(g,20,-30);
    POFloatingWindowGeometry moved=phone(.7,p);
    near(moved.chrome.x-g.pageOffset,x+20);near(moved.chrome.y,y-30);
    p=POFloatingWindowMovePosition(g,DBL_MAX,-DBL_MAX);
    moved=phone(.7,p);near(moved.chrome.x-g.pageOffset,g.maximumOriginX);near(moved.chrome.y,g.minimumOriginY);
    p=POFloatingWindowMovePosition(g,-DBL_MAX,DBL_MAX);
    moved=phone(.7,p);near(moved.chrome.x-g.pageOffset,g.minimumOriginX);near(moved.chrome.y,g.maximumOriginY);
    p=POFloatingWindowMovePosition(g,0,0);near(p.x,.5);near(p.y,.5);
    // Parent conversion gives the same logical delta for opposite screen-side drags.
    POFloatingWindowPosition left=POFloatingWindowMovePosition(g,-(-20),-30);
    POFloatingWindowPosition right=POFloatingWindowMovePosition(g,20,-30);
    near(left.x,right.x);near(left.y,right.y);
    p=POFloatingWindowMovePosition(g,NAN,20);near(p.x,g.position.x);near(p.y,g.position.y);
    p=POFloatingWindowPositionForOrigin(g,INFINITY,y);near(p.x,g.position.x);near(p.y,g.position.y);
    p=POFloatingWindowPositionForOrigin(g,-DBL_MAX,DBL_MAX);near(p.x,0);near(p.y,1);
    POFloatingWindowGeometry maximum=phone(1,(POFloatingWindowPosition){true,.5,.9});
    p=POFloatingWindowPositionForOrigin(maximum,0,100);assert(p.specified);near(p.y,0);
    POFloatingWindowGeometry asymmetric=POFloatingWindowMakeGeometry(414,896,500,600,25,30,30,34,.6,unset);
    near(asymmetric.chrome.x-asymmetric.pageOffset,50);
    p=POFloatingWindowPositionForOrigin(asymmetric,-100,-100);
    POFloatingWindowGeometry atCorner=POFloatingWindowMakeGeometry(414,896,500,600,25,30,30,34,.6,p);
    near(atCorner.chrome.x-atCorner.pageOffset,25);near(atCorner.chrome.y,30);
}
static void resizingKeepsOriginUntilClamped(void) {
    POFloatingWindowGeometry start=phone(.55,(POFloatingWindowPosition){true,.8,.8});
    double x=start.chrome.x-start.pageOffset,y=start.chrome.y;
    POFloatingWindowGeometry next=phone(.6,unset);
    POFloatingWindowPosition p=POFloatingWindowPositionForOrigin(next,x,y);
    next=phone(.6,p);near(next.chrome.x-next.pageOffset,x);near(next.chrome.y,y);
    next=phone(1,unset);p=POFloatingWindowPositionForOrigin(next,x,y);next=phone(1,p);
    near(next.chrome.x-next.pageOffset,next.maximumOriginX);near(next.chrome.y,next.maximumOriginY);
    // Recompute from the captured start instead of accumulating boundary shifts.
    next=phone(.55,unset);p=POFloatingWindowPositionForOrigin(next,x,y);next=phone(.55,p);
    near(next.chrome.x-next.pageOffset,x);near(next.chrome.y,y);
    double w=start.maximumWidth,h=start.maximumHeight;
    near(POFloatingWindowFractionForTranslation(.7,w*.1,h*.1,w,h),.8);
    near(POFloatingWindowFractionForTranslation(.7,h*.1,-w*.1,w,h),.7);
    near(POFloatingWindowFractionForTranslation(.7,-w,-h,w,h),.55);
    near(POFloatingWindowFractionForTranslation(.7,w,h,w,h),1);
    near(POFloatingWindowFractionForTranslation(.7,0,0,w,h),.7);
    near(POFloatingWindowFractionForTranslation(.7,NAN,10,w,h),.7);
    near(POFloatingWindowFractionForTranslation(.7,1,2,0,h),.7);
    near(POFloatingWindowFractionForTranslation(.7,DBL_MAX,DBL_MAX,w,h),1);
    near(POFloatingWindowFractionForTranslation(.7,-DBL_MAX,-DBL_MAX,w,h),.55);
}
static void invalidGeometry(void) {
    const double cases[][8]={
        {0,896,414,896,0,44,0,34},{414,0,414,896,0,44,0,34},
        {414,896,50,896,0,44,0,34},{414,896,414,50,0,0,0,0},
        {414,896,414,896,-1,44,0,34},{414,896,414,896,0,44,-1,34},
        {414,896,414,896,0,-1,0,34},{414,896,414,896,0,44,0,-1},
        {414,896,414,896,300,44,300,34},{414,896,414,896,0,450,0,450},
        {NAN,896,414,896,0,44,0,34},{414,INFINITY,414,896,0,44,0,34},
        {414,896,INFINITY,896,0,44,0,34},{414,896,414,NAN,0,44,0,34},
        {414,896,414,896,NAN,44,0,34},{414,896,414,896,0,INFINITY,0,34},
        {414,896,414,896,0,44,NAN,34},{414,896,414,896,0,44,0,INFINITY},
        {DBL_MIN,DBL_MIN,DBL_MAX,DBL_MAX,0,0,0,0},
        {414,896,DBL_MAX,DBL_MAX,0,0,0,0},{DBL_MAX,DBL_MIN,414,896,0,0,0,0}
    };
    for(unsigned i=0;i<sizeof(cases)/sizeof(cases[0]);i++) {
        POFloatingWindowGeometry g=POFloatingWindowMakeGeometry(cases[i][0],cases[i][1],cases[i][2],cases[i][3],
            cases[i][4],cases[i][5],cases[i][6],cases[i][7],NAN,(POFloatingWindowPosition){true,NAN,INFINITY});
        finiteGeometry(g);assert(!g.valid);near(g.scale,0);
        assert(!POFloatingWindowPositionForOrigin(g,0,0).specified);
        assert(!POFloatingWindowMovePosition(g,0,0).specified);
    }
}
int main(void) {
    baselineAndSweep();normalizationAndMovement();resizingKeepsOriginUntilClamped();invalidGeometry();
    puts("PASS floating-window geometry: chrome bounds, normalized movement, anchored resizing, safe-area/invalid values");
}
