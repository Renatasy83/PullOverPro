#import "../tools/bridge/PPOBridgeService.h"
#import "../tools/bridge/PPOWorkspace.h"
#import "../PPOBridgeProtocol.h"
#import "../PPOAppData.h"
#import <dispatch/dispatch.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/stat.h>

static NSUInteger refreshCalls, launchCalls;
static BOOL failInventory, throwRefresh, throwLaunch, acceptLaunch, disableDuringRefresh;
static NSString *disablePath;
static NSTimeInterval refreshDelay;
static NSString *launchedIdentifier;

NSDictionary *PPOWorkspaceRefresh(void) {
    refreshCalls++;
    if (disableDuringRefresh && ![[NSData data] writeToFile:disablePath options:0 error:NULL])
        [NSException raise:@"FixtureMarkerWrite" format:@"Cannot create own marker"];
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
    acceptLaunch = YES; refreshDelay = 0; launchedIdentifier = nil; disableDuringRefresh = NO;
}

static NSDictionary *Run(NSString *operation, NSString *identifier, NSTimeInterval age,
                          NSString *reportPath) {
    NSString *nonce = NSUUID.UUID.UUIDString;
    NSData *request = PPOBridgeRequestData(nonce, operation, identifier,
        NSProcessInfo.processInfo.systemUptime - age, NULL);
    Check(request != nil, "fixture request encoded");
    NSData *data = PPOBridgeServiceResponseWithDisablePath(request, reportPath, disablePath);
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
        disablePath = [directory stringByAppendingPathComponent:@".ppo_disable"];
        Reset();
        NSDictionary *reply = Run(@"ping", nil, 0, reportPath);
        Check([reply[@"status"] isEqual:@"ready"] && refreshCalls == 0 && launchCalls == 0,
            "ping performs no workspace call");

        Check([[NSData data] writeToFile:disablePath options:0 error:NULL], "create own disable marker");
        for (NSString *operation in @[@"ping", @"refresh", @"launch"]) {
            Reset();
            reply = Run(operation, [operation isEqual:@"launch"] ? @"com.apple.mobilesafari" : nil, 0, reportPath);
            Check([reply[@"status"] isEqual:@"rejected"] &&
                [reply[@"detail"] isEqual:@"feature-disabled"] && refreshCalls == 0 && launchCalls == 0,
                "disable marker rejects operation before any workspace call");
        }
        Check(![NSFileManager.defaultManager fileExistsAtPath:reportPath], "disabled refresh does not create inventory");
        Check(unlink(disablePath.fileSystemRepresentation) == 0, "remove only own disable marker");
        Check(symlink("missing-fixture-target", disablePath.fileSystemRepresentation) == 0,
            "create own dangling marker symlink");
        Reset();
        reply = Run(@"launch", @"com.apple.mobilesafari", 0, reportPath);
        Check([reply[@"detail"] isEqual:@"feature-disabled"] && refreshCalls == 0 && launchCalls == 0,
            "dangling marker symlink still disables service");
        Check(unlink(disablePath.fileSystemRepresentation) == 0, "remove only own marker symlink");
        Reset();

        NSString *nonce = NSUUID.UUID.UUIDString;
        NSData *expired = PPOBridgeRequestData(nonce, @"launch", @"com.apple.mobilesafari",
            NSProcessInfo.processInfo.systemUptime - 6, NULL);
        Check(PPOBridgeServiceResponseWithDisablePath(expired, reportPath, disablePath) == nil &&
            refreshCalls == 0 && launchCalls == 0, "expired request performs no workspace call");
        Check(PPOBridgeServiceResponseWithDisablePath([@"bad JSON" dataUsingEncoding:NSUTF8StringEncoding], reportPath, disablePath) == nil &&
            refreshCalls == 0 && launchCalls == 0, "malformed request performs no workspace call");

        Reset();
        reply = Run(@"refresh", nil, 0, reportPath);
        NSArray *saved = PPOAppsFromData([NSData dataWithContentsOfFile:reportPath], NULL);
        Check([reply[@"status"] isEqual:@"refreshed"] &&
            [reply[@"appsCount"] isEqual:@3] && saved.count == 3 && refreshCalls == 1 && launchCalls == 0,
            "refresh saves validated inventory");

        // reportPath is a regular file, so this control path fails with ENOTDIR.
        // Like EACCES, it must fail closed rather than being mistaken for ENOENT.
        Reset();
        NSString *controlNonce = NSUUID.UUID.UUIDString;
        NSData *controlRequest = PPOBridgeRequestData(controlNonce, @"launch", @"com.apple.mobilesafari",
            NSProcessInfo.processInfo.systemUptime, NULL);
        NSData *controlReply = PPOBridgeServiceResponseWithDisablePath(controlRequest, reportPath,
            [reportPath stringByAppendingPathComponent:@"marker"]);
        reply = PPOBridgeResponseFromData(controlReply, controlNonce, NULL);
        Check([reply[@"status"] isEqual:@"error"] && [reply[@"detail"] isEqual:@"disable-check-failed"] &&
            refreshCalls == 0 && launchCalls == 0, "control path errors fail closed before workspace calls");
        if (geteuid() != 0) {
            NSString *deniedDirectory = [directory stringByAppendingPathComponent:@"denied-control"];
            Check(mkdir(deniedDirectory.fileSystemRepresentation, 0700) == 0,
                "create own permission-denied control directory");
            Check(chmod(deniedDirectory.fileSystemRepresentation, 0000) == 0,
                "temporarily remove search permission on own fixture");
            controlReply = PPOBridgeServiceResponseWithDisablePath(controlRequest, reportPath,
                [deniedDirectory stringByAppendingPathComponent:@"marker"]);
            Check(chmod(deniedDirectory.fileSystemRepresentation, 0700) == 0,
                "restore permissions on own fixture");
            reply = PPOBridgeResponseFromData(controlReply, controlNonce, NULL);
            Check([reply[@"status"] isEqual:@"error"] && [reply[@"detail"] isEqual:@"disable-check-failed"] &&
                refreshCalls == 0 && launchCalls == 0, "EACCES on control path fails closed");
        }
        controlReply = PPOBridgeServiceResponseWithDisablePath(controlRequest, reportPath, nil);
        reply = PPOBridgeResponseFromData(controlReply, controlNonce, NULL);
        Check([reply[@"detail"] isEqual:@"disable-check-failed"] && refreshCalls == 0 && launchCalls == 0,
            "missing control path configuration fails closed");

        Reset();
        disableDuringRefresh = YES;
        reply = Run(@"launch", @"com.apple.mobilesafari", 0, reportPath);
        Check([reply[@"status"] isEqual:@"rejected"] && [reply[@"detail"] isEqual:@"feature-disabled"] &&
            refreshCalls == 1 && launchCalls == 0, "marker created during refresh blocks launch");
        Check(unlink(disablePath.fileSystemRepresentation) == 0, "remove own mid-refresh marker");
        Reset();
        disableDuringRefresh = YES;
        NSString *blockedReportPath = [directory stringByAppendingPathComponent:@"disabled-refresh.json"];
        reply = Run(@"refresh", nil, 0, blockedReportPath);
        Check([reply[@"detail"] isEqual:@"feature-disabled"] && refreshCalls == 1 && launchCalls == 0 &&
            ![NSFileManager.defaultManager fileExistsAtPath:blockedReportPath],
            "marker created during refresh prevents inventory persistence");
        Check(unlink(disablePath.fileSystemRepresentation) == 0, "remove own blocked-refresh marker");

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
            @autoreleasepool { backgroundResponse = PPOBridgeServiceResponseWithDisablePath(request, reportPath, disablePath); }
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
