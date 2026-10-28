#import <Foundation/Foundation.h>

// Single serial caller, worker queue only. No private API, process creation or main-thread waiting.
NSDictionary *PPOBridgeSend(NSString *operation, NSString *identifier, NSError **error);
