#import <Foundation/Foundation.h>

// Own-new-scene adapter. Caller must gate exact framework UUIDs and select a
// unique Safari source. A source scene is read only and is never invalidated.
@interface PPOOwnedSceneHost : NSObject
@property(nonatomic,strong,readonly) id viewController;
@property(nonatomic,strong,readonly) id hostedScene;
@property(nonatomic,copy,readonly) NSString *state;
@property(nonatomic,readonly) BOOL poisoned;
@property(nonatomic,readonly) BOOL closed;
- (instancetype)initWithClasses:(NSDictionary<NSString *, id> *)classes;
- (BOOL)prepareScene:(id)source;
- (BOOL)close;
- (BOOL)pollCleanup;
- (void)quarantineCleanup;
- (NSDictionary *)sampleState;
- (NSDictionary *)snapshot;
@end
