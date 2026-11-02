#import "../PPOCapabilityDiagnostics.h"
#import "../PPOSceneCapability.h"
#import <CoreFoundation/CoreFoundation.h>
#include <cmath>
#include <initializer_list>
#include <limits>
#include <stdio.h>
#include <stdlib.h>

// Native Foundation fixtures only. No I/O, actual bundle or private iOS API.
static unsigned checks;
static void Check(BOOL condition, const char *message) {
    checks++;
    if (!condition) { fprintf(stderr, "FAIL: %s\n", message); exit(1); }
}
static NSDictionary *Proof(NSString *identifier, BOOL eligible = YES) {
    if (!eligible) return PPOSceneCapabilityUnknown(identifier, @"manifest-complex", 100);
    return PPOSceneCapabilityFromInfo(@{@"CFBundleIdentifier":identifier, @"CFBundlePackageType":@"APPL",
        @"UIDeviceFamily":@[@1], @"UIApplicationSceneManifest":@{@"UIApplicationSupportsMultipleScenes":@YES}},identifier,100);
}
static NSDictionary *Response(NSString *identifier, BOOL eligible = YES) {
    return @{@"status":@"inspected",@"sceneCapability":Proof(identifier,eligible)};
}
static NSDictionary *Record(id history, id identifier, id response, NSError *error = nil,
    id version = @"1.0.3~rc4", double now = 101) {
    return PPOCapabilityDiagnosticRecord(history,identifier,response,error,version,now);
}
static NSDictionary *Entry(NSDictionary *report, NSString *identifier) {
    for (NSDictionary *value in report[@"observations"])
        if ([value[@"bundleIdentifier"] isEqual:identifier]) return value;
    return nil;
}
static NSString *JSONText(id value) {
    NSData *data = [NSJSONSerialization dataWithJSONObject:value options:0 error:NULL];
    Check(data != nil, "every valid report is JSON-serializable");
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}
static BOOL IsFalse(id value) {
    return [value isKindOfClass:NSNumber.class] && CFGetTypeID((__bridge CFTypeRef)value)==CFBooleanGetTypeID() && ![value boolValue];
}
int main(void) {
    @autoreleasepool {
        NSString *a=@"com.example.messages", *b=@"com.example.browser", *c=@"com.example.chat";
        NSDictionary *failed=Record(nil,a,Response(a,NO));
        Check(PPOCapabilityDiagnosticHistoryLimit==8, "history has an explicit small bound");
        Check(failed.count==10 && [failed[@"observations"] count]==1 && [failed[@"bundleIdentifier"] isEqual:a],
              "top envelope remains compatible and adds one bounded history array");
        Check([failed[@"sceneCapability"][@"status"] isEqual:@"unknown"] &&
              [failed[@"sceneCapability"][@"reason"] isEqual:@"manifest-complex"] &&
              [failed[@"capabilityIssue"] isEqual:@"none"],
              "valid unknown proof records the actual refusal reason without inventing a parse error");
        Check(IsFalse(failed[@"runtimeCompatibilityConfirmed"]), "a diagnostic does not assert compatibility");
        NSDictionary *success=Record(failed[@"observations"],b,Response(b));
        Check([success[@"bundleIdentifier"] isEqual:b] && [success[@"observations"] count]==2 &&
              [Entry(success,a)[@"sceneCapability"][@"status"] isEqual:@"unknown"] &&
              [Entry(success,b)[@"sceneCapability"][@"status"] isEqual:@"eligible"],
              "unrelated success preserves the earlier application's failure");
        Check([failed[@"observations"] count]==1 && [failed[@"bundleIdentifier"] isEqual:a],
              "new records cannot mutate old caller snapshots");
        NSDictionary *retry=Record(success[@"observations"],a,Response(a));
        Check([retry[@"observations"] count]==2 && [retry[@"observations"][0][@"bundleIdentifier"] isEqual:b] &&
              [retry[@"observations"][1][@"bundleIdentifier"] isEqual:a] &&
              [Entry(retry,a)[@"sceneCapability"][@"status"] isEqual:@"eligible"],
              "same app replaces its old entry and becomes most recent");
        NSDictionary *report=retry;
        for (unsigned i=0;i<40;i++) {
            NSString *identifier=[NSString stringWithFormat:@"com.example.app%u",i];
            report=Record(report[@"observations"],identifier,Response(identifier,i%2==0));
            Check([report[@"observations"] count]<=8 && [report[@"observations"] lastObject]!=nil,
                  "many selections never grow the retained observation array beyond eight");
            Check([report[@"observations"] lastObject][@"bundleIdentifier"]==report[@"bundleIdentifier"] ||
                  [[report[@"observations"] lastObject][@"bundleIdentifier"] isEqual:report[@"bundleIdentifier"]],
                  "top and newest entry describe the same selected app");
        }
        Check([report[@"observations"] count]==8 &&
              [report[@"observations"][0][@"bundleIdentifier"] isEqual:@"com.example.app32"] &&
              [report[@"observations"][7][@"bundleIdentifier"] isEqual:@"com.example.app39"] && Entry(report,a)==nil,
              "only oldest distinct apps are evicted at capacity");
        JSONText(report);

        NSArray *history=success[@"observations"];
        for (id bad in @[NSNull.null,@YES,@1,@"history",@{}]) {
            NSDictionary *value=Record(bad,c,Response(c));
            Check([value[@"observations"] count]==1 && Entry(value,c)!=nil,
                  "invalid history containers do not leak into a new report");
        }
        NSMutableArray *huge=[NSMutableArray array];
        for (unsigned i=0;i<1000;i++) [huge addObject:failed[@"observations"][0]];
        [huge addObjectsFromArray:history];
        NSDictionary *bounded=Record(huge,c,Response(c));
        Check([bounded[@"observations"] count]==3 && Entry(bounded,a)!=nil && Entry(bounded,b)!=nil,
              "oversized prior history inspects bounded trailing slots and deduplicates them");
        NSMutableDictionary *badEntry=[failed[@"observations"][0] mutableCopy]; badEntry[@"extra"]=@"secret";
        Check([Record(@[badEntry,NSNull.null,@{},history[1]],c,Response(c))[@"observations"] count]==2,
              "corrupted history entries cannot propagate extra keys or arbitrary nested values");
        for (NSString *key in @[@"schema",@"version",@"bundleIdentifier",@"responseStatus",@"sceneCapability",
                 @"capabilityIssue",@"errorCode",@"observedUptime",@"runtimeCompatibilityConfirmed"]) {
            NSMutableDictionary *missing=[history[0] mutableCopy]; [missing removeObjectForKey:key];
            Check([Record(@[missing],c,Response(c))[@"observations"] count]==1,
                  "incomplete historical observations are discarded rather than trusted");
        }
        for (NSDictionary *mutation in @[@{@"schema":@YES},@{@"schema":@2},@{@"observedUptime":@(-1)},
                 @{@"observedUptime":@YES},@{@"observedUptime":@(NAN)},@{@"errorCode":@1.5},
                 @{@"errorCode":@YES},@{@"errorCode":@1000001},@{@"runtimeCompatibilityConfirmed":@YES},
                 @{@"runtimeCompatibilityConfirmed":@0},@{@"capabilityIssue":@"unreviewed"},
                 @{@"responseStatus":@"unreviewed"},@{@"version":@"private/path"},
                 @{@"bundleIdentifier":@"com.apple.springboard"}]) {
            NSMutableDictionary *changed=[history[0] mutableCopy]; [changed addEntriesFromDictionary:mutation];
            Check([Record(@[changed],c,Response(c))[@"observations"] count]==1,
                  "malformed historical scalars cannot alter a reconstructed diagnostic");
        }

        for (id bad in @[NSNull.null,@YES,@1,@[],@{},@"",@"app",@"com..example",@"private/path",
                 @"com.apple.springboard",@"COM.APPLE.BACKBOARDD",[@"a" stringByPaddingToLength:256 withString:@"a" startingAtIndex:0]])
            Check(Record(history,bad,Response(c))==nil,
                  "invalid selected identity produces no replacement report or history");
        Check(Record(history,nil,Response(c))==nil && [history count]==2,
              "nil identity leaves caller-owned failure history intact");
        for (id bad in @[NSNull.null,@YES,@1,@[],@{},@"",@"private/path",@"bad\nversion",
                 [@"v" stringByPaddingToLength:65 withString:@"v" startingAtIndex:0]])
            Check(Record(history,c,Response(c),nil,bad)==nil,
                  "invalid or oversized version labels cannot become diagnostic text");
        for (double bad : {-1.0,double(NAN),double(INFINITY),-double(INFINITY)})
            Check(Record(history,c,Response(c),nil,@"1.0.3~rc4",bad)==nil,
                  "nonfinite/negative observation time produces no replacement report");
        Check(Record(history,c,Response(c),nil,@"1.0.3~rc4",0)!=nil,
              "zero monotonic time is a valid pure fixture input");

        NSError *secret=[NSError errorWithDomain:@"SECRET_DOMAIN" code:5 userInfo:@{
            NSLocalizedDescriptionKey:@"SECRET /private/var/user-data",@"rawBundleInfo":@{@"secret":@"secret"}}];
        NSDictionary *unavailable=Record(history,c,nil,secret);
        Check([unavailable[@"responseStatus"] isEqual:@"unavailable"] &&
              unavailable[@"sceneCapability"]==NSNull.null && [unavailable[@"errorCode"] isEqual:@5] &&
              [unavailable[@"capabilityIssue"] isEqual:@"response-unavailable"],
              "missing transport reply records bounded status and numeric error only");
        NSString *serialized=JSONText(unavailable);
        Check([serialized rangeOfString:@"SECRET"].location==NSNotFound &&
              [serialized rangeOfString:@"private"].location==NSNotFound &&
              [serialized rangeOfString:@"rawBundleInfo"].location==NSNotFound,
              "raw error descriptions, domains, paths and user info never reach the report");
        for (NSInteger code : {-1000001,-1000000,0,1000000,1000001}) {
            NSError *error=[NSError errorWithDomain:@"fixture" code:code userInfo:nil];
            NSInteger expected=code>=-1000000 && code<=1000000?code:0;
            Check([Record(nil,c,nil,error)[@"errorCode"] integerValue]==expected,
                  "numeric diagnostic error codes are explicitly bounded");
        }
        NSDictionary *wrongID=Record(history,c,Response(a));
        Check(wrongID[@"sceneCapability"]==NSNull.null && [wrongID[@"capabilityIssue"] isEqual:@"identifier-mismatch"] &&
              [wrongID[@"bundleIdentifier"] isEqual:c] && Entry(wrongID,a)!=nil,
              "a valid proof for another selected ID is stripped without replacing that app's history");
        NSDictionary *malformed=Record(nil,c,@{@"status":@"inspected",@"sceneCapability":@{@"secret":@"PRIVATE"}});
        Check(malformed[@"sceneCapability"]==NSNull.null && [malformed[@"capabilityIssue"] isEqual:@"capability-invalid"],
              "malformed capability data is replaced with an issue code");
        Check([JSONText(malformed) rangeOfString:@"PRIVATE"].location==NSNotFound,
              "malformed proof contents are not serialized");
        for (id empty in @[NSNull.null,@{}]) {
            id proof=empty==NSNull.null?NSNull.null:nil;
            NSMutableDictionary *response=[@{@"status":@"inspected"} mutableCopy];
            if (proof) response[@"sceneCapability"]=proof;
            NSDictionary *value=Record(nil,c,response);
            Check(value[@"sceneCapability"]==NSNull.null && [value[@"capabilityIssue"] isEqual:@"capability-missing"],
                  "both absent and null inspected proofs remain diagnostic failures");
        }
        NSDictionary *unexpected=Record(nil,c,@{@"status":@"unsupported",@"sceneCapability":Proof(c)});
        Check([unexpected[@"responseStatus"] isEqual:@"unsupported"] && unexpected[@"sceneCapability"]==NSNull.null &&
              [unexpected[@"capabilityIssue"] isEqual:@"unexpected-capability"],
              "a non-inspection response cannot attach an apparently usable proof");
        for (NSString *status in @[@"ready",@"refreshed",@"accepted",@"rejected",@"unsupported",@"error",@"busy",@"stale",@"unavailable"])
            Check([Record(nil,c,@{@"status":status})[@"responseStatus"] isEqual:status],
                  "known non-inspection transport statuses remain bounded canonical strings");
        for (id response in @[NSNull.null,@YES,@1,@[],@"PRIVATE",@{},@{@"status":@"PRIVATE_STATUS"},
                 @{@"status":@YES},@{@"status":[@"x" stringByPaddingToLength:1000 withString:@"x" startingAtIndex:0]}]) {
            NSDictionary *value=Record(nil,c,response);
            Check([value[@"responseStatus"] isEqual:@"unavailable"] && value[@"sceneCapability"]==NSNull.null &&
                  [value[@"capabilityIssue"] isEqual:@"response-invalid"],
                  "unrecognized response shape/status is not copied into the report");
            Check([JSONText(value) rangeOfString:@"PRIVATE"].location==NSNotFound,
                  "unknown response strings are sanitized rather than emitted");
        }
        NSMutableDictionary *oversized=[NSMutableDictionary dictionaryWithObject:@"inspected" forKey:@"status"];
        for (unsigned i=0;i<16;i++) oversized[[NSString stringWithFormat:@"key%u",i]]=@1;
        Check([Record(nil,c,oversized)[@"capabilityIssue"] isEqual:@"response-invalid"],
              "oversized response dictionaries are rejected before nested proof processing");

        NSMutableString *mutableID=[c mutableCopy], *mutableVersion=[@"1.0.3~rc4" mutableCopy], *mutableStatus=[@"inspected" mutableCopy];
        NSMutableDictionary *mutableProof=[Proof(c) mutableCopy];
        NSMutableString *proofID=[c mutableCopy]; mutableProof[@"bundleIdentifier"]=proofID;
        NSMutableDictionary *mutableResponse=[@{@"status":mutableStatus,@"sceneCapability":mutableProof} mutableCopy];
        NSDictionary *frozen=Record(history,mutableID,mutableResponse,nil,mutableVersion);
        NSData *before=[NSJSONSerialization dataWithJSONObject:frozen options:NSJSONWritingSortedKeys error:NULL];
        [mutableID setString:@"com.example.changed"]; [mutableVersion setString:@"changed"];
        [mutableStatus setString:@"error"]; [proofID setString:@"com.example.other"];
        mutableProof[@"reason"]=@"unreviewed"; [mutableResponse removeAllObjects];
        NSData *after=[NSJSONSerialization dataWithJSONObject:frozen options:NSJSONWritingSortedKeys error:NULL];
        Check([before isEqual:after] && [frozen[@"bundleIdentifier"] isEqual:c] &&
              [frozen[@"version"] isEqual:@"1.0.3~rc4"] && [frozen[@"responseStatus"] isEqual:@"inspected"],
              "fresh nested mutable caller state is frozen before returning the report");
        NSMutableDictionary *mutableOld=[history[0] mutableCopy];
        NSMutableString *oldID=[a mutableCopy]; mutableOld[@"bundleIdentifier"]=oldID;
        NSMutableArray *mutableHistory=[NSMutableArray arrayWithObjects:mutableOld,history[1],nil];
        NSDictionary *frozenOld=Record(mutableHistory,c,Response(c));
        [oldID setString:@"com.example.changed"]; [mutableOld removeAllObjects]; [mutableHistory removeAllObjects];
        Check([frozenOld[@"observations"] count]==3 && Entry(frozenOld,a)!=nil && Entry(frozenOld,b)!=nil,
              "historical entries are reconstructed rather than retaining mutable input objects");
        Check([JSONText(frozenOld) rangeOfString:@"com.example.changed"].location==NSNotFound,
              "caller mutation cannot rewrite previously retained failure identity");
        printf("Capability diagnostics tests passed: %u checks; bounded immutable latest-per-app history, not admission\n",checks);
    }
    return 0;
}
