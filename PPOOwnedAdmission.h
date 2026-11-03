#pragma once
#import <Foundation/Foundation.h>

// Eligibility or exact reviewed warm-trial provenance, not an entitlement/runtime claim.
// Returns a frozen minimal descriptor, or nil. No current-clock/private reads.
NSDictionary *PPOOwnedAdmissionSnapshot(NSString *identifier,
    NSDictionary *capability, NSTimeInterval now);
