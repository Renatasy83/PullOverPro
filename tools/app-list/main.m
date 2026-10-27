#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#include <dlfcn.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

// This executable runs only when invoked from NewTerm, never inside SpringBoard.
static id ObjectResult(id receiver, const char *name) {
    if (!receiver) [NSException raise:@"PPOAPI" format:@"Missing receiver for %s", name];
    SEL selector = sel_registerName(name);
    Method method = class_getInstanceMethod(object_getClass(receiver), selector);
    const char *types = method ? method_getTypeEncoding(method) : NULL;
    // Exact ABI observed on the device; revalidate in THIS process before every call.
    if (!types || strcmp(types, "@16@0:8") != 0 ||
        method_getNumberOfArguments(method) != 2) {
        [NSException raise:@"PPOAPI" format:@"Rejected signature for %s: %s",
            name, types ? types : "(missing)"];
    }
    // These accessor names follow the Cocoa +0 return convention.
    return ((id (*)(id, SEL))objc_msgSend)(receiver, selector);
}

int main(int argc, char *argv[]) {
    (void)argv;
    @autoreleasepool {
        if (argc != 1) {
            fprintf(stderr, "Usage: ppo-apps (no arguments)\n");
            return 2;
        }
        if (geteuid() == 0) {
            fprintf(stderr, "Run from NewTerm as mobile, without su or sudo.\n");
            return 2;
        }
        // Default SIGALRM terminates only this helper if a request hangs.
        alarm(20);
        @try {
            Class workspaceClass = objc_lookUpClass("LSApplicationWorkspace");
            if (!workspaceClass) {
                void *framework = dlopen(
                    "/System/Library/Frameworks/MobileCoreServices.framework/MobileCoreServices",
                    RTLD_LAZY | RTLD_LOCAL);
                if (!framework) {
                    fprintf(stderr, "MobileCoreServices unavailable; no enumeration performed.\n");
                    return 3;
                }
                // Keep the system framework loaded until this process exits.
                workspaceClass = objc_lookUpClass("LSApplicationWorkspace");
            }
            if (!workspaceClass) {
                fprintf(stderr, "LSApplicationWorkspace unavailable in helper process.\n");
                return 3;
            }
            id workspace = ObjectResult((id)workspaceClass, "defaultWorkspace");
            id value = ObjectResult(workspace, "allInstalledApplications");
            if (![value isKindOfClass:NSArray.class] || [(NSArray *)value count] > 4096) {
                fprintf(stderr, "Rejected unexpected application collection.\n");
                return 4;
            }
            Class proxyClass = objc_lookUpClass("LSApplicationProxy");
            if (!proxyClass) {
                fprintf(stderr, "LSApplicationProxy unavailable.\n");
                return 3;
            }
            NSMutableArray *apps = [NSMutableArray array];
            NSMutableSet *seen = [NSMutableSet set];
            NSUInteger skipped = 0;
            for (id proxy in (NSArray *)value) {
                @autoreleasepool {
                    if (![proxy isKindOfClass:proxyClass]) { skipped++; continue; }
                    id identifier = ObjectResult(proxy, "applicationIdentifier");
                    id name = ObjectResult(proxy, "localizedName");
                    if (![identifier isKindOfClass:NSString.class] ||
                        ![(NSString *)identifier length] || [(NSString *)identifier length] > 512) {
                        skipped++; continue;
                    }
                    if ([seen containsObject:identifier]) { skipped++; continue; }
                    [seen addObject:identifier];
                    NSString *label = [name isKindOfClass:NSString.class] &&
                        [(NSString *)name length] ? name : identifier;
                    if (label.length > 512) label = [label substringToIndex:512];
                    [apps addObject:@{@"bundleIdentifier": identifier, @"name": label}];
                }
            }
            [apps sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
                return [a[@"name"] localizedCaseInsensitiveCompare:b[@"name"]];
            }];
            NSDictionary *report = @{
                @"schema": @1, @"version": @"0.5.7~enumerator1",
                @"source": @"LSApplicationWorkspace.allInstalledApplications",
                @"os": NSProcessInfo.processInfo.operatingSystemVersionString,
                @"created": NSDate.date.description,
                @"count": @(apps.count), @"skipped": @(skipped), @"apps": apps
            };
            NSError *error = nil;
            NSData *json = [NSJSONSerialization dataWithJSONObject:report
                options:NSJSONWritingPrettyPrinted error:&error];
            NSString *directory = @"/var/mobile/Library/Logs/PullOverPro";
            NSString *path = [directory stringByAppendingPathComponent:@"apps-0.5.7.json"];
            if (!json || ![NSFileManager.defaultManager createDirectoryAtPath:directory
                    withIntermediateDirectories:YES attributes:nil error:&error] ||
                ![json writeToFile:path options:NSDataWritingAtomic error:&error]) {
                fprintf(stderr, "Cannot save PPO report (error code %ld).\n", (long)error.code);
                return 5;
            }
            alarm(0);
            printf("PPO 0.5.7: %lu entries, %lu skipped.\nReport: %s\n",
                (unsigned long)apps.count, (unsigned long)skipped, path.UTF8String);
            printf("No apps launched. Entries are not verified as launchable.\n");
            return 0;
        } @catch (NSException *exception) {
            fprintf(stderr, "Enumeration stopped: %s: %s\n",
                exception.name.UTF8String, exception.reason.UTF8String);
            return 6;
        }
    }
}
