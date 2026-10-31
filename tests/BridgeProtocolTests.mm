#import "../PPOBridgeProtocol.h"
#import "../PPOSceneCapability.h"
#include <cmath>
#include <stdio.h>
#include <stdlib.h>

static void Check(BOOL condition, const char *name) {
    if (!condition) { fprintf(stderr, "FAIL: %s\n", name); exit(1); }
}
static NSData *JSON(id value) {
    return [NSJSONSerialization dataWithJSONObject:value options:0 error:NULL];
}
static NSDictionary *Capability(NSString *identifier, NSTimeInterval now) {
    NSDictionary *info = @{@"CFBundleIdentifier": identifier, @"CFBundlePackageType": @"APPL",
        @"UIDeviceFamily": @[@1], @"UIApplicationSceneManifest": @{
            @"UIApplicationSupportsMultipleScenes": @YES,
            @"UISceneConfigurations": @{@"UIWindowSceneSessionRoleApplication": @[
                @{@"UISceneDelegateClassName": @"FixtureSceneDelegate"}]}}};
    return PPOSceneCapabilityFromInfo(info, identifier, now);
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
        Check([capability[@"status"] isEqual:@"eligible"], "positive capability fixture satisfies data policy");
        NSData *inspectedData = PPOBridgeCapabilityResponseData(nonce, capability, 102, NULL);
        NSDictionary *inspected = PPOBridgeResponseFromData(inspectedData, nonce, NULL);
        Check(inspectedData.length <= PPOBridgeMessageLimit &&
              [inspected[@"status"] isEqual:@"inspected"] &&
              [inspected[@"sceneCapability"] isEqual:capability],
              "canonical capability is carried in a bounded nonce-bound response");
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
        printf("Bridge protocol tests passed\n");
    }
    return 0;
}
