#import "../Tweak/POWindowPositionStore.h"
#import <dispatch/dispatch.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

static NSUInteger checks;
#define CHECK(condition) do { checks++; if (!(condition)) { \
    fprintf(stderr, "FAIL %s:%d: %s\n", __FILE__, __LINE__, #condition); abort(); \
} } while (0)

static POFloatingWindowPosition Position(double x, double y) {
    return (POFloatingWindowPosition){true, x, y};
}
static POFloatingWindowPosition Unspecified(void) {
    return (POFloatingWindowPosition){false, 0.3, 0.4};
}
static void NearPosition(POFloatingWindowPosition actual, double x, double y) {
    CHECK(actual.specified);
    CHECK(fabs(actual.x - x) < 0.0000001);
    CHECK(fabs(actual.y - y) < 0.0000001);
}
static void NoPosition(POFloatingWindowPosition actual) {
    CHECK(!actual.specified);
    CHECK(actual.x == 0 && actual.y == 0);
}

int main(void) {
    @autoreleasepool {
        NSString *suite = [@"com.renatasy83.pulloverpro.window-position-tests."
            stringByAppendingString:NSUUID.UUID.UUIDString];
        NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:suite];
        CHECK(defaults != nil);
        NSString *a = @"com.apple.mobilesafari", *b = @"com.facebook.Messenger";
        NSDictionary *sizes = @{a: @0.63, b: @0.91};
        NSDictionary *global = @{@"enabled": @YES, @"favorites": @[a, b]};
        @try {
            [defaults setObject:sizes forKey:@"windowSizeFractionsV1"];
            [defaults setObject:@"{0, 120}" forKey:@"handlePoint"];
            [defaults setObject:b forKey:@"lastPinnedBundleId"];
            [defaults setObject:global forKey:@"unrelatedSettings"];
            NoPosition([POWindowPositionStore positionForBundleIdentifier:a defaults:defaults]);
            CHECK([defaults objectForKey:POWindowPositionsKey] == nil);

            CHECK([POWindowPositionStore savePosition:Position(0.2, 0.7) forBundleIdentifier:a defaults:defaults]);
            CHECK([POWindowPositionStore savePosition:Position(0.85, 0.1) forBundleIdentifier:b defaults:defaults]);
            NearPosition([POWindowPositionStore positionForBundleIdentifier:a defaults:defaults], 0.2, 0.7);
            NearPosition([POWindowPositionStore positionForBundleIdentifier:b defaults:defaults], 0.85, 0.1);
            NSUserDefaults *reopened = [[NSUserDefaults alloc] initWithSuiteName:suite];
            NearPosition([POWindowPositionStore positionForBundleIdentifier:a defaults:reopened], 0.2, 0.7);
            NearPosition([POWindowPositionStore positionForBundleIdentifier:b defaults:reopened], 0.85, 0.1);

            NSDictionary *future = @{@"schema": @2, @"notes": @[@"preserve"]};
            NSDictionary *snapshot = @{a: @{@"x": @0.2, @"y": @0.7, @"future": future},
                                       b: @{@"x": @0.85, @"y": @0.1}, @"future.metadata": future};
            [defaults setObject:snapshot forKey:POWindowPositionsKey];
            CHECK([POWindowPositionStore savePosition:Position(0.4, 0.6) forBundleIdentifier:a defaults:defaults]);
            NSDictionary *after = [defaults dictionaryForKey:POWindowPositionsKey];
            CHECK([after[@"future.metadata"] isEqual:future]);
            CHECK([after[a][@"future"] isEqual:future]);
            CHECK([after[b] isEqual:snapshot[b]]);
            NearPosition([POWindowPositionStore positionForBundleIdentifier:a defaults:defaults], 0.4, 0.6);
            NSDictionary *afterSave = after;
            CHECK([POWindowPositionStore savePosition:Position(0.4, 0.6) forBundleIdentifier:a defaults:defaults]);
            CHECK([[defaults dictionaryForKey:POWindowPositionsKey] isEqual:afterSave]);

            CHECK([POWindowPositionStore resetPositionForBundleIdentifier:a defaults:defaults]);
            NoPosition([POWindowPositionStore positionForBundleIdentifier:a defaults:defaults]);
            NearPosition([POWindowPositionStore positionForBundleIdentifier:b defaults:defaults], 0.85, 0.1);
            after = [defaults dictionaryForKey:POWindowPositionsKey];
            CHECK([after[@"future.metadata"] isEqual:future]);
            CHECK([POWindowPositionStore resetPositionForBundleIdentifier:a defaults:defaults]);
            CHECK([[defaults dictionaryForKey:POWindowPositionsKey] isEqual:after]);

            // Whole-key corruption has no side effect on read or a no-op reset.
            for (id malformed in @[@"wrong schema", @[], @3]) {
                [defaults setObject:malformed forKey:POWindowPositionsKey];
                NoPosition([POWindowPositionStore positionForBundleIdentifier:a defaults:defaults]);
                CHECK([[defaults objectForKey:POWindowPositionsKey] isEqual:malformed]);
                CHECK([POWindowPositionStore resetPositionForBundleIdentifier:a defaults:defaults]);
                CHECK([[defaults objectForKey:POWindowPositionsKey] isEqual:malformed]);
            }
            CHECK([POWindowPositionStore savePosition:Position(0.3, 0.4) forBundleIdentifier:a defaults:defaults]);
            NearPosition([POWindowPositionStore positionForBundleIdentifier:a defaults:defaults], 0.3, 0.4);

            NSArray *malformedEntries = @[@"0.5", @[], @{}, @{@"x": @0.5}, @{@"y": @0.5},
                @{@"x": @"0.5", @"y": @0.5}, @{@"x": @0.5, @"y": @[]},
                @{@"x": @(NAN), @"y": @0.5}, @{@"x": @0.5, @"y": @(INFINITY)}];
            for (id malformed in malformedEntries) {
                NSDictionary *raw = @{a: malformed, b: @{@"x": @0.25, @"y": @0.75}, @"future.metadata": future};
                [defaults setObject:raw forKey:POWindowPositionsKey];
                NoPosition([POWindowPositionStore positionForBundleIdentifier:a defaults:defaults]);
                NearPosition([POWindowPositionStore positionForBundleIdentifier:b defaults:defaults], 0.25, 0.75);
                NSDictionary *afterRead = [defaults dictionaryForKey:POWindowPositionsKey];
                CHECK(afterRead.count == 3 && [afterRead[b] isEqual:raw[b]]);
                CHECK([afterRead[@"future.metadata"] isEqual:future]);
                if ([malformed isKindOfClass:[NSDictionary class]] &&
                    [malformed[@"x"] isKindOfClass:[NSNumber class]] && isnan([malformed[@"x"] doubleValue])) {
                    CHECK(isnan([afterRead[a][@"x"] doubleValue]));
                    CHECK([afterRead[a][@"y"] isEqual:malformed[@"y"]]);
                } else CHECK([afterRead[a] isEqual:malformed]);
            }

            NSDictionary *rawLimits = @{a: @{@"x": @(-100), @"y": @100},
                                        b: @{@"x": @1, @"y": @0}};
            [defaults setObject:rawLimits forKey:POWindowPositionsKey];
            NearPosition([POWindowPositionStore positionForBundleIdentifier:a defaults:defaults], 0, 1);
            CHECK([[defaults dictionaryForKey:POWindowPositionsKey] isEqual:rawLimits]);
            CHECK([POWindowPositionStore savePosition:Position(-20, 20) forBundleIdentifier:a defaults:defaults]);
            NearPosition([POWindowPositionStore positionForBundleIdentifier:a defaults:defaults], 0, 1);
            CHECK([POWindowPositionStore savePosition:Position(1, 0) forBundleIdentifier:a defaults:defaults]);
            NearPosition([POWindowPositionStore positionForBundleIdentifier:a defaults:defaults], 1, 0);

            NSDictionary *validBefore = [defaults dictionaryForKey:POWindowPositionsKey];
            CHECK(![POWindowPositionStore savePosition:Unspecified() forBundleIdentifier:a defaults:defaults]);
            CHECK(![POWindowPositionStore savePosition:Position(NAN, 0.5) forBundleIdentifier:a defaults:defaults]);
            CHECK(![POWindowPositionStore savePosition:Position(0.5, NAN) forBundleIdentifier:a defaults:defaults]);
            CHECK(![POWindowPositionStore savePosition:Position(INFINITY, 0.5) forBundleIdentifier:a defaults:defaults]);
            CHECK(![POWindowPositionStore savePosition:Position(0.5, -INFINITY) forBundleIdentifier:a defaults:defaults]);
            CHECK(![POWindowPositionStore savePosition:Position(0.5, 0.5) forBundleIdentifier:nil defaults:defaults]);
            CHECK(![POWindowPositionStore resetPositionForBundleIdentifier:nil defaults:defaults]);
            for (NSString *invalid in @[@"", @"bad/id", @"com.bad id",
                [@"x" stringByPaddingToLength:256 withString:@"x" startingAtIndex:0]]) {
                NoPosition([POWindowPositionStore positionForBundleIdentifier:invalid defaults:defaults]);
                CHECK(![POWindowPositionStore savePosition:Position(0.5, 0.5) forBundleIdentifier:invalid defaults:defaults]);
                CHECK(![POWindowPositionStore resetPositionForBundleIdentifier:invalid defaults:defaults]);
            }
            CHECK([[defaults dictionaryForKey:POWindowPositionsKey] isEqual:validBefore]);
            NoPosition([POWindowPositionStore positionForBundleIdentifier:a defaults:nil]);
            CHECK(![POWindowPositionStore savePosition:Position(0.5, 0.5) forBundleIdentifier:a defaults:nil]);
            CHECK(![POWindowPositionStore resetPositionForBundleIdentifier:a defaults:nil]);

            dispatch_apply(32, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^(size_t index) {
                @autoreleasepool {
                    NSString *identifier = [NSString stringWithFormat:@"com.example.position-%zu", index];
                    if (![POWindowPositionStore savePosition:Position((double)index / 31.0, 1.0 - (double)index / 31.0)
                        forBundleIdentifier:identifier defaults:defaults]) abort();
                }
            });
            for (NSUInteger index = 0; index < 32; index++) {
                NSString *identifier = [NSString stringWithFormat:@"com.example.position-%lu", (unsigned long)index];
                NearPosition([POWindowPositionStore positionForBundleIdentifier:identifier defaults:defaults],
                             (double)index / 31.0, 1.0 - (double)index / 31.0);
            }
            CHECK([[defaults dictionaryForKey:@"windowSizeFractionsV1"] isEqual:sizes]);
            CHECK([[defaults stringForKey:@"handlePoint"] isEqual:@"{0, 120}"]);
            CHECK([[defaults stringForKey:@"lastPinnedBundleId"] isEqual:b]);
            CHECK([[defaults dictionaryForKey:@"unrelatedSettings"] isEqual:global]);

            [defaults setObject:@{a: @{@"x": @0.3, @"y": @0.4}} forKey:POWindowPositionsKey];
            CHECK([POWindowPositionStore resetPositionForBundleIdentifier:a defaults:defaults]);
            CHECK([[defaults dictionaryForKey:POWindowPositionsKey] count] == 0);
            NoPosition([POWindowPositionStore positionForBundleIdentifier:a defaults:defaults]);
            printf("WindowPositionStore: %lu checks passed (actual Foundation store; isolated defaults suite).\n", (unsigned long)checks);
        } @finally {
            // This domain is generated above exclusively for this fixture.
            [defaults removePersistentDomainForName:suite];
        }
    }
    return 0;
}
