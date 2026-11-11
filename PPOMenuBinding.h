#pragma once

#import <Foundation/Foundation.h>

// Main-thread binding for a destination whose setter may copy the source.
// Source identity is the caller's original model, never the destination's copy.
// The source is retained; owner and destination are weak. The setter is invoked
// synchronously and is never stored. A YES result means it was invoked and the
// binding was committed; unchanged, invalid and reentrant requests return NO.
@interface PPOMenuBinding : NSObject
- (BOOL)bindSource:(id)source owner:(id)owner destination:(id)destination
           setter:(void (^)(id destination, id source))setter;
@end
