#import "PPOSceneCapability.h"
#import <CoreFoundation/CoreFoundation.h>
#include <cmath>

static NSString *const CapabilityPolicy = @"installed-basic-multiscene-v4";

static BOOL CapabilityASCIIAlphanumeric(unichar value) {
    return (value >= 'a' && value <= 'z') || (value >= 'A' && value <= 'Z') ||
        (value >= '0' && value <= '9');
}

BOOL PPOSceneApplicationIdentifierAllowed(id identifier) {
    if (![identifier isKindOfClass:NSString.class]) return NO;
    NSString *text = identifier;
    if (text.length < 3 || text.length > 255) return NO;
    BOOL dotted = NO, segmentStart = YES;
    for (NSUInteger i = 0; i < text.length; i++) {
        unichar value = [text characterAtIndex:i];
        if (value == '.') {
            if (segmentStart || !CapabilityASCIIAlphanumeric([text characterAtIndex:i - 1])) return NO;
            dotted = YES; segmentStart = YES;
        } else {
            if (!CapabilityASCIIAlphanumeric(value) && value != '_' && value != '-') return NO;
            if (segmentStart && !CapabilityASCIIAlphanumeric(value)) return NO;
            segmentStart = NO;
        }
    }
    if (!dotted || segmentStart || !CapabilityASCIIAlphanumeric([text characterAtIndex:text.length - 1])) return NO;
    NSString *folded = text.lowercaseString;
    for (NSString *process in @[@"com.apple.springboard", @"com.apple.backboardd",
            @"com.apple.runningboardd", @"com.apple.lsd", @"com.apple.uikitservices"]) {
        if ([folded isEqual:process] || [folded hasPrefix:[process stringByAppendingString:@"."]]) return NO;
    }
    return YES;
}

static BOOL CapabilityBoolean(id value) {
    return [value isKindOfClass:NSNumber.class] &&
        CFGetTypeID((__bridge CFTypeRef)value) == CFBooleanGetTypeID();
}
static BOOL CapabilityNumber(id value) {
    return [value isKindOfClass:NSNumber.class] && !CapabilityBoolean(value) &&
        std::isfinite([(NSNumber *)value doubleValue]);
}
static BOOL CapabilityTime(NSTimeInterval value) { return std::isfinite(value) && value >= 0; }
static BOOL CapabilityText(id value, NSUInteger limit) {
    return [value isKindOfClass:NSString.class] && [(NSString *)value length] > 0 &&
        [(NSString *)value length] <= limit;
}
static BOOL CapabilityDictionaryKeys(NSDictionary *value, NSArray<NSString *> *allowed) {
    for (id key in value) {
        if (![key isKindOfClass:NSString.class] || ![allowed containsObject:key]) return NO;
    }
    return YES;
}
static NSArray<NSString *> *CapabilityUnknownReasons(void) {
    return @[@"unsupported-framework", @"unsupported-abi", @"app-unavailable", @"ambiguous-app",
        @"no-bundle-url", @"bundle-unavailable", @"file-unavailable", @"file-invalid", @"file-too-large",
        @"plist-invalid", @"manifest-unknown", @"manifest-complex", @"identifier-mismatch",
        @"scene-manifest-missing", @"scene-manifest-invalid",
        @"multiple-scenes-undeclared", @"multiple-scenes-invalid", @"reviewed-messenger585-warm-trial",
        @"request-expired", @"service-unavailable"];
}
static NSArray<NSString *> *CapabilityIneligibleReasons(void) {
    return @[@"not-application", @"app-extension", @"not-iphone", @"multiple-scenes-disabled"];
}
static NSString *CapabilityCanonicalReason(id value, NSArray<NSString *> *reasons) {
    if (![value isKindOfClass:NSString.class]) return nil;
    NSUInteger index = [reasons indexOfObject:value];
    return index == NSNotFound ? nil : reasons[index];
}
static NSDictionary *CapabilityResult(NSString *identifier, NSString *status, NSString *reason,
    NSTimeInterval observedUptime) {
    // Rebuild scalar values instead of retaining mutable nested caller values.
    return @{@"schema": @1, @"policy": CapabilityPolicy,
        @"bundleIdentifier": [identifier copy], @"status": status,
        @"eligible": @([status isEqual:@"eligible"]), @"reason": reason,
        @"observedUptime": @(observedUptime)};
}

