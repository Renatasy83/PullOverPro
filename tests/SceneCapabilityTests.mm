#import "../PPOSceneCapability.h"
#import <CoreFoundation/CoreFoundation.h>
#include <cmath>
#include <stdio.h>
#include <stdlib.h>

// Fixture contract: pure synthetic plist/descriptor policy v4, normalization and freshness.
// Files (two names) and Mail (four names) model metadata shapes only. They do not
// read Apple bundles/binaries, call private APIs or establish app/scene admission.
static unsigned checks;
static NSString *const Identifier = @"com.example.application";
static void Check(BOOL condition, const char *message) {
    checks++;
    if (!condition) { fprintf(stderr, "FAIL: %s\n", message); exit(1); }
}
static NSMutableDictionary *Info(void) {
    return [@{@"CFBundleIdentifier": Identifier, @"CFBundlePackageType": @"APPL",
        @"UIDeviceFamily": @[@1, @2],
        @"UIApplicationSceneManifest": @{@"UIApplicationSupportsMultipleScenes": @YES,
            @"UISceneConfigurations": @{@"UIWindowSceneSessionRoleApplication":
                @[@{@"UISceneConfigurationName": @"Default Configuration",
                    @"UISceneDelegateClassName": @"Example.SceneDelegate"}]}}} mutableCopy];
}
static NSMutableDictionary *Manifest(NSMutableDictionary *info) {
    NSMutableDictionary *manifest = [info[@"UIApplicationSceneManifest"] mutableCopy];
    info[@"UIApplicationSceneManifest"] = manifest;
    return manifest;
}
static NSMutableDictionary *ProgrammaticInfo(void) {
    NSMutableDictionary *info = Info();
    [Manifest(info) removeObjectForKey:@"UISceneConfigurations"];
    return info;
}
static NSMutableDictionary *Roles(NSMutableDictionary *info) {
    NSMutableDictionary *manifest = Manifest(info);
    NSMutableDictionary *roles = [manifest[@"UISceneConfigurations"] mutableCopy];
    manifest[@"UISceneConfigurations"] = roles;
    return roles;
}
static NSMutableDictionary *NamedInfo(NSArray<NSString *> *names) {
    NSMutableDictionary *info = Info();
    NSMutableArray *configurations = [NSMutableArray array];
    for (NSString *name in names) {
        [configurations addObject:@{@"UISceneConfigurationName": name,
            @"UISceneClassName": @"UIWindowScene",
            @"UISceneDelegateClassName": @"Fixture.NamedSceneDelegate",
            @"UISceneStoryboardFile": @"FixtureScenes"}];
    }
    Roles(info)[@"UIWindowSceneSessionRoleApplication"] = configurations;
    return info;
}
static NSMutableArray *NamedConfigurations(NSMutableDictionary *info) {
    NSMutableDictionary *roles = Roles(info);
    NSMutableArray *configurations = [roles[@"UIWindowSceneSessionRoleApplication"] mutableCopy];
    roles[@"UIWindowSceneSessionRoleApplication"] = configurations;
    return configurations;
}
static NSMutableDictionary *FilesInfo(void) {
    NSMutableDictionary *info = NamedInfo(@[@"Files Browser", @"Files Document"]);
    NSMutableArray *configurations = NamedConfigurations(info);
    for (NSUInteger index = 0; index < configurations.count; index++) {
        NSMutableDictionary *configuration = [configurations[index] mutableCopy];
        [configuration removeObjectsForKeys:@[@"UISceneClassName", @"UISceneStoryboardFile"]];
        configurations[index] = configuration;
    }
    return info;
}
static NSMutableDictionary *MailInfo(void) {
    NSMutableDictionary *info = NamedInfo(@[@"Mail Viewer", @"Mail Compose", @"Mail Message", @"Mail Search"]);
    NSMutableArray *configurations = NamedConfigurations(info);
    for (NSUInteger index = 0; index < configurations.count; index++) {
        NSMutableDictionary *configuration = [configurations[index] mutableCopy];
        [configuration removeObjectForKey:@"UISceneStoryboardFile"];
        configurations[index] = configuration;
    }
    return info;
}
static NSDictionary *Read(id info) { return PPOSceneCapabilityFromInfo(info, Identifier, 100); }
static void Result(NSDictionary *value, NSString *status, NSString *reason) {
    Check(value != nil && value.count == 7, "capability contains only the normalized seven scalar fields");
    Check([value[@"status"] isEqual:status] && [value[@"reason"] isEqual:reason],
          "outcome distinguishes explicit negatives from unavailable or unsupported metadata");
    Check([value[@"bundleIdentifier"] isEqual:Identifier] &&
          [value[@"policy"] isEqual:@"installed-basic-multiscene-v4"] &&
          [value[@"schema"] isEqual:@1] && [value[@"observedUptime"] isEqual:@100],
          "result is bound to the requested app, fixed policy and injected observation time");
    Check(CFGetTypeID((__bridge CFTypeRef)value[@"eligible"]) == CFBooleanGetTypeID() &&
          [value[@"eligible"] boolValue] == [status isEqual:@"eligible"],
          "eligibility is a real Boolean consistent with the status");
    Check(PPOSceneCapabilityNormalize(value) != nil, "parser-generated results obey the wire contract");
    Check([NSJSONSerialization isValidJSONObject:value], "normalized diagnostics are safely serializable");
}
static void NormalizeField(NSString *field, NSArray *values) {
    for (NSDictionary *fixture in @[Read(Info()), Read(ProgrammaticInfo()), Read(FilesInfo()), Read(MailInfo())])
        for (id invalid in values) {
            NSMutableDictionary *value = [fixture mutableCopy];
            value[field] = invalid;
            Check(PPOSceneCapabilityNormalize(value) == nil, "malformed descriptor scalar is rejected for every positive metadata shape");
        }
}
// Derived Messages profile facts, not a copied Apple plist or app execution.
static NSString *const MessagesID = @"com.apple.MobileSMS";
static NSMutableDictionary *MessagesInfo(void) {
    return [@{@"CFBundleIdentifier": MessagesID, @"CFBundlePackageType": @"APPL",
        @"UIDeviceFamily": @[@1, @2], @"CFBundleExecutable": @"MobileSMS", @"NSPrincipalClass": @"SMSApplication",
        @"CFBundleVersion": @"1448.100.1.2.102", @"CFBundleShortVersionString": @"26.0",
        @"DTPlatformVersion": @"26.0", @"DTPlatformBuild": @"23A345", @"DTSDKBuild": @"23A345",
        @"UIApplicationSceneManifest": @{@"UIApplicationSupportsMultipleScenes": @YES,
            @"UIApplicationSupportsSceneItemProviders": @YES, @"UISceneConfigurations": @{
                @"CPTemplateApplicationSceneSessionRoleApplication": @[@{@"UISceneClassName": @"CPTemplateApplicationScene",
                    @"UISceneConfigurationName": @"Messages-Car", @"UISceneDelegateClassName": @"CKStarkManager"}],
                @"UIWindowSceneSessionRoleAssistiveAccessApplication": @[@{@"UISceneConfigurationName": @"Messages-ClarityUI",
                    @"UISceneDelegateClassName": @"CKClarityUISceneDelegate"}],
                @"com.apple.PosterBoardUIServices.editor-overlay": @[@{@"UISceneConfigurationName": @"Messages-EditorOverlayConfiguration",
                    @"UISceneDelegateClassName": @"ChatKit.PosterEditorOverlaySceneDelegate"}]}}} mutableCopy];
}
static NSDictionary *MessagesRead(id info) { return PPOSceneCapabilityFromInfo(info, MessagesID, 100); }
static void MessagesResult(NSDictionary *value, NSString *status, NSString *reason) {
    Check(value.count == 7 && [value[@"bundleIdentifier"] isEqual:MessagesID] &&
          [value[@"policy"] isEqual:@"installed-basic-multiscene-v4"] &&
          [value[@"observedUptime"] isEqual:@100] && [value[@"status"] isEqual:status] &&
          [value[@"reason"] isEqual:reason], "Messages profile result is bounded, identity-bound and reason-specific");
    Check(CFGetTypeID((__bridge CFTypeRef)value[@"eligible"]) == CFBooleanGetTypeID() &&
          [value[@"eligible"] boolValue] == [status isEqual:@"eligible"] &&
          [PPOSceneCapabilityNormalize(value) isEqual:value], "Messages result normalizes without changing eligibility");
    NSData *wire = [NSJSONSerialization dataWithJSONObject:value options:0 error:NULL];
    Check(wire != nil && [PPOSceneCapabilityNormalize([NSJSONSerialization JSONObjectWithData:wire options:0 error:NULL]) isEqual:value],
          "Messages profile crosses JSON using only seven canonical scalars");
}
static NSMutableDictionary *MessagesConfiguration(NSMutableDictionary *info, NSString *role) {
    NSMutableDictionary *roles = Roles(info);
    NSMutableArray *configurations = [roles[role] mutableCopy]; roles[role] = configurations;
    NSMutableDictionary *configuration = [configurations[0] mutableCopy]; configurations[0] = configuration;
    return configuration;
}
static void MessagesProfileCases(void) {
    NSDictionary *positive = MessagesRead(MessagesInfo());
    MessagesResult(positive, @"eligible", @"declared-messages-programmatic-scenes");
    Check(![[positive description] containsString:@"CKStarkManager"] && ![[positive description] containsString:@"SMSApplication"] &&
          ![[positive description] containsString:@"Messages-Car"], "Messages profile details are not disclosed in eligibility");
    for (NSString *key in @[@"CFBundleExecutable", @"NSPrincipalClass", @"CFBundleVersion", @"CFBundleShortVersionString",
            @"DTPlatformVersion", @"DTPlatformBuild", @"DTSDKBuild"]) {
        NSMutableDictionary *missing = MessagesInfo(); [missing removeObjectForKey:key];
        MessagesResult(MessagesRead(missing), @"unknown", @"manifest-complex");
        for (id value in @[NSNull.null, @YES, @1, @[], @{}, @"", @"future-profile", @"1448.100.1.2.103"]) {
            NSMutableDictionary *changed = MessagesInfo(); changed[key] = value;
            MessagesResult(MessagesRead(changed), @"unknown", @"manifest-complex");
        }
    }
    for (id family in @[@[@1], @[@2, @1], @[@1, @2, @3]]) {
        NSMutableDictionary *changed = MessagesInfo(); changed[@"UIDeviceFamily"] = family;
        MessagesResult(MessagesRead(changed), @"unknown", @"manifest-complex");
    }
    NSMutableDictionary *changed = MessagesInfo(); changed[@"UIDeviceFamily"] = @[@2];
    MessagesResult(MessagesRead(changed), @"ineligible", @"not-iphone");
    changed = MessagesInfo(); changed[@"UIDeviceFamily"] = @[@YES, @2];
    MessagesResult(MessagesRead(changed), @"unknown", @"manifest-unknown");
    for (id impostor in @[@1, @0, @"true", NSNull.null, @[], @{}]) {
        changed = MessagesInfo(); Manifest(changed)[@"UIApplicationSupportsSceneItemProviders"] = impostor;
        MessagesResult(MessagesRead(changed), @"unknown", @"manifest-complex");
        changed = MessagesInfo(); Manifest(changed)[@"UIApplicationSupportsMultipleScenes"] = impostor;
        MessagesResult(MessagesRead(changed), @"unknown", @"manifest-unknown");
    }
    changed = MessagesInfo(); Manifest(changed)[@"UIApplicationSupportsSceneItemProviders"] = @NO;
    MessagesResult(MessagesRead(changed), @"unknown", @"manifest-complex");
    changed = MessagesInfo(); [Manifest(changed) removeObjectForKey:@"UIApplicationSupportsSceneItemProviders"];
    MessagesResult(MessagesRead(changed), @"unknown", @"manifest-complex");
    changed = MessagesInfo(); Manifest(changed)[@"UIApplicationSupportsMultipleScenes"] = @NO;
    Manifest(changed)[@"unreviewed-security-field"] = @YES;
    MessagesResult(MessagesRead(changed), @"ineligible", @"multiple-scenes-disabled");
    for (NSString *flag in @[@"LSBackgroundOnly", @"LSUIElement", @"UIBackgroundOnly"]) {
        changed = MessagesInfo(); changed[flag] = @YES;
        MessagesResult(MessagesRead(changed), @"ineligible", @"not-application");
    }
    changed = MessagesInfo(); changed[@"NSExtension"] = @{};
    MessagesResult(MessagesRead(changed), @"ineligible", @"app-extension");
    changed = MessagesInfo(); changed[@"CFBundlePackageType"] = @"XPC!";
    MessagesResult(MessagesRead(changed), @"ineligible", @"not-application");
    for (NSString *field in @[@"ExtraSceneSetting", @"WindowSecurity", @"scene", @"window"]) {
        changed = MessagesInfo(); changed[field] = @YES;
        MessagesResult(MessagesRead(changed), @"unknown", @"manifest-complex");
    }
    for (NSString *field in @[@"UnreviewedManifestField", @"UISceneClassName", @"UIWindowSceneSessionRoleApplication"]) {
        changed = MessagesInfo(); Manifest(changed)[field] = @YES;
        MessagesResult(MessagesRead(changed), @"unknown", @"manifest-complex");
    }
    for (id roles in @[@{}, @[], @YES, NSNull.null]) {
        changed = MessagesInfo(); Manifest(changed)[@"UISceneConfigurations"] = roles;
        MessagesResult(MessagesRead(changed), @"unknown", @"manifest-complex");
    }
    for (NSString *role in [MessagesInfo()[@"UIApplicationSceneManifest"][@"UISceneConfigurations"] allKeys]) {
        changed = MessagesInfo(); [Roles(changed) removeObjectForKey:role];
        MessagesResult(MessagesRead(changed), @"unknown", @"manifest-complex");
        for (id configs in @[@[], @[@{}], NSNull.null, @[@1], @[@{}, @{}]]) {
            changed = MessagesInfo(); Roles(changed)[role] = configs;
            MessagesResult(MessagesRead(changed), @"unknown", @"manifest-complex");
        }
        NSDictionary *original = MessagesInfo()[@"UIApplicationSceneManifest"][@"UISceneConfigurations"][role][0];
        for (NSString *field in original) {
            changed = MessagesInfo(); [MessagesConfiguration(changed,role) removeObjectForKey:field];
            MessagesResult(MessagesRead(changed), @"unknown", @"manifest-complex");
            for (id value in @[@"Changed", @"", @1, @YES, NSNull.null, @[], @{}]) {
                changed = MessagesInfo(); MessagesConfiguration(changed,role)[field] = value;
                MessagesResult(MessagesRead(changed), @"unknown", @"manifest-complex");
            }
        }
        changed = MessagesInfo(); MessagesConfiguration(changed,role)[@"UnreviewedConfiguration"] = @"value";
        MessagesResult(MessagesRead(changed), @"unknown", @"manifest-complex");
    }
    for (NSString *role in @[@"UIWindowSceneSessionRoleApplication", @"UnreviewedRole", @"UIWindowSceneSessionRoleExternalDisplay"]) {
        changed = MessagesInfo(); Roles(changed)[role] = @[@{@"UISceneDelegateClassName": @"UnreviewedDelegate"}];
        MessagesResult(MessagesRead(changed), @"unknown", @"manifest-complex");
    }
    for (NSString *other in @[@"com.facebook.Messenger", @"com.example.application", @"com.apple.mobilesms"]) {
        changed = MessagesInfo(); changed[@"CFBundleIdentifier"] = other;
        NSDictionary *value = PPOSceneCapabilityFromInfo(changed,other,100);
        Check([value[@"status"] isEqual:@"unknown"] && [value[@"reason"] isEqual:@"manifest-complex"],
              "the Messages profile never authorizes Messenger, another app or case-folded identifier");
        NSMutableDictionary *rebound = [positive mutableCopy]; rebound[@"bundleIdentifier"] = other;
        Check(PPOSceneCapabilityNormalize(rebound) == nil, "the Messages-only wire reason cannot cross identifiers");
    }
    changed = MessagesInfo(); changed[@"CFBundleIdentifier"] = @"com.example.other";
    MessagesResult(MessagesRead(changed), @"unknown", @"identifier-mismatch");
    for (NSString *status in @[@"unknown", @"ineligible"]) {
        NSMutableDictionary *bad = [positive mutableCopy]; bad[@"status"] = status; bad[@"eligible"] = @NO;
        Check(PPOSceneCapabilityNormalize(bad) == nil, "Messages reason cannot be reclassified into another status");
    }
    for (id flag in @[@NO, @1, @0, @"true", NSNull.null]) {
        NSMutableDictionary *bad = [positive mutableCopy]; bad[@"eligible"] = flag;
        Check(PPOSceneCapabilityNormalize(bad) == nil, "Messages reason requires a genuine true Boolean");
    }
    for (NSString *policy in @[@"installed-basic-multiscene-v1", @"installed-basic-multiscene-v2", @"installed-basic-multiscene-v3"]) {
        NSMutableDictionary *old = [positive mutableCopy]; old[@"policy"] = policy;
        Check(!PPOSceneCapabilityNormalize(old) && !PPOSceneCapabilityFresh(old,100), "old descriptors cannot claim Messages profile eligibility");
    }
    NSMutableString *mutableVersion = [@"1448.100.1.2.102" mutableCopy];
    changed = MessagesInfo(); changed[@"CFBundleVersion"] = mutableVersion;
    NSDictionary *frozen = MessagesRead(changed); [mutableVersion setString:@"future"]; [changed removeAllObjects];
    MessagesResult(frozen, @"eligible", @"declared-messages-programmatic-scenes");
    Check(PPOSceneCapabilityFresh(positive,105) && !PPOSceneCapabilityFresh(positive,105.000001),
          "Messages eligibility retains the same short five-second freshness boundary");
}
int main(void) {
    @autoreleasepool {
        MessagesProfileCases();
        for (NSString *valid in @[@"com.example.application", @"com.apple.mobilesafari",
                @"com.apple.reminders", @"com.apple.MobileAddressBook", @"org.Example.some-app_1"])
            Check(PPOSceneApplicationIdentifierAllowed(valid), "ordinary dotted identifiers preserve exact case");
        NSArray *invalidIdentifiers = @[@"", @"app", @"com..app", @".com.app", @"com.app.", @"-com.app",
            @"com.-app", @"com.app_", @"com/app", @"com app", @"com.example.é", @"../app.app",
            @"com.apple.springboard", @"COM.APPLE.SPRINGBOARD", @"com.apple.SpringBoard.extension",
            @"com.apple.backboardd", @"com.apple.runningboardd", @"com.apple.lsd", @"com.apple.uikitservices",
            @1, NSNull.null, @[]];
        for (id invalid in invalidIdentifiers) {
            Check(!PPOSceneApplicationIdentifierAllowed(invalid), "invalid and critical-process identifiers are denied");
            Check(PPOSceneCapabilityFromInfo(Info(), invalid, 100) == nil &&
                  PPOSceneCapabilityUnknown(invalid, @"file-unavailable", 100) == nil,
                  "invalid identifiers never receive an eligibility descriptor");
        }
        Check(!PPOSceneApplicationIdentifierAllowed(nil) && PPOSceneCapabilityFromInfo(Info(), nil, 100) == nil,
              "nil identifier is refused without reading metadata");
        NSString *limit = [@"com." stringByAppendingString:[@"a" stringByPaddingToLength:251
            withString:@"a" startingAtIndex:0]];
        Check(limit.length == 255 && PPOSceneApplicationIdentifierAllowed(limit) &&
              !PPOSceneApplicationIdentifierAllowed([limit stringByAppendingString:@"a"]), "identifier length is bounded");

        Result(Read(Info()), @"eligible", @"declared-single-application-scene");
        Result(Read(ProgrammaticInfo()), @"eligible", @"declared-programmatic-application-scenes");
        // Synthetic fixtures represent only the supported metadata shape, not installed Apple apps.
        for (NSString *identifier in @[@"com.example.FixtureCalendar", @"com.example.FixturePreview"]) {
            NSMutableDictionary *fixture = ProgrammaticInfo();
            fixture[@"CFBundleIdentifier"] = identifier;
            NSDictionary *capability = PPOSceneCapabilityFromInfo(fixture, identifier, 100);
            Check([fixture[@"UIApplicationSceneManifest"] count] == 1 &&
                  fixture[@"UIApplicationSceneManifest"][@"UISceneConfigurations"] == nil &&
                  [capability[@"bundleIdentifier"] isEqual:identifier] &&
                  [capability[@"status"] isEqual:@"eligible"] &&
                  [capability[@"reason"] isEqual:@"declared-programmatic-application-scenes"] &&
                  [PPOSceneCapabilityNormalize(capability) isEqual:capability],
                  "Calendar and Preview synthetic programmatic fixtures retain their selected identifier");
            Check([PPOSceneCapabilityFromInfo(fixture, Identifier, 100)[@"reason"] isEqual:@"identifier-mismatch"],
                  "a programmatic manifest does not let metadata cross application identifiers");
        }
        Result(Read(FilesInfo()), @"eligible", @"declared-named-application-configurations");
        Result(Read(MailInfo()), @"eligible", @"declared-named-application-configurations");
        for (NSDictionary *fixture in @[
                @{@"identifier": @"com.example.FixtureFiles", @"info": FilesInfo(), @"count": @2},
                @{@"identifier": @"com.example.FixtureMail", @"info": MailInfo(), @"count": @4}]) {
            NSMutableDictionary *metadata = fixture[@"info"];
            metadata[@"CFBundleIdentifier"] = fixture[@"identifier"];
            NSDictionary *manifest = metadata[@"UIApplicationSceneManifest"];
            NSArray *configurations = manifest[@"UISceneConfigurations"][@"UIWindowSceneSessionRoleApplication"];
            NSDictionary *capability = PPOSceneCapabilityFromInfo(metadata, fixture[@"identifier"], 100);
            Check(manifest.count == 2 && [configurations count] == [fixture[@"count"] unsignedIntegerValue] &&
                  [capability[@"bundleIdentifier"] isEqual:fixture[@"identifier"]] &&
                  [capability[@"policy"] isEqual:@"installed-basic-multiscene-v4"] &&
                  [capability[@"reason"] isEqual:@"declared-named-application-configurations"] &&
                  [capability[@"status"] isEqual:@"eligible"] &&
                  [PPOSceneCapabilityNormalize(capability) isEqual:capability],
                  "synthetic Files two-name and Mail four-name factories retain only their selected identifier");
            Check(capability.count == 7 &&
                  ![[capability description] containsString:@"Fixture.NamedSceneDelegate"] &&
                  ![[capability description] containsString:configurations[0][@"UISceneConfigurationName"]],
                  "named eligibility publishes no configuration names, delegates or raw metadata");
            Check([PPOSceneCapabilityFromInfo(metadata, Identifier, 100)[@"reason"] isEqual:@"identifier-mismatch"],
                  "named metadata cannot cross application identifiers");
        }
        for (NSUInteger count = 2; count <= 8; count++) {
            NSMutableArray *names = [NSMutableArray array];
            for (NSUInteger index = 0; index < count; index++)
                [names addObject:[NSString stringWithFormat:@"Named Configuration %lu", (unsigned long)index]];
            Result(Read(NamedInfo(names)), @"eligible", @"declared-named-application-configurations");
        }
        Result(Read(NamedInfo(@[@"Document", @"document", @" Document "])), @"eligible",
               @"declared-named-application-configurations");
        Result(Read(NamedInfo(@[@"Only Configuration"])), @"eligible", @"declared-single-application-scene");
        NSMutableDictionary *legacySingle = NamedInfo(@[@"Legacy Single Configuration"]);
        NSMutableArray *legacyConfigurations = NamedConfigurations(legacySingle);
        NSMutableDictionary *legacyConfiguration = [legacyConfigurations[0] mutableCopy];
        legacyConfiguration[@"UILaunchStoryboardName"] = @"LegacyLaunch";
        legacyConfigurations[0] = legacyConfiguration;
        Result(Read(legacySingle), @"eligible", @"declared-single-application-scene");
        Result(Read(NamedInfo(@[])), @"unknown", @"manifest-complex");
        Result(Read(NamedInfo(@[@"One", @"Two", @"Three", @"Four", @"Five", @"Six", @"Seven", @"Eight", @"Nine"])),
               @"unknown", @"manifest-complex");
        for (NSMutableDictionary *named in @[FilesInfo(), MailInfo()]) {
            for (id malformed in @[@YES, @1, @"named", @{}, NSNull.null]) {
                NSMutableDictionary *metadata = [named mutableCopy];
                Roles(metadata)[@"UIWindowSceneSessionRoleApplication"] = malformed;
                Result(Read(metadata), @"unknown", @"manifest-unknown");
            }
            for (NSUInteger index = 0; index < [NamedConfigurations(named) count]; index++) {
                for (id malformed in @[@{}, @[], @YES, @"configuration", NSNull.null]) {
                    NSMutableDictionary *metadata = [named mutableCopy];
                    NamedConfigurations(metadata)[index] = malformed;
                    Result(Read(metadata), @"unknown", @"manifest-complex");
                }
                NSMutableDictionary *metadata = [named mutableCopy];
                NSMutableArray *configurations = NamedConfigurations(metadata);
                NSMutableDictionary *configuration = [configurations[index] mutableCopy];
                [configuration removeObjectForKey:@"UISceneConfigurationName"];
                configurations[index] = configuration;
                Result(Read(metadata), @"unknown", @"manifest-complex");
            }
            for (NSString *field in @[@"UISceneConfigurationName", @"UISceneClassName", @"UISceneDelegateClassName",
                    @"UISceneStoryboardFile"]) {
                for (id malformed in @[@"", @1, @YES, @[], @{}, NSNull.null,
                        [@"a" stringByPaddingToLength:257 withString:@"a" startingAtIndex:0]]) {
                    NSMutableDictionary *metadata = [named mutableCopy];
                    NSMutableArray *configurations = NamedConfigurations(metadata);
                    NSMutableDictionary *last = [configurations.lastObject mutableCopy];
                    last[field] = malformed; configurations[configurations.count - 1] = last;
                    Result(Read(metadata), @"unknown", @"manifest-complex");
                }
                NSMutableDictionary *metadata = [named mutableCopy];
                NSMutableArray *configurations = NamedConfigurations(metadata);
                NSMutableDictionary *last = [configurations.lastObject mutableCopy];
                last[field] = [@"a" stringByPaddingToLength:256 withString:@"a" startingAtIndex:0];
                configurations[configurations.count - 1] = last;
                Result(Read(metadata), @"eligible", @"declared-named-application-configurations");
            }
            for (id invalidKey in @[@"UILaunchStoryboardName", @"UnknownConfigurationKey", @1]) {
                NSMutableDictionary *metadata = [named mutableCopy];
                NSMutableArray *configurations = NamedConfigurations(metadata);
                NSMutableDictionary *last = [configurations.lastObject mutableCopy];
                last[invalidKey] = @"Launch"; configurations[configurations.count - 1] = last;
                Result(Read(metadata), @"unknown", @"manifest-complex");
            }
            for (NSString *name in @[@" ", @"\t\n", @"\u00a0"]) {
                NSMutableDictionary *metadata = [named mutableCopy];
                NSMutableArray *configurations = NamedConfigurations(metadata);
                NSMutableDictionary *last = [configurations.lastObject mutableCopy];
                last[@"UISceneConfigurationName"] = name; configurations[configurations.count - 1] = last;
                Result(Read(metadata), @"unknown", @"manifest-complex");
            }
            NSMutableDictionary *metadata = [named mutableCopy];
            NSMutableArray *configurations = NamedConfigurations(metadata);
            NSMutableDictionary *last = [configurations.lastObject mutableCopy];
            last[@"UISceneConfigurationName"] = configurations[0][@"UISceneConfigurationName"];
            configurations[configurations.count - 1] = last;
            Result(Read(metadata), @"unknown", @"manifest-complex");
        }
        // Only the name is mandatory; the three other accepted fields remain optional.
        NSMutableDictionary *nameOnly = FilesInfo();
        NSMutableArray *nameOnlyConfigurations = NamedConfigurations(nameOnly);
        nameOnlyConfigurations[0] = @{@"UISceneConfigurationName": @"Name Only One"};
        nameOnlyConfigurations[1] = @{@"UISceneConfigurationName": @"Name Only Two"};
        Result(Read(nameOnly), @"eligible", @"declared-named-application-configurations");
        for (NSString *field in @[@"UISceneClassName", @"UISceneDelegateClassName", @"UISceneStoryboardFile"]) {
            NSMutableDictionary *metadata = FilesInfo();
            NSMutableArray *configurations = NamedConfigurations(metadata);
            NSMutableDictionary *last = [configurations.lastObject mutableCopy];
            last[field] = @" "; configurations[configurations.count - 1] = last;
            Result(Read(metadata), @"eligible", @"declared-named-application-configurations");
        }
        for (id multiple in @[@1, @0, @"true", NSNull.null]) {
            NSMutableDictionary *metadata = FilesInfo();
            Manifest(metadata)[@"UIApplicationSupportsMultipleScenes"] = multiple;
            Result(Read(metadata), @"unknown", @"manifest-unknown");
        }
        NSMutableDictionary *namedMissingSupport = MailInfo();
        [Manifest(namedMissingSupport) removeObjectForKey:@"UIApplicationSupportsMultipleScenes"];
        Result(Read(namedMissingSupport), @"unknown", @"manifest-unknown");
        for (NSString *rootKey in @[@"system-windows-secure", @"UnexpectedSCENEOption", @"UIWindowOptions"])
            for (NSNumber *flag in @[@YES, @NO]) {
                NSMutableDictionary *metadata = FilesInfo(); metadata[rootKey] = flag;
                Result(Read(metadata), @"unknown", @"manifest-complex");
            }
        for (id extraKey in @[@"UIApplicationSupportsTabbedScenes", @"UnexpectedManifestOption", @1]) {
            NSMutableDictionary *metadata = MailInfo(); Manifest(metadata)[extraKey] = @YES;
            Result(Read(metadata), @"unknown", @"manifest-complex");
        }
        for (id role in @[@"UIWindowSceneSessionRoleExternalDisplay", @"UnknownRole", @1]) {
            NSMutableDictionary *metadata = FilesInfo(); Roles(metadata)[role] = @[@{}];
            Result(Read(metadata), @"unknown", @"manifest-complex");
        }
        NSMutableDictionary *namedDisabled = MailInfo();
        Manifest(namedDisabled)[@"UIApplicationSupportsMultipleScenes"] = @NO;
        Manifest(namedDisabled)[@"UnexpectedManifestOption"] = @YES;
        namedDisabled[@"UnexpectedWindowOption"] = @YES;
        Result(Read(namedDisabled), @"ineligible", @"multiple-scenes-disabled");
        for (id malformed in @[@[], @[@{}, @{}], NSNull.null]) {
            NSMutableDictionary *metadata = FilesInfo();
            Manifest(metadata)[@"UIApplicationSupportsMultipleScenes"] = @NO;
            Roles(metadata)[@"UIWindowSceneSessionRoleApplication"] = malformed;
            Result(Read(metadata), @"ineligible", @"multiple-scenes-disabled");
        }
        for (NSMutableDictionary *metadata in @[FilesInfo(), MailInfo()]) {
            metadata[@"CFBundlePackageType"] = @"XPC!";
            Result(Read(metadata), @"ineligible", @"not-application");
            metadata[@"CFBundlePackageType"] = @"APPL"; metadata[@"NSExtension"] = NSNull.null;
            Result(Read(metadata), @"ineligible", @"app-extension");
            [metadata removeObjectForKey:@"NSExtension"]; metadata[@"UIDeviceFamily"] = @[@2];
            Result(Read(metadata), @"ineligible", @"not-iphone");
            metadata[@"UIDeviceFamily"] = @[@1];
            for (NSString *flag in @[@"LSBackgroundOnly", @"LSUIElement", @"UIBackgroundOnly"]) {
                metadata[flag] = @YES; Result(Read(metadata), @"ineligible", @"not-application");
                metadata[flag] = @1; Result(Read(metadata), @"unknown", @"manifest-unknown");
                [metadata removeObjectForKey:flag];
            }
        }
        NSMutableDictionary *info = Info();
        info[@"UnrelatedUserInfo"] = @{@"nested": @[@{@"notForSerialization": @"private-value"}]};
        Result(Read(info), @"eligible", @"declared-single-application-scene");
        Check(![[Read(info) description] containsString:@"private-value"], "unrelated plist content is not published");
        for (id malformed in @[@[], @1, NSNull.null, @{}]) Result(Read(malformed), @"unknown", @"plist-invalid");
        Result(Read(nil), @"unknown", @"plist-invalid");
        info = Info(); info[@1] = @"invalid-key"; Result(Read(info), @"unknown", @"plist-invalid");
        info = Info();
        while (info.count < 256) info[[NSString stringWithFormat:@"Extra%lu", (unsigned long)info.count]] = @1;
        Result(Read(info), @"eligible", @"declared-single-application-scene");
        info[@"OneMore"] = @1; Result(Read(info), @"unknown", @"plist-invalid");

        for (id mismatch in @[@"com.example.other", @"COM.EXAMPLE.APPLICATION", @YES, NSNull.null]) {
            info = Info(); info[@"CFBundleIdentifier"] = mismatch; Result(Read(info), @"unknown", @"identifier-mismatch");
        }
        info = Info(); [info removeObjectForKey:@"CFBundleIdentifier"]; Result(Read(info), @"unknown", @"identifier-mismatch");
        info = Info(); info[@"CFBundlePackageType"] = @"XPC!"; Result(Read(info), @"ineligible", @"not-application");
        info = Info(); [info removeObjectForKey:@"CFBundlePackageType"]; Result(Read(info), @"unknown", @"manifest-unknown");
        info = Info(); info[@"CFBundlePackageType"] = @YES; Result(Read(info), @"unknown", @"manifest-unknown");
        info = Info(); info[@"NSExtension"] = @{}; Result(Read(info), @"ineligible", @"app-extension");
        info = Info(); info[@"NSExtension"] = NSNull.null; Result(Read(info), @"ineligible", @"app-extension");
        for (NSString *flag in @[@"LSBackgroundOnly", @"LSUIElement", @"UIBackgroundOnly"]) {
            info = Info(); info[flag] = @YES; Result(Read(info), @"ineligible", @"not-application");
            info = Info(); info[flag] = @NO; Result(Read(info), @"eligible", @"declared-single-application-scene");
            info = Info(); info[flag] = @1; Result(Read(info), @"unknown", @"manifest-unknown");
        }
        info = Info(); info[@"UIDeviceFamily"] = @[@2]; Result(Read(info), @"ineligible", @"not-iphone");
        for (id malformed in @[@[], @[@YES, @2], @[@1, @1], @[@1, @0.5], @[@(-1)],
                @[@(NAN)], @[@(INFINITY)], @[@"1"], @[@1, @2, @3, @4, @5, @6, @7, @8, @9], NSNull.null]) {
            info = Info(); info[@"UIDeviceFamily"] = malformed; Result(Read(info), @"unknown", @"manifest-unknown");
        }
        info = Info(); [info removeObjectForKey:@"UIDeviceFamily"]; Result(Read(info), @"unknown", @"manifest-unknown");
        info = Info(); info[@"UIDeviceFamily"] = @[@1.0, @2]; Result(Read(info), @"eligible", @"declared-single-application-scene");

        info = ProgrammaticInfo(); info[@"CFBundlePackageType"] = @"XPC!";
        Result(Read(info), @"ineligible", @"not-application");
        info = ProgrammaticInfo(); info[@"NSExtension"] = NSNull.null;
        Result(Read(info), @"ineligible", @"app-extension");
        info = ProgrammaticInfo(); info[@"UIDeviceFamily"] = @[@2];
        Result(Read(info), @"ineligible", @"not-iphone");
        info = ProgrammaticInfo(); info[@"UIDeviceFamily"] = @[@YES];
        Result(Read(info), @"unknown", @"manifest-unknown");
        for (NSString *flag in @[@"LSBackgroundOnly", @"LSUIElement", @"UIBackgroundOnly"]) {
            info = ProgrammaticInfo(); info[flag] = @YES;
            Result(Read(info), @"ineligible", @"not-application");
            info = ProgrammaticInfo(); info[flag] = @1;
            Result(Read(info), @"unknown", @"manifest-unknown");
        }

        info = Info(); [info removeObjectForKey:@"UIApplicationSceneManifest"]; Result(Read(info), @"unknown", @"manifest-unknown");
        for (id malformed in @[@YES, @[], NSNull.null]) {
            info = Info(); info[@"UIApplicationSceneManifest"] = malformed; Result(Read(info), @"unknown", @"manifest-unknown");
        }
        for (id malformed in @[@1, @0, @"true", NSNull.null]) {
            info = Info(); Manifest(info)[@"UIApplicationSupportsMultipleScenes"] = malformed;
            Result(Read(info), @"unknown", @"manifest-unknown");
            info = ProgrammaticInfo(); Manifest(info)[@"UIApplicationSupportsMultipleScenes"] = malformed;
            Result(Read(info), @"unknown", @"manifest-unknown");
        }
        info = Info(); [Manifest(info) removeObjectForKey:@"UIApplicationSupportsMultipleScenes"];
        Result(Read(info), @"unknown", @"manifest-unknown");
        info = ProgrammaticInfo(); [Manifest(info) removeObjectForKey:@"UIApplicationSupportsMultipleScenes"];
        Result(Read(info), @"unknown", @"manifest-unknown");
        info = Info(); Manifest(info)[@"UIApplicationSupportsMultipleScenes"] = @NO;
        info[@"system-windows-secure"] = @YES;
        Result(Read(info), @"ineligible", @"multiple-scenes-disabled");
        info = ProgrammaticInfo(); Manifest(info)[@"UIApplicationSupportsMultipleScenes"] = @NO;
        Manifest(info)[@"UnexpectedManifestOption"] = @YES;
        info[@"UnexpectedWindowOption"] = @YES;
        Result(Read(info), @"ineligible", @"multiple-scenes-disabled");
        info = Info(); info[@"system-windows-secure"] = @NO; Result(Read(info), @"unknown", @"manifest-complex");
        info = Info(); info[@"UnexpectedSCENEOption"] = @1; Result(Read(info), @"unknown", @"manifest-complex");
        info = Info(); Manifest(info)[@"UIApplicationSupportsTabbedScenes"] = @YES;
        Result(Read(info), @"unknown", @"manifest-complex");
        info = Info(); [Manifest(info) removeObjectForKey:@"UISceneConfigurations"];
        Result(Read(info), @"eligible", @"declared-programmatic-application-scenes");
        for (NSString *key in @[@"system-windows-secure", @"UnexpectedSCENEOption", @"UIWindowOptions"])
            for (NSNumber *value in @[@NO, @YES]) {
                info = ProgrammaticInfo(); info[key] = value;
                Result(Read(info), @"unknown", @"manifest-complex");
            }
        for (id key in @[@"UIApplicationSupportsTabbedScenes", @"UnexpectedManifestOption", @1]) {
            info = ProgrammaticInfo(); Manifest(info)[key] = @YES;
            Result(Read(info), @"unknown", @"manifest-complex");
        }
        for (id malformed in @[@[], @YES, @1, @"dynamic", NSNull.null]) {
            info = ProgrammaticInfo(); Manifest(info)[@"UISceneConfigurations"] = malformed;
            Result(Read(info), @"unknown", @"manifest-unknown");
        }
        info = Info(); Manifest(info)[@"UISceneConfigurations"] = @{}; Result(Read(info), @"unknown", @"manifest-complex");
        info = Info(); Roles(info)[@"UIWindowSceneSessionRoleExternalDisplay"] = @[@{}];
        Result(Read(info), @"unknown", @"manifest-complex");
        info = ProgrammaticInfo(); Manifest(info)[@"UISceneConfigurations"] = @{
            @"UIWindowSceneSessionRoleExternalDisplay": @[@{}]};
        Result(Read(info), @"unknown", @"manifest-complex");
        for (id malformed in @[@[], @[@{}, @{}], @[@{}], @[@1], @[@{@"unknown": @"value"}],
                @[@{@"UISceneDelegateClassName": @[]}], @[@{@"UISceneClassName": @""}],
                @[@{@"UISceneClassName": [@"a" stringByPaddingToLength:257 withString:@"a" startingAtIndex:0]}],
                @YES, NSNull.null]) {
            info = Info(); Roles(info)[@"UIWindowSceneSessionRoleApplication"] = malformed;
            Result(Read(info), @"unknown", ([malformed isKindOfClass:NSArray.class] ? @"manifest-complex" : @"manifest-unknown"));
        }
        for (NSString *field in @[@"UISceneConfigurationName", @"UISceneClassName", @"UISceneDelegateClassName",
                @"UISceneStoryboardFile", @"UILaunchStoryboardName"]) {
            info = Info(); Roles(info)[@"UIWindowSceneSessionRoleApplication"] = @[@{field: @"Valid Configuration"}];
            Result(Read(info), @"eligible", @"declared-single-application-scene");
        }

        NSArray *unknownReasons = @[@"unsupported-framework", @"unsupported-abi", @"app-unavailable", @"ambiguous-app",
            @"no-bundle-url", @"bundle-unavailable", @"file-unavailable", @"file-invalid", @"file-too-large",
            @"plist-invalid", @"manifest-unknown", @"manifest-complex", @"identifier-mismatch",
            @"request-expired", @"service-unavailable"];
        for (NSString *reason in unknownReasons)
            Result(PPOSceneCapabilityUnknown(Identifier, reason, 100), @"unknown", reason);
        Check(PPOSceneCapabilityUnknown(Identifier, @"made-up", 100) == nil, "unknown reason cannot expand the protocol");
        for (NSString *reason in @[@"declared-single-application-scene", @"declared-programmatic-application-scenes",
                @"declared-named-application-configurations"]) {
            NSMutableDictionary *candidate = [Read(Info()) mutableCopy];
            candidate[@"reason"] = reason;
            Result(PPOSceneCapabilityNormalize(candidate), @"eligible", reason);
            Check(PPOSceneCapabilityUnknown(Identifier, reason, 100) == nil,
                  "eligible reasons are not members of the unknown reason enumeration");
            for (NSString *status in @[@"unknown", @"ineligible"]) {
                candidate[@"status"] = status; candidate[@"eligible"] = @NO;
                Check(PPOSceneCapabilityNormalize(candidate) == nil,
                      "each eligible reason is confined to eligible status with a genuine true Boolean");
            }
            candidate[@"status"] = @"eligible"; candidate[@"eligible"] = @NO;
            Check(PPOSceneCapabilityNormalize(candidate) == nil,
                  "an eligible reason cannot turn a false eligibility flag into an eligible proof");
        }
        NSArray *reasonGroups = @[
            @{@"status": @"eligible", @"reasons": @[@"declared-single-application-scene",
                @"declared-programmatic-application-scenes", @"declared-named-application-configurations"]},
            @{@"status": @"ineligible", @"reasons": @[@"not-application", @"app-extension",
                @"not-iphone", @"multiple-scenes-disabled"]},
            @{@"status": @"unknown", @"reasons": unknownReasons}];
        for (NSDictionary *group in reasonGroups)
            for (NSString *reason in group[@"reasons"]) {
                for (NSString *status in @[@"eligible", @"ineligible", @"unknown"])
                    for (NSDictionary *flag in @[@{@"value": @YES, @"genuine": @YES},
                            @{@"value": @NO, @"genuine": @YES},
                            @{@"value": @1, @"genuine": @NO}, @{@"value": @0, @"genuine": @NO}]) {
                        NSMutableDictionary *candidate = [Read(Info()) mutableCopy];
                        candidate[@"reason"] = reason; candidate[@"status"] = status;
                        candidate[@"eligible"] = flag[@"value"];
                        BOOL expected = [group[@"status"] isEqual:status] && [flag[@"genuine"] boolValue] &&
                            [flag[@"value"] boolValue] == [status isEqual:@"eligible"];
                        NSDictionary *normalized = PPOSceneCapabilityNormalize(candidate);
                        Check(expected ? [normalized isEqual:candidate] : normalized == nil,
                              "the complete canonical reason/status matrix requires its matching genuine Boolean");
                    }
                NSMutableDictionary *canonical = [Read(Info()) mutableCopy];
                canonical[@"reason"] = reason; canonical[@"status"] = group[@"status"];
                canonical[@"eligible"] = @([group[@"status"] isEqual:@"eligible"]);
                for (NSString *policy in @[@"installed-basic-multiscene-v1", @"installed-basic-multiscene-v2", @"installed-basic-multiscene-v3"]) {
                    canonical[@"policy"] = policy;
                    Check(PPOSceneCapabilityNormalize(canonical) == nil && !PPOSceneCapabilityFresh(canonical, 100),
                          "legacy policy rejection also covers every unknown and ineligible canonical reason");
                }
            }
        for (NSNumber *badTime in @[@(-1), @(NAN), @(INFINITY)])
            Check(PPOSceneCapabilityFromInfo(Info(), Identifier, badTime.doubleValue) == nil &&
                  PPOSceneCapabilityUnknown(Identifier, @"file-unavailable", badTime.doubleValue) == nil,
                  "invalid observation clocks never produce descriptors");

        NormalizeField(@"schema", @[@YES, @0, @2, @0.5, @(NAN), @(INFINITY), @"1", NSNull.null]);
        NormalizeField(@"policy", @[@"installed-basic-multiscene-v1", @"installed-basic-multiscene-v2", @"installed-basic-multiscene-v3", @"unknown-v2", @1, NSNull.null]);
        NormalizeField(@"bundleIdentifier", @[@"com.other..app", @"com.apple.springboard", @1, NSNull.null]);
        NormalizeField(@"status", @[@"unknown", @"ineligible", @"other", @1, NSNull.null]);
        NormalizeField(@"eligible", @[@1, @0, @NO, @"true", NSNull.null]);
        NormalizeField(@"reason", @[@"manifest-unknown", @"not-application", @"other",
            @"declared-programmatic-application-scene", @"Declared-programmatic-application-scenes",
            @"declared-programmatic-application-scenes ", @"declared-named-application-configuration",
            @"Declared-named-application-configurations", @"declared-named-application-configurations ", @1, NSNull.null]);
        NormalizeField(@"observedUptime", @[@YES, @(-1), @(NAN), @(INFINITY), @"100", NSNull.null]);
        NSDictionary *valid = Read(Info());
        for (NSString *field in valid) {
            NSMutableDictionary *value = [valid mutableCopy]; [value removeObjectForKey:field];
            Check(PPOSceneCapabilityNormalize(value) == nil, "every normalized field is required");
        }
        NSMutableDictionary *extra = [valid mutableCopy]; extra[@"bundlePath"] = @"/private/app.app";
        Check(PPOSceneCapabilityNormalize(extra) == nil, "raw paths and extra metadata cannot enter the descriptor");
        Check(PPOSceneCapabilityNormalize(@[]) == nil && PPOSceneCapabilityNormalize(nil) == nil,
              "normalized root must be a dictionary");
        NSMutableDictionary *contradictory = [PPOSceneCapabilityUnknown(Identifier, @"file-unavailable", 100) mutableCopy];
        contradictory[@"eligible"] = @YES;
        Check(PPOSceneCapabilityNormalize(contradictory) == nil, "an unknown status cannot carry positive eligibility");
        contradictory = [valid mutableCopy]; contradictory[@"schema"] = @1.0;
        Check(PPOSceneCapabilityNormalize(contradictory) != nil, "integral numeric schema is distinct from a Boolean");

        NSMutableString *mutableIdentifier = [Identifier mutableCopy];
        NSMutableString *mutablePolicy = [@"installed-basic-multiscene-v4" mutableCopy];
        NSMutableString *mutableStatus = [@"eligible" mutableCopy];
        NSMutableString *mutableReason = [@"declared-single-application-scene" mutableCopy];
        NSMutableDictionary *caller = [valid mutableCopy];
        caller[@"bundleIdentifier"] = mutableIdentifier; caller[@"policy"] = mutablePolicy;
        caller[@"status"] = mutableStatus; caller[@"reason"] = mutableReason;
        NSDictionary *snapshot = PPOSceneCapabilityNormalize(caller);
        [mutableIdentifier setString:@"com.example.other"]; [mutablePolicy setString:@"other"];
        [mutableStatus setString:@"unknown"]; [mutableReason setString:@"file-unavailable"];
        caller[@"observedUptime"] = @1000;
        Result(snapshot, @"eligible", @"declared-single-application-scene");
        info = Info(); info[@"CFBundleIdentifier"] = [Identifier mutableCopy];
        NSDictionary *parsedSnapshot = Read(info);
        [(NSMutableString *)info[@"CFBundleIdentifier"] setString:@"com.example.changed"];
        Result(parsedSnapshot, @"eligible", @"declared-single-application-scene");

        NSMutableString *programmaticReason = [@"declared-programmatic-application-scenes" mutableCopy];
        caller = [Read(ProgrammaticInfo()) mutableCopy]; caller[@"reason"] = programmaticReason;
        snapshot = PPOSceneCapabilityNormalize(caller);
        [programmaticReason setString:@"file-unavailable"]; [caller removeAllObjects];
        Result(snapshot, @"eligible", @"declared-programmatic-application-scenes");
        NSMutableString *namedReason = [@"declared-named-application-configurations" mutableCopy];
        caller = [Read(MailInfo()) mutableCopy]; caller[@"reason"] = namedReason;
        snapshot = PPOSceneCapabilityNormalize(caller);
        [namedReason setString:@"file-unavailable"]; [caller removeAllObjects];
        Result(snapshot, @"eligible", @"declared-named-application-configurations");
        NSMutableDictionary *namedMetadata = MailInfo();
        NSMutableArray *mutableConfigurations = NamedConfigurations(namedMetadata);
        NSMutableString *mutableName = [@"Mutable Named Configuration" mutableCopy];
        NSMutableDictionary *mutableConfiguration = [mutableConfigurations.lastObject mutableCopy];
        mutableConfiguration[@"UISceneConfigurationName"] = mutableName;
        mutableConfigurations[mutableConfigurations.count - 1] = mutableConfiguration;
        NSDictionary *namedSnapshot = Read(namedMetadata);
        [mutableName setString:@" "]; [mutableConfiguration removeAllObjects];
        [mutableConfigurations removeAllObjects]; [namedMetadata removeAllObjects];
        Result(namedSnapshot, @"eligible", @"declared-named-application-configurations");
        NSDictionary *programmatic = Read(ProgrammaticInfo());
        NSDictionary *wireCopy = [NSJSONSerialization JSONObjectWithData:
            [NSJSONSerialization dataWithJSONObject:programmatic options:0 error:NULL] options:0 error:NULL];
        Result(PPOSceneCapabilityNormalize(wireCopy), @"eligible", @"declared-programmatic-application-scenes");

        Check(PPOSceneCapabilityFresh(valid, 100) && PPOSceneCapabilityFresh(valid, 105) &&
              PPOSceneCapabilityFresh(valid, 99.9), "freshness includes exact current, deadline and skew boundaries");
        Check(!PPOSceneCapabilityFresh(valid, 105.0001) && !PPOSceneCapabilityFresh(valid, 99.8999),
              "expired and excessively future observations are rejected");
        for (NSNumber *now in @[@(-1), @(NAN), @(INFINITY)])
            Check(!PPOSceneCapabilityFresh(valid, now.doubleValue), "invalid caller clocks cannot grant freshness");
        Check(!PPOSceneCapabilityFresh(extra, 100) && !PPOSceneCapabilityFresh(nil, 100),
              "freshness never bypasses normalization");
        Check(PPOSceneCapabilityFresh(programmatic, 100) && PPOSceneCapabilityFresh(programmatic, 105) &&
              PPOSceneCapabilityFresh(programmatic, 99.9) && !PPOSceneCapabilityFresh(programmatic, 105.0001) &&
              !PPOSceneCapabilityFresh(programmatic, 99.8999),
              "programmatic eligibility uses the same freshness and future-skew limits");
        for (NSDictionary *fixture in @[valid, programmatic, Read(FilesInfo()), Read(MailInfo())]) {
            NSDictionary *jsonCopy = [NSJSONSerialization JSONObjectWithData:
                [NSJSONSerialization dataWithJSONObject:fixture options:0 error:NULL] options:0 error:NULL];
            Check([PPOSceneCapabilityNormalize(jsonCopy) isEqual:fixture],
                  "JSON round trip retains the exact normalized proof for every eligible shape");
            Check(PPOSceneCapabilityFresh(fixture, 100) && PPOSceneCapabilityFresh(fixture, 105) &&
                  PPOSceneCapabilityFresh(fixture, 99.9) && !PPOSceneCapabilityFresh(fixture, 105.0001) &&
                  !PPOSceneCapabilityFresh(fixture, 99.8999),
                  "every current-policy eligible reason obeys the same freshness boundaries");
            for (NSString *policy in @[@"installed-basic-multiscene-v1", @"installed-basic-multiscene-v2", @"installed-basic-multiscene-v3"]) {
                NSMutableDictionary *legacy = [fixture mutableCopy]; legacy[@"policy"] = policy;
                Check(PPOSceneCapabilityNormalize(legacy) == nil && !PPOSceneCapabilityFresh(legacy, 100),
                      "v1 and v2 proofs are rejected without translation or freshening for every eligible reason");
            }
        }
        printf("Scene capability tests passed: %u checks; policy v4 synthetic metadata, normalization and freshness; no app admission\n", checks);
    }
    return 0;
}
