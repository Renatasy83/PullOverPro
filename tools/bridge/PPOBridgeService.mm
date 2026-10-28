#import "PPOBridgeService.h"
#import "PPOWorkspace.h"
#import "../../PPOAppData.h"
#import "../../PPOBridgeProtocol.h"
#include <sys/stat.h>
#include <errno.h>

static NSString *PPOServiceControlFailure(NSString *disablePath) {
    if (![disablePath isKindOfClass:NSString.class] || !disablePath.isAbsolutePath)
        return @"disable-check-failed";
    struct stat marker = {};
    // Existence disables the service, even if the marker is a dangling symlink.
    // A missing marker permits requests; an unreadable control path never does.
    if (lstat(disablePath.fileSystemRepresentation, &marker) == 0) return @"feature-disabled";
    return errno == ENOENT ? nil : @"disable-check-failed";
}

NSData *PPOBridgeServiceResponse(NSData *requestData, NSString *reportPath) {
    return PPOBridgeServiceResponseWithDisablePath(requestData, reportPath,
        @"/var/mobile/.ppo_disable");
}

NSData *PPOBridgeServiceResponseWithDisablePath(NSData *requestData,
    NSString *reportPath, NSString *disablePath) {
    NSDictionary *request = PPOBridgeRequestFromData(requestData,
        NSProcessInfo.processInfo.systemUptime, NULL);
    if (!request || !NSThread.isMainThread) return nil;
    NSString *status = @"error", *detail = @"internal-error";
    NSNumber *count = nil;
    @try {
        NSString *operation = request[@"operation"];
        NSString *controlFailure = PPOServiceControlFailure(disablePath);
        if (controlFailure) {
            status = [controlFailure isEqual:@"feature-disabled"] ? @"rejected" : @"error";
            detail = controlFailure;
        } else if ([operation isEqual:@"ping"]) {
            status = @"ready"; detail = @"service-ready";
        } else {
            NSDictionary *report = PPOWorkspaceRefresh();
            NSData *json = report ? [NSJSONSerialization dataWithJSONObject:report options:0 error:NULL] : nil;
            NSArray *apps = PPOAppsFromData(json, NULL);
            // Refresh can involve IPC. Honor a marker created while it was running
            // before persisting data or making the subsequent private launch call.
            controlFailure = PPOServiceControlFailure(disablePath);
            if (controlFailure) {
                status = [controlFailure isEqual:@"feature-disabled"] ? @"rejected" : @"error";
                detail = controlFailure;
            } else if (!apps) { detail = @"inventory-unavailable"; }
            else if ([operation isEqual:@"refresh"]) {
                if ([json writeToFile:reportPath options:NSDataWritingAtomic error:NULL]) {
                    status = @"refreshed"; detail = @"inventory-saved"; count = @(apps.count);
                } else { detail = @"inventory-write-failed"; }
            } else {
                NSString *identifier = request[@"bundleIdentifier"];
                BOOL found = NO;
                for (NSDictionary *app in apps) {
                    if ([app[@"bundleIdentifier"] isEqual:identifier]) { found = YES; break; }
                }
                if (!found || [identifier isEqual:@"com.apple.springboard"] ||
                    [identifier isEqual:@"com.apple.backboardd"]) {
                    status = @"rejected"; detail = @"application-not-permitted";
                } else if (!PPOBridgeRequestFromData(requestData,
                    NSProcessInfo.processInfo.systemUptime, NULL)) {
                    status = @"stale"; detail = @"request-expired";
                } else if ((controlFailure = PPOServiceControlFailure(disablePath))) {
                    // Final check immediately before the private opener call.
                    status = [controlFailure isEqual:@"feature-disabled"] ? @"rejected" : @"error";
                    detail = controlFailure;
                } else {
                    NSString *failure = nil;
                    BOOL accepted = PPOWorkspaceLaunch(identifier, &failure);
                    status = accepted ? @"accepted" : @"rejected";
                    detail = accepted ? @"launch-request-accepted" : (failure ?: @"launch-rejected");
                }
            }
        }
    } @catch (NSException *exception) {
        (void)exception; status = @"error"; detail = @"service-exception";
    }
    return PPOBridgeResponseData(request[@"nonce"], status, detail, count,
        NSProcessInfo.processInfo.systemUptime, NULL);
}
