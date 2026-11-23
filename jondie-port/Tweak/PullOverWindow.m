//
//  PullOverWindow.m
//  PullOverPro
//
//  Created by Will Smillie on 4/8/19.
//

#import "PullOverWindow.h"
#import "POApplicationHelper.h"

@implementation PullOverWindow
@synthesize controller;

+ (id)sharedWindow {
    static PullOverWindow *window = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        window = [[self alloc] init];
    });
    
    return window;
}

- (id)init{
    self = [super initWithFrame:[UIScreen mainScreen].bounds];
    if(self){
        self.windowLevel = UIWindowLevelAlert-1;
        [self setHidden:NO];
        self.alpha = 1;
        self.rootViewController = controller = [[PullOverViewController alloc] init];
        self.userInteractionEnabled = YES;
        self.backgroundColor = [UIColor clearColor];
        [self attachSceneIfNeeded];
    }
    return self;
}

// A window needs a scene to show up: use SpringBoard's main display scene. If SpringBoard has not connected
// it yet when the tweak starts, the window stays invisible, so this is called again each time visibility is
// worked out (unlock, scene activation) until it has one.
- (void)attachSceneIfNeeded {
    if (self.windowScene) return;
    UIWindowScene *fallback = nil;
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) continue;
        if (((UIWindowScene *)scene).screen == [UIScreen mainScreen]) { fallback = (UIWindowScene *)scene; break; }
        if (!fallback) fallback = (UIWindowScene *)scene;
    }
    if (fallback) {
        self.windowScene = fallback;
        if (!self.hidden) [self makeKeyAndVisible];
    }
}

- (void)applySettings{
    NSDictionary *settings = [POApplicationHelper settings];
    if (controller.isOpened) {
        [controller endHosting];
        [controller close];
    }
    // A fresh controller picks up dark mode, scale, labels, left-handed etc.
    self.rootViewController = controller = [[PullOverViewController alloc] init];
    self.transform = [settings[@"leftHanded"] boolValue] ? CGAffineTransformMakeScale(-1.0, 1.0) : CGAffineTransformIdentity;
    self.hidden = ![settings[@"enabled"] boolValue];
}

-(void)makeKeyAndVisible{
    [super makeKeyAndVisible];
}
- (bool)_shouldCreateContextAsSecure{
    return YES;
}



- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event{
    UIView *hitTestResult = [super hitTest:point withEvent:event];
    

    CGPoint convertedPoint = [self convertPoint:point toView:controller.contentView];

    if ([controller isOpened]) {
//        if (CGRectContainsPoint(controller.contentView.bounds, convertedPoint)) {
//            NSLog(@"[PO] Touch is contained in controller!");
//            return nil;
//        }
        return hitTestResult;
    }else{
        if ([hitTestResult isKindOfClass:[POHandle class]]) {
            return controller.handle;
        }
        return nil;
    }
}


@end