NSDictionary *PPOSceneCapabilityUnknown(NSString *identifier, NSString *reason, NSTimeInterval observedUptime) {
    if (!PPOSceneApplicationIdentifierAllowed(identifier) || !CapabilityTime(observedUptime)) return nil;
    if ([reason isEqual:@"reviewed-messenger585-warm-trial"] &&
        ![identifier isEqual:@"com.facebook.Messenger"]) return nil;
    NSString *canonical = CapabilityCanonicalReason(reason, CapabilityUnknownReasons());
    return canonical ? CapabilityResult(identifier, @"unknown", canonical, observedUptime) : nil;
}

NSDictionary *PPOSceneCapabilityNormalize(id value) {
    @try {
        if (![value isKindOfClass:NSDictionary.class]) return nil;
        NSDictionary *raw = value;
        if (raw.count != 7 || !CapabilityDictionaryKeys(raw, @[@"schema", @"policy", @"bundleIdentifier",
                @"status", @"eligible", @"reason", @"observedUptime"]) ||
            !CapabilityNumber(raw[@"schema"]) || [raw[@"schema"] doubleValue] != 1 ||
            ![raw[@"policy"] isKindOfClass:NSString.class] || ![raw[@"policy"] isEqual:CapabilityPolicy] ||
            !PPOSceneApplicationIdentifierAllowed(raw[@"bundleIdentifier"]) ||
            !CapabilityBoolean(raw[@"eligible"]) || !CapabilityNumber(raw[@"observedUptime"]) ||
            !CapabilityTime([raw[@"observedUptime"] doubleValue])) return nil;
        NSString *status = nil, *reason = nil;
        if ([raw[@"status"] isEqual:@"eligible"] && [raw[@"eligible"] boolValue]) {
            status = @"eligible";
            reason = CapabilityCanonicalReason(raw[@"reason"], @[@"declared-single-application-scene",
                @"declared-programmatic-application-scenes", @"declared-named-application-configurations",
                @"declared-messages-programmatic-scenes"]);
            if ([reason isEqual:@"declared-messages-programmatic-scenes"] &&
                ![raw[@"bundleIdentifier"] isEqual:@"com.apple.MobileSMS"]) return nil;
        } else if ([raw[@"status"] isEqual:@"ineligible"] && ![raw[@"eligible"] boolValue]) {
            status = @"ineligible";
            reason = CapabilityCanonicalReason(raw[@"reason"], CapabilityIneligibleReasons());
        } else if ([raw[@"status"] isEqual:@"unknown"] && ![raw[@"eligible"] boolValue]) {
            status = @"unknown";
            reason = CapabilityCanonicalReason(raw[@"reason"], CapabilityUnknownReasons());
        }
        if ([reason isEqual:@"reviewed-messenger585-warm-trial"] &&
            ![raw[@"bundleIdentifier"] isEqual:@"com.facebook.Messenger"]) return nil;
        if (!status || !reason) return nil;
        return CapabilityResult(raw[@"bundleIdentifier"], status, reason, [raw[@"observedUptime"] doubleValue]);
    } @catch (NSException *exception) { (void)exception; return nil; }
}

BOOL PPOSceneCapabilityFresh(id value, NSTimeInterval now) {
    NSDictionary *capability = PPOSceneCapabilityNormalize(value);
    if (!capability || !CapabilityTime(now)) return NO;
    NSTimeInterval observed = [capability[@"observedUptime"] doubleValue];
    return now >= observed - 0.1 && now <= observed + 5.0;
}

