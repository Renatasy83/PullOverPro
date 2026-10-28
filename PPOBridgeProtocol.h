#import <Foundation/Foundation.h>

NSString *PPOBridgeMailboxPath(void);

// The transport owns bounded, atomic I/O. This module validates message contents.
FOUNDATION_EXPORT NSString *const PPOBridgeDirectory;
FOUNDATION_EXPORT NSString *const PPOBridgeRequestFile;
FOUNDATION_EXPORT NSString *const PPOBridgeResponseFile;
FOUNDATION_EXPORT NSString *const PPOBridgeHeartbeatFile;
FOUNDATION_EXPORT const NSUInteger PPOBridgeMessageLimit;
FOUNDATION_EXPORT const NSTimeInterval PPOBridgeRequestLifetime;

BOOL PPOBridgeValidIdentifier(NSString *identifier);
NSData *PPOBridgeRequestData(NSString *nonce, NSString *operation,
    NSString *bundleIdentifier, NSTimeInterval createdUptime, NSError **error);
NSDictionary *PPOBridgeRequestFromData(NSData *data, NSTimeInterval now, NSError **error);
NSData *PPOBridgeResponseData(NSString *nonce, NSString *status, NSString *detail,
    NSNumber *appsCount, NSTimeInterval uptime, NSError **error);
NSDictionary *PPOBridgeResponseFromData(NSData *data, NSString *expectedNonce, NSError **error);
