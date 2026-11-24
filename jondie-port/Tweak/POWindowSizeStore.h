// Added 2026-11-24 by Renatasy83: per-app window size state; GPL-3.0.
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const POWindowSizeFractionsKey;

// Foundation-only state storage. The caller supplies POApplicationHelper.state
// in SpringBoard; tests use their own uniquely named defaults suites.
@interface POWindowSizeStore : NSObject
+ (double)fractionForBundleIdentifier:(nullable NSString *)bundleIdentifier
                            defaults:(nullable NSUserDefaults *)defaults;
+ (BOOL)saveFraction:(double)fraction
 forBundleIdentifier:(nullable NSString *)bundleIdentifier
            defaults:(nullable NSUserDefaults *)defaults;
+ (BOOL)resetFractionForBundleIdentifier:(nullable NSString *)bundleIdentifier
                               defaults:(nullable NSUserDefaults *)defaults;
@end

NS_ASSUME_NONNULL_END
