#import "../PPOBridgeProtocol.h"
#import "../PPOSceneCapability.h"
#include <cmath>
#include <stdio.h>
#include <stdlib.h>

// Fixture contract: synthetic policy v3 descriptors, bounded JSON transport and nonce binding.
// Named Files/Mail fixtures do not read Apple bundles/binaries or call private APIs.
// Decoding binds only the nonce; callers separately bind the selected identifier and freshness.
static unsigned checks;
static void Check(BOOL condition, const char *name) {
    checks++;
    if (!condition) { fprintf(stderr, "FAIL: %s\n", name); exit(1); }
}
static NSData *JSON(id value) {
    return [NSJSONSerialization dataWithJSONObject:value options:0 error:NULL];
}
// Synthetic metadata only: no installed application plist or private API is used.
static NSDictionary *Capability(NSString *identifier, NSTimeInterval now) {
    NSDictionary *info = @{@"CFBundleIdentifier": identifier, @"CFBundlePackageType": @"APPL",
        @"UIDeviceFamily": @[@1], @"UIApplicationSceneManifest": @{
            @"UIApplicationSupportsMultipleScenes": @YES}};
    return PPOSceneCapabilityFromInfo(info, identifier, now);
}
static NSDictionary *StaticCapability(NSString *identifier, NSTimeInterval now) {
    NSDictionary *info = @{@"CFBundleIdentifier": identifier, @"CFBundlePackageType": @"APPL",
        @"UIDeviceFamily": @[@1], @"UIApplicationSceneManifest": @{
            @"UIApplicationSupportsMultipleScenes": @YES,
            @"UISceneConfigurations": @{@"UIWindowSceneSessionRoleApplication": @[
                @{@"UISceneDelegateClassName": @"FixtureSceneDelegate"}]}}};
    return PPOSceneCapabilityFromInfo(info, identifier, now);
}
static NSDictionary *NamedCapability(NSString *identifier, NSArray<NSString *> *names,
    BOOL includesSceneClass, NSTimeInterval now) {
    NSMutableArray *configurations = [NSMutableArray array];
    for (NSString *name in names) {
        NSMutableDictionary *configuration = [@{@"UISceneConfigurationName": name,
            @"UISceneDelegateClassName": @"Fixture.NamedSceneDelegate"} mutableCopy];
        if (includesSceneClass) configuration[@"UISceneClassName"] = @"UIWindowScene";
        [configurations addObject:configuration];
    }
    NSDictionary *info = @{@"CFBundleIdentifier": identifier, @"CFBundlePackageType": @"APPL",
        @"UIDeviceFamily": @[@1], @"UIApplicationSceneManifest": @{
            @"UIApplicationSupportsMultipleScenes": @YES,
            @"UISceneConfigurations": @{@"UIWindowSceneSessionRoleApplication": configurations}}};
    return PPOSceneCapabilityFromInfo(info, identifier, now);
}
static void RejectCapability(NSString *nonce, NSDictionary *inspected, NSDictionary *capability) {
    Check(PPOBridgeCapabilityResponseData(nonce, capability, 102, NULL) == nil,
          "malformed capability cannot be encoded as a current-policy proof");
    NSMutableDictionary *reply = [inspected mutableCopy];
    reply[@"sceneCapability"] = capability;
    Check(PPOBridgeResponseFromData(JSON(reply), nonce, NULL) == nil,
          "incoming malformed capability cannot bypass current-policy normalization");
}
int main(void) {
    @autoreleasepool {
        NSString *nonce = NSUUID.UUID.UUIDString;
        NSString *other = NSUUID.UUID.UUIDString;
        NSData *ping = PPOBridgeRequestData(nonce, @"ping", nil, 100, NULL);
        NSDictionary *request = PPOBridgeRequestFromData(ping, 100, NULL);
        Check([request[@"nonce"] isEqual:nonce], "ping round trip");
        Check(PPOBridgeRequestFromData(ping, 105, NULL) != nil, "TTL inclusive boundary");
        NSError *error = nil;
        Check(PPOBridgeRequestFromData(ping, 105.001, &error) == nil && error.code == 2, "expired request");
        Check(PPOBridgeRequestFromData(ping, 99.95, NULL) != nil, "small timestamp skew");
        Check(PPOBridgeRequestFromData(ping, 99.8, NULL) == nil, "future request");
        Check(PPOBridgeRequestFromData(ping, NAN, NULL) == nil, "NaN now");
        Check(PPOBridgeRequestData(nonce, @"ping", nil, NAN, NULL) == nil, "NaN created");
        Check(PPOBridgeRequestData(nonce, @"ping", nil, INFINITY, NULL) == nil, "infinite created");
        Check(PPOBridgeRequestData(nonce, @"ping", nil, -1, NULL) == nil, "negative created");
        Check(PPOBridgeRequestData(@"bad", @"ping", nil, 100, NULL) == nil, "bad nonce");
        Check(PPOBridgeRequestData(nonce, @"unknown", nil, 100, NULL) == nil, "unknown operation");
        Check(PPOBridgeRequestData(nonce, @"refresh", nil, 100, NULL) != nil, "refresh request");
        Check(PPOBridgeRequestData(nonce, @"launch", @"com.apple.mobilesafari", 100, NULL) != nil, "launch request");
        Check(PPOBridgeRequestData(nonce, @"launch", nil, 100, NULL) == nil, "launch requires id");
        NSData *inspection = PPOBridgeRequestData(nonce, @"inspect-scene", @"com.example.window", 100, NULL);
        NSDictionary *inspectionRequest = PPOBridgeRequestFromData(inspection, 100, NULL);
        Check([inspectionRequest[@"operation"] isEqual:@"inspect-scene"] &&
              [inspectionRequest[@"bundleIdentifier"] isEqual:@"com.example.window"],
              "selected scene inspection request round trip");
        Check(PPOBridgeRequestData(nonce, @"inspect-scene", nil, 100, NULL) == nil &&
              PPOBridgeRequestData(nonce, @"inspect-scene", @"app/id", 100, NULL) == nil,
              "inspection requires an allowed identifier");
        for (NSString *identifier in @[@"com.apple.springboard", @"com.apple.backboardd",
                                       @"COM.APPLE.RUNNINGBOARDD", @"com.apple.lsd", @"com.apple.uikitservices"])
            Check(PPOBridgeRequestData(nonce, @"inspect-scene", identifier, 100, NULL) == nil,
                  "inspection cannot target a system process");
        Check(PPOBridgeRequestData(nonce, @"ping", @"com.apple.mobilesafari", 100, NULL) == nil, "ping forbids id");
        Check(!PPOBridgeValidIdentifier(@"") && !PPOBridgeValidIdentifier(@"app/id") &&
              !PPOBridgeValidIdentifier(@"app id") && !PPOBridgeValidIdentifier(@"app.é"), "identifier characters");
        NSString *maximum = [@"a" stringByPaddingToLength:255 withString:@"a" startingAtIndex:0];
        Check(PPOBridgeValidIdentifier(maximum) && !PPOBridgeValidIdentifier([maximum stringByAppendingString:@"a"]), "identifier length");

        NSMutableDictionary *raw = [request mutableCopy];
        raw[@"schema"] = @YES;
        Check(PPOBridgeRequestFromData(JSON(raw), 100, NULL) == nil, "boolean schema");
        raw[@"schema"] = @1;
        raw[@"createdUptime"] = @YES;
        Check(PPOBridgeRequestFromData(JSON(raw), 100, NULL) == nil, "boolean uptime");
        raw[@"createdUptime"] = @"100";
        Check(PPOBridgeRequestFromData(JSON(raw), 100, NULL) == nil, "string uptime");
        raw[@"createdUptime"] = @100;
        raw[@"extra"] = @1;
        Check(PPOBridgeRequestFromData(JSON(raw), 100, NULL) == nil, "unknown request key");
        Check(PPOBridgeRequestFromData(JSON(@[]), 100, NULL) == nil, "array root");
        Check(PPOBridgeRequestFromData([@"{" dataUsingEncoding:NSUTF8StringEncoding], 100, NULL) == nil, "malformed JSON");
        Check(PPOBridgeRequestFromData([NSMutableData dataWithLength:4097], 100, NULL) == nil, "oversized request");

        NSData *response = PPOBridgeResponseData(nonce, @"refreshed", @"apps-refreshed", @443, 102, NULL);
        Check([PPOBridgeResponseFromData(response, nonce, NULL)[@"appsCount"] isEqual:@443], "response round trip");
        Check(PPOBridgeResponseFromData(response, other, NULL) == nil, "response nonce binding");
        Check(PPOBridgeResponseData(nonce, @"accepted", nil, nil, 102, NULL) != nil, "minimal response");
        Check(PPOBridgeResponseData(nonce, @"unknown", nil, nil, 102, NULL) == nil, "unknown status");
        Check(PPOBridgeResponseData(nonce, @"ready", @"arbitrary detail!", nil, 102, NULL) == nil, "controlled detail");
        Check(PPOBridgeResponseData(nonce, @"ready", nil, @YES, 102, NULL) == nil, "boolean count");
        Check(PPOBridgeResponseData(nonce, @"ready", nil, @0.5, 102, NULL) == nil, "fractional count");
        Check(PPOBridgeResponseData(nonce, @"ready", nil, @4097, 102, NULL) == nil, "oversized count");
        Check(PPOBridgeResponseData(nonce, @"ready", nil, @-1, 102, NULL) == nil, "negative count");
        Check(PPOBridgeResponseData(nonce, @"ready", nil, nil, INFINITY, NULL) == nil, "infinite response uptime");
        NSMutableDictionary *reply = [[NSJSONSerialization JSONObjectWithData:response options:0 error:NULL] mutableCopy];
        reply[@"extra"] = @YES;
        Check(PPOBridgeResponseFromData(JSON(reply), nonce, NULL) == nil, "unknown response key");
        [reply removeObjectForKey:@"extra"];
        reply[@"schema"] = @YES;
        Check(PPOBridgeResponseFromData(JSON(reply), nonce, NULL) == nil, "boolean response schema");
        reply[@"schema"] = @1;
        reply[@"uptime"] = @YES;
        Check(PPOBridgeResponseFromData(JSON(reply), nonce, NULL) == nil, "boolean response uptime");
        Check(PPOBridgeResponseFromData([NSMutableData dataWithLength:4097], nonce, NULL) == nil, "oversized response");

        NSDictionary *capability = Capability(@"com.example.window", 100);
        Check([capability[@"status"] isEqual:@"eligible"] &&
              [capability[@"policy"] isEqual:@"installed-basic-multiscene-v3"] &&
              [capability[@"reason"] isEqual:@"declared-programmatic-application-scenes"] &&
              [PPOSceneCapabilityNormalize(capability) isEqual:capability],
              "synthetic programmatic capability satisfies the v3 data policy");
        NSData *inspectedData = PPOBridgeCapabilityResponseData(nonce, capability, 102, NULL);
        NSDictionary *inspected = PPOBridgeResponseFromData(inspectedData, nonce, NULL);
        Check(inspectedData.length <= PPOBridgeMessageLimit &&
              [inspected[@"status"] isEqual:@"inspected"] &&
              [inspected[@"sceneCapability"] isEqual:capability],
              "canonical capability is carried in a bounded nonce-bound response");
        Check([inspected[@"detail"] isEqual:@"declared-programmatic-application-scenes"] &&
              [inspected[@"sceneCapability"][@"bundleIdentifier"] isEqual:@"com.example.window"] &&
              [inspected[@"sceneCapability"][@"observedUptime"] isEqual:@100],
              "programmatic round trip preserves the exact reason, selected identifier and observation time");
        Check(PPOSceneCapabilityFresh(inspected[@"sceneCapability"], 100) &&
              PPOSceneCapabilityFresh(inspected[@"sceneCapability"], 105) &&
              PPOSceneCapabilityFresh(inspected[@"sceneCapability"], 99.9) &&
              !PPOSceneCapabilityFresh(inspected[@"sceneCapability"], 105.0001) &&
              !PPOSceneCapabilityFresh(inspected[@"sceneCapability"], 99.8999),
              "transport preserves the existing capability freshness boundaries");
        NSDictionary *staticCapability = StaticCapability(@"com.example.window", 100);
        NSDictionary *staticReply = PPOBridgeResponseFromData(
            PPOBridgeCapabilityResponseData(nonce, staticCapability, 102, NULL), nonce, NULL);
        Check([staticCapability[@"policy"] isEqual:@"installed-basic-multiscene-v3"] &&
              [staticReply[@"sceneCapability"] isEqual:staticCapability] &&
              [staticReply[@"detail"] isEqual:@"declared-single-application-scene"],
              "the existing single static application configuration still round trips under v3");
        NSDictionary *filesCapability = NamedCapability(@"com.example.FixtureFiles",
            @[@"Files Browser", @"Files Document"], NO, 100);
        NSDictionary *mailCapability = NamedCapability(@"com.example.FixtureMail",
            @[@"Mail Viewer", @"Mail Compose", @"Mail Message", @"Mail Search"], YES, 100);
        for (NSDictionary *named in @[filesCapability, mailCapability]) {
            Check([named[@"policy"] isEqual:@"installed-basic-multiscene-v3"] &&
                  [named[@"reason"] isEqual:@"declared-named-application-configurations"] &&
                  [named[@"status"] isEqual:@"eligible"] &&
                  [PPOSceneCapabilityNormalize(named) isEqual:named],
                  "synthetic Files two-name and Mail four-name metadata produces a canonical v3 proof");
            NSData *namedData = PPOBridgeCapabilityResponseData(nonce, named, 102, NULL);
            NSDictionary *namedReply = PPOBridgeResponseFromData(namedData, nonce, NULL);
            Check(namedData.length <= PPOBridgeMessageLimit && namedReply.count == inspected.count &&
                  [namedReply[@"status"] isEqual:@"inspected"] &&
                  [namedReply[@"detail"] isEqual:@"declared-named-application-configurations"] &&
                  [namedReply[@"sceneCapability"] isEqual:named] &&
                  [namedReply[@"sceneCapability"] count] == 7 &&
                  [namedReply[@"sceneCapability"][@"observedUptime"] isEqual:@100],
                  "named JSON transport preserves exactly seven scalar fields, identifier, reason and observation time");
            Check(![[[NSString alloc] initWithData:namedData encoding:NSUTF8StringEncoding] containsString:@"Fixture.NamedSceneDelegate"] &&
                  ![[[NSString alloc] initWithData:namedData encoding:NSUTF8StringEncoding] containsString:@"UISceneConfigurationName"],
                  "configuration names and raw plist metadata never cross the protocol boundary");
            Check(PPOBridgeResponseFromData(namedData, other, NULL) == nil,
                  "named response decoding rejects a different nonce");
            Check(PPOSceneCapabilityFresh(namedReply[@"sceneCapability"], 100) &&
                  PPOSceneCapabilityFresh(namedReply[@"sceneCapability"], 105) &&
                  PPOSceneCapabilityFresh(namedReply[@"sceneCapability"], 99.9) &&
                  !PPOSceneCapabilityFresh(namedReply[@"sceneCapability"], 105.0001) &&
                  !PPOSceneCapabilityFresh(namedReply[@"sceneCapability"], 99.8999),
                  "named transport preserves freshness without making the decoder a clock authority");
        }
        NSDictionary *wrongIdentifier = NamedCapability(@"com.example.other",
            @[@"Other Main", @"Other Document"], NO, 100);
        NSDictionary *wrongIdentifierReply = PPOBridgeResponseFromData(
            PPOBridgeCapabilityResponseData(nonce, wrongIdentifier, 102, NULL), nonce, NULL);
        Check([wrongIdentifierReply[@"sceneCapability"][@"bundleIdentifier"] isEqual:@"com.example.other"] &&
              ![wrongIdentifierReply[@"sceneCapability"][@"bundleIdentifier"] isEqual:inspectionRequest[@"bundleIdentifier"]],
              "matching nonce preserves a different valid identifier so the caller can enforce selected-app binding");
        NSDictionary *staleReply = PPOBridgeResponseFromData(
            PPOBridgeCapabilityResponseData(nonce, filesCapability, 1000, NULL), nonce, NULL);
        Check([staleReply[@"sceneCapability"] isEqual:filesCapability] &&
              !PPOSceneCapabilityFresh(staleReply[@"sceneCapability"], 1000),
              "response uptime cannot freshen the separate observed capability clock");
        for (NSDictionary *current in @[capability, staticCapability, filesCapability, mailCapability])
            for (NSString *policy in @[@"installed-basic-multiscene-v1", @"installed-basic-multiscene-v2"]) {
                NSMutableDictionary *legacy = [current mutableCopy]; legacy[@"policy"] = policy;
                Check(PPOSceneCapabilityNormalize(legacy) == nil && !PPOSceneCapabilityFresh(legacy, 100),
                      "v1 and v2 descriptors are rejected without translation into v3 proofs");
                RejectCapability(nonce, inspected, legacy);
            }
        for (NSDictionary *fields in @[
                @{@"status": @"eligible", @"eligible": @NO},
                @{@"status": @"unknown", @"eligible": @NO},
                @{@"status": @"ineligible", @"eligible": @NO},
                @{@"status": @"unknown", @"eligible": @YES},
                @{@"status": @"ineligible", @"eligible": @YES},
                @{@"status": @"eligible", @"eligible": @1},
                @{@"status": @"eligible", @"eligible": @0}]) {
            for (NSDictionary *current in @[capability, staticCapability, filesCapability, mailCapability]) {
                NSMutableDictionary *bad = [current mutableCopy];
                [bad addEntriesFromDictionary:fields];
                RejectCapability(nonce, inspected, bad);
            }
        }
        for (NSString *reason in @[@"declared-programmatic-application-scene",
                @"declared-programmatic-application-scenes-extra", @"declared-named-application-configuration",
                @"Declared-named-application-configurations", @"declared-named-application-configurations "]) {
            NSMutableDictionary *bad = [capability mutableCopy]; bad[@"reason"] = reason;
            RejectCapability(nonce, inspected, bad);
        }
        Check(PPOBridgeResponseFromData(inspectedData, other, NULL) == nil,
              "inspection response still requires the caller's nonce");
        Check(PPOBridgeResponseData(nonce, @"inspected", nil, nil, 102, NULL) == nil,
              "generic encoder cannot emit inspected without a capability");
        Check(PPOBridgeCapabilityResponseData(nonce, nil, 102, NULL) == nil &&
              PPOBridgeCapabilityResponseData(nonce, @{}, 102, NULL) == nil,
              "inspection encoder rejects absent or malformed payloads");
        NSMutableDictionary *inspectionReply = [inspected mutableCopy];
        [inspectionReply removeObjectForKey:@"sceneCapability"];
        Check(PPOBridgeResponseFromData(JSON(inspectionReply), nonce, NULL) == nil,
              "inspected requires the normalized capability payload");
        inspectionReply = [inspected mutableCopy]; inspectionReply[@"status"] = @"accepted";
        Check(PPOBridgeResponseFromData(JSON(inspectionReply), nonce, NULL) == nil,
              "launch acceptance cannot carry a scene eligibility payload");
        inspectionReply = [inspected mutableCopy]; inspectionReply[@"appsCount"] = @1;
        Check(PPOBridgeResponseFromData(JSON(inspectionReply), nonce, NULL) == nil,
              "inspection does not overload inventory count fields");
        for (NSString *key in @[@"schema", @"policy", @"status", @"eligible", @"reason", @"bundleIdentifier", @"observedUptime"]) {
            NSMutableDictionary *bad = [capability mutableCopy];
            id replacement = @"invalid";
            if ([key isEqual:@"schema"] || [key isEqual:@"observedUptime"]) replacement = @YES;
            else if ([key isEqual:@"eligible"]) replacement = @1;
            else if ([key isEqual:@"bundleIdentifier"]) replacement = @"com.apple.springboard";
            bad[key] = replacement;
            Check(PPOBridgeCapabilityResponseData(nonce, bad, 102, NULL) == nil,
                  "capability fields are independently normalized before encoding");
            inspectionReply = [inspected mutableCopy]; inspectionReply[@"sceneCapability"] = bad;
            Check(PPOBridgeResponseFromData(JSON(inspectionReply), nonce, NULL) == nil,
                  "incoming capability fields cannot bypass normalization");
        }
        NSMutableDictionary *extraCapability = [capability mutableCopy];
        extraCapability[@"bundleURL"] = @"file:///private/fixture.app";
        inspectionReply = [inspected mutableCopy]; inspectionReply[@"sceneCapability"] = extraCapability;
        Check(PPOBridgeResponseFromData(JSON(inspectionReply), nonce, NULL) == nil,
              "capability transport forbids paths and arbitrary added keys");
        NSDictionary *unknown = PPOSceneCapabilityUnknown(@"com.example.window", @"file-unavailable", 100);
        NSDictionary *unknownReply = PPOBridgeResponseFromData(
            PPOBridgeCapabilityResponseData(nonce, unknown, 102, NULL), nonce, NULL);
        Check([unknownReply[@"status"] isEqual:@"inspected"] &&
              [unknownReply[@"sceneCapability"][@"status"] isEqual:@"unknown"] &&
              [unknownReply[@"sceneCapability"][@"eligible"] isEqual:@NO],
              "unavailable metadata remains a valid unknown observation, never launch acceptance");
        NSMutableString *mutableIdentifier = [@"com.example.window" mutableCopy];
        NSMutableDictionary *mutableCapability = [capability mutableCopy];
        mutableCapability[@"bundleIdentifier"] = mutableIdentifier;
        NSData *frozenData = PPOBridgeCapabilityResponseData(nonce, mutableCapability, 102, NULL);
        [mutableIdentifier setString:@"com.example.changed"];
        [mutableCapability removeAllObjects];
        NSDictionary *frozenReply = PPOBridgeResponseFromData(frozenData, nonce, NULL);
        Check([frozenReply[@"sceneCapability"][@"bundleIdentifier"] isEqual:@"com.example.window"] &&
              [frozenReply[@"sceneCapability"] count] == 7,
              "encoded and parsed eligibility is independent of later caller mutation");
        NSMutableString *namedIdentifier = [@"com.example.FixtureMail" mutableCopy];
        NSMutableString *namedReason = [@"declared-named-application-configurations" mutableCopy];
        NSMutableDictionary *mutableNamed = [mailCapability mutableCopy];
        mutableNamed[@"bundleIdentifier"] = namedIdentifier; mutableNamed[@"reason"] = namedReason;
        NSDictionary *normalizedNamed = PPOSceneCapabilityNormalize(mutableNamed);
        NSData *namedSnapshotData = PPOBridgeCapabilityResponseData(nonce, mutableNamed, 102, NULL);
        [namedIdentifier setString:@"com.example.changed"]; [namedReason setString:@"file-unavailable"];
        [mutableNamed removeAllObjects];
        NSDictionary *namedSnapshotReply = PPOBridgeResponseFromData(namedSnapshotData, nonce, NULL);
        Check([normalizedNamed isEqual:mailCapability] &&
              [namedSnapshotReply[@"sceneCapability"] isEqual:mailCapability],
              "normalization and JSON encoding snapshot mutable named descriptor scalars");
        printf("Bridge protocol tests passed: %u checks; policy v3 synthetic metadata, JSON transport and caller binding\n", checks);
    }
    return 0;
}
