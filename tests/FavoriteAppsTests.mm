#import "../PPOFavoriteApps.h"
#import <CoreFoundation/CoreFoundation.h>
#include <stdio.h>
#include <stdlib.h>

// Pure Foundation fixtures. No real inventory, preferences, application launch or UI.
static unsigned checks;
static NSString *const Alpha = @"com.example.alpha";
static NSString *const Beta = @"com.example.beta";
static NSString *const Missing = @"com.example.missing";

static void Check(BOOL condition, const char *message) {
    checks++;
    if (!condition) { fprintf(stderr, "FAIL: %s\n", message); exit(1); }
}
static NSData *Plist(id value) {
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:value
        format:NSPropertyListXMLFormat_v1_0 options:0 error:NULL];
    Check(data != nil, "test fixture is a valid property list");
    return data;
}
static NSData *Wire(id schema, id identifiers) {
    return Plist(@{@"schema": schema, @"bundleIdentifiers": identifiers});
}
static NSDictionary *App(NSString *identifier, NSString *name) {
    return @{@"bundleIdentifier": identifier, @"name": name};
}
static BOOL Boolean(id value, BOOL expected) {
    return [value isKindOfClass:NSNumber.class] &&
        CFGetTypeID((__bridge CFTypeRef)value) == CFBooleanGetTypeID() &&
        [value boolValue] == expected;
}
static void Row(NSDictionary *row, NSString *identifier, NSString *name,
    BOOL available, BOOL favorite) {
    Check([row isKindOfClass:NSDictionary.class] && row.count == 4,
        "projected row contains only four normalized fields");
    Check([row[@"bundleIdentifier"] isEqual:identifier] && [row[@"name"] isEqual:name],
        "projected row preserves exact identity and the expected current name");
    Check(Boolean(row[@"available"], available) && Boolean(row[@"favorite"], favorite),
        "projected availability and favorite flags are real Booleans");
}
static void InvalidIdentifiers(id value) {
    Check(PPOFavoriteIdentifiersNormalize(value) == nil,
        "malformed favorite collection is rejected by normalization");
    if ([NSPropertyListSerialization propertyList:value isValidForFormat:NSPropertyListXMLFormat_v1_0]) {
        Check(PPOFavoriteIdentifiersFromData(Wire(@1, value), NULL) == nil,
            "malformed favorite collection is rejected in persisted data");
        Check(PPOFavoriteIdentifiersData(value, NULL) == nil,
            "malformed favorite collection cannot be serialized");
    }
}

