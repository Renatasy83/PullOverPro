#import "../PPOPickerState.h"
#include <stdio.h>
#include <stdlib.h>

// Exercise the production coordinator with completions deliberately out of order.
// No preferences, inventory service, launch requests, UI or clocks are used.
static unsigned checks;
static NSString *const Alpha = @"com.example.alpha";
static NSString *const Beta = @"com.example.beta";
static NSString *const Missing = @"com.example.missing";

static void Check(BOOL condition, const char *message) {
    checks++;
    if (!condition) { fprintf(stderr, "FAIL: %s\n", message); exit(1); }
}
static NSDictionary *App(NSString *identifier, NSString *name) {
    return @{@"bundleIdentifier": identifier, @"name": name};
}
static NSArray *Inventory(void) {
    return @[App(Alpha, @"Alpha"), App(Beta, @"Beta")];
}
static PPOPickerState *Loaded(NSArray *apps, NSDictionary *selection, NSArray *favorites) {
    PPOPickerState *state = [PPOPickerState new];
    PPOPickerTicket *load = [state beginLoad];
    Check(load != nil && [state finishLoad:load apps:apps selection:selection favorites:favorites],
        "fixture consumes its actual production load ticket");
    return state;
}
static void Refresh(PPOPickerState *state, NSArray *apps, NSDictionary *selection, NSArray *favorites) {
    PPOPickerTicket *load = [state beginLoad];
    Check(load != nil && [state finishLoad:load apps:apps selection:selection favorites:favorites],
        "refresh consumes its actual production load ticket");
}

static void LoadLifecycle(void) {
    PPOPickerState *state = [PPOPickerState new];
    Check(state.apps.count == 0 && state.favoriteIdentifiers.count == 0 &&
        state.selectedIdentifier == nil && state.selectionGeneration == 0,
        "initial inventory, favorites, target and generation are empty");
    Check(!state.loading && !state.selectionSaving && !state.favoritesSaving &&
        !state.favoritesReadable && !state.listRequested && !state.favoritesOnly,
        "initial pending, readability and visibility flags are false");
    Check([state beginSelection:Alpha] == nil && [state beginFavoriteToggle:Alpha] == nil,
        "uncached targets and unread favorites cannot start writes");
    Check(![state finishLoad:nil apps:Inventory() selection:nil favorites:@[]] &&
        ![state finishSelection:nil saved:YES] && ![state finishFavorite:nil saved:YES],
        "nil tickets cannot complete any operation");

    [state requestListFavoritesOnly:YES];
    PPOPickerTicket *load = [state beginLoad];
    Check(load != nil && state.loading && [state beginLoad] == nil,
        "at most one inventory load can be in flight");
    Check(state.listRequested && state.favoritesOnly, "requested favorites mode is recorded");
    [state requestListFavoritesOnly:NO];
    [state closeList];
    Check(!state.listRequested && state.loading && !state.favoritesOnly,
        "closing the latest requested list preserves its in-flight load");
    Check([state finishLoad:load apps:Inventory() selection:App(Alpha, @"Old disk name") favorites:@[Beta]],
        "closed list can finish loading its cache");
    Check(!state.loading && !state.listRequested && [state.selectedIdentifier isEqual:Alpha] &&
        state.selectionGeneration == 1 && state.favoritesReadable,
        "load selects the persisted member without reopening a closed list");
    Check(![state finishLoad:load apps:@[] selection:nil favorites:@[]] && state.apps.count == 2,
        "load ticket replay cannot overwrite a newer cache");

    load = [state beginLoad];
    [state closeList];
    [state requestListFavoritesOnly:NO];
    [state requestListFavoritesOnly:YES];
    Check([state beginLoad] == nil, "reopening during a load coalesces the inventory work");
    Check([state finishLoad:load apps:Inventory() selection:App(Alpha, @"Alpha") favorites:@[Beta]] &&
        state.listRequested && state.favoritesOnly,
        "completion respects the latest reopened list and mode");

    PPOPickerState *other = [PPOPickerState new];
    PPOPickerTicket *foreign = [other beginLoad];
    load = [state beginLoad];
    Check(![state finishLoad:foreign apps:@[] selection:nil favorites:@[]] && state.loading,
        "a foreign load ticket cannot clear the current load");
    NSUInteger generation = state.selectionGeneration;
    Check([state finishLoad:load apps:nil selection:nil favorites:nil] && !state.loading &&
        state.apps.count == 2 && [state.selectedIdentifier isEqual:Alpha] &&
        state.selectionGeneration == generation && [state.favoriteIdentifiers isEqual:@[Beta]] &&
        state.favoritesReadable, "failed refresh consumes only loading and preserves all cached state");
    Check([other finishLoad:foreign apps:@[] selection:nil favorites:@[]],
        "the issuing state still owns its foreign load ticket");
    Refresh(state, @[App(Alpha, @"Alpha"), App(Alpha, @"Duplicate")], nil, nil);
    Check(state.apps.count == 2 && [state.selectedIdentifier isEqual:Alpha] &&
        state.favoritesReadable && [state.favoriteIdentifiers isEqual:@[Beta]],
        "malformed nonnil report preserves the entire last valid cache");
    Refresh(state, @[], App(Alpha, @"Alpha"), @[Beta]);
    Check(state.apps.count == 0 && state.selectedIdentifier == nil &&
        state.selectionGeneration == generation + 1 && [state.favoriteIdentifiers isEqual:@[Beta]],
        "valid empty report clears an unavailable target but never prunes favorites");
}

