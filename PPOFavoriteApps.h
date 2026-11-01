#pragma once
#import <Foundation/Foundation.h>

// Pure bounded data operations. No I/O, current-clock reads or private APIs.
FOUNDATION_EXPORT NSUInteger const PPOFavoriteIdentifiersLimit;
FOUNDATION_EXPORT NSUInteger const PPOFavoriteDataLimit;

// Favorite identity is exact and case-sensitive. Invalid values return nil;
// a valid empty array is distinct from absent or malformed preferences.
NSArray<NSString *> *PPOFavoriteIdentifiersNormalize(id value);
NSArray<NSString *> *PPOFavoriteIdentifiersFromData(NSData *data, NSError **error);
NSData *PPOFavoriteIdentifiersData(NSArray *identifiers, NSError **error);

// Inventory is display data, not application permission or scene eligibility.
// Rows contain only bundleIdentifier, name, available and favorite. All mode
// preserves inventory order; favorites mode preserves stored identifiers and
// keeps absent apps as removable rows. Reading never prunes stored favorites.
NSArray<NSDictionary *> *PPOFavoriteAppRows(NSArray<NSDictionary *> *apps,
    NSArray<NSString *> *favorites, BOOL favoritesOnly);
