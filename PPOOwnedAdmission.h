#pragma once
#import <Foundation/Foundation.h>

// Eligibility evidence only, not an entitlement or runtime-compatibility claim.
// Returns a frozen minimal descriptor, or nil. No current-clock/private reads.
NSDictionary *PPOOwnedAdmissionSnapshot(NSString *identifier,
    NSDictionary *capability, NSTimeInterval now);
