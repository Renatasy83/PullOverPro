#import "../Tweak/POWindowSizeStore.h"
#import <dispatch/dispatch.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

static NSUInteger checks;
#define CHECK(condition) do { checks++; if (!(condition)) { \
    fprintf(stderr, "FAIL %s:%d: %s\n", __FILE__, __LINE__, #condition); abort(); \
} } while (0)

static void Near(double actual, double expected) { CHECK(fabs(actual - expected) < 0.0000001); }

int main(void) {
    @autoreleasepool {
        NSString *suite = [@"com.renatasy83.pulloverpro.window-size-tests." stringByAppendingString:NSUUID.UUID.UUIDString];
        NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:suite];
        CHECK(defaults != nil);
        NSString *a = @"com.apple.mobilesafari", *b = @"com.facebook.Messenger";
        @try {
            [defaults setObject:@"{0, 120}" forKey:@"handlePoint"];
            [defaults setObject:b forKey:@"lastPinnedBundleId"];
            [defaults setObject:@{@"enabled": @YES, @"favorites": @[a, b]} forKey:@"unrelatedSettings"];
            Near([POWindowSizeStore fractionForBundleIdentifier:a defaults:defaults], 1.0);
            CHECK([defaults objectForKey:POWindowSizeFractionsKey] == nil);

            CHECK([POWindowSizeStore saveFraction:0.72 forBundleIdentifier:a defaults:defaults]);
            CHECK([POWindowSizeStore saveFraction:0.91 forBundleIdentifier:b defaults:defaults]);
            Near([POWindowSizeStore fractionForBundleIdentifier:a defaults:defaults], 0.72);
            Near([POWindowSizeStore fractionForBundleIdentifier:b defaults:defaults], 0.91);
            NSUserDefaults *reopened = [[NSUserDefaults alloc] initWithSuiteName:suite];
            Near([POWindowSizeStore fractionForBundleIdentifier:a defaults:reopened], 0.72);
            Near([POWindowSizeStore fractionForBundleIdentifier:b defaults:reopened], 0.91);

            NSDictionary *unknownSibling = @{@"futureSchema": @2, @"notes": @[@"preserve"]};
            NSDictionary *snapshot = @{a: @0.72, b: @0.91, @"future.metadata": unknownSibling};
            [defaults setObject:snapshot forKey:POWindowSizeFractionsKey];
            CHECK([POWindowSizeStore saveFraction:0.82 forBundleIdentifier:a defaults:defaults]);
            NSDictionary *after = [defaults dictionaryForKey:POWindowSizeFractionsKey];
            CHECK([after[@"future.metadata"] isEqual:unknownSibling]);
            Near([after[b] doubleValue], 0.91);
            Near([after[a] doubleValue], 0.82);
            CHECK([POWindowSizeStore resetFractionForBundleIdentifier:a defaults:defaults]);
            Near([POWindowSizeStore fractionForBundleIdentifier:a defaults:defaults], 1.0);
            Near([POWindowSizeStore fractionForBundleIdentifier:b defaults:defaults], 0.91);
            after = [defaults dictionaryForKey:POWindowSizeFractionsKey];
            CHECK([after[@"future.metadata"] isEqual:unknownSibling]);
            CHECK([POWindowSizeStore resetFractionForBundleIdentifier:a defaults:defaults]);
            CHECK([[defaults dictionaryForKey:POWindowSizeFractionsKey] isEqual:after]);

            for (id malformed in @[@"wrong schema", @[], @3]) {
                [defaults setObject:malformed forKey:POWindowSizeFractionsKey];
                Near([POWindowSizeStore fractionForBundleIdentifier:a defaults:defaults], 1.0);
                CHECK([[defaults objectForKey:POWindowSizeFractionsKey] isEqual:malformed]);
                CHECK([POWindowSizeStore resetFractionForBundleIdentifier:a defaults:defaults]);
                CHECK([[defaults objectForKey:POWindowSizeFractionsKey] isEqual:malformed]);
            }
            CHECK([POWindowSizeStore saveFraction:0.63 forBundleIdentifier:a defaults:defaults]);
            Near([POWindowSizeStore fractionForBundleIdentifier:a defaults:defaults], 0.63);

            for (id malformed in @[@"0.7", @[], @{}, @(NAN), @(INFINITY)]) {
                NSDictionary *raw = @{a: malformed, b: @0.88};
                [defaults setObject:raw forKey:POWindowSizeFractionsKey];
                Near([POWindowSizeStore fractionForBundleIdentifier:a defaults:defaults], 1.0);
                Near([POWindowSizeStore fractionForBundleIdentifier:b defaults:defaults], 0.88);
                NSDictionary *afterRead = [defaults dictionaryForKey:POWindowSizeFractionsKey];
                CHECK(afterRead.count == 2);
                Near([afterRead[b] doubleValue], 0.88);
                if ([malformed isKindOfClass:[NSNumber class]] && isnan([malformed doubleValue])) {
                    CHECK([afterRead[a] isKindOfClass:[NSNumber class]] && isnan([afterRead[a] doubleValue]));
                } else {
                    CHECK([afterRead[a] isEqual:malformed]);
                }
            }
            [defaults setObject:@{a: @(-100), b: @100} forKey:POWindowSizeFractionsKey];
            NSDictionary *rawLimits = [defaults dictionaryForKey:POWindowSizeFractionsKey];
            Near([POWindowSizeStore fractionForBundleIdentifier:a defaults:defaults], 0.55);
            Near([POWindowSizeStore fractionForBundleIdentifier:b defaults:defaults], 1.0);
            CHECK([[defaults dictionaryForKey:POWindowSizeFractionsKey] isEqual:rawLimits]);
            CHECK([POWindowSizeStore saveFraction:-20 forBundleIdentifier:a defaults:defaults]);
            CHECK([POWindowSizeStore saveFraction:20 forBundleIdentifier:b defaults:defaults]);
            Near([[defaults dictionaryForKey:POWindowSizeFractionsKey][a] doubleValue], 0.55);
            Near([[defaults dictionaryForKey:POWindowSizeFractionsKey][b] doubleValue], 1.0);

            NSDictionary *validBefore = [defaults dictionaryForKey:POWindowSizeFractionsKey];
            CHECK(![POWindowSizeStore saveFraction:NAN forBundleIdentifier:a defaults:defaults]);
            CHECK(![POWindowSizeStore saveFraction:INFINITY forBundleIdentifier:a defaults:defaults]);
            CHECK(![POWindowSizeStore saveFraction:0.7 forBundleIdentifier:nil defaults:defaults]);
            CHECK(![POWindowSizeStore resetFractionForBundleIdentifier:nil defaults:defaults]);
            for (NSString *invalid in @[@"", @"bad/id", @"com.bad id",
                [@"x" stringByPaddingToLength:256 withString:@"x" startingAtIndex:0]]) {
                Near([POWindowSizeStore fractionForBundleIdentifier:invalid defaults:defaults], 1.0);
                CHECK(![POWindowSizeStore saveFraction:0.7 forBundleIdentifier:invalid defaults:defaults]);
                CHECK(![POWindowSizeStore resetFractionForBundleIdentifier:invalid defaults:defaults]);
            }
            CHECK([[defaults dictionaryForKey:POWindowSizeFractionsKey] isEqual:validBefore]);
            Near([POWindowSizeStore fractionForBundleIdentifier:a defaults:nil], 1.0);
            CHECK(![POWindowSizeStore saveFraction:0.7 forBundleIdentifier:a defaults:nil]);
            CHECK(![POWindowSizeStore resetFractionForBundleIdentifier:a defaults:nil]);

            // Concurrent updates through the real store must preserve siblings.
            dispatch_apply(32, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^(size_t index) {
                @autoreleasepool {
                    NSString *identifier = [NSString stringWithFormat:@"com.example.parallel-%zu", index];
                    if (![POWindowSizeStore saveFraction:0.60 + (double)index / 100.0
                        forBundleIdentifier:identifier defaults:defaults]) abort();
                }
            });
            for (NSUInteger index = 0; index < 32; index++) {
                NSString *identifier = [NSString stringWithFormat:@"com.example.parallel-%lu", (unsigned long)index];
                Near([POWindowSizeStore fractionForBundleIdentifier:identifier defaults:defaults], 0.60 + (double)index / 100.0);
            }
            [defaults setObject:@{a: @0.7} forKey:POWindowSizeFractionsKey];
            CHECK([POWindowSizeStore resetFractionForBundleIdentifier:a defaults:defaults]);
            CHECK([[defaults dictionaryForKey:POWindowSizeFractionsKey] count] == 0);
            Near([POWindowSizeStore fractionForBundleIdentifier:a defaults:defaults], 1.0);
            CHECK([[defaults stringForKey:@"handlePoint"] isEqual:@"{0, 120}"]);
            CHECK([[defaults stringForKey:@"lastPinnedBundleId"] isEqual:b]);
            CHECK(([[defaults dictionaryForKey:@"unrelatedSettings"] isEqual:@{@"enabled": @YES, @"favorites": @[a, b]}]));
            printf("WindowSizeStore: %lu checks passed (actual Foundation store; isolated defaults suite).\n", (unsigned long)checks);
        } @finally {
            // Test-only domain, uniquely named above; no production/user domain.
            [defaults removePersistentDomainForName:suite];
        }
    }
    return 0;
}
