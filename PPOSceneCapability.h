#pragma once
#import <Foundation/Foundation.h>

// Pure data policy. No file access, private API or current-clock reads.
// Exact normalized keys: schema, policy, bundleIdentifier, status, eligible,
// reason, observedUptime. Policy is installed-basic-multiscene-v1.
BOOL PPOSceneApplicationIdentifierAllowed(id identifier);
NSDictionary *PPOSceneCapabilityUnknown(NSString *identifier, NSString *reason, NSTimeInterval observedUptime);
NSDictionary *PPOSceneCapabilityFromInfo(id info, NSString *identifier, NSTimeInterval observedUptime);
NSDictionary *PPOSceneCapabilityNormalize(id value);
BOOL PPOSceneCapabilityFresh(id value, NSTimeInterval now);
