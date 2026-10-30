#import <Foundation/Foundation.h>

// Main-thread-only ownership of ONE newly created PPO presenter. Does not own
// or invalidate the FBScene, presentation manager or any existing presenter.
@interface PPOScenePresenter : NSObject
@property(nonatomic,strong,readonly) id presentationView;
@property(nonatomic,copy,readonly) NSString *state;
@property(nonatomic,readonly) BOOL poisoned;
- (instancetype)initWithManagerClass:(Class)managerClass presenterClass:(Class)presenterClass
                          viewClass:(Class)viewClass;
- (BOOL)prepareScene:(id)scene;
// Own presenter context only; exact23A355 synchronous mutable-copy callback.
// Failure closes the owned presenter. No foreign scene/default-manager writes.
- (BOOL)enableVisibilityPropagationWithContextClass:(Class)contextClass
                               mutableContextClass:(Class)mutableContextClass;
- (BOOL)activate;
- (BOOL)close;
// Bounded diagnostic read using only the same ABI-checked bool getters.
- (NSDictionary *)sampleState;
- (NSDictionary *)snapshot;
@end
