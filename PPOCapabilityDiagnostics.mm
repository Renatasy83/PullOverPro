#import "PPOCapabilityDiagnostics.h"
#import "PPOSceneCapability.h"
#import <CoreFoundation/CoreFoundation.h>
#include <cmath>

const NSUInteger PPOCapabilityDiagnosticHistoryLimit = 8;
static const NSInteger DiagnosticErrorLimit = 1000000;

static BOOL DiagnosticBoolean(id value) {
    return [value isKindOfClass:NSNumber.class] &&
        CFGetTypeID((__bridge CFTypeRef)value) == CFBooleanGetTypeID();
}
static BOOL DiagnosticNumber(id value) {
    return [value isKindOfClass:NSNumber.class] && !DiagnosticBoolean(value) &&
        std::isfinite([(NSNumber *)value doubleValue]);
}
static BOOL DiagnosticVersion(id value) {
    if (![value isKindOfClass:NSString.class] || [value length] == 0 || [value length] > 64) return NO;
    NSString *text = value;
    for (NSUInteger i = 0; i < text.length; i++) {
        unichar c = [text characterAtIndex:i];
        BOOL alpha = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z');
        if (!alpha && !(c >= '0' && c <= '9') && c != '.' && c != '-' && c != '_' && c != '~' && c != '+')
            return NO;
    }
    return YES;
}
static NSString *DiagnosticCanonical(id value, NSArray<NSString *> *allowed) {
    if (![value isKindOfClass:NSString.class] || [value length] > 64) return nil;
    NSUInteger found = [allowed indexOfObject:value];
    return found == NSNotFound ? nil : allowed[found];
}
static NSArray<NSString *> *DiagnosticStatuses(void) {
    return @[@"ready", @"refreshed", @"accepted", @"rejected", @"unsupported", @"error", @"busy",
        @"stale", @"inspected", @"unavailable"];
}
static NSArray<NSString *> *DiagnosticIssues(void) {
    return @[@"none", @"response-unavailable", @"response-invalid", @"capability-missing",
        @"capability-invalid", @"identifier-mismatch", @"unexpected-capability"];
}
static NSDictionary *DiagnosticObservation(NSString *identifier, NSString *version,
    NSString *status, NSDictionary *capability, NSString *issue, NSInteger errorCode, NSTimeInterval now) {
    return @{@"schema":@1, @"version":[version copy], @"bundleIdentifier":[identifier copy],
        @"responseStatus":status, @"sceneCapability":capability ?: (id)NSNull.null,
        @"capabilityIssue":issue, @"errorCode":@(errorCode), @"observedUptime":@(now),
        @"runtimeCompatibilityConfirmed":@NO};
}
static NSDictionary *DiagnosticHistoryObservation(id value) {
    if (![value isKindOfClass:NSDictionary.class] || [value count] != 9) return nil;
    NSDictionary *raw = value;
    NSArray *keys = @[@"schema", @"version", @"bundleIdentifier", @"responseStatus", @"sceneCapability",
        @"capabilityIssue", @"errorCode", @"observedUptime", @"runtimeCompatibilityConfirmed"];
    for (id key in raw) if (![key isKindOfClass:NSString.class] || ![keys containsObject:key]) return nil;
    if (!DiagnosticNumber(raw[@"schema"]) || [raw[@"schema"] doubleValue] != 1 ||
        !DiagnosticVersion(raw[@"version"]) || !PPOSceneApplicationIdentifierAllowed(raw[@"bundleIdentifier"]) ||
        !DiagnosticNumber(raw[@"errorCode"]) ||
        [raw[@"errorCode"] doubleValue] < -DiagnosticErrorLimit ||
        [raw[@"errorCode"] doubleValue] > DiagnosticErrorLimit ||
        std::floor([raw[@"errorCode"] doubleValue]) != [raw[@"errorCode"] doubleValue] ||
        !DiagnosticNumber(raw[@"observedUptime"]) || [raw[@"observedUptime"] doubleValue] < 0 ||
        !DiagnosticBoolean(raw[@"runtimeCompatibilityConfirmed"]) ||
        [raw[@"runtimeCompatibilityConfirmed"] boolValue]) return nil;
    NSString *status = DiagnosticCanonical(raw[@"responseStatus"], DiagnosticStatuses());
    NSString *issue = DiagnosticCanonical(raw[@"capabilityIssue"], DiagnosticIssues());
    if (!status || !issue) return nil;
    NSDictionary *capability = nil;
    if (raw[@"sceneCapability"] != NSNull.null) {
        capability = PPOSceneCapabilityNormalize(raw[@"sceneCapability"]);
        if (!capability || ![capability[@"bundleIdentifier"] isEqual:raw[@"bundleIdentifier"]] ||
            ![status isEqual:@"inspected"] || ![issue isEqual:@"none"]) return nil;
    } else if ([issue isEqual:@"none"]) return nil;
    return DiagnosticObservation(raw[@"bundleIdentifier"], raw[@"version"], status, capability, issue,
        [raw[@"errorCode"] integerValue], [raw[@"observedUptime"] doubleValue]);
}

