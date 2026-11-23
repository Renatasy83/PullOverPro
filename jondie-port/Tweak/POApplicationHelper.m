//
//  POApplicationHelper.m
//  PullOverPro
//
//  Created by Will Smillie on 4/8/19.
//  Rootless port (iOS 15-16): Jond-ie.
//

#import "POApplicationHelper.h"
#import "ContextInterfaces.h"
#import "POLog.h"
#import "../Shared/POPreferencesValidation.h"

@interface UIImage (POPrivate)
+ (UIImage *)_applicationIconImageForBundleIdentifier:(NSString *)bundleIdentifier format:(int)format scale:(CGFloat)scale;
@end

@implementation POApplicationHelper

// Recents live on SBMainSwitcherViewController on iOS 15 and moved to
// SBMainSwitcherControllerCoordinator on iOS 16.
+(NSArray *)recentAppLayouts{
    for (NSString *name in @[@"SBMainSwitcherControllerCoordinator", @"SBMainSwitcherViewController"]) {
        Class cls = NSClassFromString(name);
        if (![cls respondsToSelector:@selector(sharedInstance)]) continue;
        id switcher = [cls sharedInstance];
        if ([switcher respondsToSelector:@selector(recentAppLayouts)]) {
            NSArray *layouts = [[switcher valueForKey:@"recentAppLayouts"] copy];
            POLog(@"recents from %@: %lu layouts", name, (unsigned long)layouts.count);
            return layouts;
        }
    }
    POLog(@"recents: no switcher class answered");
    return @[];
}

+(NSArray *)recentAppsWithCount:(int)count{
    NSMutableArray *objects = [NSMutableArray new];
    for (id layout in [self recentAppLayouts]) {
        if ((int)objects.count >= count) break;
        NSString *bundleId = nil;
        @try {
            bundleId = [[[layout valueForKey:@"allItems"] valueForKey:@"bundleIdentifier"] firstObject];
        } @catch (NSException *e) {}
        if ([bundleId isKindOfClass:[NSString class]] && ![objects containsObject:bundleId]) {
            [objects addObject:bundleId];
        }
    }
    POLog(@"recent apps: %@", objects);
    return objects;
}

+(UIImage *)imageForBundleId:(NSString *)bundleId{
    if (!bundleId) return nil;
    // format 2 = home screen icon size (60 pt)
    return [UIImage _applicationIconImageForBundleIdentifier:bundleId format:2 scale:[UIScreen mainScreen].scale];
}

static NSString *POTrackedFrontMost;
static BOOL POHasTrackedFrontMost;

void POSetFrontMostBundleId(NSString *bundleId){
    POTrackedFrontMost = [bundleId copy];
    POHasTrackedFrontMost = YES;
}

+(NSString *)frontMostBundleId{
    if (POHasTrackedFrontMost) return POTrackedFrontMost;
    UIApplication *sb = [UIApplication sharedApplication];
    if (![sb respondsToSelector:@selector(_accessibilityFrontMostApplication)]) return nil;
    id app = [sb _accessibilityFrontMostApplication];
    return [app respondsToSelector:@selector(bundleIdentifier)] ? [app bundleIdentifier] : nil;
}

static NSDictionary *POCachedSettings;

+(NSDictionary *)defaultSettings{
    return @{
        @"enabled": @YES,
        @"hideInLandscape": @YES,
        @"favorites": @[],
        @"recentAppsCount": @5,
        @"quickswitchScale": @1.75f,
        @"style": @"Recent Apps",
        @"leftHanded": @NO,
        @"darkHandle": @NO,
        @"hideLabels": @NO,
        @"hapticFeedback": @YES,
        @"closeOnHome": @YES,
        @"hideHandle": @NO,
        @"keyboardAvoiding": @NO,
        @"externalKeyboard": @NO,
        @"autoNub": @NO,
        @"autoNub-time": @5,
    };
}

// Defaults merged with whatever the settings page saved (CFPreferences, so
// cfprefsd's cache is always current; reading the plist file can be stale).
+(NSDictionary *)settings{
    @synchronized (self) {
        if (!POCachedSettings) {
            CFStringRef domain = (__bridge CFStringRef)PODomain;
            CFPreferencesAppSynchronize(domain);
            NSDictionary *saved = nil;
            CFArrayRef keys = CFPreferencesCopyKeyList(domain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
            if (keys) {
                saved = CFBridgingRelease(CFPreferencesCopyMultiple(keys, domain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost));
                CFRelease(keys);
            }
            POCachedSettings = POValidatedPreferences(saved, [self defaultSettings]);
        }
        return POCachedSettings;
    }
}

+(void)reloadSettings{
    @synchronized (self) { POCachedSettings = nil; }
}

+(NSUserDefaults *)state{
    static NSUserDefaults *state;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ state = [[NSUserDefaults alloc] initWithSuiteName:POStateDomain]; });
    return state;
}

@end
