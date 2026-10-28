#import <Foundation/Foundation.h>
// Called only on helper main thread, with an outer process-local watchdog.
NSData *PPOBridgeServiceResponse(NSData *requestData, NSString *reportPath);

// Explicit path dependency for isolated tests. Production callers use the wrapper
// above, which always checks /var/mobile/.ppo_disable; no environment override.
NSData *PPOBridgeServiceResponseWithDisablePath(NSData *requestData,
    NSString *reportPath, NSString *disablePath);
