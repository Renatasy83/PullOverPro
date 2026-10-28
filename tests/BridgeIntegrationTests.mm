#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>
#import "../PPOBridgeClient.h"
#import "../PPOBridgeProtocol.h"
#import "../PPOBridgeIO.h"
#import "../PPOAppData.h"
#import "../tools/bridge/PPOWorkspace.h"
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#if !defined(PPO_BRIDGE_TESTING)
#error This harness must never be built without isolated test paths.
#endif

// Build service main.mm separately with -Dmain=PPOBridgeServerMain.
int PPOBridgeServerMain(int argc, char *argv[]);
static NSMutableArray<NSTask *> *tasks;
static NSUInteger checks;

static NSTimeInterval Now(void) { return NSProcessInfo.processInfo.systemUptime; }
static void Pause(void) { [NSThread sleepForTimeInterval:0.02]; }
static void Check(BOOL condition, const char *name) {
    checks++;
    if (condition) return;
    fprintf(stderr, "FAIL: %s\n", name);
    for (NSTask *task in tasks) if (task.running) [task terminate];
    exit(1);
}
static NSString *CounterPath(void) {
    return [PPOBridgeMailboxPath().stringByDeletingLastPathComponent
        stringByAppendingPathComponent:@"fixture-launch-count.txt"];
}
static NSInteger Counter(void) {
    return [[NSString stringWithContentsOfFile:CounterPath()
        encoding:NSUTF8StringEncoding error:NULL] integerValue];
}

// Workspace fixture is linked instead of PPOWorkspace.mm. No private APIs.
NSDictionary *PPOWorkspaceRefresh(void) {
    NSArray *apps = @[@{@"bundleIdentifier": @"com.apple.mobilesafari", @"name": @"Safari"}];
    return @{@"schema": @1, @"source": @"LSApplicationWorkspace.allInstalledApplications",
        @"count": @1, @"apps": apps};
}
BOOL PPOWorkspaceLaunch(NSString *identifier, NSString **failureCode) {
    if (![identifier isEqual:@"com.apple.mobilesafari"]) {
        if (failureCode) *failureCode = @"fixture-rejected";
        return NO;
    }
    NSString *count = [NSString stringWithFormat:@"%ld", (long)Counter() + 1];
    return [count writeToFile:CounterPath() atomically:YES encoding:NSUTF8StringEncoding error:NULL];
}

static NSTask *Start(void) {
    NSTask *task = [NSTask new];
    NSString *binary = NSProcessInfo.processInfo.arguments.firstObject;
    task.executableURL = [NSURL fileURLWithPath:binary];
    task.arguments = @[@"--serve"];
    NSMutableDictionary *environment = [NSProcessInfo.processInfo.environment mutableCopy];
    environment[@"PPO_BRIDGE_TEST_PATH"] = PPOBridgeMailboxPath();
    task.environment = environment;
    NSError *error = nil;
    Check([task launchAndReturnError:&error], "spawn fixture service");
    [tasks addObject:task];
    return task;
}
static void Stop(NSTask *task) {
    if (task.running) [task terminate];
    NSTimeInterval deadline = Now() + 3;
    while (task.running && Now() < deadline) Pause();
    Check(!task.running, "fixture service terminates within deadline");
}
static NSData *Read(int directory, const char *name) {
    char buffer[PPOBridgeMaximumBytes]; size_t length = 0;
    int code = PPOBridgeRead(directory, name, buffer, sizeof(buffer), &length);
    return code == 0 ? [NSData dataWithBytes:buffer length:length] : nil;
}
static void Write(int directory, const char *name, NSData *data) {
    Check(data != nil && PPOBridgeWrite(directory, name, data.bytes, data.length) == 0,
        "write bounded fixture message");
}
static void Ready(int directory, NSTask *task) {
    NSTimeInterval deadline = Now() + 3;
    NSData *ready = nil;
    while (task.running && Now() < deadline && !(ready = Read(directory, "heartbeat.json"))) Pause();
    NSDictionary *value = ready ? [NSJSONSerialization JSONObjectWithData:ready options:0 error:NULL] : nil;
    Check(task.running && [value[@"status"] isEqual:@"ready"], "actual service publishes readiness");
}
static NSDictionary *Send(NSString *operation, NSString *identifier) {
    dispatch_group_t group = dispatch_group_create();
    __block NSDictionary *response = nil;
    dispatch_group_async(group, dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        @autoreleasepool { response = PPOBridgeSend(operation, identifier, NULL); }
    });
    Check(dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC)) == 0,
        "worker client completes within deadline");
    Check(response != nil, "actual client receives nonce-bound response");
    return response;
}
static NSDictionary *WaitResponse(int directory, NSString *nonce) {
    NSTimeInterval deadline = Now() + 3;
    NSDictionary *response = nil;
    while (Now() < deadline) {
        response = PPOBridgeResponseFromData(Read(directory, "response.json"), nonce, NULL);
        if (response) break;
        Pause();
    }
    Check(response != nil, "raw request receives matching response");
    return response;
}