// Advisory exact-profile extension, not an app/framework trust or entitlement check.
// 23A355 MobileSMS declares only auxiliary roles; its inspected delegate builds
// the unnamed normal application configuration dynamically. No auxiliary role,
// class name or delegate is selected/instantiated by this data policy. The owner
// still enforces exact firmware, normal-role specification, selected identity,
// independent workspace/child/proxy binding, lifetime and cleanup at runtime.
static BOOL CapabilityMessagesProfile(NSDictionary *raw, NSDictionary *manifest) {
    NSDictionary *scalars = @{@"CFBundleIdentifier": @"com.apple.MobileSMS",
        @"CFBundleExecutable": @"MobileSMS", @"NSPrincipalClass": @"SMSApplication",
        @"CFBundleVersion": @"1448.100.1.2.102", @"CFBundleShortVersionString": @"26.0",
        @"DTPlatformVersion": @"26.0", @"DTPlatformBuild": @"23A345", @"DTSDKBuild": @"23A345"};
    for (NSString *key in scalars)
        if (!CapabilityText(raw[key], 256) || ![raw[key] isEqual:scalars[key]]) return NO;
    if (![raw[@"UIDeviceFamily"] isEqual:@[@1, @2]] ||
        !CapabilityBoolean(manifest[@"UIApplicationSupportsMultipleScenes"]) ||
        ![manifest[@"UIApplicationSupportsMultipleScenes"] boolValue] ||
        !CapabilityBoolean(manifest[@"UIApplicationSupportsSceneItemProviders"]) ||
        ![manifest[@"UIApplicationSupportsSceneItemProviders"] boolValue]) return NO;
    NSDictionary *expected = @{@"UIApplicationSupportsMultipleScenes": @YES,
        @"UIApplicationSupportsSceneItemProviders": @YES,
        @"UISceneConfigurations": @{
            @"CPTemplateApplicationSceneSessionRoleApplication": @[
                @{@"UISceneClassName": @"CPTemplateApplicationScene", @"UISceneConfigurationName": @"Messages-Car",
                  @"UISceneDelegateClassName": @"CKStarkManager"}],
            @"UIWindowSceneSessionRoleAssistiveAccessApplication": @[
                @{@"UISceneConfigurationName": @"Messages-ClarityUI", @"UISceneDelegateClassName": @"CKClarityUISceneDelegate"}],
            @"com.apple.PosterBoardUIServices.editor-overlay": @[
                @{@"UISceneConfigurationName": @"Messages-EditorOverlayConfiguration",
                  @"UISceneDelegateClassName": @"ChatKit.PosterEditorOverlaySceneDelegate"}]}};
    return [manifest isEqual:expected];
}

