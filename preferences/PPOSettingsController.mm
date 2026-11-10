// PullOver Pro port — GPL-3.0. Original project: c1d3r / Will Smillie.
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <dispatch/dispatch.h>
#import "../PPOUserPreferences.h"
#import "../PPOAppData.h"
#import "../PPOFavoriteApps.h"
#import "../PPOFavoritesStore.h"

// PreferenceLoader requires a PSViewController subclass. Exact 23A355
// Preferences (UUID675F7F4F-9700-3B53-9C25-C717728BD095) declares this base
// directly under UIViewController. No additional private methods or ivars are
// used here; the page is built entirely with public UIKit controls.
@interface PSViewController : UIViewController
@end

@interface PPOSettingsControl : UIStepper
@property(nonatomic, copy) NSString *preferenceKey;
@end
@implementation PPOSettingsControl
@end

@interface PPOSettingsSwitch : UISwitch
@property(nonatomic, copy) NSString *preferenceKey;
@end
@implementation PPOSettingsSwitch
@end

static NSString *const PPOSettingsInventoryPath = @"/var/mobile/Library/Logs/PullOverPro/apps-0.5.7.json";
static NSString *const PPOSettingsFavoritesDirectory = @"/var/mobile/Library/Preferences/com.renatasy83.pulloverpro.diagnostic.favorites";

@interface PPOFavoritesEditorController : UITableViewController
@property(nonatomic, strong) dispatch_queue_t storageQueue;
@property(nonatomic, copy) NSArray<NSDictionary *> *inventory;
@property(nonatomic, copy) NSArray<NSString *> *favoriteIdentifiers;
@property(nonatomic, copy) NSArray<NSDictionary *> *favoriteRows;
@property(nonatomic, copy) NSArray<NSDictionary *> *availableRows;
@property(nonatomic, copy) NSString *statusMessage;
@property(nonatomic, strong) UIBarButtonItem *reloadButton;
@property(nonatomic) uint64_t loadGeneration;
@property(nonatomic) BOOL inventoryReadable;
@property(nonatomic) BOOL favoritesReadable;
@property(nonatomic) BOOL busy;
@end

@implementation PPOFavoritesEditorController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Aplicații favorite";
    self.inventory = @[];
    self.favoriteIdentifiers = @[];
    self.favoriteRows = @[];
    self.availableRows = @[];
    self.storageQueue = dispatch_queue_create("com.renatasy83.pulloverpro.favorites-settings", DISPATCH_QUEUE_SERIAL);
    self.reloadButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reloadFavorites:)];
    self.navigationItem.rightBarButtonItems = @[self.editButtonItem, self.reloadButton];
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 64;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadFavorites:nil];
}

- (BOOL)canModifyFavorites {
    return !self.busy && self.inventoryReadable && self.favoritesReadable;
}

- (void)setBusy:(BOOL)busy {
    _busy = busy;
    self.tableView.userInteractionEnabled = !busy;
    self.reloadButton.enabled = !busy;
    self.editButtonItem.enabled = !busy && self.inventoryReadable && self.favoritesReadable && self.favoriteIdentifiers.count > 0;
}

- (void)rebuildRows {
    NSArray *favorites = PPOFavoriteAppRows(self.inventory, self.favoriteIdentifiers, YES);
    NSArray *all = PPOFavoriteAppRows(self.inventory, self.favoriteIdentifiers, NO);
    if (!favorites || !all) {
        self.favoritesReadable = NO;
        self.statusMessage = @"Datele nu au putut fi verificate. Favoritele existente nu au fost modificate.";
        return;
    }
    NSMutableArray *available = [NSMutableArray array];
    for (NSDictionary *row in all) {
        if (![row[@"favorite"] boolValue] && PPOFavoriteIdentifiersNormalize(@[row[@"bundleIdentifier"]]))
            [available addObject:row];
    }
    self.favoriteRows = favorites;
    self.availableRows = [available copy];
}

