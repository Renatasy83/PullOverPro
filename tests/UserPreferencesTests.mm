#import "../PPOUserPreferences.h"
#import <CoreFoundation/CoreFoundation.h>
#include <cmath>
#include <limits>
#include <stdio.h>
#include <stdlib.h>

// Pure model fixtures. No real preference read/write, Darwin notification, UI
// or private iOS methods. Empty/invalid storage edits terminate before I/O.
static unsigned checks;
static void Check(BOOL condition, const char *message) {
    checks++;
    if (!condition) { fprintf(stderr, "FAIL: %s\n", message); exit(1); }
}
static BOOL PreferenceFixtureBoolean(id value, BOOL expected) {
    return [value isKindOfClass:NSNumber.class] &&
        CFGetTypeID((__bridge CFTypeRef)value) == CFBooleanGetTypeID() &&
        [value boolValue] == expected;
}
static NSDictionary *With(NSString *key, id value) {
    NSMutableDictionary *raw = [PPOUserPreferencesDefaults() mutableCopy];
    raw[key] = value;
    return raw;
}
static void Rejected(id changes) {
    NSDictionary *before = PPOUserPreferencesDefaults();
    NSError *error = [NSError errorWithDomain:@"Fixture" code:99 userInfo:nil];
    Check(PPOUserPreferencesApplyingChanges(before, changes, &error) == nil &&
          [error.domain isEqual:@"PullOverPro.UserPreferences"] && error.code == 1,
          "invalid edits report model failure without producing an updated snapshot");
    Check(PPOUserPreferencesApplyingChanges(before, changes, NULL) == nil,
          "invalid edit rejection does not depend on an error pointer");
    error = nil;
    Check(!PPOUserPreferencesWriteChanges(changes, &error) && error.code == 1 &&
          [error.domain isEqual:@"PullOverPro.UserPreferences"],
          "invalid storage edits fail before preference I/O or notification");
    Check([before isEqual:PPOUserPreferencesDefaults()],
          "rejected edits leave their input snapshot intact");
}

