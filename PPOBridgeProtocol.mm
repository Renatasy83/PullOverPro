#import "PPOBridgeProtocol.h"
#import "PPOSceneCapability.h"
#import <CoreFoundation/CoreFoundation.h>
#include <cmath>

NSString *PPOBridgeMailboxPath(void) {
#if defined(PPO_BRIDGE_TESTING)
    const char *path = getenv("PPO_BRIDGE_TEST_PATH");
    if (path) return [NSString stringWithUTF8String:path];
#endif
    return @"/var/mobile/Library/Logs/PullOverPro/Bridge";
}

NSString *const PPOBridgeDirectory = @"/var/mobile/Library/Logs/PullOverPro/Bridge";
NSString *const PPOBridgeRequestFile = @"request.json";
NSString *const PPOBridgeResponseFile = @"response.json";
NSString *const PPOBridgeHeartbeatFile = @"heartbeat.json";
const NSUInteger PPOBridgeMessageLimit = 4096;
const NSTimeInterval PPOBridgeRequestLifetime = 5.0;

static id PPOBridgeError(NSError **error, NSInteger code) {
    if (error) *error = [NSError errorWithDomain:@"PullOverPro.BridgeProtocol" code:code
        userInfo:@{NSLocalizedDescriptionKey: code == 2 ? @"Cerere PPO expirată" : @"Mesaj PPO nevalid"}];
    return nil;
}

static BOOL PPOBridgeCode(id value, NSUInteger maximum) {
    if (![value isKindOfClass:NSString.class]) return NO;
    NSString *text = value;
    if (text.length == 0 || text.length > maximum) return NO;
    for (NSUInteger i = 0; i < text.length; i++) {
        unichar c = [text characterAtIndex:i];
        if (!((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
              (c >= '0' && c <= '9') || c == '.' || c == '_' || c == '-')) return NO;
    }
    return YES;
}

BOOL PPOBridgeValidIdentifier(NSString *identifier) {
    return PPOBridgeCode(identifier, 255);
}

static BOOL PPOBridgeNonce(id value) {
    if (![value isKindOfClass:NSString.class] || [(NSString *)value length] != 36) return NO;
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:value];
    return uuid && [uuid.UUIDString caseInsensitiveCompare:value] == NSOrderedSame;
}

static BOOL PPOBridgeNumber(id value) {
    return [value isKindOfClass:NSNumber.class] &&
        CFGetTypeID((__bridge CFTypeRef)value) != CFBooleanGetTypeID() &&
        std::isfinite([(NSNumber *)value doubleValue]);
}

static BOOL PPOBridgeCount(id value) {
    if (!PPOBridgeNumber(value)) return NO;
    double count = [(NSNumber *)value doubleValue];
    return count >= 0 && count <= 4096 && std::floor(count) == count;
}

static BOOL PPOBridgeKeys(NSDictionary *value, NSArray<NSString *> *required,
                          NSArray<NSString *> *optional) {
    for (NSString *key in required) if (!value[key]) return NO;
    for (id key in value) {
        if (![required containsObject:key] && ![optional containsObject:key]) return NO;
    }
    return YES;
}

static BOOL PPOBridgeSchema(NSDictionary *value) {
    return PPOBridgeNumber(value[@"schema"]) && [value[@"schema"] doubleValue] == 1;
}

static BOOL PPOBridgeRequestShape(NSDictionary *value) {
    if (!PPOBridgeKeys(value, @[@"schema", @"nonce", @"operation", @"createdUptime"],
                        @[@"bundleIdentifier"]) ||
        !PPOBridgeSchema(value) || !PPOBridgeNonce(value[@"nonce"]) ||
        !PPOBridgeNumber(value[@"createdUptime"]) ||
        [value[@"createdUptime"] doubleValue] < 0) return NO;
    NSString *operation = value[@"operation"];
    if ([@"launch" isEqual:operation]) return PPOBridgeValidIdentifier(value[@"bundleIdentifier"]);
    if ([@"inspect-scene" isEqual:operation])
        return PPOSceneApplicationIdentifierAllowed(value[@"bundleIdentifier"]);
    return ([@"ping" isEqual:operation] || [@"refresh" isEqual:operation]) &&
        value[@"bundleIdentifier"] == nil;
}

