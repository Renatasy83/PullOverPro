#import <Foundation/Foundation.h>

// Main-thread, read-only lock observation for the exact verified firmware.
// Unknown/error states contain NSNull flags and must be treated as unsafe.
// This reader never creates a lock manager or changes lock state.
NSDictionary *PPOReadScreenLockState(Class managerClass, BOOL firmwareMatches);
