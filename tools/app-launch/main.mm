#import "../../PPOAppData.h"
#import "PPOLaunchABI.h"
#import <objc/message.h>
#include <dlfcn.h>
#include <stdio.h>
#include <unistd.h>

// Manual helper only. Never invoked by SpringBoard in this release.
int main(int argc, char *argv[]) {
    @autoreleasepool {
        BOOL probe = argc == 2 && strcmp(argv[1], "--probe") == 0;
        BOOL launch = argc == 2 && strcmp(argv[1], "--launch") == 0;
        if (!probe && !launch) {
            fprintf(stderr, "Usage: ppo-open --probe | --launch\n");
            return 2;
        }
        if (geteuid() == 0) {
            fprintf(stderr, "Run as mobile, without su or sudo.\n");
            return 2;
        }
        alarm(20);
        @try {
            Class cls = objc_lookUpClass("LSApplicationWorkspace");
            if (!cls) {
                void *framework = dlopen(
                    "/System/Library/Frameworks/MobileCoreServices.framework/MobileCoreServices",
                    RTLD_LAZY | RTLD_LOCAL);
                if (!framework) {
                    fprintf(stderr, "MobileCoreServices unavailable.\n"); return 3;
                }
                cls = objc_lookUpClass("LSApplicationWorkspace");
            }
            if (!cls) { fprintf(stderr, "Workspace class unavailable.\n"); return 3; }
            SEL factory = sel_registerName("defaultWorkspace");
            SEL open = sel_registerName("openApplicationWithBundleID:");
            Method getter = class_getClassMethod(cls, factory);
            Method opener = class_getInstanceMethod(cls, open);
            const char *getterTypes = getter ? method_getTypeEncoding(getter) : NULL;
            const char *openTypes = opener ? method_getTypeEncoding(opener) : NULL;
            BOOL supported = PPOGetterABI(getter) && PPOLaunchABI(opener);
            printf("PPO 0.5.9 launcher1\n+defaultWorkspace: %s\n-openApplicationWithBundleID:: %s\n",
                getterTypes ? getterTypes : "(missing)", openTypes ? openTypes : "(missing)");
            printf("ABI supported: %s\n", supported ? "yes" : "no");
            if (probe) { printf("Probe only. No application launch requested.\n"); return 0; }
            if (!supported) { fprintf(stderr, "Launch refused: unsupported ABI.\n"); return 4; }

            NSString *path = @"/var/mobile/Library/Preferences/com.renatasy83.pulloverpro.diagnostic.selection.plist";
            NSDictionary *selection = PPOSelectionFromData(PPOReadBoundedFile(path, 16384, NULL));
            NSString *identifier = selection[@"bundleIdentifier"];
            // One known normal application for the first device launch test.
            if (![identifier isEqualToString:@"com.apple.mobilesafari"]) {
                fprintf(stderr, "Select Safari in PPO first. This release launches only Safari.\n");
                return 5;
            }
            NSArray *apps = PPOAppsFromData(PPOReadBoundedFile(
                @"/var/mobile/Library/Logs/PullOverPro/apps-0.5.7.json", 2*1024*1024, NULL), NULL);
            BOOL found = NO;
            for (NSDictionary *app in apps) {
                if ([app[@"bundleIdentifier"] isEqual:identifier]) { found = YES; break; }
            }
            if (!found) {
                fprintf(stderr, "Safari is absent from the validated report. Refresh with ppo-apps.\n");
                return 5;
            }
            // Getter ABI and +0 Cocoa accessor convention match the enumeration baseline.
            id workspace = ((id (*)(id, SEL))objc_msgSend)((id)cls, factory);
            Method actual = workspace ?
                class_getInstanceMethod(object_getClass(workspace), open) : NULL;
            if (!PPOLaunchABI(actual)) {
                fprintf(stderr, "Launch refused: actual workspace ABI is unsupported.\n"); return 4;
            }
            printf("Requesting Safari launch...\n");
            fflush(stdout);
            BOOL accepted = ((BOOL (*)(id, SEL, id))objc_msgSend)(workspace, open, identifier);
            alarm(0);
            printf("Launch request accepted: %s\n", accepted ? "yes" : "no");
            printf("Confirm visually whether Safari opened. No scene hosting requested.\n");
            return accepted ? 0 : 6;
        } @catch (NSException *exception) {
            fprintf(stderr, "Launcher stopped: %s\n", exception.name.UTF8String);
            return 7;
        }
    }
}
