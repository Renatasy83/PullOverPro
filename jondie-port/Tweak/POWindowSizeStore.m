// Added 2026-11-24 by Renatasy83: per-app window size state; GPL-3.0.
#import "POWindowSizeStore.h"
#import "../Shared/POPreferencesValidation.h"
#import "../Shared/POWindowSizeGeometry.h"

NSString *const POWindowSizeFractionsKey = @"windowSizeFractionsV1";

@implementation POWindowSizeStore

+ (double)fractionForBundleIdentifier:(NSString *)bundleIdentifier defaults:(NSUserDefaults *)defaults {
    if (!defaults || !POValidFavoriteIdentifier(bundleIdentifier)) return POWindowSizeDefaultFraction;
    @synchronized (self) {
        id saved = [defaults objectForKey:POWindowSizeFractionsKey];
        if (![saved isKindOfClass:[NSDictionary class]]) return POWindowSizeDefaultFraction;
        id value = saved[bundleIdentifier];
        if (![value isKindOfClass:[NSNumber class]]) return POWindowSizeDefaultFraction;
        // Clamp finite legacy/corrupt values in memory. A read never rewrites
        // the dictionary, including values owned by another app or future code.
        return POWindowSizeClampFraction([value doubleValue]);
    }
}

+ (BOOL)saveFraction:(double)fraction forBundleIdentifier:(NSString *)bundleIdentifier
            defaults:(NSUserDefaults *)defaults {
    if (!defaults || !POValidFavoriteIdentifier(bundleIdentifier) || !isfinite(fraction)) return NO;
    double normalized = POWindowSizeClampFraction(fraction);
    @synchronized (self) {
        id saved = [defaults objectForKey:POWindowSizeFractionsKey];
        NSMutableDictionary *updated = [saved isKindOfClass:[NSDictionary class]]
            ? [saved mutableCopy] : [NSMutableDictionary new];
        id previous = updated[bundleIdentifier];
        if ([previous isKindOfClass:[NSNumber class]] && [previous isEqualToNumber:@(normalized)]) return YES;
        updated[bundleIdentifier] = @(normalized);
        // Preserve all sibling entries verbatim. Only this app's size changes;
        // unrelated handle position, selection and preferences are untouched.
        [defaults setObject:[updated copy] forKey:POWindowSizeFractionsKey];
        return YES;
    }
}

+ (BOOL)resetFractionForBundleIdentifier:(NSString *)bundleIdentifier defaults:(NSUserDefaults *)defaults {
    if (!defaults || !POValidFavoriteIdentifier(bundleIdentifier)) return NO;
    @synchronized (self) {
        id saved = [defaults objectForKey:POWindowSizeFractionsKey];
        if (![saved isKindOfClass:[NSDictionary class]] || !saved[bundleIdentifier]) return YES;
        NSMutableDictionary *updated = [saved mutableCopy];
        [updated removeObjectForKey:bundleIdentifier];
        [defaults setObject:[updated copy] forKey:POWindowSizeFractionsKey];
        return YES;
    }
}

@end
