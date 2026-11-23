#import "../Shared/POPreferencesValidation.h"
#include <assert.h>
#include <stdio.h>

int main(void) {
    @autoreleasepool {
        NSDictionary *defaults = @{@"enabled": @YES, @"hideInLandscape": @YES, @"leftHanded": @NO,
            @"darkHandle": @NO, @"hideLabels": @NO, @"hapticFeedback": @YES, @"closeOnHome": @YES,
            @"hideHandle": @NO, @"keyboardAvoiding": @NO, @"externalKeyboard": @NO, @"autoNub": @NO,
            @"style": @"Recent Apps", @"favorites": @[], @"recentAppsCount": @5, @"quickswitchScale": @1.75,
            @"autoNub-time": @5};
        assert([POValidatedPreferences(nil, defaults) isEqual:defaults]);
        assert([POValidatedPreferences(@[], defaults) isEqual:defaults]);
        NSDictionary *valid = POValidatedPreferences(@{@"enabled": @NO, @"style": @"Favorites",
            @"favorites": @[@"com.apple.mobilesafari", @"com.facebook.Messenger"], @"quickswitchScale": @2.1,
            @"autoNub-time": @15, @"recentAppsCount": @8}, defaults);
        assert(![valid[@"enabled"] boolValue]);
        assert([valid[@"style"] isEqual:@"Favorites"]);
        assert([valid[@"favorites"] count] == 2);
        assert([valid[@"autoNub-time"] integerValue] == 15);
        assert([valid[@"recentAppsCount"] integerValue] == 8);
        assert(fabs([valid[@"quickswitchScale"] doubleValue] - 2.1) < 0.00001);
        NSDictionary *invalid = POValidatedPreferences(@{@"enabled": @"false", @"style": @4,
            @"favorites": @7, @"quickswitchScale": @(NAN), @"autoNub-time": @(INFINITY),
            @"recentAppsCount": [NSNull null], @"injected": @YES}, defaults);
        assert([invalid isEqual:defaults]);
        invalid = POValidatedPreferences(@{@"style": @"Something Else", @"enabled": @(INFINITY)}, defaults);
        assert([invalid isEqual:defaults]);
        NSDictionary *bounded = POValidatedPreferences(@{@"quickswitchScale": @1000, @"autoNub-time": @(-1000),
            @"recentAppsCount": @1000}, defaults);
        assert([bounded[@"quickswitchScale"] doubleValue] == 2.5);
        assert([bounded[@"autoNub-time"] integerValue] == 1);
        assert([bounded[@"recentAppsCount"] integerValue] == 10);
        bounded = POValidatedPreferences(@{@"quickswitchScale": @(-1000), @"autoNub-time": @1000,
            @"recentAppsCount": @(-1000)}, defaults);
        assert([bounded[@"quickswitchScale"] doubleValue] == 1);
        assert([bounded[@"autoNub-time"] integerValue] == 30);
        assert([bounded[@"recentAppsCount"] integerValue] == 1);
        NSMutableString *identifier = [@"com.example-App_test" mutableCopy];
        NSMutableArray *favorites = [NSMutableArray arrayWithArray:@[identifier, @"com.apple.mobilesafari",
            @"com.apple.mobilesafari", @"", @" app", @"com.bad/id", @1, [NSNull null]]];
        NSDictionary *snapshot = POValidatedPreferences(@{@"favorites": favorites}, defaults);
        [identifier appendString:@".changed"];
        [favorites removeAllObjects];
        assert(([snapshot[@"favorites"] isEqual:@[@"com.example-App_test", @"com.apple.mobilesafari"]]));
        assert(!POValidFavoriteIdentifier([@"x" stringByPaddingToLength:256 withString:@"x" startingAtIndex:0]));
        assert(![defaults[@"favorites"] count]); // Stored input and defaults are not mutated.
        puts("PASS preferences: valid settings, malformed types, finite ranges, favorite filtering and immutable copies");
    }
    return 0;
}