NSDictionary *PPOSceneCapabilityFromInfo(id info, NSString *identifier, NSTimeInterval observedUptime) {
    if (!PPOSceneApplicationIdentifierAllowed(identifier) || !CapabilityTime(observedUptime)) return nil;
    @try {
        if (![info isKindOfClass:NSDictionary.class] || [(NSDictionary *)info count] == 0 ||
            [(NSDictionary *)info count] > 256)
            return PPOSceneCapabilityUnknown(identifier, @"plist-invalid", observedUptime);
        NSDictionary *raw = info;
        for (id key in raw) {
            if (!CapabilityText(key, 256)) return PPOSceneCapabilityUnknown(identifier, @"plist-invalid", observedUptime);
        }
        if (!CapabilityText(raw[@"CFBundleIdentifier"], 255) || ![raw[@"CFBundleIdentifier"] isEqual:identifier])
            return PPOSceneCapabilityUnknown(identifier, @"identifier-mismatch", observedUptime);
        if (!CapabilityText(raw[@"CFBundlePackageType"], 16))
            return PPOSceneCapabilityUnknown(identifier, @"manifest-unknown", observedUptime);
        if (![raw[@"CFBundlePackageType"] isEqual:@"APPL"])
            return CapabilityResult(identifier, @"ineligible", @"not-application", observedUptime);
        if (raw[@"NSExtension"])
            return CapabilityResult(identifier, @"ineligible", @"app-extension", observedUptime);
        for (NSString *flag in @[@"LSBackgroundOnly", @"LSUIElement", @"UIBackgroundOnly"]) {
            id value = raw[flag];
            if (value && !CapabilityBoolean(value))
                return PPOSceneCapabilityUnknown(identifier, @"manifest-unknown", observedUptime);
            if (value && [value boolValue])
                return CapabilityResult(identifier, @"ineligible", @"not-application", observedUptime);
        }
        id families = raw[@"UIDeviceFamily"];
        if (![families isKindOfClass:NSArray.class] || [families count] == 0 || [families count] > 8)
            return PPOSceneCapabilityUnknown(identifier, @"manifest-unknown", observedUptime);
        BOOL iPhone = NO;
        NSMutableSet *seenFamilies = [NSMutableSet set];
        for (id family in (NSArray *)families) {
            if (!CapabilityNumber(family)) return PPOSceneCapabilityUnknown(identifier, @"manifest-unknown", observedUptime);
            double number = [family doubleValue];
            if (number < 1 || number > 255 || std::floor(number) != number || [seenFamilies containsObject:family])
                return PPOSceneCapabilityUnknown(identifier, @"manifest-unknown", observedUptime);
            [seenFamilies addObject:family];
            if (number == 1) iPhone = YES;
        }
        if (!iPhone) return CapabilityResult(identifier, @"ineligible", @"not-iphone", observedUptime);
        id manifest = raw[@"UIApplicationSceneManifest"];
        // Diagnostic distinctions only: none of these unknown states permits hosting.
        if (!manifest) return PPOSceneCapabilityUnknown(identifier, @"scene-manifest-missing", observedUptime);
        if (![manifest isKindOfClass:NSDictionary.class])
            return PPOSceneCapabilityUnknown(identifier, @"scene-manifest-invalid", observedUptime);
        id multiple = manifest[@"UIApplicationSupportsMultipleScenes"];
        if (!multiple) return PPOSceneCapabilityUnknown(identifier, @"multiple-scenes-undeclared", observedUptime);
        if (!CapabilityBoolean(multiple)) return PPOSceneCapabilityUnknown(identifier, @"multiple-scenes-invalid", observedUptime);
        if (![multiple boolValue]) return CapabilityResult(identifier, @"ineligible", @"multiple-scenes-disabled", observedUptime);

        // Explicit hard negatives above must not be hidden by an unknown layout.
        for (NSString *key in raw) {
            if (![key isEqual:@"UIApplicationSceneManifest"] &&
                ([key rangeOfString:@"scene" options:NSCaseInsensitiveSearch].location != NSNotFound ||
                 [key rangeOfString:@"window" options:NSCaseInsensitiveSearch].location != NSNotFound))
                return PPOSceneCapabilityUnknown(identifier, @"manifest-complex", observedUptime);
        }
        if (CapabilityMessagesProfile(raw, manifest))
            return CapabilityResult(identifier, @"eligible", @"declared-messages-programmatic-scenes", observedUptime);
        if ([(NSDictionary *)manifest count] > 2 || !CapabilityDictionaryKeys(manifest,
                @[@"UIApplicationSupportsMultipleScenes", @"UISceneConfigurations"]))
            return PPOSceneCapabilityUnknown(identifier, @"manifest-complex", observedUptime);
        // Exact23A355 UIKit accepts an unnamed configuration without a plist
        // configuration dictionary, then applies app/SwiftUI overrides or the
        // specification's minimum scene class. This shape is advisory eligibility:
        // normal app/client admission and the exact owned-scene guards still apply.
        // Explicit empty/null/malformed configurations are not this absent-key path.
        if ([(NSDictionary *)manifest count] == 1 && !manifest[@"UISceneConfigurations"])
            return CapabilityResult(identifier, @"eligible", @"declared-programmatic-application-scenes", observedUptime);
        id configurations = manifest[@"UISceneConfigurations"];
        if (![configurations isKindOfClass:NSDictionary.class])
            return PPOSceneCapabilityUnknown(identifier, @"manifest-unknown", observedUptime);
        if ([(NSDictionary *)configurations count] != 1 ||
            !CapabilityDictionaryKeys(configurations, @[@"UIWindowSceneSessionRoleApplication"]))
            return PPOSceneCapabilityUnknown(identifier, @"manifest-complex", observedUptime);
        id application = configurations[@"UIWindowSceneSessionRoleApplication"];
        if (![application isKindOfClass:NSArray.class])
            return PPOSceneCapabilityUnknown(identifier, @"manifest-unknown", observedUptime);
        NSUInteger configurationCount = [(NSArray *)application count];
        if (configurationCount == 0 || configurationCount > 8)
            return PPOSceneCapabilityUnknown(identifier, @"manifest-complex", observedUptime);
        BOOL namedMultiple = configurationCount > 1;
        NSArray<NSString *> *allowed = namedMultiple
            ? @[@"UISceneConfigurationName", @"UISceneClassName", @"UISceneDelegateClassName", @"UISceneStoryboardFile"]
            : @[@"UISceneConfigurationName", @"UISceneClassName", @"UISceneDelegateClassName",
                @"UISceneStoryboardFile", @"UILaunchStoryboardName"];
        NSMutableSet<NSString *> *names = [NSMutableSet set];
        // Validate every declaration. UIKit, rather than PPO, selects the
        // default/requested/app-delegate configuration during connection.
        for (id configuration in (NSArray *)application) {
            if (![configuration isKindOfClass:NSDictionary.class] || [(NSDictionary *)configuration count] == 0 ||
                [(NSDictionary *)configuration count] > 8 || !CapabilityDictionaryKeys(configuration, allowed))
                return PPOSceneCapabilityUnknown(identifier, @"manifest-complex", observedUptime);
            for (id key in configuration) {
                if (!CapabilityText(configuration[key], 256))
                    return PPOSceneCapabilityUnknown(identifier, @"manifest-complex", observedUptime);
            }
            if (namedMultiple) {
                NSString *name = configuration[@"UISceneConfigurationName"];
                if (!CapabilityText(name, 256) ||
                    [name stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].length == 0 ||
                    [names containsObject:name])
                    return PPOSceneCapabilityUnknown(identifier, @"manifest-complex", observedUptime);
                [names addObject:[name copy]];
            }
        }
        return CapabilityResult(identifier, @"eligible", namedMultiple
            ? @"declared-named-application-configurations" : @"declared-single-application-scene", observedUptime);
    } @catch (NSException *exception) {
        (void)exception; return PPOSceneCapabilityUnknown(identifier, @"plist-invalid", observedUptime);
    }
}

