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
- (BOOL)activate;
- (BOOL)close;
- (NSDictionary *)snapshot;
@end
