#import <Foundation/Foundation.h>

@protocol PPOHostedSession <NSObject>
@property(nonatomic,readonly,getter=isFinished) BOOL finished;
@property(nonatomic,readonly) BOOL replacementAllowed;
@end

// Main-thread-only single-session ownership. Never closes/retries an active or
// uncertain session. Replacement is explicit and requires confirmed cleanup.
@interface PPOHostSessionSlot : NSObject
@property(nonatomic,strong,readonly) id<PPOHostedSession> session;
@property(nonatomic,readonly) BOOL poisoned;
- (BOOL)adopt:(id<PPOHostedSession>)candidate error:(NSError **)error;
@end

// Controlled first expansion beyond the device-confirmed Safari path.
BOOL PPOHostApplicationAllowed(NSString *identifier);
