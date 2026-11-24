// Added 2026-11-24 by Renatasy83: per-app floating-window positions; GPL-3.0.
#import "POWindowPositionStore.h"
#import "../Shared/POPreferencesValidation.h"

NSString *const POWindowPositionsKey = @"windowPositionsV1";

@implementation POWindowPositionStore

+ (POFloatingWindowPosition)positionForBundleIdentifier:(NSString *)bundleIdentifier
                                              defaults:(NSUserDefaults *)defaults {
    const POFloatingWindowPosition unspecified = {false, 0, 0};
    if (!defaults || !POValidFavoriteIdentifier(bundleIdentifier)) return unspecified;
    @synchronized (self) {
        id saved = [defaults objectForKey:POWindowPositionsKey];
        if (![saved isKindOfClass:[NSDictionary class]]) return unspecified;
        id value = saved[bundleIdentifier];
        if (![value isKindOfClass:[NSDictionary class]]) return unspecified;
        id x = value[@"x"], y = value[@"y"];
        if (![x isKindOfClass:[NSNumber class]] || ![y isKindOfClass:[NSNumber class]]) return unspecified;
        // Normalize only the returned value. Reads never migrate or rewrite
        // malformed data, another app's position, or future metadata.
        return POFloatingWindowNormalizePosition((POFloatingWindowPosition){true, [x doubleValue], [y doubleValue]});
    }
}

+ (BOOL)savePosition:(POFloatingWindowPosition)position
 forBundleIdentifier:(NSString *)bundleIdentifier defaults:(NSUserDefaults *)defaults {
    if (!defaults || !POValidFavoriteIdentifier(bundleIdentifier) || !position.specified ||
        !isfinite(position.x) || !isfinite(position.y)) return NO;
    POFloatingWindowPosition normalized = POFloatingWindowNormalizePosition(position);
    @synchronized (self) {
        id saved = [defaults objectForKey:POWindowPositionsKey];
        NSMutableDictionary *updated = [saved isKindOfClass:[NSDictionary class]]
            ? [saved mutableCopy] : [NSMutableDictionary new];
        id previous = updated[bundleIdentifier];
        NSMutableDictionary *entry = [previous isKindOfClass:[NSDictionary class]]
            ? [previous mutableCopy] : [NSMutableDictionary new];
        if ([entry[@"x"] isKindOfClass:[NSNumber class]] && [entry[@"y"] isKindOfClass:[NSNumber class]] &&
            [entry[@"x"] isEqualToNumber:@(normalized.x)] && [entry[@"y"] isEqualToNumber:@(normalized.y)]) return YES;
        entry[@"x"] = @(normalized.x);
        entry[@"y"] = @(normalized.y);
        // Preserve unknown fields in this entry, all sibling apps, and every
        // other defaults key, including the existing per-app size dictionary.
        updated[bundleIdentifier] = [entry copy];
        [defaults setObject:[updated copy] forKey:POWindowPositionsKey];
        return YES;
    }
}

+ (BOOL)resetPositionForBundleIdentifier:(NSString *)bundleIdentifier defaults:(NSUserDefaults *)defaults {
    if (!defaults || !POValidFavoriteIdentifier(bundleIdentifier)) return NO;
    @synchronized (self) {
        id saved = [defaults objectForKey:POWindowPositionsKey];
        if (![saved isKindOfClass:[NSDictionary class]] || !saved[bundleIdentifier]) return YES;
        NSMutableDictionary *updated = [saved mutableCopy];
        [updated removeObjectForKey:bundleIdentifier];
        [defaults setObject:[updated copy] forKey:POWindowPositionsKey];
        return YES;
    }
}

@end
