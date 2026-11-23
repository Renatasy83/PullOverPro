// Normalize settings without rewriting the user's stored preference file.
// Foundation-only so the same implementation can be exercised on macOS.
#ifndef PO_PREFERENCES_VALIDATION_H
#define PO_PREFERENCES_VALIDATION_H
#import <Foundation/Foundation.h>
#include <math.h>

static inline BOOL POValidFavoriteIdentifier(id value) {
    if (![value isKindOfClass:[NSString class]] || [value length] == 0 || [value length] > 255) return NO;
    NSCharacterSet *invalid = [[NSCharacterSet characterSetWithCharactersInString:
        @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-"] invertedSet];
    return [value rangeOfCharacterFromSet:invalid].location == NSNotFound;
}

static inline NSDictionary *POValidatedPreferences(id saved, NSDictionary *defaults) {
    NSMutableDictionary *result = [defaults mutableCopy];
    if (![saved isKindOfClass:[NSDictionary class]]) return [result copy];
    for (NSString *key in @[@"enabled", @"hideInLandscape", @"leftHanded", @"darkHandle",
                            @"hideLabels", @"hapticFeedback", @"closeOnHome", @"hideHandle",
                            @"keyboardAvoiding", @"externalKeyboard", @"autoNub"]) {
        id value = saved[key];
        if ([value isKindOfClass:[NSNumber class]] && isfinite([value doubleValue])) result[key] = @([value boolValue]);
    }
    id style = saved[@"style"];
    if ([style isKindOfClass:[NSString class]] &&
        ([style isEqualToString:@"Recent Apps"] || [style isEqualToString:@"Favorites"])) result[@"style"] = [style copy];
    id favorites = saved[@"favorites"];
    if ([favorites isKindOfClass:[NSArray class]]) {
        NSMutableOrderedSet *valid = [NSMutableOrderedSet orderedSet];
        for (id identifier in favorites) if (POValidFavoriteIdentifier(identifier)) [valid addObject:[identifier copy]];
        result[@"favorites"] = [valid.array copy];
    }
    NSDictionary *limits = @{@"recentAppsCount": @[@1, @10], @"quickswitchScale": @[@1, @2.5], @"autoNub-time": @[@1, @30]};
    for (NSString *key in limits) {
        id value = saved[key];
        if (![value isKindOfClass:[NSNumber class]]) continue;
        double number = [value doubleValue];
        if (!isfinite(number)) continue;
        NSArray *range = limits[key];
        number = fmax([range[0] doubleValue], fmin([range[1] doubleValue], number));
        result[key] = [key isEqualToString:@"quickswitchScale"] ? @(number) : @((NSInteger)number);
    }
    return [result copy];
}
#endif
