#import "PPOPickerState.h"
#import "PPOFavoriteApps.h"
#import "PPOSceneCapability.h"

@interface PPOPickerTicket ()
@property(nonatomic, readonly) NSUInteger selectionGeneration;
@property(nonatomic, readonly) NSUInteger favoriteGeneration;
@property(nonatomic, readonly) BOOL selectionWasSaving;
- (instancetype)initWithSelection:(NSDictionary *)selection
                expectedFavorites:(NSArray<NSString *> *)expectedFavorites
             replacementFavorites:(NSArray<NSString *> *)replacementFavorites
              selectionGeneration:(NSUInteger)selectionGeneration
               favoriteGeneration:(NSUInteger)favoriteGeneration
               selectionWasSaving:(BOOL)selectionWasSaving;
@end

@implementation PPOPickerTicket
- (instancetype)initWithSelection:(NSDictionary *)selection
                expectedFavorites:(NSArray<NSString *> *)expectedFavorites
             replacementFavorites:(NSArray<NSString *> *)replacementFavorites
              selectionGeneration:(NSUInteger)selectionGeneration
               favoriteGeneration:(NSUInteger)favoriteGeneration
               selectionWasSaving:(BOOL)selectionWasSaving {
    self = [super init];
    if (self) {
        _selection = [selection copy];
        _expectedFavorites = [expectedFavorites copy] ?: @[];
        _replacementFavorites = [replacementFavorites copy] ?: @[];
        _selectionGeneration = selectionGeneration;
        _favoriteGeneration = favoriteGeneration;
        _selectionWasSaving = selectionWasSaving;
    }
    return self;
}
@end

static BOOL PickerText(id value) {
    return [value isKindOfClass:NSString.class] &&
        [(NSString *)value length] > 0 && [(NSString *)value length] <= 512;
}

static NSArray<NSDictionary *> *PickerInventory(id value) {
    @try {
        if (![value isKindOfClass:NSArray.class] || [(NSArray *)value count] > 4096) return nil;
        NSMutableArray<NSDictionary *> *apps = [NSMutableArray arrayWithCapacity:[value count]];
        NSMutableSet<NSString *> *identifiers = [NSMutableSet set];
        for (id item in (NSArray *)value) {
            if (![item isKindOfClass:NSDictionary.class] ||
                !PickerText(item[@"bundleIdentifier"]) || !PickerText(item[@"name"])) return nil;
            NSString *identifier = [item[@"bundleIdentifier"] copy];
            if ([identifiers containsObject:identifier]) return nil;
            [identifiers addObject:identifier];
            [apps addObject:@{@"bundleIdentifier": identifier, @"name": [item[@"name"] copy]}];
        }
        return [apps copy];
    } @catch (NSException *exception) { (void)exception; return nil; }
}

static NSDictionary *PickerApp(NSArray<NSDictionary *> *apps, NSString *identifier) {
    for (NSDictionary *app in apps) {
        if ([app[@"bundleIdentifier"] isEqual:identifier]) return app;
    }
    return nil;
}

static NSDictionary *PickerDiskSelection(id value, NSArray<NSDictionary *> *apps) {
    @try {
        if (![value isKindOfClass:NSDictionary.class] ||
            !PickerText(value[@"bundleIdentifier"]) || !PickerText(value[@"name"]) ||
            !PPOSceneApplicationIdentifierAllowed(value[@"bundleIdentifier"])) return nil;
        return PickerApp(apps, value[@"bundleIdentifier"]);
    } @catch (NSException *exception) { (void)exception; return nil; }
}

@implementation PPOPickerState {
    PPOPickerTicket *_loadTicket;
    PPOPickerTicket *_selectionTicket;
    PPOPickerTicket *_favoriteTicket;
    NSUInteger _favoriteGeneration;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _apps = @[];
        _favoriteIdentifiers = @[];
    }
    return self;
}

- (void)requestListFavoritesOnly:(BOOL)favoritesOnly {
    _listRequested = YES;
    _favoritesOnly = favoritesOnly;
}

- (void)closeList {
    _listRequested = NO;
}

- (PPOPickerTicket *)beginLoad {
    if (_loading || _favoritesSaving) return nil;
    _loadTicket = [[PPOPickerTicket alloc] initWithSelection:nil
        expectedFavorites:nil replacementFavorites:nil
        selectionGeneration:_selectionGeneration favoriteGeneration:_favoriteGeneration
        selectionWasSaving:_selectionSaving];
    _loading = YES;
    return _loadTicket;
}

