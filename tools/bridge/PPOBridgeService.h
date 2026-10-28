#import <Foundation/Foundation.h>
// Called only on helper main thread, with an outer process-local watchdog.
NSData *PPOBridgeServiceResponse(NSData *requestData, NSString *reportPath);