static void SelectionOwnership(void) {
    PPOPickerState *state = Loaded(Inventory(), nil, @[]);
    Check([state beginSelection:nil] == nil && [state beginSelection:Missing] == nil &&
        [state beginSelection:@"com.apple.springboard"] == nil,
        "selection requires an allowed actual inventory member");
    PPOPickerTicket *first = [state beginSelection:Alpha];
    Check(first != nil && [first.selection isEqual:App(Alpha, @"Alpha")] &&
        state.selectionSaving && state.selectionGeneration == 1,
        "selection ticket captures the canonical inventory app and starts a new generation");
    PPOPickerTicket *second = [state beginSelection:Beta];
    Check(second != nil && [state.selectedIdentifier isEqual:Beta] && state.selectionGeneration == 2,
        "a newer target replaces an in-flight selection");
    Check(![state finishSelection:first saved:NO] && state.selectionSaving &&
        [state.selectedIdentifier isEqual:Beta] && state.selectionGeneration == 2,
        "failed stale selection save has no effect on the newer target");
    Check([state finishSelection:second saved:YES] && !state.selectionSaving &&
        [state.selectedIdentifier isEqual:Beta] && state.selectionGeneration == 2,
        "only the latest successful save clears its pending flag");
    Check(![state finishSelection:second saved:NO] && [state.selectedIdentifier isEqual:Beta],
        "replayed failure cannot clear an already saved target");

    PPOPickerState *other = Loaded(Inventory(), nil, @[]);
    PPOPickerTicket *foreign = [other beginSelection:Beta];
    first = [state beginSelection:Alpha];
    PPOPickerTicket *load = [state beginLoad];
    Check(load != nil && ![state finishSelection:foreign saved:NO] &&
        ![state finishSelection:load saved:YES] && state.selectionSaving,
        "foreign and wrong-operation tickets preserve the active selection save");
    Check([state finishSelection:first saved:NO] && !state.selectionSaving &&
        state.selectedIdentifier == nil && state.selectionGeneration == 4,
        "current save failure clears the target and invalidates its generation");
    Check([state finishLoad:load apps:Inventory() selection:App(Beta, @"Beta") favorites:@[]] &&
        state.selectedIdentifier == nil && state.selectionGeneration == 4,
        "an older disk read cannot resurrect a target cleared by a failed save");
    Check([other finishSelection:foreign saved:YES], "foreign selection remains owned by its issuer");
}

