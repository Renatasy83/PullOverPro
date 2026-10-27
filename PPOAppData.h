#import <Foundation/Foundation.h>

NSArray<NSDictionary *> *PPOAppsFromData(NSData *data, NSError **error);
NSDictionary *PPOSelectionFromData(NSData *data);
NSData *PPOSelectionData(NSDictionary *selection, NSError **error);
NSData *PPOReadBoundedFile(NSString *path, NSUInteger limit, NSError **error);
