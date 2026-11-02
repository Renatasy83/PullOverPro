#import "PPOUserPreferences.h"
#import <CoreFoundation/CoreFoundation.h>
#include <cmath>

NSString *const PPOUserPreferencesDomain = @"com.renatasy83.pulloverpro.settings";
NSString *const PPOUserPreferencesChangedNotification = @"com.renatasy83.pulloverpro.settings-changed";

static void PreferenceError(NSError **error, NSInteger code, NSString *description) {
    if (error) *error = [NSError errorWithDomain:@"PullOverPro.UserPreferences" code:code
        userInfo:@{NSLocalizedDescriptionKey: description}];
}

NSDictionary<NSString *, id> *PPOUserPreferencesDefaults(void) {
    return @{@"enabled": @YES, @"edge": @"right", @"handleYRatio": @0.5,
        @"handleSize": @34, @"handleOpacity": @0.85, @"windowSize": @3,
        @"appearance": @"system", @"autoHideHandle": @NO, @"autoHideDelay": @5,
        @"keepWindowOpen": @YES, @"rememberPosition": @YES,
        @"quickSwitchMode": @"recent", @"recentAppsCount": @5, @"quickSwitchScale": @1.75,
        @"hideLabels": @NO, @"hideInLandscape": @YES, @"hapticFeedback": @YES,
        @"keyboardAvoiding": @NO,
        @"recentIdentifiers": @[]};
}

static BOOL PreferenceIsBoolean(id value) {
    return [value isKindOfClass:NSNumber.class] &&
        CFGetTypeID((__bridge CFTypeRef)value) == CFBooleanGetTypeID();
}

static NSArray<NSString *> *PreferenceRecentIdentifiers(id value) {
    if (![value isKindOfClass:NSArray.class] || [(NSArray *)value count] > 16) return nil;
    NSMutableArray<NSString *> *identifiers = [NSMutableArray arrayWithCapacity:[value count]];
    NSMutableSet<NSString *> *seen = [NSMutableSet set];
    for (id raw in (NSArray *)value) {
        if (![raw isKindOfClass:NSString.class] || ![(NSString *)raw length] || [(NSString *)raw length] > 255)
            return nil;
        NSString *identifier = raw;
        for (NSUInteger index = 0; index < identifier.length; index++) {
            unichar c = [identifier characterAtIndex:index];
            BOOL alphanumeric = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9');
            if (!alphanumeric && (index == 0 || (c != '.' && c != '-'))) return nil;
        }
        if ([seen containsObject:identifier]) return nil;
        NSString *copied = [identifier copy];
        [seen addObject:copied]; [identifiers addObject:copied];
    }
    return [identifiers copy];
}

static id PreferenceScalar(NSString *key, id value, BOOL strict) {
    if ([key isEqual:@"recentIdentifiers"]) return PreferenceRecentIdentifiers(value);
    if ([key isEqual:@"enabled"] || [key isEqual:@"autoHideHandle"] ||
        [key isEqual:@"keepWindowOpen"] || [key isEqual:@"rememberPosition"] ||
        [key isEqual:@"hideLabels"] || [key isEqual:@"hideInLandscape"] || [key isEqual:@"hapticFeedback"] ||
        [key isEqual:@"keyboardAvoiding"])
        return PreferenceIsBoolean(value) ? ([value boolValue] ? @YES : @NO) : nil;
    if ([key isEqual:@"edge"] || [key isEqual:@"appearance"] || [key isEqual:@"quickSwitchMode"]) {
        if (![value isKindOfClass:NSString.class] || [(NSString *)value length] > 16) return nil;
        NSArray *allowed = [key isEqual:@"edge"] ? @[@"left", @"right"] :
            ([key isEqual:@"appearance"] ? @[@"system", @"light", @"dark"] : @[@"recent", @"favorites"]);
        return [allowed containsObject:value] ? [value copy] : nil;
    }
    if (![value isKindOfClass:NSNumber.class] || PreferenceIsBoolean(value)) return nil;
    double number = [(NSNumber *)value doubleValue];
    if (!std::isfinite(number)) return nil;
    double minimum = 0, maximum = 0;
    BOOL integer = NO;
    if ([key isEqual:@"handleYRatio"]) { minimum = 0; maximum = 1; }
    else if ([key isEqual:@"handleSize"]) { minimum = 32; maximum = 72; }
    else if ([key isEqual:@"handleOpacity"]) { minimum = 0.2; maximum = 1; }
    else if ([key isEqual:@"windowSize"]) { minimum = 0; maximum = 3; integer = YES; }
    else if ([key isEqual:@"autoHideDelay"]) { minimum = 1; maximum = 30; }
    else if ([key isEqual:@"recentAppsCount"]) { minimum = 1; maximum = 16; integer = YES; }
    else if ([key isEqual:@"quickSwitchScale"]) { minimum = 1; maximum = 3; }
    else return nil;
    if (integer && std::floor(number) != number) return nil;
    if (strict && (number < minimum || number > maximum)) return nil;
    number = std::fmax(minimum, std::fmin(maximum, number));
    return integer ? @((NSInteger)number) : @(number == 0 ? 0 : number);
}

