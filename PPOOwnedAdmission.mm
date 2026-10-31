#import "PPOOwnedAdmission.h"
#import "PPOOwnedApplicationPolicy.h"
#import "PPOSceneCapability.h"
#include <cmath>

NSDictionary *PPOOwnedAdmissionSnapshot(NSString *identifier,
    NSDictionary *capability, NSTimeInterval now) {
    @try {
        if (!std::isfinite(now) || now < 0 || !PPOSceneApplicationIdentifierAllowed(identifier)) return nil;
        NSString *selected = [identifier copy];
        if (!PPOSceneApplicationIdentifierAllowed(selected)) return nil;
        BOOL baseline = PPOOwnedApplicationAllowed(selected);
        if (!capability) {
            return baseline ? @{@"bundleIdentifier": selected, @"basis": @"firmware-baseline",
                @"sceneCapability": NSNull.null} : nil;
        }
        // Normalization rebuilds every nested string/scalar, rather than
        // retaining a caller's mutable values via NSDictionary.copy alone.
        NSDictionary *observed = PPOSceneCapabilityNormalize(capability);
        if (!observed || ![observed[@"bundleIdentifier"] isEqual:selected] ||
            !PPOSceneCapabilityFresh(observed, now)) return nil;
        NSString *status = observed[@"status"];
        if ([status isEqual:@"ineligible"]) return nil;
        if ([status isEqual:@"eligible"]) {
            return @{@"bundleIdentifier": selected, @"basis": @"installed-info",
                @"sceneCapability": observed};
        }
        if ([status isEqual:@"unknown"] && baseline) {
            return @{@"bundleIdentifier": selected, @"basis": @"firmware-baseline",
                @"sceneCapability": observed};
        }
        return nil;
    } @catch (NSException *exception) {
        (void)exception; return nil;
    }
}