NSDictionary *PPOCapabilityDiagnosticRecord(id previousHistory, id identifier, id response,
    NSError *error, id version, NSTimeInterval now) {
    @try {
        if (!PPOSceneApplicationIdentifierAllowed(identifier) || !DiagnosticVersion(version) ||
            !std::isfinite(now) || now < 0) return nil;
        NSString *selected = [identifier copy], *release = [version copy];
        if (!PPOSceneApplicationIdentifierAllowed(selected) || !DiagnosticVersion(release)) return nil;
        NSString *status = @"unavailable", *issue = @"response-unavailable";
        NSDictionary *capability = nil;
        if (response) {
            if (![response isKindOfClass:NSDictionary.class] || [response count] > 16) {
                issue = @"response-invalid";
            } else {
                NSString *observedStatus = DiagnosticCanonical(response[@"status"], DiagnosticStatuses());
                if (!observedStatus) issue = @"response-invalid";
                else {
                    status = observedStatus;
                    id proof = response[@"sceneCapability"];
                    if ([status isEqual:@"inspected"]) {
                        if (!proof || proof == NSNull.null) issue = @"capability-missing";
                        else {
                            capability = PPOSceneCapabilityNormalize(proof);
                            if (!capability) issue = @"capability-invalid";
                            else if (![capability[@"bundleIdentifier"] isEqual:selected]) {
                                capability = nil; issue = @"identifier-mismatch";
                            } else issue = @"none";
                        }
                    } else issue = proof && proof != NSNull.null ? @"unexpected-capability" : @"capability-missing";
                }
            }
        }
        NSInteger code = 0;
        if ([error isKindOfClass:NSError.class]) {
            NSInteger observedCode = error.code;
            if (observedCode >= -DiagnosticErrorLimit && observedCode <= DiagnosticErrorLimit) code = observedCode;
        }
        NSDictionary *latest = DiagnosticObservation(selected, release, status, capability, issue, code, now);
        NSMutableArray<NSDictionary *> *history = [NSMutableArray arrayWithCapacity:PPOCapabilityDiagnosticHistoryLimit];
        if ([previousHistory isKindOfClass:NSArray.class]) {
            NSUInteger count = [previousHistory count];
            NSUInteger first = count > PPOCapabilityDiagnosticHistoryLimit ? count-PPOCapabilityDiagnosticHistoryLimit : 0;
            for (NSUInteger i = first; i < count; i++) {
                NSDictionary *entry = DiagnosticHistoryObservation(previousHistory[i]);
                if (!entry || [entry[@"bundleIdentifier"] isEqual:selected]) continue;
                NSUInteger duplicate = NSNotFound;
                for (NSUInteger n = 0; n < history.count; n++)
                    if ([history[n][@"bundleIdentifier"] isEqual:entry[@"bundleIdentifier"]]) { duplicate = n; break; }
                if (duplicate != NSNotFound) [history removeObjectAtIndex:duplicate];
                [history addObject:entry];
            }
        }
        [history addObject:latest];
        if (history.count > PPOCapabilityDiagnosticHistoryLimit) [history removeObjectAtIndex:0];
        NSMutableDictionary *report = [latest mutableCopy];
        report[@"observations"] = [history copy];
        return [report copy];
    } @catch (NSException *exception) { (void)exception; return nil; }
}