- (void)reloadFavorites:(id)sender {
    (void)sender;
    if (self.busy || !self.storageQueue) return;
    [self setEditing:NO animated:NO];
    uint64_t generation = ++self.loadGeneration;
    self.statusMessage = @"Se citesc aplicațiile și favoritele…";
    self.busy = YES;
    __weak PPOFavoritesEditorController *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{ [weakSelf.tableView reloadData]; });
    dispatch_async(self.storageQueue, ^{
        NSError *favoriteError = nil;
        NSArray *favorites = PPOFavoritesLoad(PPOSettingsFavoritesDirectory, &favoriteError);
        NSError *inventoryError = nil;
        NSData *data = PPOReadBoundedFile(PPOSettingsInventoryPath, 2 * 1024 * 1024, &inventoryError);
        NSArray *inventory = data && !inventoryError ? PPOAppsFromData(data, &inventoryError) : nil;
        BOOL favoriteOK = favorites != nil && favoriteError == nil;
        BOOL inventoryOK = inventory != nil && inventoryError == nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            PPOFavoritesEditorController *strongSelf = weakSelf;
            if (!strongSelf || strongSelf.loadGeneration != generation) return;
            if (favoriteOK) strongSelf.favoriteIdentifiers = favorites;
            if (inventoryOK) strongSelf.inventory = inventory;
            strongSelf.favoritesReadable = favoriteOK;
            strongSelf.inventoryReadable = inventoryOK;
            strongSelf.statusMessage = !favoriteOK
                ? @"Favoritele nu pot fi citite în siguranță. Nu au fost modificate. Reîncearcă folosind butonul de reîncărcare."
                : (!inventoryOK ? @"Deschide lista PPO pentru a actualiza aplicațiile, apoi reîncarcă această pagină. Favoritele existente sunt păstrate." : nil);
            [strongSelf rebuildRows];
            strongSelf.busy = NO;
            [strongSelf.tableView reloadData];
        });
    });
}

