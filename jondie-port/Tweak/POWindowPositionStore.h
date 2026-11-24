// Added 2026-11-24 by Renatasy83: per-app floating-window positions; GPL-3.0.
#import <Foundation/Foundation.h>
#import "../Shared/POFloatingWindowGeometry.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const POWindowPositionsKey;

// The caller supplies POApplicationHelper.state in SpringBoard. Native tests
// supply their own uniquely named defaults suites, never the user's domain.
@interface POWindowPositionStore : NSObject
+ (POFloatingWindowPosition)positionForBundleIdentifier:(nullable NSString *)bundleIdentifier
                                              defaults:(nullable NSUserDefaults *)defaults;
+ (BOOL)savePosition:(POFloatingWindowPosition)position
 forBundleIdentifier:(nullable NSString *)bundleIdentifier
            defaults:(nullable NSUserDefaults *)defaults;
+ (BOOL)resetPositionForBundleIdentifier:(nullable NSString *)bundleIdentifier
                               defaults:(nullable NSUserDefaults *)defaults;
@end

NS_ASSUME_NONNULL_END