BOOL PPOSceneCapabilityIsMessengerTrial(id value) {
    NSDictionary *proof=PPOSceneCapabilityNormalize(value);
    return [proof[@"bundleIdentifier"] isEqual:@"com.facebook.Messenger"] &&
        [proof[@"status"] isEqual:@"unknown"] &&
        [proof[@"reason"] isEqual:@"reviewed-messenger585-warm-trial"];
}
NSDictionary *PPOSceneCapabilityFromInfoWithDigest(id info, NSString *identifier,
    NSTimeInterval observedUptime, NSString *sha256) {
    NSDictionary *base=PPOSceneCapabilityFromInfo(info,identifier,observedUptime);
    if (![base[@"status"] isEqual:@"unknown"] || ![base[@"reason"] isEqual:@"scene-manifest-missing"] ||
        ![identifier isEqual:@"com.facebook.Messenger"] ||
        ![sha256 isKindOfClass:NSString.class] ||
        ![sha256 isEqual:@"741517f9808a10ac225c6490d2af5bd835ff56b112464c5d53ce670d7ff92e30"])
        return base;
    NSDictionary *expected=@{@"CFBundleIdentifier":@"com.facebook.Messenger",@"CFBundleExecutable":@"Messenger",
        @"CFBundlePackageType":@"APPL",@"CFBundleVersion":@"1101076820",@"CFBundleShortVersionString":@"585.0.0"};
    for (NSString *key in expected) if (![info[key] isEqual:expected[key]]) return base;
    if (![info[@"UIDeviceFamily"] isEqual:@[@1,@2]]) return base;
    for (NSString *key in info) if ([key rangeOfString:@"scene" options:NSCaseInsensitiveSearch].location!=NSNotFound ||
        [key rangeOfString:@"window" options:NSCaseInsensitiveSearch].location!=NSNotFound) return base;
    return PPOSceneCapabilityUnknown(identifier,@"reviewed-messenger585-warm-trial",observedUptime);
}