- (void)commitFavoriteIdentifiers:(NSArray<NSString *> *)replacement {
    if (![self canModifyFavorites]) return;
    NSArray *normalized = PPOFavoriteIdentifiersNormalize(replacement);
    if (!normalized || [normalized isEqual:self.favoriteIdentifiers]) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self.tableView reloadData]; });
        return;
    }
    NSArray *expected = [self.favoriteIdentifiers copy];
    uint64_t generation = ++self.loadGeneration;
    self.busy = YES;
    self.statusMessage = @"Se salvează favoritele…";
    // UIKit may have moved a row visually. Keep the verified snapshot until
    // the CAS operation and readback finish; failure never removes a row here.
    dispatch_async(dispatch_get_main_queue(), ^{ [self.tableView reloadData]; });
    __weak PPOFavoritesEditorController *weakSelf = self;
    dispatch_async(self.storageQueue, ^{
        NSError *saveError = nil;
        BOOL saved = PPOFavoritesCommit(PPOSettingsFavoritesDirectory, expected, normalized, &saveError);
        NSError *readError = nil;
        NSArray *current = PPOFavoritesLoad(PPOSettingsFavoritesDirectory, &readError);
        BOOL readable = current != nil && readError == nil;
        if (saved && readable) {
            CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                (__bridge CFStringRef)PPOUserPreferencesChangedNotification, NULL, NULL, true);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            PPOFavoritesEditorController *strongSelf = weakSelf;
            if (!strongSelf || strongSelf.loadGeneration != generation) return;
            if (readable) strongSelf.favoriteIdentifiers = current;
            strongSelf.favoritesReadable = readable;
            strongSelf.statusMessage = !readable
                ? @"Verificarea favoritelor nu a reușit. Lista afișată a fost păstrată; reîncarcă înainte de alte modificări."
                : (!saved ? @"Modificarea nu a fost salvată. Lista a fost recitită; o altă schimbare sau o eroare de acces poate necesita reîncercarea."
                    : (![current isEqual:normalized] ? @"Lista a fost schimbată între timp și a fost recitită." : nil));
            [strongSelf rebuildRows];
            strongSelf.busy = NO;
            [strongSelf.tableView reloadData];
        });
    });
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    (void)tableView;
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView;
    return (NSInteger)(section == 0 ? self.favoriteRows.count : self.availableRows.count);
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    (void)tableView;
    return section == 0 ? [NSString stringWithFormat:@"Favorite · %lu/%lu", (unsigned long)self.favoriteIdentifiers.count,
        (unsigned long)PPOFavoriteIdentifiersLimit] : @"Alte aplicații";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    (void)tableView;
    if (section == 0) return self.statusMessage ?: @"Atinge o favorită pentru eliminare. Folosește Editare și trage mânerul unei linii pentru a schimba ordinea. O aplicație absentă din lista salvată rămâne favorită până o elimini.";
    return @"Atinge o aplicație pentru a o adăuga. Alegerea unei favorite nu garantează că aplicația poate fi găzduită într-o fereastră.";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    (void)tableView;
    NSDictionary *row = (indexPath.section == 0 ? self.favoriteRows : self.availableRows)[(NSUInteger)indexPath.row];
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    cell.textLabel.text = row[@"name"];
    cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    cell.textLabel.adjustsFontForContentSizeCategory = YES;
    cell.textLabel.numberOfLines = 0;
    NSString *identifier = row[@"bundleIdentifier"];
    cell.detailTextLabel.text = [row[@"available"] boolValue] ? identifier : [identifier stringByAppendingString:@" · Nu apare în lista salvată"];
    cell.detailTextLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    cell.detailTextLabel.adjustsFontForContentSizeCategory = YES;
    cell.detailTextLabel.numberOfLines = 0;
    cell.accessoryType = indexPath.section == 0 ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (![self canModifyFavorites]) return;
    NSMutableArray *replacement = [self.favoriteIdentifiers mutableCopy];
    if (indexPath.section == 0) {
        if ((NSUInteger)indexPath.row >= replacement.count) return;
        [replacement removeObjectAtIndex:(NSUInteger)indexPath.row];
    } else {
        if ((NSUInteger)indexPath.row >= self.availableRows.count) return;
        if (replacement.count >= PPOFavoriteIdentifiersLimit) {
            self.statusMessage = @"Sunt permise cel mult 16 favorite. Elimină una înainte de a adăuga alta.";
            [self.tableView reloadData];
            return;
        }
        [replacement addObject:self.availableRows[(NSUInteger)indexPath.row][@"bundleIdentifier"]];
    }
    [self commitFavoriteIdentifiers:replacement];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    (void)tableView;
    return indexPath.section == 0 && [self canModifyFavorites];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    (void)tableView;
    return indexPath.section == 0 && self.favoriteIdentifiers.count > 1 && [self canModifyFavorites];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    (void)tableView;
    return indexPath.section == 0 ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    (void)tableView;
    if (editingStyle != UITableViewCellEditingStyleDelete || indexPath.section != 0 ||
        ![self canModifyFavorites] || (NSUInteger)indexPath.row >= self.favoriteIdentifiers.count) return;
    NSMutableArray *replacement = [self.favoriteIdentifiers mutableCopy];
    [replacement removeObjectAtIndex:(NSUInteger)indexPath.row];
    [self commitFavoriteIdentifiers:replacement];
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
    (void)tableView;
    if (sourceIndexPath.section != 0 || !self.favoriteIdentifiers.count) return sourceIndexPath;
    NSUInteger target = proposedDestinationIndexPath.section == 0
        ? MIN((NSUInteger)proposedDestinationIndexPath.row, self.favoriteIdentifiers.count - 1)
        : self.favoriteIdentifiers.count - 1;
    return [NSIndexPath indexPathForRow:(NSInteger)target inSection:0];
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    (void)tableView;
    if (![self canModifyFavorites] || sourceIndexPath.section != 0 || destinationIndexPath.section != 0 ||
        (NSUInteger)sourceIndexPath.row >= self.favoriteIdentifiers.count ||
        (NSUInteger)destinationIndexPath.row >= self.favoriteIdentifiers.count) {
        [self.tableView reloadData];
        return;
    }
    NSMutableArray *replacement = [self.favoriteIdentifiers mutableCopy];
    NSString *identifier = replacement[(NSUInteger)sourceIndexPath.row];
    [replacement removeObjectAtIndex:(NSUInteger)sourceIndexPath.row];
    [replacement insertObject:identifier atIndex:(NSUInteger)destinationIndexPath.row];
    [self commitFavoriteIdentifiers:replacement];
}

@end

@interface PPOSettingsController : PSViewController <UITableViewDataSource, UITableViewDelegate>
@property(nonatomic, strong) UITableView *preferencesTable;
@property(nonatomic, copy) NSDictionary<NSString *, id> *preferences;
@property(nonatomic, strong) dispatch_queue_t preferenceQueue;
@property(nonatomic, copy) NSString *storageStatus;
@property(nonatomic) uint64_t requestGeneration;
@property(nonatomic) BOOL busy;
@end