static void SelectionLoadRaces(void) {
    PPOPickerState *state = Loaded(Inventory(), App(Alpha, @"Alpha"), @[]);
    PPOPickerTicket *load = [state beginLoad];
    PPOPickerTicket *save = [state beginSelection:Beta];
    NSUInteger generation = state.selectionGeneration;
    Check([state finishLoad:load apps:Inventory() selection:App(Alpha, @"Alpha") favorites:@[]] &&
        [state.selectedIdentifier isEqual:Beta] && state.selectionSaving &&
        state.selectionGeneration == generation,
        "new selection survives a load that captured the previous target");
    Check([state finishSelection:save saved:YES], "newer target save completes after older load");

    save = [state beginSelection:Beta];
    load = [state beginLoad];
    Check(load != nil && [state finishSelection:save saved:YES],
        "inventory loading is permitted while a selection write is pending");
    generation = state.selectionGeneration;
    Check([state finishLoad:load apps:Inventory() selection:App(Alpha, @"Alpha") favorites:@[]] &&
        [state.selectedIdentifier isEqual:Beta] && state.selectionGeneration == generation,
        "a load begun during a now-completed save cannot restore older disk selection");

    load = [state beginLoad];
    save = [state beginSelection:Beta];
    generation = state.selectionGeneration;
    Check([state finishLoad:load apps:@[App(Alpha, @"Renamed Alpha")]
        selection:App(Alpha, @"Alpha") favorites:@[]] && state.selectedIdentifier == nil &&
        !state.selectionSaving && state.selectionGeneration == generation + 1,
        "refresh missing the newer pending target clears it and cancels its ticket");
    Check(![state finishSelection:save saved:YES] && state.selectedIdentifier == nil,
        "successful stale write cannot restore a target removed by inventory reconciliation");
    Check([state beginSelection:Beta] == nil, "removed apps cannot be selected from old rows");
    save = [state beginSelection:Alpha];
    Check([save.selection[@"name"] isEqual:@"Renamed Alpha"] && [state finishSelection:save saved:YES],
        "selection after refresh uses the current app name");

    generation = state.selectionGeneration;
    Refresh(state, Inventory(), App(Missing, @"Unavailable disk app"), @[]);
    Check(state.selectedIdentifier == nil && state.selectionGeneration == generation + 1,
        "persisted unavailable target clears current selection without choosing a fallback app");
    Refresh(state, Inventory(), @{@"bundleIdentifier": Alpha}, @[]);
    Check(state.selectedIdentifier == nil, "malformed disk selection cannot select an inventory app");
    Refresh(state, @[App(@"com.apple.springboard", @"System")],
        App(@"com.apple.springboard", @"System"), @[]);
    Check(state.selectedIdentifier == nil && [state beginSelection:@"com.apple.springboard"] == nil,
        "inventory membership does not bypass the application identifier policy");
}

static void FavoriteTransactions(void) {
    PPOPickerState *state = Loaded(Inventory(), nil, nil);
    Check(!state.favoritesReadable && [state beginFavoriteToggle:Alpha] == nil,
        "missing favorites remain unreadable rather than silently becoming writable empty data");
    Refresh(state, Inventory(), nil, @[]);
    PPOPickerTicket *favorite = [state beginFavoriteToggle:Alpha];
    Check(favorite != nil && [favorite.expectedFavorites isEqual:@[]] &&
        [favorite.replacementFavorites isEqual:@[Alpha]] && state.favoriteIdentifiers.count == 0,
        "favorite addition freezes expected and replacement values without optimistic commit");
    Check(state.favoritesSaving && [state beginFavoriteToggle:Beta] == nil && [state beginLoad] == nil,
        "favorite transaction excludes other favorite writes and loads");
    PPOPickerTicket *save = [state beginSelection:Beta];
    Check(save != nil && [state finishSelection:save saved:YES],
        "favorite persistence does not block an independent target selection");
    Check([state finishFavorite:favorite saved:YES] && !state.favoritesSaving &&
        state.favoritesReadable && [state.favoriteIdentifiers isEqual:@[Alpha]] &&
        [state.selectedIdentifier isEqual:Beta], "successful favorite write commits only its replacement");
    Check(![state finishFavorite:favorite saved:NO] && state.favoritesReadable,
        "favorite ticket replay cannot make saved data unreadable");

    PPOPickerTicket *next = [state beginFavoriteToggle:Beta];
    Check([next.expectedFavorites isEqual:@[Alpha]] &&
        [next.replacementFavorites isEqual:@[Alpha, Beta]], "favorite additions preserve stored order");
    Check(![state finishFavorite:favorite saved:NO] && state.favoritesSaving && state.favoritesReadable,
        "old favorite failure cannot alter the newer transaction");
    Check([state finishFavorite:next saved:NO] && !state.favoritesSaving &&
        !state.favoritesReadable && [state.favoriteIdentifiers isEqual:@[Alpha]],
        "current favorite failure preserves last known IDs and disables further writes");
    Check([state beginFavoriteToggle:Alpha] == nil, "unreadable state blocks removal as well as addition");
    Refresh(state, Inventory(), App(Beta, @"Beta"), @[Alpha, Alpha]);
    Check(!state.favoritesReadable && [state.favoriteIdentifiers isEqual:@[Alpha]],
        "corrupt favorite data preserves the last known ordered IDs read only");
    Refresh(state, Inventory(), App(Beta, @"Beta"), nil);
    Check(!state.favoritesReadable && [state.favoriteIdentifiers isEqual:@[Alpha]],
        "missing favorites after a failed write never replace the last known IDs");
    Refresh(state, Inventory(), App(Beta, @"Beta"), @[]);
    Check(state.favoritesReadable && state.favoriteIdentifiers.count == 0,
        "valid empty preferences restore writes and explicitly clear the favorites");
    PPOPickerTicket *load = [state beginLoad];
    Check([state beginFavoriteToggle:Alpha] == nil, "loading blocks favorite writes against stale disk data");
    Check([state finishLoad:load apps:Inventory() selection:App(Beta, @"Beta") favorites:@[]],
        "blocking a favorite toggle does not disturb its load");
}

