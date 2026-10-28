#import "../tools/bridge/PPOBridgeService.h"
#import "../tools/bridge/PPOWorkspace.h"
#import "../PPOBridgeProtocol.h"
#import "../PPOAppData.h"
#import <dispatch/dispatch.h>
#include <stdio.h>
#include <stdlib.h>

static NSUInteger refreshCalls, launchCalls;
static BOOL failInventory, throwRefresh, throwLaunch, acceptLaunch;
static NSTimeInterval refreshDelay;
static NSString *launchedIdentifier;

NSDictionary *PPOWorkspaceRefresh(void) {
    refreshCalls++;
    if (refreshDelay > 0) [NSThread sleepForTimeInterval:refreshDelay];
    if (throwRefresh) [NSException raise:@"FakeRefreshException" format:@"fixture"];
    if (failInventory) return nil;
    NSArray *apps = @[
        @{@"bundleIdentifier": @"com.apple.mobilesafari", @"name": @"Safari"},
        @{@"bundleIdentifier": @"com.apple.springboard", @"name": @"SpringBoard"},
        @{@"bundleIdentifier": @"com.apple.backboardd", @"name": @"BackBoard"}
    ];
    return @{@"schema": @1, @"source": @"LSApplicationWorkspace.allInstalledApplications",
        @"count": @(apps.count), @"apps": apps};
}

BOOL PPOWorkspaceLaunch(NSString *identifier, NSString **failureCode) {
    launchCalls++;
    launchedIdentifier = [identifier copy];
    if (throwLaunch) [NSException raise:@"FakeLaunchException" format:@"fixture"];
    if (!acceptLaunch && failureCode) *failureCode = @"launch-rejected";
    return acceptLaunch;
}

static void Check(BOOL condition, const char *name) {
    if (!condition) { fprintf(stderr, "FAIL: %s\n", name); exit(1); }
}

static void Reset(void) {
    refreshCalls = 0; launchCalls = 0;
    failInventory = NO; throwRefresh = NO; throwLaunch = NO;
    acceptLaunch = YES; refreshDelay = 0; launchedIdentifier = nil;
}

static NSDictionary *Run(NSString *operation, NSString *identifier, NSTimeInterval age,
                          NSString *reportPath) {
    NSString *nonce = NSUUID.UUID.UUIDString;
    NSData *request = PPOBridgeRequestData(nonce, operation, identifier,
        NSProcessInfo.processInfo.systemUptime - age, NULL);
    Check(request != nil, "fixture request encoded");
    NSData *data = PPOBridgeServiceResponse(request, reportPath);
    NSDictionary *response = PPOBridgeResponseFromData(data, nonce, NULL);
    Check(response != nil && [response[@"nonce"] isEqual:nonce], "valid nonce-bound response");
    return response;
}

int main(void) {
    @autoreleasepool {
        NSString *directory = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
        Check([NSFileManager.defaultManager createDirectoryAtPath:directory
            withIntermediateDirectories:NO attributes:nil error:NULL], "temporary directory");
        NSString *reportPath = [directory stringByAppendingPathComponent:@"apps.json"];
        Reset();
        NSDictionary *reply = Run(@"ping", nil, 0, reportPath);
        Check([reply[@"status"] isEqual:@"ready"] && refreshCalls == 0 && launchCalls == 0,
            "ping performs no workspace call");

        NSString *nonce = NSUUID.UUID.UUIDString;
        NSData *expired = PPOBridgeRequestData(nonce, @"launch", @"com.apple.mobilesafari",
            NSProcessInfo.processInfo.systemUptime - 6, NULL);
        Check(PPOBridgeServiceResponse(expired, reportPath) == nil &&
            refreshCalls == 0 && launchCalls == 0, "expired request performs no workspace call");
        Check(PPOBridgeServiceResponse([@"bad JSON" dataUsingEncoding:NSUTF8StringEncoding], reportPath) == nil &&
            refreshCalls == 0 && launchCalls == 0, "malformed request performs no workspace call");

        Reset();
        reply = Run(@"refresh", nil, 0, reportPath);
        NSArray *saved = PPOAppsFromData([NSData dataWithContentsOfFile:reportPath], NULL);
        Check([reply[@"status"] isEqual:@"refreshed"] &&
            [reply[@"appsCount"] isEqual:@3] && saved.count == 3 && refreshCalls == 1 && launchCalls == 0,
            "refresh saves validated inventory");

        Reset();
        reply = Run(@"launch", @"com.apple.mobilesafari", 0, reportPath);
        Check([reply[@"status"] isEqual:@"accepted"] && refreshCalls == 1 && launchCalls == 1 &&
            [launchedIdentifier isEqual:@"com.apple.mobilesafari"], "exact member launch accepted");
        for (NSString *identifier in @[@"unknown.app", @"com.apple.mobilesafari.suffix",
                                       @"com.apple.springboard", @"com.apple.backboardd"]) {
            Reset();
            reply = Run(@"launch", identifier, 0, reportPath);
            Check([reply[@"status"] isEqual:@"rejected"] && refreshCalls == 1 && launchCalls == 0,
                "unknown or restricted identifier denied before launch");
        }

        Reset();
        refreshDelay = 0.25;
        reply = Run(@"launch", @"com.apple.mobilesafari", 4.9, reportPath);
        Check([reply[@"status"] isEqual:@"stale"] && refreshCalls == 1 && launchCalls == 0,
            "request expires during inventory refresh before launch");

        Reset();
        acceptLaunch = NO;
        reply = Run(@"launch", @"com.apple.mobilesafari", 0, reportPath);
        Check([reply[@"status"] isEqual:@"rejected"] && launchCalls == 1,
            "workspace rejection preserved");

        Reset();
        failInventory = YES;
        reply = Run(@"launch", @"com.apple.mobilesafari", 0, reportPath);
        Check([reply[@"status"] isEqual:@"error"] &&
            [reply[@"detail"] isEqual:@"inventory-unavailable"] && launchCalls == 0,
            "missing inventory prevents launch");

        Reset();
        throwRefresh = YES;
        reply = Run(@"refresh", nil, 0, reportPath);
        Check([reply[@"status"] isEqual:@"error"] &&
            [reply[@"detail"] isEqual:@"service-exception"] && launchCalls == 0,
            "refresh exception contained");
        Reset();
        throwLaunch = YES;
        reply = Run(@"launch", @"com.apple.mobilesafari", 0, reportPath);
        Check([reply[@"status"] isEqual:@"error"] &&
            [reply[@"detail"] isEqual:@"service-exception"] && launchCalls == 1,
            "launch exception contained");

        Reset();
        NSData *request = PPOBridgeRequestData(NSUUID.UUID.UUIDString, @"launch",
            @"com.apple.mobilesafari", NSProcessInfo.processInfo.systemUptime, NULL);
        dispatch_group_t group = dispatch_group_create();
        __block NSData *backgroundResponse = nil;
        dispatch_group_async(group, dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
            @autoreleasepool { backgroundResponse = PPOBridgeServiceResponse(request, reportPath); }
        });
        Check(dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC)) == 0,
            "background guard returns promptly");
        Check(backgroundResponse == nil && refreshCalls == 0 && launchCalls == 0,
            "background service call refused before workspace calls");

        Check([NSFileManager.defaultManager removeItemAtPath:directory error:NULL], "remove fixture directory");
        printf("Bridge service policy tests passed\n");
    }
    return 0;
}