static NSArray<NSArray<NSDictionary *> *> *PPOSettingsRows(void) {
    static NSArray *rows;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        rows = @[
            @[
                @{@"key": @"enabled", @"title": @"Activează PullOver Pro", @"kind": @"switch"},
                @{@"key": @"edge", @"title": @"Marginea ecranului", @"kind": @"choice",
                    @"values": @[@"left", @"right"], @"labels": @[@"Stânga", @"Dreapta"]},
                @{@"key": @"appearance", @"title": @"Aspect", @"kind": @"choice",
                    @"values": @[@"system", @"light", @"dark"], @"labels": @[@"Sistem", @"Luminos", @"Întunecat"]},
                @{@"key": @"hideInLandscape", @"title": @"Ascunde în modul peisaj", @"kind": @"switch"},
                @{@"key": @"hapticFeedback", @"title": @"Feedback haptic", @"kind": @"switch"}
            ],
            @[
                @{@"key": @"quickSwitchMode", @"title": @"Aplicații în comutator", @"kind": @"choice",
                    @"values": @[@"recent", @"favorites"], @"labels": @[@"Recente", @"Favorite"]},
                @{@"key": @"recentAppsCount", @"title": @"Număr de aplicații recente", @"kind": @"stepper", @"min": @1, @"max": @16, @"step": @1},
                @{@"key": @"quickSwitchScale", @"title": @"Scară comutator", @"kind": @"stepper", @"min": @1, @"max": @3, @"step": @0.25},
                @{@"key": @"hideLabels", @"title": @"Ascunde indicațiile de glisare", @"kind": @"switch"},
                @{@"title": @"Alege/reordonează favoritele", @"kind": @"favorites"}
            ],
            @[
                @{@"key": @"rememberPosition", @"title": @"Memorează poziția mânerului", @"kind": @"switch"},
                @{@"key": @"keyboardAvoiding", @"title": @"Evită tastatura", @"kind": @"switch"},
                @{@"key": @"autoHideHandle", @"title": @"Restrânge automat mânerul", @"kind": @"switch"},
                @{@"key": @"autoHideDelay", @"title": @"Întârziere restrângere", @"kind": @"stepper", @"min": @1, @"max": @30, @"step": @1},
                @{@"key": @"handleSize", @"title": @"Dimensiune mâner", @"kind": @"stepper", @"min": @32, @"max": @72, @"step": @4},
                @{@"key": @"handleOpacity", @"title": @"Opacitate mâner", @"kind": @"stepper", @"min": @0.2, @"max": @1.0, @"step": @0.05}
            ],
            @[
                @{@"key": @"windowSize", @"title": @"Dimensiune inițială", @"kind": @"choice",
                    @"values": @[@3, @0, @1, @2], @"labels": @[@"Sertar", @"Mică", @"Standard", @"Mare"]},
                @{@"key": @"keepWindowOpen", @"title": @"Păstrează fereastra deschisă", @"kind": @"switch"}
            ],
            @[
                @{@"title": @"Prima atingere sau tragere spre interior afișează mânerul și lista de aplicații. Alege o aplicație din listă sau apasă a doua oară mânerul pentru aplicația deja selectată. Pentru o fereastră deja deschisă, mânerul retrage sau readuce sertarul.", @"kind": @"info"},
                @{@"title": @"Când sertarul este închis, trage mânerul spre marginea exterioară pentru a-l restrânge. Apasă lung pentru Recente sau Favorite; atinge de două ori pentru lista completă. În modul Sertar, X de pe mâner închide fereastra.", @"kind": @"info"},
                @{@"title": @"Evită tastatura mută temporar doar mânerul și comutatorul de aplicații într-o zonă liberă când se suprapun cu tastatura. Poziția memorată revine când tastatura dispare; dimensiunea ferestrei aplicației nu se schimbă.", @"kind": @"info"},
                @{@"title": @"Favoritele se aleg și se reordonează pe această pagină sau în lista de aplicații PPO. Lista și favoritele existente sunt păstrate.", @"kind": @"info"},
                @{@"title": @"Recuperare: creează /var/mobile/.ppo_disable și fă respring. Dacă SpringBoard nu pornește, dezactivează tweak injection în Dopamine și dezinstalează doar PPO.", @"kind": @"info"},
                @{@"title": @"PullOver Pro · 1.0.11 RC12\nOriginal: c1d3r / Will Smillie\nPort: Renatasy83 · GPL-3.0", @"kind": @"info"},
                @{@"title": @"Cod sursă și licență", @"kind": @"source"}
            ]
        ];
    });
    return rows;
}

@implementation PPOSettingsController

- (void)loadView {
    if (!self.preferences) self.preferences = PPOUserPreferencesDefaults();
    UITableView *table = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    table.dataSource = self;
    table.delegate = self;
    table.rowHeight = UITableViewAutomaticDimension;
    table.estimatedRowHeight = 64;
    table.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.preferencesTable = table;
    self.view = table;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"PullOver Pro";
    self.preferences = PPOUserPreferencesDefaults();
    self.preferenceQueue = dispatch_queue_create("com.renatasy83.pulloverpro.settings-ui", DISPATCH_QUEUE_SERIAL);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadPreferences];
}