static void FavoriteLimitAndRows(void) {
    NSMutableArray<NSString *> *full = [NSMutableArray arrayWithObject:Missing];
    for (NSUInteger i = 1; i < 16; i++)
        [full addObject:[NSString stringWithFormat:@"com.example.favorite%lu", (unsigned long)i]];
    PPOPickerState *state = Loaded(Inventory(), nil, full);
    Check(state.favoriteIdentifiers.count == 16 && [state beginFavoriteToggle:Beta] == nil,
        "sixteen stored favorites prevent a seventeenth addition");
    Check([state beginFavoriteToggle:@"com.apple.springboard"] == nil &&
        [state beginFavoriteToggle:@"invalid"] == nil && [state beginFavoriteToggle:nil] == nil,
        "favorites reject excluded, malformed and nil identifiers");
    PPOPickerTicket *remove = [state beginFavoriteToggle:Missing];
    Check(remove != nil && remove.expectedFavorites.count == 16 && remove.replacementFavorites.count == 15 &&
        state.favoriteIdentifiers.count == 16, "unavailable favorites remain removable at the full limit");
    Check([state finishFavorite:remove saved:YES] && state.favoriteIdentifiers.count == 15,
        "successful unavailable removal releases one slot");
    PPOPickerTicket *add = [state beginFavoriteToggle:Beta];
    Check(add != nil && [add.replacementFavorites.lastObject isEqual:Beta] &&
        [state finishFavorite:add saved:YES], "addition after removal appends the current installed app");

    Refresh(state, @[App(Beta, @"Beta Current")], nil, @[Missing, Beta, Alpha]);
    [state requestListFavoritesOnly:YES];
    NSArray<NSDictionary *> *rows = state.rows;
    Check(rows.count == 3 && [rows[0][@"bundleIdentifier"] isEqual:Missing] &&
        [rows[1][@"bundleIdentifier"] isEqual:Beta] && [rows[2][@"bundleIdentifier"] isEqual:Alpha],
        "favorites rows retain stored order including unavailable IDs");
    Check([rows[0][@"name"] isEqual:Missing] && ![rows[0][@"available"] boolValue] &&
        [rows[0][@"favorite"] boolValue] && [rows[1][@"name"] isEqual:@"Beta Current"] &&
        [rows[1][@"available"] boolValue], "favorites rows show current names and removable missing placeholders");
    [state requestListFavoritesOnly:NO];
    rows = state.rows;
    Check(rows.count == 1 && [rows[0][@"bundleIdentifier"] isEqual:Beta] &&
        [rows[0][@"favorite"] boolValue], "all mode projects only the current inventory with favorite status");
    Refresh(state, @[], nil, @[Missing, Beta, Alpha]);
    Check(state.favoriteIdentifiers.count == 3, "empty inventory never prunes any unavailable favorite");
}

