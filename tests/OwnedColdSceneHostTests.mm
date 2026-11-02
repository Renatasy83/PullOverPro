// Reuse the actual owner fixtures; no private Apple API is executed here.
#define main OwnedWarmFixtureMain
#include "OwnedSceneHostTests.mm"
#undef main

static unsigned identityFactories, specificationFactories;
static unsigned identityFault, specificationFault;
@interface OwnedColdClientSubclass : OwnedFixtureClient @end
@implementation OwnedColdClientSubclass @end
@interface OwnedFixtureClient (ColdFactory)
+ (id)identityForBundleID:(NSString *)identifier;
@end
@implementation OwnedFixtureClient (ColdFactory)
+ (id)identityForBundleID:(NSString *)identifier {
    identityFactories++;
    if (identityFault == 5) [NSException raise:@"fixture" format:@"identity factory"];
    if (identityFault == 1) return nil;
    if (identityFault == 2) return [NSObject new];
    if (callerIdentifierMutation) [callerIdentifierMutation setString:@"com.example.changed"];
    OwnedFixtureClient *value = identityFault == 3 ? [OwnedColdClientSubclass new] : [self new];
    value.bundleIdentifier = identityFault == 4 ? @"com.example.foreign" : [identifier copy];
    return value;
}
@end
@interface OwnedFixtureSpecification (ColdFactory)
+ (id)specification;
@end
@implementation OwnedFixtureSpecification (ColdFactory)
+ (id)specification {
    specificationFactories++;
    if (specificationFault == 5) [NSException raise:@"fixture" format:@"specification factory"];
    if (specificationFault == 1) return nil;
    if (specificationFault == 2) return [NSObject new];
    OwnedFixtureSpecification *value = specificationFault == 3 ? [OwnedFixtureSpecificationSubclass new] : [self new];
    value.uiSceneSessionRole = specificationFault == 4 ? @"unreviewed-role" : @"UIWindowSceneSessionRoleApplication";
    return value;
}
@end
static int ColdWrongFactory(id receiver, SEL selector, ...) {
    (void)receiver; (void)selector; abort();
}
static Class ColdBadFactoryClass(Class parent, const char *name, const char *selector, const char *encoding) {
    Class cls = objc_lookUpClass(name);
    if (cls) return cls;
    cls = objc_allocateClassPair(parent, name, 0);
    Check(cls && class_addMethod(object_getClass(cls), sel_registerName(selector), (IMP)ColdWrongFactory, encoding),
          "bad factory ABI fixture created without executing it");
    objc_registerClassPair(cls); return cls;
}
static void ResetCold(NSString *identifier = @"com.example.coldapp") {
    ResetForApplication(identifier);
    requestedCapability = DynamicCapability(identifier);
    identityFactories = specificationFactories = identityFault = specificationFault = 0;
}
int main(void) {
    @autoreleasepool {
        for (NSString *reason in @[@"declared-single-application-scene", @"declared-programmatic-application-scenes", @"declared-named-application-configurations"]) {
            ResetCold();
            NSMutableDictionary *proof = [requestedCapability mutableCopy]; proof[@"reason"] = reason; requestedCapability = proof;
            Check(Prepare(nil), "fresh eligible installed metadata can prepare without an original scene");
            Check(identityFactories == 1 && specificationFactories == 1 && sourceProbes == 0 && sourceInvalidations == 0,
                  "cold factories run once and never query or mutate an original");
            Check([current.snapshot[@"preparationMode"] isEqual:@"fresh-application-identity"] &&
                  ![current.snapshot[@"sourceSceneProvided"] boolValue] &&
                  current.snapshot[@"componentBinding"][@"matchesBorrowedSource"] == NSNull.null,
                  "cold diagnostics identify absence instead of fabricating borrowed-source inequality");
            Check([current.snapshot[@"componentBinding"][@"matchesCreatedScene"] boolValue] && current.hostedScene != sourceScene,
                  "namespace and exact proxy still bind the independently created child");
            Check([current close] && current.closed && !current.poisoned && controllerInvalidations == 1 && workspaceInvalidations == 1,
                  "cold path explicitly invalidates only its verified controller and empty workspace");
            Check(!Prepare(nil) && identityFactories == 1, "closed cold requests cannot be replayed");
            SourceUnchanged();
        }
        for (NSString *identifier in @[@"com.apple.mobilesafari", @"com.apple.reminders", @"com.apple.MobileAddressBook", @"com.example.coldapp"]) {
            for (unsigned fault = 0; fault < 8; fault++) {
                ResetCold(identifier);
                NSMutableDictionary *proof = [requestedCapability mutableCopy];
                if (fault == 0) requestedCapability = nil;
                else {
                    if (fault == 1) { proof[@"status"] = @"unknown"; proof[@"eligible"] = @NO; proof[@"reason"] = @"manifest-unknown"; }
                    if (fault == 2) { proof[@"status"] = @"ineligible"; proof[@"eligible"] = @NO; proof[@"reason"] = @"multiple-scenes-disabled"; }
                    if (fault == 3) proof[@"observedUptime"] = @(NSProcessInfo.processInfo.systemUptime - 10);
                    if (fault == 4) proof[@"bundleIdentifier"] = @"com.example.other";
                    if (fault == 5) proof[@"policy"] = @"installed-basic-multiscene-v2";
                    if (fault == 6) proof[@"eligible"] = @1;
                    if (fault == 7) proof[@"reason"] = @"unreviewed-reason";
                    requestedCapability = proof;
                }
                Check(!Prepare(nil) && current.closed && !current.poisoned && identityFactories == 0 && specificationFactories == 0 &&
                      constructors == 0 && workspaceConstructions == 0 && sourceProbes == 0,
                      "missing/unknown/negative/stale/mismatched/malformed data never invokes a cold factory, including baselines");
                SourceUnchanged();
            }
        }
        for (unsigned kind = 0; kind < 2; kind++) {
            ResetCold(); NSMutableDictionary *classes = [Classes() mutableCopy];
            classes[kind ? @"UIApplicationSceneSpecification" : @"FBSSceneClientIdentity"] = kind
                ? ColdBadFactoryClass(OwnedFixtureSpecification.class, "ColdWrongSpecificationFactory", "specification", "i@:")
                : ColdBadFactoryClass(OwnedFixtureClient.class, "ColdWrongIdentityFactory", "identityForBundleID:", "i@:@");
            current = [[PPOOwnedSceneHost alloc] initWithClasses:classes];
            Check(!Prepare(nil) && current.closed && identityFactories == 0 && specificationFactories == 0 && constructors == 0,
                  "wrong class-factory encodings reject before any private allocation");
        }
        for (unsigned kind = 0; kind < 2; kind++) for (unsigned fault = 1; fault <= 5; fault++) {
            ResetCold(); if (kind) specificationFault = fault; else identityFault = fault;
            Check(!Prepare(nil) && current.poisoned && !current.closed && workspaceConstructions == 0 && constructors == 0,
                  "uncertain factory return/role/identity/exception is pinned before any workspace attempt");
            Check(![current close] && ![current pollCleanup] && !Prepare(nil), "factory quarantine cannot be retried or released blindly");
            SourceUnchanged();
        }
        for (unsigned fault = 0; fault < 7; fault++) {
            ResetCold();
            if (fault == 0) wrongNewIdentity = YES;
            if (fault == 1) wrongNewWorkspace = YES;
            if (fault == 2) badNewClientIdentity = YES;
            if (fault == 3) badNewRole = YES;
            if (fault == 4) childSpecificationSubclass = YES;
            if (fault == 5) badComponentScene = YES;
            if (fault == 6) aliasSource = YES;
            Check(!Prepare(nil) && current.poisoned && !current.closed && sourceInvalidations == 0 && sourceProbes == 0,
                  "no-original mode still rejects child namespace/client/specification/binding alias failures");
            SourceUnchanged();
        }
        ResetCold(); delayedCleanup = YES;
        Check(Prepare(nil) && ![current close] && !current.closed && workspaceInvalidations == 0,
              "cold cleanup preserves populated workspace until child invalidation is observed");
        CompleteDeferredCleanup();
        Check([current pollCleanup] && current.closed && workspaceInvalidations == 1, "cold deferred cleanup finishes after independent proof");
        ResetCold(); NSMutableString *identifier = [originalApplication mutableCopy];
        requestedApplication = identifier; callerIdentifierMutation = identifier;
        Check(Prepare(nil) && [identifier isEqual:@"com.apple.MobileAddressBook"] &&
              [current.snapshot[@"expectedBundleIdentifier"] isEqual:originalApplication],
              "factory dispatch uses an immutable selected-ID snapshot despite caller mutation");
        Check([current close], "frozen cold identity closes normally");
        ResetCold();
        Check(Prepare(sourceScene) && identityFactories == 0 && specificationFactories == 0 &&
              [current.snapshot[@"preparationMode"] isEqual:@"existing-source-definition"],
              "existing-source path does not invoke the new factories");
        Check([current close], "warm path preserves its cleanup");
        printf("Owned cold scene tests passed: %u checks; synthetic identity factories, not iOS process launch\n", checks);
    }
    return 0;
}
