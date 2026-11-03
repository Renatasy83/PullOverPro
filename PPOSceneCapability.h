#pragma once
#import <Foundation/Foundation.h>

// Pure data policy. No file access, private API or current-clock reads.
// Exact normalized keys: schema, policy, bundleIdentifier, status, eligible,
// reason, observedUptime. Policy is installed-basic-multiscene-v4.
// The Messages-only programmatic reason is advisory and bound to its exact
// inspected manifest/version profile; all owned-host runtime gates still apply.
BOOL PPOSceneApplicationIdentifierAllowed(id identifier);
NSDictionary *PPOSceneCapabilityUnknown(NSString *identifier, NSString *reason, NSTimeInterval observedUptime);
NSDictionary *PPOSceneCapabilityFromInfo(id info, NSString *identifier, NSTimeInterval observedUptime);
NSDictionary *PPOSceneCapabilityNormalize(id value);
BOOL PPOSceneCapabilityFresh(id value, NSTimeInterval now);

// Trusted installed-bundle reader supplies SHA256 of the exact Info.plist bytes.
// The reviewed reason remains unknown/eligible=false; it is a warm timed trial only.
NSDictionary *PPOSceneCapabilityFromInfoWithDigest(id info, NSString *identifier,
    NSTimeInterval observedUptime, NSString *sha256);
BOOL PPOSceneCapabilityIsMessengerTrial(id capability);