- (BOOL)finishLoad:(PPOPickerTicket *)ticket apps:(NSArray *)apps
         selection:(NSDictionary *)diskSelection favorites:(NSArray *)diskFavorites {
    if (!ticket || ticket != _loadTicket) return NO;
    _loadTicket = nil;
    _loading = NO;
    NSArray<NSDictionary *> *canonicalApps = PickerInventory(apps);
    if (!canonicalApps) return YES;
    _apps = canonicalApps;

    // A load begun during a write may have read the previous file, even if
    // that write completed before the load callback reached this queue.
    if (ticket.selectionGeneration == _selectionGeneration &&
        !ticket.selectionWasSaving && !_selectionSaving) {
        NSString *identifier = PickerDiskSelection(diskSelection, _apps)[@"bundleIdentifier"];
        if (![_selectedIdentifier isEqual:identifier] && (_selectedIdentifier || identifier)) {
            _selectedIdentifier = [identifier copy];
            _selectionGeneration++;
        }
    } else if (_selectedIdentifier && !PickerApp(_apps, _selectedIdentifier)) {
        _selectedIdentifier = nil;
        _selectionGeneration++;
        _selectionTicket = nil;
        _selectionSaving = NO;
    }

    if (ticket.favoriteGeneration == _favoriteGeneration && !_favoritesSaving) {
        NSArray<NSString *> *identifiers = PPOFavoriteIdentifiersNormalize(diskFavorites);
        _favoritesReadable = identifiers != nil;
        if (identifiers) _favoriteIdentifiers = identifiers;
    }
    return YES;
}

- (PPOPickerTicket *)beginSelection:(NSString *)identifier {
    if (!PPOSceneApplicationIdentifierAllowed(identifier)) return nil;
    NSDictionary *app = PickerApp(_apps, identifier);
    if (!app) return nil;
    _selectionGeneration++;
    _selectedIdentifier = [app[@"bundleIdentifier"] copy];
    _selectionSaving = YES;
    _selectionTicket = [[PPOPickerTicket alloc] initWithSelection:app
        expectedFavorites:nil replacementFavorites:nil
        selectionGeneration:_selectionGeneration favoriteGeneration:_favoriteGeneration
        selectionWasSaving:YES];
    return _selectionTicket;
}

- (BOOL)finishSelection:(PPOPickerTicket *)ticket saved:(BOOL)saved {
    if (!ticket || ticket != _selectionTicket || ticket.selectionGeneration != _selectionGeneration) return NO;
    _selectionTicket = nil;
    _selectionSaving = NO;
    if (!saved) {
        _selectedIdentifier = nil;
        _selectionGeneration++;
    }
    return YES;
}

- (PPOPickerTicket *)beginFavoriteToggle:(NSString *)identifier {
    if (!_favoritesReadable || _favoritesSaving || _loading ||
        !PPOSceneApplicationIdentifierAllowed(identifier)) return nil;
    NSMutableArray<NSString *> *replacement = [_favoriteIdentifiers mutableCopy];
    NSUInteger index = [replacement indexOfObject:identifier];
    if (index != NSNotFound) {
        [replacement removeObjectAtIndex:index];
    } else {
        if (!PickerApp(_apps, identifier) || replacement.count >= PPOFavoriteIdentifiersLimit) return nil;
        [replacement addObject:[identifier copy]];
    }
    _favoriteGeneration++;
    _favoritesSaving = YES;
    _favoriteTicket = [[PPOPickerTicket alloc] initWithSelection:nil
        expectedFavorites:_favoriteIdentifiers replacementFavorites:replacement
        selectionGeneration:_selectionGeneration favoriteGeneration:_favoriteGeneration
        selectionWasSaving:_selectionSaving];
    return _favoriteTicket;
}

- (BOOL)finishFavorite:(PPOPickerTicket *)ticket saved:(BOOL)saved {
    if (!ticket || ticket != _favoriteTicket) return NO;
    _favoriteTicket = nil;
    _favoritesSaving = NO;
    if (saved) _favoriteIdentifiers = ticket.replacementFavorites;
    else _favoritesReadable = NO;
    return YES;
}

- (NSArray<NSDictionary *> *)rows {
    return PPOFavoriteAppRows(_apps, _favoriteIdentifiers, _favoritesOnly);
}
@end
