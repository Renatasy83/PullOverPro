#import "PPOBridgeService.h"
#import "PPOWorkspace.h"
#import "../../PPOAppData.h"
#import "../../PPOBridgeProtocol.h"

NSData *PPOBridgeServiceResponse(NSData *requestData, NSString *reportPath) {
    NSDictionary *request = PPOBridgeRequestFromData(requestData,
        NSProcessInfo.processInfo.systemUptime, NULL);
    if (!request || !NSThread.isMainThread) return nil;
    NSString *status = @"error", *detail = @"internal-error";
    NSNumber *count = nil;
    @try {
        NSString *operation = request[@"operation"];
        if ([operation isEqual:@"ping"]) {
            status = @"ready"; detail = @"service-ready";
        } else {
            NSDictionary *report = PPOWorkspaceRefresh();
            NSData *json = report ? [NSJSONSerialization dataWithJSONObject:report options:0 error:NULL] : nil;
            NSArray *apps = PPOAppsFromData(json, NULL);
            if (!apps) { detail = @"inventory-unavailable"; }
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