int main(void) {
    @autoreleasepool {
        NSDictionary *defaults = PPOUserPreferencesDefaults();
        NSSet *keys = [NSSet setWithArray:@[@"enabled", @"edge", @"handleYRatio", @"handleSize",
            @"handleOpacity", @"windowSize", @"appearance", @"autoHideHandle", @"autoHideDelay",
            @"keepWindowOpen", @"rememberPosition", @"quickSwitchMode", @"recentAppsCount",
            @"quickSwitchScale", @"hideLabels", @"hideInLandscape", @"hapticFeedback", @"keyboardAvoiding", @"recentIdentifiers"]];
        Check([PPOUserPreferencesDomain isEqual:@"com.renatasy83.pulloverpro.settings"] &&
              [PPOUserPreferencesChangedNotification isEqual:@"com.renatasy83.pulloverpro.settings-changed"],
              "storage and Darwin notification use only the dedicated PPO settings domain");
        Check(defaults.count == 19 && [[NSSet setWithArray:defaults.allKeys] isEqual:keys],
              "default schema contains eighteen scalar keys and the own recent-choice cache");
        Check(PreferenceFixtureBoolean(defaults[@"enabled"], YES) &&
              PreferenceFixtureBoolean(defaults[@"autoHideHandle"], NO) &&
              PreferenceFixtureBoolean(defaults[@"rememberPosition"], YES) &&
              PreferenceFixtureBoolean(defaults[@"keepWindowOpen"], YES) &&
              PreferenceFixtureBoolean(defaults[@"hideLabels"], NO) &&
              PreferenceFixtureBoolean(defaults[@"hideInLandscape"], YES) &&
              PreferenceFixtureBoolean(defaults[@"hapticFeedback"], YES) &&
              PreferenceFixtureBoolean(defaults[@"keyboardAvoiding"], NO),
              "default flags preserve original visible-handle behavior and persistent release windows");
        Check([defaults[@"edge"] isEqual:@"right"] && [defaults[@"appearance"] isEqual:@"system"] &&
              [defaults[@"handleYRatio"] isEqual:@0.5] && [defaults[@"handleSize"] isEqual:@34] &&
              [defaults[@"handleOpacity"] isEqual:@0.85] && [defaults[@"windowSize"] isEqual:@3] &&
              [defaults[@"autoHideDelay"] isEqual:@5] &&
              [defaults[@"quickSwitchMode"] isEqual:@"recent"] &&
              [defaults[@"recentAppsCount"] isEqual:@5] && [defaults[@"quickSwitchScale"] isEqual:@1.75],
              "default presentation is right edge, centered handle and standard window");
        Check([PPOUserPreferencesNormalize(nil) isEqual:defaults] &&
              [PPOUserPreferencesNormalize(@{}) isEqual:defaults] &&
              [PPOUserPreferencesNormalize(defaults) isEqual:defaults],
              "missing, empty and already-normalized state have deterministic defaults");
        for (id raw in @[NSNull.null, @YES, @1, @"settings", @[], @[@{}]])
            Check([PPOUserPreferencesNormalize(raw) isEqual:defaults],
                  "non-dictionary root data safely normalizes to defaults");

        for (NSString *key in keys) {
            NSMutableDictionary *missing = [defaults mutableCopy];
            [missing removeObjectForKey:key];
            Check([PPOUserPreferencesNormalize(missing) isEqual:defaults],
                  "a missing individual key uses only that key's documented default");
            for (id malformed in @[NSNull.null, @{}, @"invalid value"])
                Check([PPOUserPreferencesNormalize(With(key, malformed)) isEqual:defaults],
                      "bad scalar types and unsupported strings cannot alter normalized state");
            if (![key isEqual:@"recentIdentifiers"]) {
                Check([PPOUserPreferencesNormalize(With(key, @[])) isEqual:defaults],
                      "an array cannot replace a scalar presentation setting");
                Rejected(@{key: @[]});
            }
        }
        NSDictionary *unknown = PPOUserPreferencesNormalize(@{@"enabled": @NO, @"otherAppPreference": @"untouched"});
        Check(unknown.count == 19 && PreferenceFixtureBoolean(unknown[@"enabled"], NO) &&
              unknown[@"otherAppPreference"] == nil,
              "unknown read keys are omitted without suppressing known valid values");
        NSMutableDictionary *oversized = [NSMutableDictionary dictionary];
        for (unsigned i = 0; i < 65; i++) oversized[[NSString stringWithFormat:@"x%u", i]] = @1;
        Check([PPOUserPreferencesNormalize(oversized) isEqual:defaults],
              "oversized root objects cannot amplify preference processing");

        for (NSString *key in @[@"enabled", @"autoHideHandle", @"keepWindowOpen", @"rememberPosition",
                @"hideLabels", @"hideInLandscape", @"hapticFeedback", @"keyboardAvoiding"]) {
            for (NSNumber *flag in @[@YES, @NO]) {
                NSDictionary *result = PPOUserPreferencesNormalize(With(key, flag));
                Check(PreferenceFixtureBoolean(result[key], flag.boolValue),
                      "real Boolean settings preserve both true and false");
                NSError *error = [NSError errorWithDomain:@"Fixture" code:99 userInfo:nil];
                Check([PPOUserPreferencesApplyingChanges(defaults, @{key: flag}, &error) isEqual:result] && error == nil,
                      "valid Boolean edits clear stale error state and match normalized values");
            }
            for (id impostor in @[@0, @1, @(-1), @2, @"true", @"false", @"1", NSNull.null]) {
                Check([PPOUserPreferencesNormalize(With(key, impostor)) isEqual:defaults],
                      "numeric and textual Boolean impostors cannot enable or disable behavior");
                Rejected(@{key: impostor});
            }
        }

        // Opt-in keyboard avoidance must neither migrate existing position nor
        // rewrite window/choice state. Only this explicit Boolean may change.
        NSMutableDictionary *legacy = [defaults mutableCopy];
        [legacy removeObjectForKey:@"keyboardAvoiding"];
        legacy[@"handleYRatio"] = @0.91;
        NSDictionary *legacySnapshot = PPOUserPreferencesNormalize(legacy);
        Check(PreferenceFixtureBoolean(legacySnapshot[@"keyboardAvoiding"], NO) &&
              [legacySnapshot[@"handleYRatio"] isEqual:@0.91],
              "old preference snapshots gain opt-in keyboard avoidance without moving the saved handle");
        NSDictionary *avoiding = PPOUserPreferencesApplyingChanges(legacySnapshot, @{@"keyboardAvoiding": @YES}, NULL);
        NSMutableDictionary *otherBefore = [legacySnapshot mutableCopy], *otherAfter = [avoiding mutableCopy];
        [otherBefore removeObjectForKey:@"keyboardAvoiding"]; [otherAfter removeObjectForKey:@"keyboardAvoiding"];
        Check(PreferenceFixtureBoolean(avoiding[@"keyboardAvoiding"], YES) && [otherBefore isEqual:otherAfter],
              "enabling keyboard avoidance leaves saved position, selection history and window policy intact");
        Check([PPOUserPreferencesApplyingChanges(avoiding, @{@"keyboardAvoiding": @NO}, NULL) isEqual:legacySnapshot],
              "turning off keyboard avoidance restores only its flag and preserves other preferences");

        NSDictionary *numericBounds = @{@"handleYRatio": @[@0, @1], @"handleSize": @[@32, @72],
            @"handleOpacity": @[@0.2, @1], @"windowSize": @[@0, @3], @"autoHideDelay": @[@1, @30],
            @"recentAppsCount": @[@1, @16], @"quickSwitchScale": @[@1, @3]};
        for (NSString *key in numericBounds) {
            double minimum = [numericBounds[key][0] doubleValue], maximum = [numericBounds[key][1] doubleValue];
            for (NSNumber *value in @[@(minimum), @(maximum)]) {
                NSDictionary *normalized = PPOUserPreferencesNormalize(With(key, value));
                Check([normalized[key] doubleValue] == value.doubleValue &&
                      !PreferenceFixtureBoolean(normalized[key], YES) && !PreferenceFixtureBoolean(normalized[key], NO),
                      "numeric boundary values remain numbers rather than Boolean flags");
                Check([PPOUserPreferencesApplyingChanges(defaults, @{key: value}, NULL) isEqual:normalized],
                      "inclusive numeric boundaries are valid edits");
            }
            for (NSNumber *outside in @[@(minimum - 1), @(maximum + 1), @(-1e100), @(1e100)]) {
                NSDictionary *normalized = PPOUserPreferencesNormalize(With(key, outside));
                double expected = outside.doubleValue < minimum ? minimum : maximum;
                Check([normalized[key] doubleValue] == expected,
                      "finite out-of-range persisted numbers clamp to reachable presentation bounds");
                Rejected(@{key: outside});
            }
            for (NSNumber *nonfinite in @[@(std::numeric_limits<double>::quiet_NaN()),
                    @(std::numeric_limits<double>::infinity()), @(-std::numeric_limits<double>::infinity())]) {
                Check([PPOUserPreferencesNormalize(With(key, nonfinite)) isEqual:defaults],
                      "NaN and infinities cannot reach layout or timers");
                Rejected(@{key: nonfinite});
            }
            for (id malformed in @[@YES, @NO, @"0.5", NSNull.null]) {
                Check([PPOUserPreferencesNormalize(With(key, malformed)) isEqual:defaults],
                      "numeric controls reject Boolean and textual values");
                Rejected(@{key: malformed});
            }
        }
        for (NSNumber *size in @[@0, @1, @2, @3])
            Check([PPOUserPreferencesApplyingChanges(defaults, @{@"windowSize": size}, NULL)[@"windowSize"] isEqual:size],
                  "all four window presets are exact integral selections");
        for (NSNumber *fraction in @[@0.25, @1.5, @(-0.5)]) {
            Check([PPOUserPreferencesNormalize(With(@"windowSize", fraction)) isEqual:defaults],
                  "fractional preset indexes use the drawer default rather than truncation");
            Rejected(@{@"windowSize": fraction});
            Check([PPOUserPreferencesNormalize(With(@"recentAppsCount", fraction)) isEqual:defaults],
                  "fractional recent counts use the default rather than truncation");
            Rejected(@{@"recentAppsCount": fraction});
        }
        for (NSInteger count = 1; count <= 16; count++)
            Check([PPOUserPreferencesApplyingChanges(defaults, @{@"recentAppsCount": @(count)}, NULL)[@"recentAppsCount"] isEqual:@(count)],
                  "each bounded recent count remains an exact integer");
        for (NSDictionary *fractional in @[@{@"handleYRatio": @0.25}, @{@"handleSize": @48.5},
                @{@"handleOpacity": @0.75}, @{@"autoHideDelay": @2.5}, @{@"quickSwitchScale": @1.5}])
            Check(PPOUserPreferencesApplyingChanges(defaults, fractional, NULL) != nil,
                  "continuous controls retain their valid fractional values");

        for (NSString *edge in @[@"left", @"right"])
            Check([PPOUserPreferencesNormalize(With(@"edge", edge))[@"edge"] isEqual:edge] &&
                  [PPOUserPreferencesApplyingChanges(defaults, @{@"edge": edge}, NULL)[@"edge"] isEqual:edge],
                  "both exact edge choices survive normalization and edits");
        for (NSString *appearance in @[@"system", @"light", @"dark"])
            Check([PPOUserPreferencesNormalize(With(@"appearance", appearance))[@"appearance"] isEqual:appearance] &&
                  [PPOUserPreferencesApplyingChanges(defaults, @{@"appearance": appearance}, NULL)[@"appearance"] isEqual:appearance],
                  "all three exact appearance choices survive normalization and edits");
        for (NSString *mode in @[@"recent", @"favorites"])
            Check([PPOUserPreferencesNormalize(With(@"quickSwitchMode", mode))[@"quickSwitchMode"] isEqual:mode] &&
                  [PPOUserPreferencesApplyingChanges(defaults, @{@"quickSwitchMode": mode}, NULL)[@"quickSwitchMode"] isEqual:mode],
                  "both exact quick-switch modes survive normalization and edits");
        for (NSString *key in @[@"edge", @"appearance", @"quickSwitchMode"])
            for (NSString *invalid in @[@"", @"Left", @"RIGHT", @" right", @"left ", @"SYSTEM", @"automatic",
                    [@"x" stringByPaddingToLength:257 withString:@"x" startingAtIndex:0]]) {
                Check([PPOUserPreferencesNormalize(With(key, invalid)) isEqual:defaults],
                      "unknown, spaced, case-changed and overlong enums do not silently gain meanings");
                Rejected(@{key: invalid});
            }

        Check([defaults[@"recentIdentifiers"] isEqual:@[]] &&
              [PPOUserPreferencesApplyingChanges(defaults, @{@"recentIdentifiers": @[]}, NULL) isEqual:defaults],
              "a missing or empty own recent cache remains a valid empty list");
        NSMutableArray<NSString *> *sixteen = [NSMutableArray array];
        for (unsigned index = 0; index < 16; index++)
            [sixteen addObject:[NSString stringWithFormat:@"com.example.choice%u", index]];
        NSDictionary *sixteenSnapshot = PPOUserPreferencesNormalize(With(@"recentIdentifiers", sixteen));
        Check([sixteenSnapshot[@"recentIdentifiers"] isEqual:sixteen] &&
              [PPOUserPreferencesApplyingChanges(defaults, @{@"recentIdentifiers": sixteen}, NULL) isEqual:sixteenSnapshot],
              "all sixteen distinct recent choices preserve exact order and identity");
        NSString *maxID = [@"A" stringByPaddingToLength:255 withString:@"b" startingAtIndex:0];
        Check([PPOUserPreferencesNormalize(With(@"recentIdentifiers", @[maxID]))[@"recentIdentifiers"] isEqual:@[maxID]],
              "a syntactic identifier at the byte-compatible ASCII length limit survives");
        Check([PPOUserPreferencesApplyingChanges(defaults,
                  @{@"recentIdentifiers": @[@"A", @"1-app.2", @"com.example.App", @"com.example.app"]}, NULL)[@"recentIdentifiers"]
                  isEqual:@[@"A", @"1-app.2", @"com.example.App", @"com.example.app"]],
              "recent choices preserve syntactic ASCII case and never infer app authorization");
        NSMutableArray *seventeen = [sixteen mutableCopy]; [seventeen addObject:@"com.example.extra"];
        NSArray *badRecentValues = @[@YES, @1, @"com.example.app", NSNull.null, @{},
            @[@1], @[NSNull.null], @[@[]], @[@{}], @[@""], @[@".bad"], @[@"-bad"],
            @[@"bad/path"], @[@"bad space"], @[@"com.example_under"], @[@"com.éxample"],
            @[@"com.example\n"], @[@"com.example.same", @"com.example.same"],
            @[[maxID stringByAppendingString:@"x"]], seventeen];
        for (id invalid in badRecentValues) {
            Check([PPOUserPreferencesNormalize(With(@"recentIdentifiers", invalid)) isEqual:defaults],
                  "malformed, duplicate, non-ASCII and oversized recent lists never survive normalization");
            Rejected(@{@"recentIdentifiers": invalid});
        }
        NSMutableString *mutableRecent = [@"com.example.original" mutableCopy];
        NSMutableArray *mutableRecents = [@[mutableRecent, @"com.example.previous"] mutableCopy];
        NSDictionary *recentSnapshot = PPOUserPreferencesNormalize(With(@"recentIdentifiers", mutableRecents));
        NSDictionary *recentEditSnapshot = PPOUserPreferencesApplyingChanges(defaults,
            @{@"recentIdentifiers": mutableRecents}, NULL);
        [mutableRecent setString:@"com.example.changed"]; [mutableRecents removeAllObjects];
        Check([recentSnapshot[@"recentIdentifiers"] isEqual:@[@"com.example.original", @"com.example.previous"]] &&
              [recentEditSnapshot isEqual:recentSnapshot],
              "recent cache snapshots copy both their ordered array and caller-owned strings");
        NSDictionary *preservedRecents = PPOUserPreferencesApplyingChanges(recentSnapshot, @{@"edge": @"left"}, NULL);
        Check([preservedRecents[@"recentIdentifiers"] isEqual:recentSnapshot[@"recentIdentifiers"]],
              "unrelated settings edits preserve the own recent cache");

        NSMutableString *edgeKey = [@"edge" mutableCopy], *edgeValue = [@"left" mutableCopy];
        NSMutableDictionary *mutableRaw = [@{edgeKey: edgeValue, @"enabled": @NO} mutableCopy];
        NSDictionary *snapshot = PPOUserPreferencesNormalize(mutableRaw);
        NSDictionary *editSnapshot = PPOUserPreferencesApplyingChanges(defaults, mutableRaw, NULL);
        [edgeKey setString:@"other"]; [edgeValue setString:@"right"]; mutableRaw[@"enabled"] = @YES;
        Check([snapshot[@"edge"] isEqual:@"left"] && PreferenceFixtureBoolean(snapshot[@"enabled"], NO) &&
              [editSnapshot isEqual:snapshot],
              "normalized and edited snapshots do not retain caller-owned mutable strings or dictionaries");
        Check([PPOUserPreferencesNormalize(snapshot) isEqual:snapshot] && snapshot.count == 19,
              "normalization is idempotent and does not retain unknown metadata");
        NSData *plist = [NSPropertyListSerialization dataWithPropertyList:snapshot
            format:NSPropertyListBinaryFormat_v1_0 options:0 error:NULL];
        NSDictionary *decoded = [NSPropertyListSerialization propertyListWithData:plist
            options:NSPropertyListImmutable format:NULL error:NULL];
        Check(plist != nil && [PPOUserPreferencesNormalize(decoded) isEqual:snapshot],
              "settings scalar snapshots round trip as property lists");

        NSError *error = [NSError errorWithDomain:@"Fixture" code:99 userInfo:nil];
        Check([PPOUserPreferencesApplyingChanges(snapshot, @{}, &error) isEqual:snapshot] && error == nil,
              "empty edits preserve state and clear an obsolete error");
        error = [NSError errorWithDomain:@"Fixture" code:99 userInfo:nil];
        Check(PPOUserPreferencesWriteChanges(@{}, &error) && error == nil,
              "empty storage updates succeed without preference I/O or notification");
        NSDictionary *allChanged = @{@"enabled": @NO, @"edge": @"left", @"handleYRatio": @0.8,
            @"handleSize": @64, @"handleOpacity": @0.6, @"windowSize": @2,
            @"appearance": @"dark", @"autoHideHandle": @YES, @"autoHideDelay": @12,
            @"keepWindowOpen": @NO, @"rememberPosition": @NO,
            @"quickSwitchMode": @"favorites", @"recentAppsCount": @16, @"quickSwitchScale": @2.5,
            @"hideLabels": @YES, @"hideInLandscape": @NO, @"hapticFeedback": @NO, @"keyboardAvoiding": @YES,
            @"recentIdentifiers": @[@"com.example.chosen", @"com.example.previous"]};
        Check([PPOUserPreferencesApplyingChanges(defaults, allChanged, NULL) isEqual:allChanged],
              "one valid multi-key edit produces an independently normalized complete snapshot");
        Check([defaults[@"enabled"] boolValue] && PreferenceFixtureBoolean(defaults[@"keepWindowOpen"], YES),
              "a valid edit leaves the shared persistent-window default intact");
        NSDictionary *timed = PPOUserPreferencesApplyingChanges(defaults, @{@"keepWindowOpen": @NO}, NULL);
        Check(PreferenceFixtureBoolean(timed[@"keepWindowOpen"], NO) &&
              [timed isEqual:With(@"keepWindowOpen", @NO)] &&
              PreferenceFixtureBoolean(defaults[@"keepWindowOpen"], YES),
              "an explicit false preference selects timed mode without changing other defaults");
        for (id invalid in @[NSNull.null, @YES, @[], @"edge", @{@"schema": @1},
                @{@".ppo_disable": @YES}, @{@"favorites": @[]}, @{@"bundleIdentifier": @"com.apple.mobilesafari"},
                @{@"enabled": @NO, @"unknown": @YES}, @{@1: @YES}])
            Rejected(invalid);
        Rejected(nil);
        Check([PPOUserPreferencesApplyingChanges(nil, @{@"edge": @"left"}, NULL)[@"edge"] isEqual:@"left"],
              "valid edits can start from normalized defaults when current state is absent");
        printf("User preferences tests passed: %u checks; pure model and pre-I/O rejection only\n", checks);
    }
    return 0;
}
