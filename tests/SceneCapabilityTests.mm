#import "../PPOSceneCapability.h"
#import <CoreFoundation/CoreFoundation.h>
#include <cmath>
#include <stdio.h>
#include <stdlib.h>

// Pure plist/descriptor fixtures. No private APIs, real bundle reads or iOS UI.
static unsigned checks;
static NSString *const Identifier = @"com.example.application";
static void Check(BOOL condition, const char *message) {
    checks++;
    if (!condition) { fprintf(stderr, "FAIL: %s\n", message); exit(1); }
}
static NSMutableDictionary *Info(void) {
    return [@{@"CFBundleIdentifier": Identifier, @"CFBundlePackageType": @"APPL",
        @"UIDeviceFamily": @[@1, @2],
        @"UIApplicationSceneManifest": @{@"UIApplicationSupportsMultipleScenes": @YES,
            @"UISceneConfigurations": @{@"UIWindowSceneSessionRoleApplication":
                @[@{@"UISceneConfigurationName": @"Default Configuration",
                    @"UISceneDelegateClassName": @"Example.SceneDelegate"}]}}} mutableCopy];
}
static NSMutableDictionary *Manifest(NSMutableDictionary *info) {
    NSMutableDictionary *manifest = [info[@"UIApplicationSceneManifest"] mutableCopy];
    info[@"UIApplicationSceneManifest"] = manifest;
    return manifest;
}
static NSMutableDictionary *Roles(NSMutableDictionary *info) {
    NSMutableDictionary *manifest = Manifest(info);
    NSMutableDictionary *roles = [manifest[@"UISceneConfigurations"] mutableCopy];
    manifest[@"UISceneConfigurations"] = roles;
    return roles;
}
static NSDictionary *Read(id info) { return PPOSceneCapabilityFromInfo(info, Identifier, 100); }
static void Result(NSDictionary *value, NSString *status, NSString *reason) {
    Check(value != nil && value.count == 7, "capability contains only the normalized seven scalar fields");
    Check([value[@"status"] isEqual:status] && [value[@"reason"] isEqual:reason],
          "outcome distinguishes explicit negatives from unavailable or unsupported metadata");
    Check([value[@"bundleIdentifier"] isEqual:Identifier] &&
          [value[@"policy"] isEqual:@"installed-basic-multiscene-v1"] &&
          [value[@"schema"] isEqual:@1] && [value[@"observedUptime"] isEqual:@100],
          "result is bound to the requested app, fixed policy and injected observation time");
    Check(CFGetTypeID((__bridge CFTypeRef)value[@"eligible"]) == CFBooleanGetTypeID() &&
          [value[@"eligible"] boolValue] == [status isEqual:@"eligible"],
          "eligibility is a real Boolean consistent with the status");
    Check(PPOSceneCapabilityNormalize(value) != nil, "parser-generated results obey the wire contract");
    Check([NSJSONSerialization isValidJSONObject:value], "normalized diagnostics are safely serializable");
}
static void NormalizeField(NSString *field, NSArray *values) {
    for (id invalid in values) {
        NSMutableDictionary *value = [Read(Info()) mutableCopy];
        value[field] = invalid;
        Check(PPOSceneCapabilityNormalize(value) == nil, "malformed descriptor scalar is rejected");
    }
}
int main(void) {
    @autoreleasepool {
        for (NSString *valid in @[@"com.example.application", @"com.apple.mobilesafari",
                @"com.apple.reminders", @"com.apple.MobileAddressBook", @"org.Example.some-app_1"])
            Check(PPOSceneApplicationIdentifierAllowed(valid), "ordinary dotted identifiers preserve exact case");
        NSArray *invalidIdentifiers = @[@"", @"app", @"com..app", @".com.app", @"com.app.", @"-com.app",
            @"com.-app", @"com.app_", @"com/app", @"com app", @"com.example.é", @"../app.app",
            @"com.apple.springboard", @"COM.APPLE.SPRINGBOARD", @"com.apple.SpringBoard.extension",
            @"com.apple.backboardd", @"com.apple.runningboardd", @"com.apple.lsd", @"com.apple.uikitservices",
            @1, NSNull.null, @[]];
        for (id invalid in invalidIdentifiers) {
            Check(!PPOSceneApplicationIdentifierAllowed(invalid), "invalid and critical-process identifiers are denied");
            Check(PPOSceneCapabilityFromInfo(Info(), invalid, 100) == nil &&
                  PPOSceneCapabilityUnknown(invalid, @"file-unavailable", 100) == nil,
                  "invalid identifiers never receive an eligibility descriptor");
        }
        Check(!PPOSceneApplicationIdentifierAllowed(nil) && PPOSceneCapabilityFromInfo(Info(), nil, 100) == nil,
              "nil identifier is refused without reading metadata");
        NSString *limit = [@"com." stringByAppendingString:[@"a" stringByPaddingToLength:251
            withString:@"a" startingAtIndex:0]];
        Check(limit.length == 255 && PPOSceneApplicationIdentifierAllowed(limit) &&
              !PPOSceneApplicationIdentifierAllowed([limit stringByAppendingString:@"a"]), "identifier length is bounded");

        Result(Read(Info()), @"eligible", @"declared-single-application-scene");
        NSMutableDictionary *info = Info();
        info[@"UnrelatedUserInfo"] = @{@"nested": @[@{@"notForSerialization": @"private-value"}]};
        Result(Read(info), @"eligible", @"declared-single-application-scene");
        Check(![[Read(info) description] containsString:@"private-value"], "unrelated plist content is not published");
        for (id malformed in @[@[], @1, NSNull.null, @{}]) Result(Read(malformed), @"unknown", @"plist-invalid");
        Result(Read(nil), @"unknown", @"plist-invalid");
        info = Info(); info[@1] = @"invalid-key"; Result(Read(info), @"unknown", @"plist-invalid");
        info = Info();
        while (info.count < 256) info[[NSString stringWithFormat:@"Extra%lu", (unsigned long)info.count]] = @1;
        Result(Read(info), @"eligible", @"declared-single-application-scene");
        info[@"OneMore"] = @1; Result(Read(info), @"unknown", @"plist-invalid");

        for (id mismatch in @[@"com.example.other", @"COM.EXAMPLE.APPLICATION", @YES, NSNull.null]) {
            info = Info(); info[@"CFBundleIdentifier"] = mismatch; Result(Read(info), @"unknown", @"identifier-mismatch");
        }
        info = Info(); [info removeObjectForKey:@"CFBundleIdentifier"]; Result(Read(info), @"unknown", @"identifier-mismatch");
        info = Info(); info[@"CFBundlePackageType"] = @"XPC!"; Result(Read(info), @"ineligible", @"not-application");
        info = Info(); [info removeObjectForKey:@"CFBundlePackageType"]; Result(Read(info), @"unknown", @"manifest-unknown");
        info = Info(); info[@"CFBundlePackageType"] = @YES; Result(Read(info), @"unknown", @"manifest-unknown");
        info = Info(); info[@"NSExtension"] = @{}; Result(Read(info), @"ineligible", @"app-extension");
        info = Info(); info[@"NSExtension"] = NSNull.null; Result(Read(info), @"ineligible", @"app-extension");
        for (NSString *flag in @[@"LSBackgroundOnly", @"LSUIElement", @"UIBackgroundOnly"]) {
            info = Info(); info[flag] = @YES; Result(Read(info), @"ineligible", @"not-application");
            info = Info(); info[flag] = @NO; Result(Read(info), @"eligible", @"declared-single-application-scene");
            info = Info(); info[flag] = @1; Result(Read(info), @"unknown", @"manifest-unknown");
        }
        info = Info(); info[@"UIDeviceFamily"] = @[@2]; Result(Read(info), @"ineligible", @"not-iphone");
        for (id malformed in @[@[], @[@YES, @2], @[@1, @1], @[@1, @0.5], @[@(-1)],
                @[@(NAN)], @[@(INFINITY)], @[@"1"], @[@1, @2, @3, @4, @5, @6, @7, @8, @9], NSNull.null]) {
            info = Info(); info[@"UIDeviceFamily"] = malformed; Result(Read(info), @"unknown", @"manifest-unknown");
        }
        info = Info(); [info removeObjectForKey:@"UIDeviceFamily"]; Result(Read(info), @"unknown", @"manifest-unknown");
        info = Info(); info[@"UIDeviceFamily"] = @[@1.0, @2]; Result(Read(info), @"eligible", @"declared-single-application-scene");

        info = Info(); [info removeObjectForKey:@"UIApplicationSceneManifest"]; Result(Read(info), @"unknown", @"manifest-unknown");
        for (id malformed in @[@YES, @[], NSNull.null]) {
            info = Info(); info[@"UIApplicationSceneManifest"] = malformed; Result(Read(info), @"unknown", @"manifest-unknown");
        }
        for (id malformed in @[@1, @0, @"true", NSNull.null]) {
            info = Info(); Manifest(info)[@"UIApplicationSupportsMultipleScenes"] = malformed;
            Result(Read(info), @"unknown", @"manifest-unknown");
        }
        info = Info(); [Manifest(info) removeObjectForKey:@"UIApplicationSupportsMultipleScenes"];
        Result(Read(info), @"unknown", @"manifest-unknown");
        info = Info(); Manifest(info)[@"UIApplicationSupportsMultipleScenes"] = @NO;
        info[@"system-windows-secure"] = @YES;
        Result(Read(info), @"ineligible", @"multiple-scenes-disabled");
        info = Info(); info[@"system-windows-secure"] = @NO; Result(Read(info), @"unknown", @"manifest-complex");
        info = Info(); info[@"UnexpectedSCENEOption"] = @1; Result(Read(info), @"unknown", @"manifest-complex");
        info = Info(); Manifest(info)[@"UIApplicationSupportsTabbedScenes"] = @YES;
        Result(Read(info), @"unknown", @"manifest-complex");
        info = Info(); [Manifest(info) removeObjectForKey:@"UISceneConfigurations"];
        Result(Read(info), @"unknown", @"manifest-unknown");
        info = Info(); Manifest(info)[@"UISceneConfigurations"] = @[]; Result(Read(info), @"unknown", @"manifest-unknown");
        info = Info(); Manifest(info)[@"UISceneConfigurations"] = @{}; Result(Read(info), @"unknown", @"manifest-complex");
        info = Info(); Roles(info)[@"UIWindowSceneSessionRoleExternalDisplay"] = @[@{}];
        Result(Read(info), @"unknown", @"manifest-complex");
        for (id malformed in @[@[], @[@{}, @{}], @[@{}], @[@1], @[@{@"unknown": @"value"}],
                @[@{@"UISceneDelegateClassName": @[]}], @[@{@"UISceneClassName": @""}],
                @[@{@"UISceneClassName": [@"a" stringByPaddingToLength:257 withString:@"a" startingAtIndex:0]}],
                @YES, NSNull.null]) {
            info = Info(); Roles(info)[@"UIWindowSceneSessionRoleApplication"] = malformed;
            Result(Read(info), @"unknown", ([malformed isKindOfClass:NSArray.class] ? @"manifest-complex" : @"manifest-unknown"));
        }
        for (NSString *field in @[@"UISceneConfigurationName", @"UISceneClassName", @"UISceneDelegateClassName",
                @"UISceneStoryboardFile", @"UILaunchStoryboardName"]) {
            info = Info(); Roles(info)[@"UIWindowSceneSessionRoleApplication"] = @[@{field: @"Valid Configuration"}];
            Result(Read(info), @"eligible", @"declared-single-application-scene");
        }

        NSArray *unknownReasons = @[@"unsupported-framework", @"unsupported-abi", @"app-unavailable", @"ambiguous-app",
            @"no-bundle-url", @"bundle-unavailable", @"file-unavailable", @"file-invalid", @"file-too-large",
            @"plist-invalid", @"manifest-unknown", @"manifest-complex", @"identifier-mismatch",
            @"request-expired", @"service-unavailable"];
        for (NSString *reason in unknownReasons)
            Result(PPOSceneCapabilityUnknown(Identifier, reason, 100), @"unknown", reason);
        Check(PPOSceneCapabilityUnknown(Identifier, @"made-up", 100) == nil, "unknown reason cannot expand the protocol");
        for (NSNumber *badTime in @[@(-1), @(NAN), @(INFINITY)])
            Check(PPOSceneCapabilityFromInfo(Info(), Identifier, badTime.doubleValue) == nil &&
                  PPOSceneCapabilityUnknown(Identifier, @"file-unavailable", badTime.doubleValue) == nil,
                  "invalid observation clocks never produce descriptors");

        NormalizeField(@"schema", @[@YES, @0, @2, @0.5, @(NAN), @(INFINITY), @"1", NSNull.null]);
        NormalizeField(@"policy", @[@"unknown-v2", @1, NSNull.null]);
        NormalizeField(@"bundleIdentifier", @[@"com.other..app", @"com.apple.springboard", @1, NSNull.null]);
        NormalizeField(@"status", @[@"unknown", @"ineligible", @"other", @1, NSNull.null]);
        NormalizeField(@"eligible", @[@1, @0, @NO, @"true", NSNull.null]);
        NormalizeField(@"reason", @[@"manifest-unknown", @"not-application", @"other", @1, NSNull.null]);
        NormalizeField(@"observedUptime", @[@YES, @(-1), @(NAN), @(INFINITY), @"100", NSNull.null]);
        NSDictionary *valid = Read(Info());
        for (NSString *field in valid) {
            NSMutableDictionary *value = [valid mutableCopy]; [value removeObjectForKey:field];
            Check(PPOSceneCapabilityNormalize(value) == nil, "every normalized field is required");
        }
        NSMutableDictionary *extra = [valid mutableCopy]; extra[@"bundlePath"] = @"/private/app.app";
        Check(PPOSceneCapabilityNormalize(extra) == nil, "raw paths and extra metadata cannot enter the descriptor");
        Check(PPOSceneCapabilityNormalize(@[]) == nil && PPOSceneCapabilityNormalize(nil) == nil,
              "normalized root must be a dictionary");
        NSMutableDictionary *contradictory = [PPOSceneCapabilityUnknown(Identifier, @"file-unavailable", 100) mutableCopy];
        contradictory[@"eligible"] = @YES;
        Check(PPOSceneCapabilityNormalize(contradictory) == nil, "an unknown status cannot carry positive eligibility");
        contradictory = [valid mutableCopy]; contradictory[@"schema"] = @1.0;
        Check(PPOSceneCapabilityNormalize(contradictory) != nil, "integral numeric schema is distinct from a Boolean");

        NSMutableString *mutableIdentifier = [Identifier mutableCopy];
        NSMutableString *mutablePolicy = [@"installed-basic-multiscene-v1" mutableCopy];
        NSMutableString *mutableStatus = [@"eligible" mutableCopy];
        NSMutableString *mutableReason = [@"declared-single-application-scene" mutableCopy];
        NSMutableDictionary *caller = [valid mutableCopy];
        caller[@"bundleIdentifier"] = mutableIdentifier; caller[@"policy"] = mutablePolicy;
        caller[@"status"] = mutableStatus; caller[@"reason"] = mutableReason;
        NSDictionary *snapshot = PPOSceneCapabilityNormalize(caller);
        [mutableIdentifier setString:@"com.example.other"]; [mutablePolicy setString:@"other"];
        [mutableStatus setString:@"unknown"]; [mutableReason setString:@"file-unavailable"];
        caller[@"observedUptime"] = @1000;
        Result(snapshot, @"eligible", @"declared-single-application-scene");
        info = Info(); info[@"CFBundleIdentifier"] = [Identifier mutableCopy];
        NSDictionary *parsedSnapshot = Read(info);
        [(NSMutableString *)info[@"CFBundleIdentifier"] setString:@"com.example.changed"];
        Result(parsedSnapshot, @"eligible", @"declared-single-application-scene");

        Check(PPOSceneCapabilityFresh(valid, 100) && PPOSceneCapabilityFresh(valid, 105) &&
              PPOSceneCapabilityFresh(valid, 99.9), "freshness includes exact current, deadline and skew boundaries");
        Check(!PPOSceneCapabilityFresh(valid, 105.0001) && !PPOSceneCapabilityFresh(valid, 99.8999),
              "expired and excessively future observations are rejected");
        for (NSNumber *now in @[@(-1), @(NAN), @(INFINITY)])
            Check(!PPOSceneCapabilityFresh(valid, now.doubleValue), "invalid caller clocks cannot grant freshness");
        Check(!PPOSceneCapabilityFresh(extra, 100) && !PPOSceneCapabilityFresh(nil, 100),
              "freshness never bypasses normalization");
        printf("Scene capability tests passed: %u checks; pure metadata policy, not app admission\n", checks);
    }
    return 0;
}