static void ForeignFavoriteCompletion(void) {
    PPOPickerState *state = Loaded(Inventory(), nil, @[Alpha]);
    PPOPickerState *other = Loaded(Inventory(), nil, @[Beta]);
    PPOPickerTicket *foreign = [other beginFavoriteToggle:Beta];
    PPOPickerTicket *load = [state beginLoad];
    Check(![state finishFavorite:foreign saved:NO] && state.loading && state.favoritesReadable &&
        [state.favoriteIdentifiers isEqual:@[Alpha]],
        "foreign favorite failure during load cannot poison this state's cached favorites");
    Check(![state finishLoad:foreign apps:@[] selection:nil favorites:nil] && state.loading,
        "a favorite ticket cannot consume an inventory load");
    Check([state finishLoad:load apps:Inventory() selection:nil favorites:@[Beta]] &&
        [state.favoriteIdentifiers isEqual:@[Beta]], "valid load still applies after foreign failure");
    Check([other finishFavorite:foreign saved:NO] && !other.favoritesReadable &&
        [other.favoriteIdentifiers isEqual:@[Beta]], "only the issuing state consumes its favorite failure");
    PPOPickerTicket *favorite = [state beginFavoriteToggle:Beta];
    Check(![state finishFavorite:load saved:NO] && state.favoritesSaving && state.favoritesReadable,
        "replayed load cannot consume or corrupt an active favorite write");
    Check([state finishFavorite:favorite saved:YES] && state.favoriteIdentifiers.count == 0,
        "current favorite write survives wrong-operation completion");
}

static void FrozenInputs(void) {
    NSMutableString *identifier = [Alpha mutableCopy];
    NSMutableString *name = [@"Original Alpha" mutableCopy];
    NSMutableDictionary *app = [@{@"bundleIdentifier": identifier, @"name": name,
        @"metadata": [NSMutableArray arrayWithObject:@"discarded"]} mutableCopy];
    NSMutableArray *apps = [NSMutableArray arrayWithObject:app];
    NSMutableString *favoriteID = [Alpha mutableCopy];
    NSMutableArray *favorites = [NSMutableArray arrayWithObject:favoriteID];
    PPOPickerState *state = Loaded(apps, App(Alpha, @"Disk name"), favorites);
    PPOPickerTicket *selection = [state beginSelection:Alpha];
    PPOPickerTicket *favorite = [state beginFavoriteToggle:Alpha];
    [identifier appendString:@".changed"];
    [name appendString:@" changed"];
    [favoriteID appendString:@".changed"];
    [app removeAllObjects];
    [apps removeAllObjects];
    [favorites removeAllObjects];
    Check(state.apps.count == 1 && [state.apps[0] isEqual:App(Alpha, @"Original Alpha")] &&
        [state.selectedIdentifier isEqual:Alpha] && [state.favoriteIdentifiers isEqual:@[Alpha]],
        "accepted inventory and preferences deeply copy caller-owned mutable leaves");
    Check([selection.selection isEqual:App(Alpha, @"Original Alpha")] &&
        [favorite.expectedFavorites isEqual:@[Alpha]] && favorite.replacementFavorites.count == 0,
        "operation tickets retain frozen canonical values after caller mutation");
    Check([state finishSelection:selection saved:YES] && [state finishFavorite:favorite saved:YES],
        "frozen operation snapshots remain consumable after input mutation");
    Check(state.apps[0].count == 2, "inventory cache strips unrelated mutable metadata");

    Refresh(state, Inventory(), nil, @[]);
    NSMutableString *requested = [Beta mutableCopy];
    selection = [state beginSelection:requested];
    favorite = [state beginFavoriteToggle:requested];
    [requested appendString:@".changed"];
    Check([selection.selection[@"bundleIdentifier"] isEqual:Beta] &&
        [favorite.replacementFavorites isEqual:@[Beta]],
        "mutable operation identifiers cannot change frozen target or favorite snapshots");
    Check([state finishSelection:selection saved:YES] && [state finishFavorite:favorite saved:YES] &&
        [state.selectedIdentifier isEqual:Beta] && [state.favoriteIdentifiers isEqual:@[Beta]],
        "committed operations retain the identifiers that were originally requested");
}

int main(void) {
    @autoreleasepool {
        LoadLifecycle();
        SelectionOwnership();
        SelectionLoadRaces();
        FavoriteTransactions();
        FavoriteLimitAndRows();
        ForeignFavoriteCompletion();
        FrozenInputs();
        printf("Picker state tests passed: %u checks; production coordinator fixtures only\n", checks);
    }
    return 0;
}
