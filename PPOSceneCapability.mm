#import "PPOSceneCapability.h"
#import <CoreFoundation/CoreFoundation.h>
#include <cmath>

static NSString *const CapabilityPolicy = @"installed-basic-multiscene-v1";

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
            reason = CapabilityCanonicalReason(raw[@"reason"], @[@"declared-single-application-scene"]);
        } else if ([raw[@"status"] isEqual:@"ineligible"] && ![raw[@"eligible"] boolValue]) {
            status = @"ineligible";
            reason = CapabilityCanonicalReason(raw[@"reason"], CapabilityIneligibleReasons());
        } else if ([raw[@"status"] isEqual:@"unknown"] && ![raw[@"eligible"] boolValue]) {
            status = @"unknown";
            reason = CapabilityCanonicalReason(raw[@"reason"], CapabilityUnknownReasons());
        }
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
        if (![manifest isKindOfClass:NSDictionary.class])
            return PPOSceneCapabilityUnknown(identifier, @"manifest-unknown", observedUptime);
        id multiple = manifest[@"UIApplicationSupportsMultipleScenes"];
        if (!CapabilityBoolean(multiple)) return PPOSceneCapabilityUnknown(identifier, @"manifest-unknown", observedUptime);
        if (![multiple boolValue]) return CapabilityResult(identifier, @"ineligible", @"multiple-scenes-disabled", observedUptime);

        // Explicit hard negatives above must not be hidden by an unknown layout.
        for (NSString *key in raw) {
            if (![key isEqual:@"UIApplicationSceneManifest"] &&
                ([key rangeOfString:@"scene" options:NSCaseInsensitiveSearch].location != NSNotFound ||
                 [key rangeOfString:@"window" options:NSCaseInsensitiveSearch].location != NSNotFound))
                return PPOSceneCapabilityUnknown(identifier, @"manifest-complex", observedUptime);
        }
        if ([(NSDictionary *)manifest count] > 2 || !CapabilityDictionaryKeys(manifest,
                @[@"UIApplicationSupportsMultipleScenes", @"UISceneConfigurations"]))
            return PPOSceneCapabilityUnknown(identifier, @"manifest-complex", observedUptime);
        id configurations = manifest[@"UISceneConfigurations"];
        if (![configurations isKindOfClass:NSDictionary.class])
            return PPOSceneCapabilityUnknown(identifier, @"manifest-unknown", observedUptime);
        if ([(NSDictionary *)configurations count] != 1 ||
            !CapabilityDictionaryKeys(configurations, @[@"UIWindowSceneSessionRoleApplication"]))
            return PPOSceneCapabilityUnknown(identifier, @"manifest-complex", observedUptime);
        id application = configurations[@"UIWindowSceneSessionRoleApplication"];
        if (![application isKindOfClass:NSArray.class])
            return PPOSceneCapabilityUnknown(identifier, @"manifest-unknown", observedUptime);
        if ([(NSArray *)application count] != 1)
            return PPOSceneCapabilityUnknown(identifier, @"manifest-complex", observedUptime);
        id configuration = [(NSArray *)application objectAtIndex:0];
        if (![configuration isKindOfClass:NSDictionary.class] || [(NSDictionary *)configuration count] == 0 ||
            [(NSDictionary *)configuration count] > 8 || !CapabilityDictionaryKeys(configuration,
                @[@"UISceneConfigurationName", @"UISceneClassName", @"UISceneDelegateClassName",
                  @"UISceneStoryboardFile", @"UILaunchStoryboardName"]))
            return PPOSceneCapabilityUnknown(identifier, @"manifest-complex", observedUptime);
        for (id key in configuration) {
            if (!CapabilityText(configuration[key], 256))
                return PPOSceneCapabilityUnknown(identifier, @"manifest-complex", observedUptime);
        }
        return CapabilityResult(identifier, @"eligible", @"declared-single-application-scene", observedUptime);
    } @catch (NSException *exception) {
        (void)exception; return PPOSceneCapabilityUnknown(identifier, @"plist-invalid", observedUptime);
    }
}
