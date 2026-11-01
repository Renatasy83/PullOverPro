#import "PPOFavoriteApps.h"
#import "PPOSceneCapability.h"
#import <CoreFoundation/CoreFoundation.h>

NSUInteger const PPOFavoriteIdentifiersLimit = 16;
NSUInteger const PPOFavoriteDataLimit = 16384;

static void FavoriteAppsError(NSError **error) {
    if (error) *error = [NSError errorWithDomain:@"PullOverPro.FavoriteApps" code:1
        userInfo:@{NSLocalizedDescriptionKey: @"Invalid PPO favorite application data"}];
}

NSArray<NSString *> *PPOFavoriteIdentifiersNormalize(id value) {
    @try {
        if (![value isKindOfClass:NSArray.class] ||
            [(NSArray *)value count] > PPOFavoriteIdentifiersLimit) return nil;
        NSMutableArray<NSString *> *identifiers = [NSMutableArray arrayWithCapacity:[value count]];
        NSMutableSet<NSString *> *seen = [NSMutableSet set];
        for (id identifier in (NSArray *)value) {
            if (!PPOSceneApplicationIdentifierAllowed(identifier) || [seen containsObject:identifier]) return nil;
            NSString *copied = [identifier copy];
            [seen addObject:copied];
            [identifiers addObject:copied];
        }
        return [identifiers copy];
    } @catch (NSException *exception) { (void)exception; return nil; }
}

NSArray<NSString *> *PPOFavoriteIdentifiersFromData(NSData *data, NSError **error) {
    if (error) *error = nil;
    @try {
        if (![data isKindOfClass:NSData.class] || !data.length || data.length > PPOFavoriteDataLimit) {
            FavoriteAppsError(error); return nil;
        }
        id value = [NSPropertyListSerialization propertyListWithData:data
            options:NSPropertyListImmutable format:NULL error:error];
        if (![value isKindOfClass:NSDictionary.class] || [(NSDictionary *)value count] != 2) {
            FavoriteAppsError(error); return nil;
        }
        NSDictionary *raw = value;
        for (id key in raw) {
            if (![key isKindOfClass:NSString.class] ||
                (![(NSString *)key isEqualToString:@"schema"] &&
                 ![(NSString *)key isEqualToString:@"bundleIdentifiers"])) {
                FavoriteAppsError(error); return nil;
            }
        }
        id schema = raw[@"schema"];
        if (![schema isKindOfClass:NSNumber.class] ||
            CFGetTypeID((__bridge CFTypeRef)schema) == CFBooleanGetTypeID() ||
            ![(NSNumber *)schema isEqualToNumber:@1]) {
            FavoriteAppsError(error); return nil;
        }
        NSArray<NSString *> *identifiers = PPOFavoriteIdentifiersNormalize(raw[@"bundleIdentifiers"]);
        if (!identifiers) FavoriteAppsError(error);
        return identifiers;
    } @catch (NSException *exception) {
        (void)exception; FavoriteAppsError(error); return nil;
    }
}

NSData *PPOFavoriteIdentifiersData(NSArray *identifiers, NSError **error) {
    if (error) *error = nil;
    @try {
        NSArray<NSString *> *normalized = PPOFavoriteIdentifiersNormalize(identifiers);
        if (!normalized) { FavoriteAppsError(error); return nil; }
        NSData *data = [NSPropertyListSerialization dataWithPropertyList:
            @{@"schema": @1, @"bundleIdentifiers": normalized}
            format:NSPropertyListXMLFormat_v1_0 options:0 error:error];
        if (!data || data.length > PPOFavoriteDataLimit) {
            FavoriteAppsError(error); return nil;
        }
        return data;
    } @catch (NSException *exception) {
        (void)exception; FavoriteAppsError(error); return nil;
    }
}

static BOOL FavoriteInventoryText(id value) {
    return [value isKindOfClass:NSString.class] &&
        [(NSString *)value length] > 0 && [(NSString *)value length] <= 512;
}

NSArray<NSDictionary *> *PPOFavoriteAppRows(NSArray<NSDictionary *> *apps,
    NSArray<NSString *> *favorites, BOOL favoritesOnly) {
    @try {
        NSArray<NSString *> *identifiers = PPOFavoriteIdentifiersNormalize(favorites);
        if (!identifiers || ![apps isKindOfClass:NSArray.class] || apps.count > 4096) return nil;
        NSSet<NSString *> *favoriteSet = [NSSet setWithArray:identifiers];
        NSMutableDictionary<NSString *, NSDictionary *> *inventory = [NSMutableDictionary dictionary];
        NSMutableArray<NSDictionary *> *allRows = [NSMutableArray arrayWithCapacity:apps.count];
        for (id item in apps) {
            if (![item isKindOfClass:NSDictionary.class] ||
                !FavoriteInventoryText(item[@"bundleIdentifier"]) || !FavoriteInventoryText(item[@"name"])) return nil;
            NSString *identifier = [item[@"bundleIdentifier"] copy];
            if (inventory[identifier]) return nil;
            NSDictionary *row = @{@"bundleIdentifier": identifier, @"name": [item[@"name"] copy],
                @"available": @YES, @"favorite": @([favoriteSet containsObject:identifier])};
            inventory[identifier] = row;
            [allRows addObject:row];
        }
        if (!favoritesOnly) return [allRows copy];
        NSMutableArray<NSDictionary *> *favoriteRows = [NSMutableArray arrayWithCapacity:identifiers.count];
        for (NSString *identifier in identifiers) {
            NSDictionary *installed = inventory[identifier];
            [favoriteRows addObject:@{@"bundleIdentifier": [identifier copy],
                @"name": installed ? [installed[@"name"] copy] : [identifier copy],
                @"available": @(installed != nil), @"favorite": @YES}];
        }
        return [favoriteRows copy];
    } @catch (NSException *exception) { (void)exception; return nil; }
}