int main(int argc, char *argv[]) {
    if (argc == 2 && strcmp(argv[1], "--serve") == 0) return PPOBridgeServerMain(argc, argv);
    @autoreleasepool {
        tasks = [NSMutableArray array];
        NSString *root = [NSTemporaryDirectory() stringByAppendingPathComponent:
            [@"ppo-integration-" stringByAppendingString:NSUUID.UUID.UUIDString]];
        Check([NSFileManager.defaultManager createDirectoryAtPath:root
            withIntermediateDirectories:NO attributes:nil error:NULL], "isolated fixture root");
        NSString *mailbox = [root stringByAppendingPathComponent:@"Bridge"];
        Check(setenv("PPO_BRIDGE_TEST_PATH", mailbox.fileSystemRepresentation, 1) == 0,
            "select isolated mailbox");
        int directory = PPOBridgeOpenDirectory(mailbox.fileSystemRepresentation);
        Check(directory >= 0, "open fixture mailbox");
        NSTask *service = Start();
        Ready(directory, service);

        NSData *before = Read(directory, "request.json");
        NSError *guardError = nil;
        Check(PPOBridgeSend(@"launch", @"com.apple.mobilesafari", &guardError) == nil &&
            guardError.code == EDEADLK, "main-thread client guard");
        NSData *after = Read(directory, "request.json");
        Check((!before && !after) || [before isEqual:after], "main guard writes no request");

        Check([Send(@"ping", nil)[@"status"] isEqual:@"ready"], "real mailbox ping");
        Check([Send(@"refresh", nil)[@"status"] isEqual:@"refreshed"], "real mailbox refresh");
        NSArray *apps = PPOAppsFromData([NSData dataWithContentsOfFile:
            [root stringByAppendingPathComponent:@"apps-0.5.7.json"]], NULL);
        Check(apps.count == 1, "service inventory persisted outside SpringBoard");
        NSString *disablePath = [root stringByAppendingPathComponent:@".ppo_disable"];
        Check([[NSData data] writeToFile:disablePath options:0 error:NULL],
            "create own subprocess disable marker");
        NSDictionary *disabled = Send(@"launch", @"com.apple.mobilesafari");
        Check([disabled[@"status"] isEqual:@"rejected"] &&
            [disabled[@"detail"] isEqual:@"feature-disabled"] && Counter() == 0,
            "actual service rejects launch while disabled");
        Check(unlink(disablePath.fileSystemRepresentation) == 0,
            "remove only subprocess fixture marker");
        Check([Send(@"launch", @"com.apple.mobilesafari")[@"status"] isEqual:@"accepted"] &&
            Counter() == 1, "real mailbox launch invokes fixture once");

        NSTask *duplicate = Start();
        NSTimeInterval deadline = Now() + 3;
        while (duplicate.running && Now() < deadline) Pause();
        Check(!duplicate.running && duplicate.terminationStatus == 4,
            "second service refuses directory flock takeover");

        NSString *nonceA = NSUUID.UUID.UUIDString;
        NSData *requestA = PPOBridgeRequestData(nonceA, @"launch", @"com.apple.mobilesafari", Now(), NULL);
        Write(directory, "request.json", requestA);
        Check([WaitResponse(directory, nonceA)[@"status"] isEqual:@"accepted"] && Counter() == 2,
            "first nonce A executes exactly once");
        NSString *nonceB = NSUUID.UUID.UUIDString;
        Write(directory, "request.json", PPOBridgeRequestData(nonceB, @"ping", nil, Now(), NULL));
        Check([WaitResponse(directory, nonceB)[@"status"] isEqual:@"ready"], "intervening nonce B");
        Write(directory, "request.json", requestA);
        Check([WaitResponse(directory, nonceA)[@"status"] isEqual:@"rejected"] && Counter() == 2,
            "A-B-A replay does not execute second launch");

        NSString *staleNonce = NSUUID.UUID.UUIDString;
        Write(directory, "request.json", PPOBridgeRequestData(staleNonce,
            @"launch", @"com.apple.mobilesafari", Now() - 6, NULL));
        Check([WaitResponse(directory, staleNonce)[@"status"] isEqual:@"stale"] && Counter() == 2,
            "expired request never executes launch");

        Stop(service);
        // Only fixture-owned heartbeat is removed. A pending launch must survive and be ignored.
        Check(unlinkat(directory, "heartbeat.json", 0) == 0, "clear fixture readiness before restart");
        NSData *pending = PPOBridgeRequestData(NSUUID.UUID.UUIDString, @"launch",
            @"com.apple.mobilesafari", Now(), NULL);
        Write(directory, "request.json", pending);
        service = Start();
        Ready(directory, service);
        Check([Send(@"ping", nil)[@"status"] isEqual:@"ready"] && Counter() == 2,
            "restart never replays preexisting pending launch");
        Stop(service);

        // A wrong-nonce response must not satisfy the actual client. No daemon is running.
        Write(directory, "response.json", PPOBridgeResponseData(NSUUID.UUID.UUIDString,
            @"accepted", nil, nil, Now(), NULL));
        dispatch_group_t group = dispatch_group_create();
        __block NSDictionary *wrongResponse = nil;
        __block NSError *timeoutError = nil;
        NSData *priorRequest = Read(directory, "request.json");
        NSTimeInterval started = Now();
        dispatch_group_async(group, dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
            @autoreleasepool { wrongResponse = PPOBridgeSend(@"launch", @"com.apple.mobilesafari", &timeoutError); }
        });
        NSData *newRequest = nil;
        deadline = Now() + 2;
        while (Now() < deadline) {
            newRequest = Read(directory, "request.json");
            if (newRequest && ![newRequest isEqual:priorRequest]) break;
            Pause();
        }
        Check(newRequest != nil && ![newRequest isEqual:priorRequest], "client wrote one new request");
        Check(dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC)) == 0,
            "wrong nonce client timeout bounded");
        Check(wrongResponse == nil && timeoutError.code == ETIMEDOUT && Now() - started >= 7.9,
            "wrong nonce ignored until unknown-result timeout");
        Check([Read(directory, "request.json") isEqual:newRequest] && Counter() == 2,
            "timeout never rewrites or retries launch request");

        Check(close(directory) == 0, "close fixture directory");
        Check([NSFileManager.defaultManager removeItemAtPath:root error:NULL], "remove only fixture root");
        printf("Bridge subprocess integration: %lu checks passed; real kqueue/mailbox, flock, replay, restart and bounded client timeout.\n",
            (unsigned long)checks);
    }
    return 0;
}
