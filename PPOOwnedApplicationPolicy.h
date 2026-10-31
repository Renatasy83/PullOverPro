#pragma once
#import <Foundation/Foundation.h>

// Exact23A355 manifest facts are recorded in SCENE_TARGETS_23A355.json.
// Eligibility is not a claim of actual app admission, rendering or input.
static inline BOOL PPOOwnedApplicationAllowed(NSString *identifier) {
    return [identifier isKindOfClass:NSString.class] &&
        ([identifier isEqual:@"com.apple.mobilesafari"] ||
         [identifier isEqual:@"com.apple.reminders"] ||
         [identifier isEqual:@"com.apple.MobileAddressBook"]);
}
