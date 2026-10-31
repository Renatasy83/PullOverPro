#import "PPOWorkspace.h"
#import "PPOBundleSceneReader.h"
#import "../../PPOBridgeProtocol.h"
#import "../../PPOSceneCapability.h"
#import "../app-launch/PPOLaunchABI.h"
#import <objc/message.h>
#include <dlfcn.h>

// Uses only the accessors and opener previously inspected/tested on the device.
// Signature checks are repeated on the actual receiver in this helper process.
static id PPOObjectAccessor(id receiver, const char *name) {
    if (!receiver) return nil;
    SEL selector = sel_registerName(name);
    Method method = class_getInstanceMethod(object_getClass(receiver), selector);
    if (!PPOGetterABI(method)) return nil;
    // These getter names follow Cocoa's +0 ownership convention.
    return ((id (*)(id, SEL))objc_msgSend)(receiver, selector);
}

static id PPOWorkspace(void) {
    Class cls = objc_lookUpClass("LSApplicationWorkspace");
    if (!cls) {
        // Keep this system framework loaded for the lifetime of the service.
        static void *framework;
        if (!framework) {
            framework = dlopen(
                "/System/Library/Frameworks/MobileCoreServices.framework/MobileCoreServices",
                RTLD_LAZY | RTLD_LOCAL);
        }
        if (!framework) return nil;
        cls = objc_lookUpClass("LSApplicationWorkspace");
    }
    return cls ? PPOObjectAccessor((id)cls, "defaultWorkspace") : nil;
}

NSDictionary *PPOWorkspaceRefresh(void) {
    if (!NSThread.isMainThread) return nil;
    @try {
        id workspace = PPOWorkspace();
        id raw = PPOObjectAccessor(workspace, "allInstalledApplications");
        if (![raw isKindOfClass:NSArray.class] || [(NSArray *)raw count] > 4096) return nil;
        Class proxyClass = objc_lookUpClass("LSApplicationProxy");
        if (!proxyClass) return nil;
        NSMutableArray *apps = [NSMutableArray array];
        NSMutableSet *seen = [NSMutableSet set];
        NSUInteger skipped = 0;
        for (id proxy in (NSArray *)raw) {
            @autoreleasepool {
                if (![proxy isKindOfClass:proxyClass]) { skipped++; continue; }
                id identifier = PPOObjectAccessor(proxy, "applicationIdentifier");
                if (!PPOBridgeValidIdentifier(identifier) || [seen containsObject:identifier]) {
                    skipped++; continue;
                }
                id name = PPOObjectAccessor(proxy, "localizedName");
                NSString *label = [name isKindOfClass:NSString.class] && [(NSString *)name length]
                    ? name : identifier;
                if (label.length > 512) label = [label substringToIndex:512];
                [seen addObject:identifier];
                [apps addObject:@{@"bundleIdentifier": identifier, @"name": label}];
            }
        }
        [apps sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
            return [a[@"name"] localizedCaseInsensitiveCompare:b[@"name"]];
        }];
        return @{
            @"schema": @1, @"version": @"bridge1",
            @"source": @"LSApplicationWorkspace.allInstalledApplications",
            @"os": NSProcessInfo.processInfo.operatingSystemVersionString,
            @"created": NSDate.date.description,
            @"count": @(apps.count), @"skipped": @(skipped), @"apps": apps
        };
    } @catch (NSException *exception) {
        (void)exception;
        return nil;
    }
}

NSDictionary *PPOWorkspaceSceneCapability(NSString *identifier) {
    NSTimeInterval now = NSProcessInfo.processInfo.systemUptime;
    if (!PPOSceneApplicationIdentifierAllowed(identifier)) return nil;
    if (!NSThread.isMainThread)
        return PPOSceneCapabilityUnknown(identifier, @"unsupported-abi", now);
    @try {
        id raw = PPOObjectAccessor(PPOWorkspace(), "allInstalledApplications");
        Class applicationClass = objc_lookUpClass("LSApplicationProxy");
        Class bundleClass = objc_lookUpClass("LSBundleProxy");
        if (![raw isKindOfClass:NSArray.class] || [(NSArray *)raw count] > 4096 ||
            !applicationClass || !bundleClass)
            return PPOSceneCapabilityUnknown(identifier, @"app-unavailable", now);
        id selected = nil;
        for (id proxy in (NSArray *)raw) {
            if (![proxy isKindOfClass:applicationClass]) continue;
            id actualIdentifier = PPOObjectAccessor(proxy, "applicationIdentifier");
            if (![actualIdentifier isKindOfClass:NSString.class] || ![actualIdentifier isEqual:identifier]) continue;
            if (selected) return PPOSceneCapabilityUnknown(identifier, @"ambiguous-app", now);
            selected = proxy;
        }
        if (!selected) return PPOSceneCapabilityUnknown(identifier, @"app-unavailable", now);
        return PPOCapabilityFromApplicationProxy(selected, applicationClass, bundleClass,
            PPOBundleCapabilityFrameworkMatches(), identifier, NSProcessInfo.processInfo.systemUptime);
    } @catch (NSException *exception) {
        (void)exception;
        return PPOSceneCapabilityUnknown(identifier, @"unsupported-abi", NSProcessInfo.processInfo.systemUptime);
    }
}

static BOOL PPOWorkspaceFailure(NSString **failureCode, NSString *code) {
    if (failureCode) *failureCode = code;
    return NO;
}

BOOL PPOWorkspaceLaunch(NSString *identifier, NSString **failureCode) {
    if (failureCode) *failureCode = nil;
    if (!NSThread.isMainThread) return PPOWorkspaceFailure(failureCode, @"wrong-thread");
    if (!PPOBridgeValidIdentifier(identifier) ||
        [identifier isEqualToString:@"com.apple.springboard"] ||
        [identifier isEqualToString:@"com.apple.backboardd"]) {
        return PPOWorkspaceFailure(failureCode, @"invalid-identifier");
    }
    @try {
        id workspace = PPOWorkspace();
        SEL selector = sel_registerName("openApplicationWithBundleID:");
        Method opener = workspace ?
            class_getInstanceMethod(object_getClass(workspace), selector) : NULL;
        if (!PPOLaunchABI(opener)) return PPOWorkspaceFailure(failureCode, @"unsupported-abi");
        BOOL accepted = ((BOOL (*)(id, SEL, id))objc_msgSend)(workspace, selector, identifier);
        return accepted ? YES : PPOWorkspaceFailure(failureCode, @"launch-rejected");
    } @catch (NSException *exception) {
        (void)exception;
        return PPOWorkspaceFailure(failureCode, @"workspace-exception");
    }
}
