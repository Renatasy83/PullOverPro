#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>

@interface UIView : NSObject
@end
@interface UIColor : NSObject
+ (instancetype)clearColor;
@end
@interface FBProcess : NSObject
@property (copy, nonatomic) NSString *bundleIdentifier;
@end
@interface FBSSceneSettings : NSObject
@property (nonatomic, getter=isForeground) BOOL foreground;
@end
@interface UIMutableApplicationSceneSettings : FBSSceneSettings
@end
@interface UIMutableScenePresentationContext : NSObject
@property (nonatomic) unsigned long long appearanceStyle;
@property (copy, nonatomic) UIColor *backgroundColorWhileNotHosting;
@end
@interface _UIScenePresenter : NSObject
@property (strong, nonatomic) UIView *presentationView;
@property (nonatomic, getter=isInvalidated) BOOL invalidated;
@property (nonatomic) NSUInteger activations;
@property (nonatomic) NSUInteger deactivations;
@property (nonatomic) NSUInteger invalidations;
@property (nonatomic) BOOL throwOnActivate;
@property (nonatomic) BOOL throwOnDeactivate;
@property (nonatomic) BOOL throwOnInvalidate;
- (void)modifyPresentationContext:(void (^)(UIMutableScenePresentationContext *))block;
- (void)activate;
- (void)deactivate;
- (void)invalidate;
@end
@interface UIScenePresentationManager : NSObject
@property (strong, nonatomic) _UIScenePresenter *nextPresenter;
@property (nonatomic) NSUInteger creations;
- (_UIScenePresenter *)createPresenterWithIdentifier:(NSString *)identifier;
@end
@interface FBScene : NSObject
@property (copy, nonatomic) NSString *identifier;
@property (strong, nonatomic) FBProcess *clientProcess;
@property (strong, nonatomic) FBSSceneSettings *settings;
@property (strong, nonatomic) UIScenePresentationManager *uiPresentationManager;
@property (nonatomic) NSUInteger foregroundWrites;
@property (nonatomic) NSUInteger backgroundWrites;
- (void)updateSettingsWithBlock:(void (^)(UIMutableApplicationSceneSettings *))block;
@end
@interface FBSceneManager : NSObject
@property (copy, nonatomic) NSSet *scenes;
+ (instancetype)sharedInstance;
- (NSSet *)scenesPassingTest:(BOOL (^)(FBScene *))test;
@end
@interface FBSSystemService : NSObject
+ (instancetype)sharedService;
- (void)openApplication:(NSString *)bundleId options:(NSDictionary *)options withResult:(void (^)(NSError *))result;
@end
