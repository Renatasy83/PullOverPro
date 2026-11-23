// PullOver Pro settings.
// Values go through CFPreferences (what the tweak reads) and every change
// posts a Darwin notification so SpringBoard applies it without a respring.

#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSSliderTableCell.h>
#import <rootless.h>
#import <dlfcn.h>
#import "../Shared/POShared.h"

@interface POPRootListController : PSListController
@end

@implementation POPRootListController

+ (void)initialize {
    if (self != [POPRootListController class]) return;
    // The favourites picker comes from AltList (a package dependency); load it
    // at runtime so the plist can name its controller class.
    dlopen(ROOT_PATH("/Library/Frameworks/AltList.framework/AltList"), RTLD_NOW);
}

- (NSArray *)specifiers {
    if (!_specifiers) {
        NSMutableArray *specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] mutableCopy];
        // Hide Handle only shows when the PullOver Pro for Triggr add-on is installed.
        if (!POTriggrAddonInstalled()) {
            for (NSString *identifier in @[@"hideHandleGroup", @"hideHandle"]) {
                for (PSSpecifier *s in [specifiers copy]) if ([s.identifier isEqualToString:identifier]) [specifiers removeObject:s];
            }
        }
        _specifiers = specifiers;
    }
    return _specifiers;
}

- (id)readPreferenceValue:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    if (!key) return [super readPreferenceValue:specifier];
    CFPropertyListRef value = CFPreferencesCopyAppValue((__bridge CFStringRef)key, (__bridge CFStringRef)PODomain);
    id result = CFBridgingRelease(value);
    return result ?: [specifier propertyForKey:@"default"];
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    if (!key) { [super setPreferenceValue:value specifier:specifier]; return; }
    CFPreferencesSetAppValue((__bridge CFStringRef)key, (__bridge CFPropertyListRef)value, (__bridge CFStringRef)PODomain);
    CFPreferencesAppSynchronize((__bridge CFStringRef)PODomain);
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR(POPrefsChangedNotification), NULL, NULL, YES);
}

- (void)openURL:(PSSpecifier *)specifier {
    NSURL *url = [NSURL URLWithString:[specifier propertyForKey:@"url"]];
    if (url) [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

@end

#pragma mark - Slider value

// iOS 16 lays the built-in value label out too narrow for "%.2f": "5.00" showed as "5.0(". Show whole numbers on
// stepped sliders and one decimal otherwise, so the value always fits. The stored value is unchanged.
@interface POValueSliderCell : PSSliderTableCell
@end

@implementation POValueSliderCell

static void POFormatLabels(UIView *view, UIView *skip, BOOL whole) {
    for (UIView *sub in view.subviews) {
        if ([sub isKindOfClass:UILabel.class] && sub != skip) {
            UILabel *label = (UILabel *)sub;
            NSScanner *scanner = [NSScanner scannerWithString:label.text ?: @""];
            double number;
            if ([scanner scanDouble:&number] && scanner.isAtEnd) {
                NSString *text = whole ? [NSString stringWithFormat:@"%.0f", number] : [NSString stringWithFormat:@"%.1f", number];
                if (![label.text isEqualToString:text]) label.text = text;
            }
        }
        POFormatLabels(sub, skip, whole);
    }
}

- (BOOL)POWhole {
    id segmented = [self.specifier propertyForKey:@"isSegmented"];
    return [segmented respondsToSelector:@selector(boolValue)] && [segmented boolValue];
}

- (void)POReformat {
    POFormatLabels(self, self.textLabel, [self POWhole]);
}

- (void)POValueChanged {
    [self.control layoutIfNeeded];
    [self POReformat];
    dispatch_async(dispatch_get_main_queue(), ^{ [self POReformat]; });
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if ([self.control isKindOfClass:UIControl.class] && ![[(UIControl *)self.control allTargets] containsObject:self])
        [(UIControl *)self.control addTarget:self action:@selector(POValueChanged) forControlEvents:UIControlEventValueChanged];
    // The slider writes its own "%.2f" text when it lays out, after the cell: format once it has.
    [self.control layoutIfNeeded];
    [self POReformat];
    dispatch_async(dispatch_get_main_queue(), ^{ [self POReformat]; });
}

@end