- (void)setBusy:(BOOL)busy {
    _busy = busy;
    self.preferencesTable.userInteractionEnabled = !busy;
    if (busy) {
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
        [spinner startAnimating];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinner];
    } else {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

- (void)reloadPreferences {
    if (!self.preferenceQueue) return;
    uint64_t generation = ++self.requestGeneration;
    self.busy = YES;
    __weak PPOSettingsController *weakSelf = self;
    dispatch_async(self.preferenceQueue, ^{
        NSError *error = nil;
        NSDictionary *snapshot = PPOUserPreferencesRead(&error);
        dispatch_async(dispatch_get_main_queue(), ^{
            PPOSettingsController *strongSelf = weakSelf;
            if (!strongSelf || strongSelf.requestGeneration != generation) return;
            if (!error) strongSelf.preferences = snapshot;
            strongSelf.storageStatus = error ? @"Preferințele nu au putut fi citite. Încearcă din nou redeschizând această pagină." : nil;
            strongSelf.busy = NO;
            [strongSelf.preferencesTable reloadData];
        });
    });
}

- (void)saveChanges:(NSDictionary *)changes {
    if (self.busy || !self.preferenceQueue) return;
    NSError *validationError = nil;
    NSDictionary *optimistic = PPOUserPreferencesApplyingChanges(self.preferences, changes, &validationError);
    if (!optimistic || validationError) return;
    NSDictionary *prior = self.preferences;
    self.preferences = optimistic;
    self.storageStatus = nil;
    uint64_t generation = ++self.requestGeneration;
    self.busy = YES;
    [self.preferencesTable reloadData];
    __weak PPOSettingsController *weakSelf = self;
    dispatch_async(self.preferenceQueue, ^{
        NSError *error = nil;
        BOOL saved = PPOUserPreferencesWriteChanges(changes, &error);
        NSError *readError = nil;
        NSDictionary *snapshot = saved ? PPOUserPreferencesRead(&readError) : prior;
        dispatch_async(dispatch_get_main_queue(), ^{
            PPOSettingsController *strongSelf = weakSelf;
            if (!strongSelf || strongSelf.requestGeneration != generation) return;
            strongSelf.preferences = saved ? (readError ? optimistic : snapshot) : prior;
            strongSelf.storageStatus = saved && !readError ? nil : (saved
                ? @"Salvat. Citirea de verificare nu a reușit; redeschide pagina pentru verificare."
                : @"Salvarea nu a reușit. Preferințele anterioare au fost păstrate în interfață; redeschide pagina pentru verificare.");
            strongSelf.busy = NO;
            [strongSelf.preferencesTable reloadData];
        });
    });
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    (void)tableView;
    return (NSInteger)PPOSettingsRows().count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView;
    return (NSInteger)PPOSettingsRows()[(NSUInteger)section].count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    (void)tableView;
    return @[@"General", @"Comutator de aplicații", @"Mâner lateral", @"Ferestre", @"Utilizare și informații"][(NSUInteger)section];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    (void)tableView;
    if (section == 0) return self.storageStatus ?: @"Mânerul se actualizează fără respring. Aspectul, dimensiunea și păstrarea ferestrei se aplică la următoarea deschidere. Dezactivarea închide PPO.";
    if (section == 1) return @"Lista Recente memorează aplicațiile alese în PPO. Favoritele se aleg și se reordonează mai jos.";
    if (section == 2) return @"Poziția se schimbă trăgând mânerul în sus sau în jos. După restrângere rămâne o zonă mică accesibilă la marginea aleasă.";
    if (section == 3) return @"Fereastra rămâne deschisă implicit. Dezactivează păstrarea pentru închiderea automată după aproximativ 15 secunde. Protecțiile la blocarea telefonului și închiderea manuală rămân.";
    return @"Compatibilitatea depinde de aplicație. Confirmările existente nu garantează toate aplicațiile sau rutarea tastaturii.";
}

- (NSString *)valueDescriptionForRow:(NSDictionary *)row {
    NSString *key = row[@"key"];
    if (!key.length) return nil;
    id value = self.preferences[key];
    NSString *kind = row[@"kind"];
    if ([kind isEqual:@"choice"]) {
        NSUInteger index = [row[@"values"] indexOfObject:value];
        NSArray *labels = row[@"labels"];
        return index != NSNotFound && index < labels.count ? labels[index] : @"";
    }
    if ([key isEqual:@"handleOpacity"]) return [NSString stringWithFormat:@"%.0f%%", [value doubleValue] * 100];
    if ([key isEqual:@"autoHideDelay"]) return [NSString stringWithFormat:@"%.0f secunde", [value doubleValue]];
    if ([key isEqual:@"recentAppsCount"]) return [NSString stringWithFormat:@"%.0f aplicații", [value doubleValue]];
    if ([key isEqual:@"quickSwitchScale"]) return [NSString stringWithFormat:@"×%.2f", [value doubleValue]];
    if ([kind isEqual:@"stepper"]) return [NSString stringWithFormat:@"%.0f puncte", [value doubleValue]];
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    (void)tableView;
    NSDictionary *row = PPOSettingsRows()[(NSUInteger)indexPath.section][(NSUInteger)indexPath.row];
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    cell.textLabel.text = row[@"title"];
    cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    cell.textLabel.adjustsFontForContentSizeCategory = YES;
    cell.textLabel.numberOfLines = 0;
    cell.detailTextLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    cell.detailTextLabel.adjustsFontForContentSizeCategory = YES;
    cell.detailTextLabel.numberOfLines = 0;
    cell.detailTextLabel.text = [self valueDescriptionForRow:row];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    NSString *kind = row[@"kind"];
    NSString *key = row[@"key"];
    if ([kind isEqual:@"switch"]) {
        PPOSettingsSwitch *control = [PPOSettingsSwitch new];
        control.preferenceKey = key;
        control.on = [self.preferences[key] boolValue];
        control.accessibilityLabel = row[@"title"];
        [control addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = control;
    } else if ([kind isEqual:@"stepper"]) {
        PPOSettingsControl *control = [PPOSettingsControl new];
        control.preferenceKey = key;
        control.minimumValue = [row[@"min"] doubleValue];
        control.maximumValue = [row[@"max"] doubleValue];
        control.stepValue = [row[@"step"] doubleValue];
        control.value = [self.preferences[key] doubleValue];
        control.autorepeat = NO;
        control.accessibilityLabel = row[@"title"];
        [control addTarget:self action:@selector(stepperChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = control;
    } else if ([kind isEqual:@"choice"] || [kind isEqual:@"source"] || [kind isEqual:@"favorites"]) {
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return cell;
}

- (void)switchChanged:(PPOSettingsSwitch *)sender {
    if (!sender.preferenceKey) return;
    [self saveChanges:@{sender.preferenceKey: sender.on ? @YES : @NO}];
}

- (void)stepperChanged:(PPOSettingsControl *)sender {
    if (!sender.preferenceKey) return;
    [self saveChanges:@{sender.preferenceKey: @(sender.value)}];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.busy) return;
    NSDictionary *row = PPOSettingsRows()[(NSUInteger)indexPath.section][(NSUInteger)indexPath.row];
    NSString *kind = row[@"kind"];
    if ([kind isEqual:@"favorites"]) {
        PPOFavoritesEditorController *editor = [[PPOFavoritesEditorController alloc] initWithStyle:UITableViewStyleInsetGrouped];
        [self.navigationController pushViewController:editor animated:YES];
        return;
    }
    if ([kind isEqual:@"source"]) {
        NSURL *url = [NSURL URLWithString:@"https://github.com/Renatasy83/PullOverPro"];
        if (url) [UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
        return;
    }
    if (![kind isEqual:@"choice"]) return;
    NSArray *values = row[@"values"], *labels = row[@"labels"];
    NSString *key = row[@"key"];
    UIAlertController *picker = [UIAlertController alertControllerWithTitle:row[@"title"] message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    __weak PPOSettingsController *weakSelf = self;
    for (NSUInteger index = 0; index < values.count; index++) {
        id value = values[index];
        [picker addAction:[UIAlertAction actionWithTitle:labels[index] style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            [weakSelf saveChanges:@{key: value}];
        }]];
    }
    [picker addAction:[UIAlertAction actionWithTitle:@"Anulează" style:UIAlertActionStyleCancel handler:nil]];
    UIPopoverPresentationController *popover = picker.popoverPresentationController;
    if (popover) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        popover.sourceView = cell ?: tableView;
        popover.sourceRect = cell ? cell.bounds : tableView.bounds;
    }
    [self presentViewController:picker animated:YES completion:nil];
}

@end
