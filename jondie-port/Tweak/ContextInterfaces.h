// Private FrontBoard / UIKit / SpringBoard interfaces used to host another
// app's live scene inside SpringBoard (iOS 15-16). Checked against the 15.8.6
// and 16.2 class dumps.

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#import "headers.h"

@interface FBProcess : NSObject
@property (readonly, copy, nonatomic) NSString *bundleIdentifier;
@end

@interface UIMutableApplicationSceneSettings : NSObject
@property (nonatomic, getter=isForeground) BOOL foreground;
@end

@interface UIMutableScenePresentationContext : NSObject
@property (nonatomic) unsigned long long appearanceStyle;
@property (copy, nonatomic) UIColor *backgroundColorWhileHosting;
@property (copy, nonatomic) UIColor *backgroundColorWhileNotHosting;
@end

@interface _UIScenePresenter : NSObject
@property (readonly, nonatomic) UIView *presentationView;
@property (readonly, nonatomic, getter=isActive) BOOL active;
@property (readonly, nonatomic, getter=isInvalidated) BOOL invalidated;
- (void)modifyPresentationContext:(void (^)(UIMutableScenePresentationContext *context))block;
- (void)activate;
- (void)deactivate;   // iOS 16
- (void)invalidate;
@end

@interface UIScenePresentationManager : NSObject
- (_UIScenePresenter *)createPresenterWithIdentifier:(NSString *)identifier;
@end

@interface FBSSceneSettings : NSObject
@property (readonly, nonatomic, getter=isForeground) BOOL foreground;
@end

@interface FBScene : NSObject
@property (readonly, copy, nonatomic) NSString *identifier;
@property (readonly, nonatomic) FBProcess *clientProcess;
@property (readonly, nonatomic) FBSSceneSettings *settings;
@property (readonly, nonatomic) UIScenePresentationManager *uiPresentationManager;
- (void)updateSettingsWithBlock:(void (^)(UIMutableApplicationSceneSettings *settings))block;
@end

@interface FBSceneManager : NSObject
+ (instancetype)sharedInstance;
- (FBScene *)sceneWithIdentifier:(NSString *)identifier;
- (NSSet *)scenesPassingTest:(BOOL (^)(FBScene *scene))test;
@end

@interface UIApplication (PullOverPrivate)
- (BOOL)launchApplicationWithIdentifier:(NSString *)identifier suspended:(BOOL)suspended;
- (id)_accessibilityFrontMostApplication;
@end

@interface FBSSystemService : NSObject
+ (instancetype)sharedService;
- (void)openApplication:(NSString *)bundleId options:(NSDictionary *)options withResult:(void (^)(NSError *error))result;
@end
