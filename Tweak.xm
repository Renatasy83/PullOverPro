#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// Alpha 1 is intentionally diagnostic-only. It does not host applications,
// install UI overlays, or call legacy SpringBoard private APIs.
%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    NSLog(@"[PullOverPro Alpha1] SpringBoard launched; ElleKit injection succeeded");
}
%end

%ctor {
    @autoreleasepool {
        NSLog(@"[PullOverPro Alpha1] diagnostic tweak dylib loaded");
    }
}
