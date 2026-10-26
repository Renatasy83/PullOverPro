#import <Foundation/Foundation.h>

// Beta safety diagnostic. No Logos hooks, UIKit, private SpringBoard calls,
// timers, windows, application enumeration, or scene hosting.
// This build only verifies that the dylib can be loaded by the injection system.
// Emergency opt-out: create /var/mobile/.ppo_disable before enabling tweaks.
%ctor {
    @autoreleasepool {
        if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/.ppo_disable"]) {
            NSLog(@"[PullOverPro Safe Diagnostic] disabled by /var/mobile/.ppo_disable");
            return;
        }
        NSLog(@"[PullOverPro Safe Diagnostic] dylib loaded; no hooks installed");
    }
}