NSDictionary<NSString *, id> *PPOUserPreferencesNormalize(id raw) {
    NSDictionary *defaults = PPOUserPreferencesDefaults();
    @try {
        if (![raw isKindOfClass:NSDictionary.class] || [(NSDictionary *)raw count] > 64) return defaults;
        NSMutableDictionary *normalized = [NSMutableDictionary dictionaryWithCapacity:defaults.count];
        for (NSString *key in defaults) {
            id scalar = PreferenceScalar(key, raw[key], NO);
            normalized[key] = scalar ?: defaults[key];
        }
        return [normalized copy];
    } @catch (NSException *exception) { (void)exception; return defaults; }
}

static NSDictionary *PreferenceChanges(id changes, NSError **error) {
    @try {
        NSDictionary *defaults = PPOUserPreferencesDefaults();
        if (![changes isKindOfClass:NSDictionary.class] || [(NSDictionary *)changes count] > defaults.count) {
            PreferenceError(error, 1, @"Invalid PPO preference changes"); return nil;
        }
        NSMutableDictionary *validated = [NSMutableDictionary dictionaryWithCapacity:[changes count]];
        for (id key in (NSDictionary *)changes) {
            if (![key isKindOfClass:NSString.class] || !defaults[key]) {
                PreferenceError(error, 1, @"Unknown PPO preference key"); return nil;
            }
            id scalar = PreferenceScalar(key, changes[key], YES);
            if (!scalar) { PreferenceError(error, 1, @"Invalid PPO preference value"); return nil; }
            validated[[key copy]] = scalar;
        }
        return [validated copy];
    } @catch (NSException *exception) {
        (void)exception; PreferenceError(error, 1, @"Invalid PPO preference changes"); return nil;
    }
}

NSDictionary<NSString *, id> *PPOUserPreferencesApplyingChanges(id current, id changes, NSError **error) {
    if (error) *error = nil;
    NSDictionary *validated = PreferenceChanges(changes, error);
    if (!validated) return nil;
    NSMutableDictionary *updated = [PPOUserPreferencesNormalize(current) mutableCopy];
    [updated addEntriesFromDictionary:validated];
    return [updated copy];
}

NSDictionary<NSString *, id> *PPOUserPreferencesRead(NSError **error) {
    if (error) *error = nil;
    @try {
        CFStringRef domain = (__bridge CFStringRef)PPOUserPreferencesDomain;
        if (!CFPreferencesSynchronize(domain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)) {
            PreferenceError(error, 2, @"Unable to synchronize PPO preferences");
            return PPOUserPreferencesDefaults();
        }
        NSArray *keys = PPOUserPreferencesDefaults().allKeys;
        CFDictionaryRef copied = CFPreferencesCopyMultiple((__bridge CFArrayRef)keys, domain,
            kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
        NSDictionary *raw = CFBridgingRelease(copied);
        return PPOUserPreferencesNormalize(raw);
    } @catch (NSException *exception) {
        (void)exception; PreferenceError(error, 2, @"Unable to read PPO preferences");
        return PPOUserPreferencesDefaults();
    }
}

BOOL PPOUserPreferencesWriteChanges(id changes, NSError **error) {
    if (error) *error = nil;
    NSDictionary *validated = PreferenceChanges(changes, error);
    if (!validated) return NO;
    if (!validated.count) return YES;
    @try {
        CFStringRef domain = (__bridge CFStringRef)PPOUserPreferencesDomain;
        CFPreferencesSetMultiple((__bridge CFDictionaryRef)validated, NULL, domain,
            kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
        if (!CFPreferencesSynchronize(domain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)) {
            PreferenceError(error, 2, @"Unable to save PPO preferences"); return NO;
        }
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
            (__bridge CFStringRef)PPOUserPreferencesChangedNotification, NULL, NULL, true);
        return YES;
    } @catch (NSException *exception) {
        (void)exception; PreferenceError(error, 2, @"Unable to save PPO preferences"); return NO;
    }
}
