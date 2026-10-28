#import "../PPOBridgeProtocol.h"
#include <cmath>
#include <stdio.h>
#include <stdlib.h>

static void Check(BOOL condition, const char *name) {
    if (!condition) { fprintf(stderr, "FAIL: %s\n", name); exit(1); }
}
static NSData *JSON(id value) {
    return [NSJSONSerialization dataWithJSONObject:value options:0 error:NULL];
}
int main(void) {
    @autoreleasepool {
        NSString *nonce = NSUUID.UUID.UUIDString;
        NSString *other = NSUUID.UUID.UUIDString;
        NSData *ping = PPOBridgeRequestData(nonce, @"ping", nil, 100, NULL);
        NSDictionary *request = PPOBridgeRequestFromData(ping, 100, NULL);
        Check([request[@"nonce"] isEqual:nonce], "ping round trip");
        Check(PPOBridgeRequestFromData(ping, 105, NULL) != nil, "TTL inclusive boundary");
        NSError *error = nil;
        Check(PPOBridgeRequestFromData(ping, 105.001, &error) == nil && error.code == 2, "expired request");
        Check(PPOBridgeRequestFromData(ping, 99.95, NULL) != nil, "small timestamp skew");
        Check(PPOBridgeRequestFromData(ping, 99.8, NULL) == nil, "future request");
        Check(PPOBridgeRequestFromData(ping, NAN, NULL) == nil, "NaN now");
        Check(PPOBridgeRequestData(nonce, @"ping", nil, NAN, NULL) == nil, "NaN created");
        Check(PPOBridgeRequestData(nonce, @"ping", nil, INFINITY, NULL) == nil, "infinite created");
        Check(PPOBridgeRequestData(nonce, @"ping", nil, -1, NULL) == nil, "negative created");
        Check(PPOBridgeRequestData(@"bad", @"ping", nil, 100, NULL) == nil, "bad nonce");
        Check(PPOBridgeRequestData(nonce, @"unknown", nil, 100, NULL) == nil, "unknown operation");
        Check(PPOBridgeRequestData(nonce, @"refresh", nil, 100, NULL) != nil, "refresh request");
        Check(PPOBridgeRequestData(nonce, @"launch", @"com.apple.mobilesafari", 100, NULL) != nil, "launch request");
        Check(PPOBridgeRequestData(nonce, @"launch", nil, 100, NULL) == nil, "launch requires id");
        Check(PPOBridgeRequestData(nonce, @"ping", @"com.apple.mobilesafari", 100, NULL) == nil, "ping forbids id");
        Check(!PPOBridgeValidIdentifier(@"") && !PPOBridgeValidIdentifier(@"app/id") &&
              !PPOBridgeValidIdentifier(@"app id") && !PPOBridgeValidIdentifier(@"app.é"), "identifier characters");
        NSString *maximum = [@"a" stringByPaddingToLength:255 withString:@"a" startingAtIndex:0];
        Check(PPOBridgeValidIdentifier(maximum) && !PPOBridgeValidIdentifier([maximum stringByAppendingString:@"a"]), "identifier length");

        NSMutableDictionary *raw = [request mutableCopy];
        raw[@"schema"] = @YES;
        Check(PPOBridgeRequestFromData(JSON(raw), 100, NULL) == nil, "boolean schema");
        raw[@"schema"] = @1;
        raw[@"createdUptime"] = @YES;
        Check(PPOBridgeRequestFromData(JSON(raw), 100, NULL) == nil, "boolean uptime");
        raw[@"createdUptime"] = @"100";
        Check(PPOBridgeRequestFromData(JSON(raw), 100, NULL) == nil, "string uptime");
        raw[@"createdUptime"] = @100;
        raw[@"extra"] = @1;
        Check(PPOBridgeRequestFromData(JSON(raw), 100, NULL) == nil, "unknown request key");
        Check(PPOBridgeRequestFromData(JSON(@[]), 100, NULL) == nil, "array root");
        Check(PPOBridgeRequestFromData([@"{" dataUsingEncoding:NSUTF8StringEncoding], 100, NULL) == nil, "malformed JSON");
        Check(PPOBridgeRequestFromData([NSMutableData dataWithLength:4097], 100, NULL) == nil, "oversized request");

        NSData *response = PPOBridgeResponseData(nonce, @"refreshed", @"apps-refreshed", @443, 102, NULL);
        Check([PPOBridgeResponseFromData(response, nonce, NULL)[@"appsCount"] isEqual:@443], "response round trip");
        Check(PPOBridgeResponseFromData(response, other, NULL) == nil, "response nonce binding");
        Check(PPOBridgeResponseData(nonce, @"accepted", nil, nil, 102, NULL) != nil, "minimal response");
        Check(PPOBridgeResponseData(nonce, @"unknown", nil, nil, 102, NULL) == nil, "unknown status");
        Check(PPOBridgeResponseData(nonce, @"ready", @"arbitrary detail!", nil, 102, NULL) == nil, "controlled detail");
        Check(PPOBridgeResponseData(nonce, @"ready", nil, @YES, 102, NULL) == nil, "boolean count");
        Check(PPOBridgeResponseData(nonce, @"ready", nil, @0.5, 102, NULL) == nil, "fractional count");
        Check(PPOBridgeResponseData(nonce, @"ready", nil, @4097, 102, NULL) == nil, "oversized count");
        Check(PPOBridgeResponseData(nonce, @"ready", nil, @-1, 102, NULL) == nil, "negative count");
        Check(PPOBridgeResponseData(nonce, @"ready", nil, nil, INFINITY, NULL) == nil, "infinite response uptime");
        NSMutableDictionary *reply = [[NSJSONSerialization JSONObjectWithData:response options:0 error:NULL] mutableCopy];
        reply[@"extra"] = @YES;
        Check(PPOBridgeResponseFromData(JSON(reply), nonce, NULL) == nil, "unknown response key");
        [reply removeObjectForKey:@"extra"];
        reply[@"schema"] = @YES;
        Check(PPOBridgeResponseFromData(JSON(reply), nonce, NULL) == nil, "boolean response schema");
        reply[@"schema"] = @1;
        reply[@"uptime"] = @YES;
        Check(PPOBridgeResponseFromData(JSON(reply), nonce, NULL) == nil, "boolean response uptime");
        Check(PPOBridgeResponseFromData([NSMutableData dataWithLength:4097], nonce, NULL) == nil, "oversized response");
        printf("Bridge protocol tests passed\n");
    }
    return 0;
}
