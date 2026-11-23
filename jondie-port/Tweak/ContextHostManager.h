// Modified 2026-11-23 by Renatasy83: stability corrections; original credits and GPL-3.0 retained.
#import <Foundation/Foundation.h>

// Native tests replace only the interface declarations; they execute the same
// implementation and transaction paths without linking UIKit or FrontBoard.
#ifdef PO_HOSTING_TEST_INTERFACES
#import PO_HOSTING_TEST_INTERFACES
#else
#import <UIKit/UIKit.h>
#import "ContextInterfaces.h"
#endif

// Shows another app's live scene inside SpringBoard.
// Uses the existing upstream FBScene -> uiPresentationManager -> presenter path.
@interface ContextHostManager : NSObject
+ (instancetype)sharedInstance;

// Request one background launch if the app has no scene yet. Completion is
// always asynchronous on the main queue. A successful launch request does not
// guarantee that the scene is ready; callers must bound their scene retries.
- (void)launchInBackground:(NSString *)bundleId;
- (void)launchInBackground:(NSString *)bundleId completion:(void (^)(NSError *error))completion;
// Bring the app to the front full screen.
- (void)openFullScreen:(NSString *)bundleId;
// Main-thread methods. Returns nil until the scene exists or if setup fails.
// Failed setup restores the scene state changed by this manager.
- (UIView *)hostViewForBundleID:(NSString *)bundleId;
- (void)stopHostingForBundleID:(NSString *)bundleId;
- (BOOL)isHostViewHosting:(UIView *)hostView;
@end