static BOOL PPOBridgeResponseShape(NSDictionary *value) {
    if (!PPOBridgeKeys(value, @[@"schema", @"nonce", @"status", @"uptime"],
                        @[@"detail", @"appsCount", @"sceneCapability"]) ||
        !PPOBridgeSchema(value) || !PPOBridgeNonce(value[@"nonce"]) ||
        !PPOBridgeNumber(value[@"uptime"]) || [value[@"uptime"] doubleValue] < 0) return NO;
    NSArray *statuses = @[@"ready", @"refreshed", @"accepted", @"rejected", @"unsupported",
                           @"error", @"busy", @"stale", @"inspected"];
    BOOL valid = [statuses containsObject:value[@"status"]] &&
        (!value[@"detail"] || PPOBridgeCode(value[@"detail"], 128)) &&
        (!value[@"appsCount"] || PPOBridgeCount(value[@"appsCount"]));
    if (!valid) return NO;
    if ([value[@"status"] isEqual:@"inspected"])
        return value[@"appsCount"] == nil && PPOSceneCapabilityNormalize(value[@"sceneCapability"]) != nil;
    return value[@"sceneCapability"] == nil;
}

static NSDictionary *PPOBridgeJSON(NSData *data, NSError **error) {
    if (![data isKindOfClass:NSData.class] || data.length == 0 || data.length > PPOBridgeMessageLimit)
        return PPOBridgeError(error, 1);
    id value = [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
    if (![value isKindOfClass:NSDictionary.class]) return PPOBridgeError(error, 1);
    return value;
}

static NSData *PPOBridgeEncode(NSDictionary *value, NSError **error) {
    NSData *data = [NSJSONSerialization dataWithJSONObject:value options:0 error:error];
    if (!data || data.length > PPOBridgeMessageLimit) return PPOBridgeError(error, 1);
    return data;
}

NSData *PPOBridgeRequestData(NSString *nonce, NSString *operation,
    NSString *bundleIdentifier, NSTimeInterval createdUptime, NSError **error) {
    if (!nonce || !operation || !std::isfinite(createdUptime)) return PPOBridgeError(error, 1);
    NSMutableDictionary *value = [@{@"schema": @1, @"nonce": nonce, @"operation": operation,
        @"createdUptime": @(createdUptime)} mutableCopy];
    if (bundleIdentifier) value[@"bundleIdentifier"] = bundleIdentifier;
    if (!PPOBridgeRequestShape(value)) return PPOBridgeError(error, 1);
    return PPOBridgeEncode(value, error);
}

NSDictionary *PPOBridgeRequestFromData(NSData *data, NSTimeInterval now, NSError **error) {
    NSDictionary *value = PPOBridgeJSON(data, error);
    if (!value || !std::isfinite(now) || now < 0 || !PPOBridgeRequestShape(value))
        return PPOBridgeError(error, 1);
    NSTimeInterval age = now - [value[@"createdUptime"] doubleValue];
    // Same-host monotonic time: tolerate only 100 ms of rounding/scheduling skew.
    if (age < -0.1 || age > PPOBridgeRequestLifetime) return PPOBridgeError(error, 2);
    return value;
}

NSData *PPOBridgeResponseData(NSString *nonce, NSString *status, NSString *detail,
    NSNumber *appsCount, NSTimeInterval uptime, NSError **error) {
    if (!nonce || !status || !std::isfinite(uptime)) return PPOBridgeError(error, 1);
    NSMutableDictionary *value = [@{@"schema": @1, @"nonce": nonce, @"status": status,
        @"uptime": @(uptime)} mutableCopy];
    if (detail) value[@"detail"] = detail;
    if (appsCount) value[@"appsCount"] = appsCount;
    if (!PPOBridgeResponseShape(value)) return PPOBridgeError(error, 1);
    return PPOBridgeEncode(value, error);
}

NSData *PPOBridgeCapabilityResponseData(NSString *nonce, NSDictionary *capability,
    NSTimeInterval uptime, NSError **error) {
    NSDictionary *normalized = PPOSceneCapabilityNormalize(capability);
    if (!nonce || !normalized || !std::isfinite(uptime)) return PPOBridgeError(error, 1);
    NSDictionary *value = @{@"schema": @1, @"nonce": nonce, @"status": @"inspected",
        @"detail": normalized[@"reason"], @"uptime": @(uptime), @"sceneCapability": normalized};
    if (!PPOBridgeResponseShape(value)) return PPOBridgeError(error, 1);
    return PPOBridgeEncode(value, error);
}

NSDictionary *PPOBridgeResponseFromData(NSData *data, NSString *expectedNonce, NSError **error) {
    NSDictionary *value = PPOBridgeJSON(data, error);
    if (!value || !PPOBridgeNonce(expectedNonce) || !PPOBridgeResponseShape(value) ||
        ![value[@"nonce"] isEqual:expectedNonce]) return PPOBridgeError(error, 1);
    if ([value[@"status"] isEqual:@"inspected"]) {
        NSMutableDictionary *copy = [value mutableCopy];
        copy[@"sceneCapability"] = PPOSceneCapabilityNormalize(value[@"sceneCapability"]);
        return [copy copy];
    }
    return [value copy];
}
