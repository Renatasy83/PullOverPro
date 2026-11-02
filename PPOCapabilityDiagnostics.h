#pragma once
#import <Foundation/Foundation.h>

// Diagnostic snapshots only; never scene admission or a permission cache.
// Call on one serial worker. The helper reads no clocks, files or private APIs.
FOUNDATION_EXPORT const NSUInteger PPOCapabilityDiagnosticHistoryLimit;

// Return the latest selected-app observation plus at most eight immutable,
// ordered latest-per-app observations. An unrelated success cannot overwrite a
// retained failure. Pass the prior result's observations as previousHistory.
// Only the last eight input slots are inspected; malformed history items are
// discarded. No raw response, error description, bundle path or plist is kept.
// Invalid identifier/version/time returns nil. Callers must preserve their
// previous history on nil and replace it only after a nonnil result.
// errorCode is a bounded integer (+/-1,000,000); other values become zero.
FOUNDATION_EXPORT NSDictionary *PPOCapabilityDiagnosticRecord(id previousHistory,
    id identifier, id response, NSError *error, id version, NSTimeInterval now);
