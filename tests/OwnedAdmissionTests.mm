#import "../PPOOwnedAdmission.h"
#import "../PPOSceneCapability.h"
#include <cmath>
#include <initializer_list>
#include <limits>
#include <stdio.h>
#include <stdlib.h>

// Public data-policy fixtures only. No private methods or app clients run here.
static unsigned checks;
static void Check(BOOL condition, const char *message) {
    checks++;
    if (!condition) { fprintf(stderr, "FAIL: %s\n", message); exit(1); }
}
static NSDictionary *Capability(NSString *identifier, NSString *status, double observed = 100) {
    NSString *reason = [status isEqual:@"eligible"] ? @"declared-single-application-scene" :
        ([status isEqual:@"ineligible"] ? @"multiple-scenes-disabled" : @"manifest-unknown");
    return @{@"schema": @1, @"policy": @"installed-basic-multiscene-v1",
        @"bundleIdentifier": identifier, @"status": status,
        @"eligible": [status isEqual:@"eligible"] ? @YES : @NO,
        @"reason": reason, @"observedUptime": @(observed)};
}
int main(void) {
    @autoreleasepool {
        NSArray *baselines = @[@"com.apple.mobilesafari", @"com.apple.reminders", @"com.apple.MobileAddressBook"];
        NSString *dynamic = @"com.example.sceneapp";
        for (NSString *identifier in baselines) {
            NSDictionary *legacy = PPOOwnedAdmissionSnapshot(identifier, nil, 100);
            Check([legacy[@"bundleIdentifier"] isEqual:identifier] &&
                  [legacy[@"basis"] isEqual:@"firmware-baseline"] &&
                  legacy[@"sceneCapability"] == NSNull.null && legacy.count == 3,
                  "known baseline keeps explicit provenance without fabricated metadata");
            NSDictionary *positive = PPOOwnedAdmissionSnapshot(identifier, Capability(identifier, @"eligible"), 101);
            Check([positive[@"basis"] isEqual:@"installed-info"] &&
                  [positive[@"sceneCapability"][@"status"] isEqual:@"eligible"],
                  "valid fresh positive retains installed metadata provenance even for a baseline");
            Check(PPOOwnedAdmissionSnapshot(identifier, Capability(identifier, @"ineligible"), 101) == nil,
                  "fresh explicit negative overrides the known baseline");
            NSDictionary *unknown = PPOOwnedAdmissionSnapshot(identifier, Capability(identifier, @"unknown"), 101);
            Check([unknown[@"basis"] isEqual:@"firmware-baseline"] &&
                  [unknown[@"sceneCapability"][@"status"] isEqual:@"unknown"],
                  "well-formed unknown metadata permits only explicit baseline fallback");
            Check(PPOOwnedAdmissionSnapshot(identifier, Capability(dynamic, @"eligible"), 101) == nil,
                  "metadata for another app cannot pair with a baseline identifier");
            Check(PPOOwnedAdmissionSnapshot(identifier, Capability(identifier, @"unknown"), 106) == nil,
                  "stale explicit metadata is not silently discarded for fallback");
        }
        Check(PPOOwnedAdmissionSnapshot(dynamic, nil, 100) == nil,
              "a dynamic target cannot use a missing capability");
        Check(PPOOwnedAdmissionSnapshot(dynamic, Capability(dynamic, @"unknown"), 100) == nil &&
              PPOOwnedAdmissionSnapshot(dynamic, Capability(dynamic, @"ineligible"), 100) == nil,
              "unknown and explicit negative never admit dynamic targets");
        NSDictionary *admitted = PPOOwnedAdmissionSnapshot(dynamic, Capability(dynamic, @"eligible"), 105);
        Check([admitted[@"bundleIdentifier"] isEqual:dynamic] &&
              [admitted[@"basis"] isEqual:@"installed-info"] && admitted.count == 3,
              "a bound positive admits a dynamic target through the five-second endpoint");
        Check(PPOOwnedAdmissionSnapshot(dynamic, Capability(dynamic, @"eligible"), 105.000001) == nil &&
              PPOOwnedAdmissionSnapshot(dynamic, Capability(dynamic, @"eligible", 100.100001), 100) == nil,
              "expired and excessively future observations cannot grant eligibility");
        Check(PPOOwnedAdmissionSnapshot(dynamic, Capability(dynamic, @"eligible", 100.1), 100) != nil,
              "small same-host scheduling skew remains tolerated");
        for (id identifier in @[@"com.apple.springboard", @"COM.APPLE.BACKBOARDD", @"com.apple.runningboardd",
                @"com.apple.lsd", @"com.apple.uikitservices", @"bad/path", @"", @1, NSNull.null]) {
            Check(PPOOwnedAdmissionSnapshot(identifier, nil, 100) == nil,
                  "critical process or malformed identifiers never use baseline admission");
            Check(PPOOwnedAdmissionSnapshot(identifier, Capability(dynamic, @"eligible"), 100) == nil,
                  "a positive descriptor cannot bypass critical identity exclusions");
            Check(PPOOwnedAdmissionSnapshot(identifier, Capability(identifier, @"eligible"), 100) == nil,
                  "even a self-matching positive cannot admit a forbidden or malformed selected identifier");
        }
        Check(PPOOwnedAdmissionSnapshot(nil, Capability(dynamic, @"eligible"), 100) == nil,
              "nil selected identity is always rejected");
        for (double now : { -1.0, std::numeric_limits<double>::quiet_NaN(),
                            std::numeric_limits<double>::infinity() }) {
            Check(PPOOwnedAdmissionSnapshot(@"com.apple.mobilesafari", nil, now) == nil &&
                  PPOOwnedAdmissionSnapshot(dynamic, Capability(dynamic, @"eligible"), now) == nil,
                  "invalid caller clock cannot admit either baseline or dynamic target");
        }
        NSArray *badKeys = @[@"schema", @"policy", @"bundleIdentifier", @"status", @"eligible", @"reason", @"observedUptime"];
        for (NSString *key in badKeys) {
            NSMutableDictionary *missing = [Capability(dynamic, @"eligible") mutableCopy];
            [missing removeObjectForKey:key];
            Check(PPOOwnedAdmissionSnapshot(dynamic, missing, 100) == nil,
                  "missing capability fields cannot become a positive admission");
            Check(PPOOwnedAdmissionSnapshot(@"com.apple.mobilesafari", missing, 100) == nil,
                  "malformed supplied metadata never falls back silently");
        }
        for (NSDictionary *change in @[@{@"schema": @YES}, @{@"schema": @2}, @{@"eligible": @1},
                @{@"policy": @"unknown-policy"}, @{@"status": @"unknown"}, @{@"reason": @"unknown-reason"},
                @{@"observedUptime": @YES}, @{@"observedUptime": @(-1)}, @{@"rawBundleURL": @"file:///private/app"}]) {
            NSMutableDictionary *bad = [Capability(dynamic, @"eligible") mutableCopy];
            [bad addEntriesFromDictionary:change];
            Check(PPOOwnedAdmissionSnapshot(dynamic, bad, 100) == nil,
                  "Boolean/count tricks, unknown fields and inconsistent metadata are denied");
        }
        Check(PPOOwnedAdmissionSnapshot(dynamic, (id)@1, 100) == nil &&
              PPOOwnedAdmissionSnapshot(@"com.apple.mobilesafari", (id)NSNull.null, 100) == nil,
              "supplied metadata must be a valid dictionary rather than a truthy value");
        NSMutableString *request = [dynamic mutableCopy], *proofID = [dynamic mutableCopy];
        NSMutableString *policy = [@"installed-basic-multiscene-v1" mutableCopy];
        NSMutableString *status = [@"eligible" mutableCopy], *reason = [@"declared-single-application-scene" mutableCopy];
        NSMutableDictionary *mutableProof = [Capability(dynamic, @"eligible") mutableCopy];
        mutableProof[@"bundleIdentifier"] = proofID; mutableProof[@"policy"] = policy;
        mutableProof[@"status"] = status; mutableProof[@"reason"] = reason;
        NSDictionary *frozen = PPOOwnedAdmissionSnapshot(request, mutableProof, 100);
        Check(frozen != nil, "caller-owned mutable input is normalized before admission");
        [request setString:@"com.example.other"]; [proofID setString:@"com.example.other"];
        [policy setString:@"different"]; [status setString:@"ineligible"]; [reason setString:@"multiple-scenes-disabled"];
        mutableProof[@"observedUptime"] = @0; mutableProof[@"eligible"] = @NO;
        NSDictionary *frozenProof = frozen[@"sceneCapability"];
        Check([frozen[@"bundleIdentifier"] isEqual:dynamic] &&
              [frozenProof[@"bundleIdentifier"] isEqual:dynamic] &&
              [frozenProof[@"policy"] isEqual:@"installed-basic-multiscene-v1"] &&
              [frozenProof[@"status"] isEqual:@"eligible"] &&
              [frozenProof[@"reason"] isEqual:@"declared-single-application-scene"] &&
              [frozenProof[@"observedUptime"] isEqual:@100] && [frozenProof[@"eligible"] isEqual:@YES],
              "all nested eligibility strings and scalars are frozen independently of the caller");
        printf("Owned admission tests passed: %u checks; pure eligibility policy, not app admission\n", checks);
    }
    return 0;
}