int main(void) {
    @autoreleasepool {
        Check(PPOFavoriteIdentifiersLimit == 16 && PPOFavoriteDataLimit == 16384,
            "exported limits match the documented favorite and byte boundaries");
        NSArray *favorites = @[Beta, Alpha, Missing];
        Check([PPOFavoriteIdentifiersNormalize(favorites) isEqual:favorites],
            "normalization preserves favorite insertion order");
        NSError *error = nil;
        NSData *encoded = PPOFavoriteIdentifiersData(favorites, &error);
        Check(encoded != nil && encoded.length <= 16384 && error == nil,
            "valid favorites serialize within the documented byte limit");
        Check([PPOFavoriteIdentifiersFromData(encoded, NULL) isEqual:favorites],
            "favorites survive a persistence round trip without reordering");
        NSData *binary = [NSPropertyListSerialization dataWithPropertyList:
            @{@"schema": @1, @"bundleIdentifiers": favorites}
            format:NSPropertyListBinaryFormat_v1_0 options:0 error:NULL];
        Check(binary != nil && [PPOFavoriteIdentifiersFromData(binary, NULL) isEqual:favorites],
            "valid binary property lists obey the same persisted contract as XML");
        NSDictionary *persisted = [NSPropertyListSerialization propertyListWithData:encoded
            options:NSPropertyListImmutable format:NULL error:NULL];
        Check([persisted isKindOfClass:NSDictionary.class] && persisted.count == 2 &&
            [persisted[@"schema"] isEqual:@1] && !Boolean(persisted[@"schema"], YES) &&
            [persisted[@"bundleIdentifiers"] isEqual:favorites],
            "serialized schema contains only numeric version and ordered identifiers");
        Check(PPOFavoriteIdentifiersNormalize(@[]) != nil &&
            PPOFavoriteIdentifiersNormalize(@[]).count == 0,
            "empty favorites are valid rather than absent data");
        Check([PPOFavoriteIdentifiersFromData(PPOFavoriteIdentifiersData(@[], NULL), NULL) isEqual:@[]],
            "an explicitly empty favorite list remains valid after persistence");
        Check(PPOFavoriteIdentifiersNormalize(nil) == nil &&
            PPOFavoriteIdentifiersData(nil, NULL) == nil,
            "absent favorite collections are invalid");
        Check(PPOFavoriteIdentifiersFromData(nil, NULL) == nil &&
            PPOFavoriteIdentifiersFromData(NSData.data, NULL) == nil &&
            PPOFavoriteIdentifiersFromData([@"invalid" dataUsingEncoding:NSUTF8StringEncoding], NULL) == nil,
            "absent, empty and malformed files are not an empty favorite list");
        error = nil;
        Check(PPOFavoriteIdentifiersData(@[Alpha, Alpha], &error) == nil && error.code == 1 &&
            [error.domain isEqual:@"PullOverPro.FavoriteApps"],
            "invalid serialization reports the favorite data error domain and code");
        error = nil;
        Check(PPOFavoriteIdentifiersFromData(Wire(@2, @[Alpha]), &error) == nil && error.code == 1 &&
            [error.domain isEqual:@"PullOverPro.FavoriteApps"],
            "invalid persisted content reports the favorite data error domain and code");

        for (id invalid in @[@"com.example.alpha", @1, @{}, NSNull.null,
                @[@1], @[NSNull.null], @[@[]], @[@{}], @[Alpha, Alpha]])
            InvalidIdentifiers(invalid);
        for (NSString *identifier in @[@"", @"app", @"com..app", @".com.app", @"com.app.",
                @"com.-app", @"com.app_", @"com/app", @"com app", @"com.example.é",
                @"com.apple.springboard", @"COM.APPLE.SPRINGBOARD", @"com.apple.SpringBoard.extension",
                @"com.apple.backboardd", @"com.apple.runningboardd", @"com.apple.lsd", @"com.apple.uikitservices"])
            InvalidIdentifiers(@[identifier]);
        NSString *longestID = [@"com." stringByAppendingString:[@"a" stringByPaddingToLength:251
            withString:@"a" startingAtIndex:0]];
        Check(longestID.length == 255 && PPOFavoriteIdentifiersNormalize(@[longestID]) != nil,
            "favorites accept the identifier validator's 255-character boundary");
        InvalidIdentifiers(@[[longestID stringByAppendingString:@"a"]]);
        Check([PPOFavoriteIdentifiersNormalize(@[@"com.example.alpha", @"COM.EXAMPLE.ALPHA"])
            isEqual:@[@"com.example.alpha", @"COM.EXAMPLE.ALPHA"]],
            "case-distinct identifiers remain distinct favorite identities");
        Check(PPOFavoriteIdentifiersNormalize(@[@"org.Example.some-app_1", @"com.apple.mobilesafari"]) != nil,
            "ordinary strict identifiers need no scene eligibility evidence to be favorites");

        NSMutableArray *maximum = [NSMutableArray array];
        for (NSUInteger i = 0; i < 16; i++)
            [maximum addObject:[NSString stringWithFormat:@"com.example.app%lu", (unsigned long)i]];
        Check(PPOFavoriteIdentifiersNormalize(maximum).count == 16 &&
            PPOFavoriteIdentifiersFromData(PPOFavoriteIdentifiersData(maximum, NULL), NULL).count == 16,
            "the exact sixteen-favorite limit round trips");
        [maximum addObject:@"com.example.oneMore"];
        InvalidIdentifiers(maximum);

        id genuineTrue = (__bridge id)kCFBooleanTrue;
        id genuineFalse = (__bridge id)kCFBooleanFalse;
        for (id schema in @[genuineTrue, genuineFalse, @0, @2, @1.5, @"1", @[], @{}])
            Check(PPOFavoriteIdentifiersFromData(Wire(schema, @[Alpha]), NULL) == nil,
                "Boolean, wrong-type and unsupported schema values are rejected");
        Check([PPOFavoriteIdentifiersFromData(Wire(@1.0, @[Alpha]), NULL) isEqual:@[Alpha]],
            "numeric schema one is accepted independently of NSNumber storage type");
        for (id root in @[@[], @"favorites", @1])
            Check(PPOFavoriteIdentifiersFromData(Plist(root), NULL) == nil,
                "persisted favorites require a dictionary root");
        for (NSDictionary *root in @[@{}, @{@"schema": @1}, @{@"bundleIdentifiers": @[Alpha]},
                @{@"schema": @1, @"bundleIdentifiers": @[Alpha], @"extra": @1},
                @{@"version": @1, @"bundleIdentifiers": @[Alpha]}])
            Check(PPOFavoriteIdentifiersFromData(Plist(root), NULL) == nil,
                "missing, additional and substituted persistence keys are rejected");
        NSMutableData *atLimit = [Wire(@1, @[Alpha]) mutableCopy];
        while (atLimit.length < 16384) [atLimit appendBytes:" " length:1];
        Check(atLimit.length == 16384 &&
            [PPOFavoriteIdentifiersFromData(atLimit, NULL) isEqual:@[Alpha]],
            "a valid property list at the exact file-byte limit is accepted");
        [atLimit appendBytes:" " length:1];
        Check(PPOFavoriteIdentifiersFromData(atLimit, NULL) == nil,
            "a valid property list one byte beyond the file limit is rejected");

        NSMutableString *mutableFavorite = [Alpha mutableCopy];
        NSMutableArray *mutableFavorites = [NSMutableArray arrayWithObject:mutableFavorite];
        NSArray *normalized = PPOFavoriteIdentifiersNormalize(mutableFavorites);
        NSData *snapshot = PPOFavoriteIdentifiersData(mutableFavorites, NULL);
        [mutableFavorite setString:Beta];
        [mutableFavorites removeAllObjects];
        Check([normalized isEqual:@[Alpha]] && ![normalized[0] isKindOfClass:NSMutableString.class] &&
            ![normalized isKindOfClass:NSMutableArray.class],
            "normalized identifiers are immutable independent copies of mutable callers");
        Check([PPOFavoriteIdentifiersFromData(snapshot, NULL) isEqual:@[Alpha]],
            "serialized data captures the favorite value before caller mutation");

        NSArray *apps = @[App(Alpha, @"Renamed Alpha"), App(Beta, @"Beta"),
            App(@"com.example.other", @"Other")];
        NSArray *all = PPOFavoriteAppRows(apps, favorites, NO);
        Check(all.count == 3, "all-app projection preserves inventory cardinality");
        Row(all[0], Alpha, @"Renamed Alpha", YES, YES);
        Row(all[1], Beta, @"Beta", YES, YES);
        Row(all[2], @"com.example.other", @"Other", YES, NO);
        NSArray *quick = PPOFavoriteAppRows(apps, favorites, YES);
        Check(quick.count == 3, "favorite projection preserves stored cardinality including unavailable apps");
        Row(quick[0], Beta, @"Beta", YES, YES);
        Row(quick[1], Alpha, @"Renamed Alpha", YES, YES);
        Row(quick[2], Missing, Missing, NO, YES);
        Check([favorites isEqual:@[Beta, Alpha, Missing]],
            "projecting an unavailable favorite never prunes the stored identifiers");
        NSArray *caseRows = PPOFavoriteAppRows(@[App(Alpha, @"Alpha")], @[@"COM.EXAMPLE.ALPHA"], NO);
        Row(caseRows[0], Alpha, @"Alpha", YES, NO);
        caseRows = PPOFavoriteAppRows(@[App(Alpha, @"Alpha")], @[@"COM.EXAMPLE.ALPHA"], YES);
        Row(caseRows[0], @"COM.EXAMPLE.ALPHA", @"COM.EXAMPLE.ALPHA", NO, YES);
        caseRows = PPOFavoriteAppRows(@[App(Alpha, @"Lower"), App(@"COM.EXAMPLE.ALPHA", @"Upper")], @[Alpha], NO);
        Check(caseRows.count == 2, "case-distinct inventory identifiers are not duplicates");
        Row(caseRows[0], Alpha, @"Lower", YES, YES);
        Row(caseRows[1], @"COM.EXAMPLE.ALPHA", @"Upper", YES, NO);
        Check(PPOFavoriteAppRows(@[], @[], NO) != nil && PPOFavoriteAppRows(@[], @[], NO).count == 0 &&
            PPOFavoriteAppRows(@[], @[], YES) != nil && PPOFavoriteAppRows(@[], @[], YES).count == 0,
            "empty inventories and favorites are valid in both views");
        Row(PPOFavoriteAppRows(@[], @[Missing], YES)[0], Missing, Missing, NO, YES);
        Check(PPOFavoriteAppRows(apps, @[], YES).count == 0 &&
            PPOFavoriteAppRows(@[], favorites, NO).count == 0,
            "empty favorite or inventory inputs do not invent available rows");

        NSArray *unusual = @[App(@"com.apple.springboard", @"SpringBoard"), App(@"odd inventory id", @"Odd")];
        NSArray *unusualRows = PPOFavoriteAppRows(unusual, @[], NO);
        Check(unusualRows.count == 2, "inventory projection is not permission to favorite or launch an identifier");
        Row(unusualRows[0], @"com.apple.springboard", @"SpringBoard", YES, NO);
        Row(unusualRows[1], @"odd inventory id", @"Odd", YES, NO);
        Row(PPOFavoriteAppRows(@[@{@"bundleIdentifier": Alpha, @"name": @"Alpha",
            @"unrelatedMetadata": @{@"privateValue": @"discard"}}], @[Alpha], NO)[0],
            Alpha, @"Alpha", YES, YES);
        for (BOOL favoritesOnly = NO; ; favoritesOnly = YES) {
            Check(PPOFavoriteAppRows(nil, @[], favoritesOnly) == nil &&
                PPOFavoriteAppRows(@[], nil, favoritesOnly) == nil,
                "absent projection inputs are invalid in either view");
            for (id invalidInventory in @[@1, @{}, @"apps", NSNull.null, @[@1], @[@[]], @[NSNull.null],
                    @[@{}], @[@{@"bundleIdentifier": Alpha}], @[@{@"name": @"Alpha"}],
                    @[App(@"", @"Name")], @[App(Alpha, @"")],
                    @[@{@"bundleIdentifier": @1, @"name": @"Name"}],
                    @[@{@"bundleIdentifier": Alpha, @"name": @1}], @[apps[0], apps[0]]])
                Check(PPOFavoriteAppRows(invalidInventory, @[], favoritesOnly) == nil,
                    "malformed inventory and exact duplicate inventory identities are rejected");
            Check(PPOFavoriteAppRows(apps, @[Alpha, Alpha], favoritesOnly) == nil &&
                PPOFavoriteAppRows(apps, @[@"com.apple.springboard"], favoritesOnly) == nil,
                "projection validates favorite identifiers before either view");
            for (id invalidFavorites in @[@1, @{}, @"favorites", NSNull.null, maximum])
                Check(PPOFavoriteAppRows(apps, invalidFavorites, favoritesOnly) == nil,
                    "wrong-type and oversized favorite inputs invalidate either projection");
            if (favoritesOnly) break;
        }
        NSString *limitText = [@"a" stringByPaddingToLength:512 withString:@"a" startingAtIndex:0];
        Check(PPOFavoriteAppRows(@[App(limitText, limitText)], @[], NO).count == 1,
            "inventory identifier and display name accept the 512-character text boundary");
        Check(PPOFavoriteAppRows(@[App([limitText stringByAppendingString:@"a"], @"Name")], @[], NO) == nil &&
            PPOFavoriteAppRows(@[App(Alpha, [limitText stringByAppendingString:@"a"])], @[], YES) == nil,
            "oversized inventory identifiers or names are rejected before projection");
        NSMutableArray *manyApps = [NSMutableArray array];
        for (NSUInteger i = 0; i < 4096; i++)
            [manyApps addObject:App([NSString stringWithFormat:@"com.inventory.app%lu", (unsigned long)i], @"Name")];
        Check(PPOFavoriteAppRows(manyApps, @[], NO).count == 4096,
            "the exact 4096-entry inventory boundary is accepted");
        [manyApps addObject:App(@"com.inventory.extra", @"Name")];
        Check(PPOFavoriteAppRows(manyApps, @[], NO) == nil && PPOFavoriteAppRows(manyApps, @[], YES) == nil,
            "oversized inventory is rejected even when the requested favorite view would be empty");

        NSMutableString *mutableID = [Alpha mutableCopy];
        NSMutableString *mutableName = [@"Original Name" mutableCopy];
        NSMutableDictionary *mutableApp = [@{@"bundleIdentifier": mutableID, @"name": mutableName} mutableCopy];
        NSMutableArray *mutableApps = [NSMutableArray arrayWithObject:mutableApp];
        NSMutableString *mutableMissing = [Missing mutableCopy];
        NSArray *copiedAll = PPOFavoriteAppRows(mutableApps, @[mutableID], NO);
        NSArray *copiedQuick = PPOFavoriteAppRows(mutableApps, @[mutableID, mutableMissing], YES);
        [mutableID setString:Beta]; [mutableName setString:@"Changed Name"];
        [mutableMissing setString:@"com.example.changed"]; [mutableApp removeAllObjects];
        [mutableApps removeAllObjects];
        Row(copiedAll[0], Alpha, @"Original Name", YES, YES);
        Row(copiedQuick[0], Alpha, @"Original Name", YES, YES);
        Row(copiedQuick[1], Missing, Missing, NO, YES);
        Check(![copiedAll isKindOfClass:NSMutableArray.class] &&
            ![copiedAll[0] isKindOfClass:NSMutableDictionary.class] &&
            ![copiedAll[0][@"bundleIdentifier"] isKindOfClass:NSMutableString.class] &&
            ![copiedAll[0][@"name"] isKindOfClass:NSMutableString.class] &&
            ![copiedQuick[1][@"bundleIdentifier"] isKindOfClass:NSMutableString.class] &&
            ![copiedQuick[1][@"name"] isKindOfClass:NSMutableString.class],
            "projected arrays, rows, names and identifiers are immutable caller-independent values");
        printf("Favorite apps tests passed: %u checks\n", checks);
    }
    return 0;
}
