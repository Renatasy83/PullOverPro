#pragma once
#import <Foundation/Foundation.h>

// Mobile service only. Reads a selected app's Info.plist, never personal data.
NSDictionary *PPOReadBundleSceneCapability(NSURL *bundleURL, NSString *identifier, NSTimeInterval now);
// Injectable actual-class/firmware guard for the inspected cached bundleURL getter.
NSDictionary *PPOCapabilityFromApplicationProxy(id proxy, Class applicationClass,
    Class bundleClass, BOOL imageMatches, NSString *identifier, NSTimeInterval now);
BOOL PPOBundleCapabilityFrameworkMatches(void);
