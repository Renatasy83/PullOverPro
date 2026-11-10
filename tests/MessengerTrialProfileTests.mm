#import "../PPOSceneCapability.h"
#import "../PPOOwnedAdmission.h"
#import "../PPOBridgeProtocol.h"
#include <stdio.h>
#include <stdlib.h>
static unsigned checks;
static void Check(BOOL yes,const char *message) { checks++; if (!yes) { fprintf(stderr,"FAIL: %s\n",message);exit(1); } }
static NSString *const ID=@"com.facebook.Messenger";
static NSArray<NSDictionary *> *Profiles(void) { return @[
    @{@"digest":@"741517f9808a10ac225c6490d2af5bd835ff56b112464c5d53ce670d7ff92e30",
      @"version":@"585.0.0",@"build":@"1101076820",@"reason":@"reviewed-messenger585-warm-trial"},
    @{@"digest":@"354b8abc3acd00ae3a16f48e3b0156f1497be49742f6dc1db3753c13bbc89b9f",
      @"version":@"586.0.0",@"build":@"1105932679",@"reason":@"reviewed-messenger586-warm-trial"}]; }
static NSMutableDictionary *Info(NSDictionary *profile) {
    return [@{@"CFBundleIdentifier":ID,@"CFBundleExecutable":@"Messenger",@"CFBundlePackageType":@"APPL",
        @"CFBundleVersion":profile[@"build"],@"CFBundleShortVersionString":profile[@"version"],
        @"UIDeviceFamily":@[@1,@2]} mutableCopy];
}
static NSDictionary *Read(id info,id digest) { return PPOSceneCapabilityFromInfoWithDigest(info,ID,100,digest); }
static void Refused(id info,id digest) {
    NSDictionary *p=Read(info,digest);
    Check(!PPOSceneCapabilityIsMessengerTrial(p),"unreviewed metadata cannot mint a Messenger trial proof");
    Check(!PPOOwnedAdmissionSnapshot(ID,p,100),"unreviewed missing-manifest metadata cannot gain admission");
}
static void TestProfile(NSDictionary *profile,NSDictionary *other) {
    NSString *digest=profile[@"digest"];
    NSDictionary *p=Read(Info(profile),digest);
    Check(PPOSceneCapabilityIsMessengerTrial(p),"exact scalar profile plus supplied digest yields reviewed-only reason");
    Check([p[@"reason"] isEqual:profile[@"reason"]],"each profile retains its separately reviewed provenance");
    Check([p[@"status"] isEqual:@"unknown"] && [p[@"eligible"] isEqual:@NO],"trial is never declared general multiscene eligibility");
    Check([PPOOwnedAdmissionSnapshot(ID,p,105)[@"basis"] isEqual:@"reviewed-messenger-warm-trial"],"admission retains explicit experimental provenance");
    Check(!PPOOwnedAdmissionSnapshot(ID,p,105.0001) && !PPOOwnedAdmissionSnapshot(@"com.example.other",p,100),"freshness and same-app binding mandatory");
    Check(!PPOOwnedAdmissionSnapshot(ID,PPOSceneCapabilityFromInfo(Info(profile),ID,100),100),"ordinary missing-manifest policy stays closed");
    for (id invalid in @[NSNull.null,@"",@"741517",digest.uppercaseString,@1,other[@"digest"]])
        Refused(Info(profile),invalid);
    // A recognized hash alone cannot admit the other reviewed build, nor may
    // versions/builds be mixed between the separately reviewed profile tuples.
    for (NSString *key in @[@"CFBundleVersion",@"CFBundleShortVersionString"]) {
        NSMutableDictionary *i=Info(profile);
        i[key]=other[[key isEqual:@"CFBundleVersion"] ? @"build" : @"version"];
        Refused(i,digest);
    }
    Refused(Info(other),digest);
    for (NSString *key in @[@"CFBundleIdentifier",@"CFBundleExecutable",@"CFBundlePackageType",
            @"CFBundleVersion",@"CFBundleShortVersionString"]) {
        for (id value in @[@"other",@YES,@1,NSNull.null,@[],@{}]) {
            NSMutableDictionary *i=Info(profile);i[key]=value;Refused(i,digest);
        }
        NSMutableDictionary *i=Info(profile);[i removeObjectForKey:key];Refused(i,digest);
    }
    for (id families in @[@[@1],@[@2],@[@2,@1],@[@YES,@2],@[@1,@2,@3],NSNull.null]) {
        NSMutableDictionary *i=Info(profile);i[@"UIDeviceFamily"]=families;Refused(i,digest);
    }
    for (NSString *key in @[@"UIApplicationSceneManifest",@"UIWindowOptions",@"UnexpectedSCENEOption",
            @"unexpectedWINDOWOption",@"NSExtension",@"LSBackgroundOnly",@"LSUIElement",@"UIBackgroundOnly"]) {
        NSMutableDictionary *i=Info(profile);i[key]=@YES;Refused(i,digest);
    }
    for (id invalidInfo in @[NSNull.null,@YES,@[],@{},@"not a plist"])
        Refused(invalidInfo,digest);
    for (NSString *idValue in @[@"com.example.other",@"com.apple.MobileSMS",@"com.facebook.messenger"]) {
        NSMutableDictionary *i=Info(profile);i[@"CFBundleIdentifier"]=idValue;
        Check(!PPOSceneCapabilityIsMessengerTrial(PPOSceneCapabilityFromInfoWithDigest(i,idValue,100,digest)),"profile cannot cross identifiers or case");
        Check(!PPOSceneCapabilityUnknown(idValue,profile[@"reason"],100),"reserved reason cannot bind other identifiers");
        NSMutableDictionary *forged=[p mutableCopy];forged[@"bundleIdentifier"]=idValue;
        Check(!PPOSceneCapabilityNormalize(forged),"wire cannot rebind reviewed trial reason");
    }
    for (NSString *status in @[@"eligible",@"ineligible"]) {
        NSMutableDictionary *forged=[p mutableCopy];forged[@"status"]=status;forged[@"eligible"]=@([status isEqual:@"eligible"]);
        Check(!PPOSceneCapabilityNormalize(forged),"reviewed reason cannot be promoted to general eligibility");
    }
    NSString *nonce=NSUUID.UUID.UUIDString;
    NSData *wire=PPOBridgeCapabilityResponseData(nonce,p,100,NULL);
    NSDictionary *response=PPOBridgeResponseFromData(wire,nonce,NULL);
    Check(PPOSceneCapabilityIsMessengerTrial(response[@"sceneCapability"]),"actual strict bridge round trip retains scoped unknown proof");
    NSMutableDictionary *mut=[p mutableCopy]; NSDictionary *admission=PPOOwnedAdmissionSnapshot(ID,mut,100);
    [mut removeAllObjects];Check(PPOSceneCapabilityIsMessengerTrial(admission[@"sceneCapability"]),"admission freezes scalar proof");
}
int main(void) { @autoreleasepool {
    NSArray<NSDictionary *> *profiles=Profiles();
    TestProfile(profiles[0],profiles[1]);
    TestProfile(profiles[1],profiles[0]);
    for (NSString *reason in @[@"reviewed-messenger-warm-trial",@"reviewed-messenger587-warm-trial",
            @"reviewed-messenger586-warm-trial-extra"]) {
        Check(!PPOSceneCapabilityUnknown(ID,reason,100),"unreviewed or prefix-matched reason cannot mint a trial proof");
        NSMutableDictionary *forged=[Read(Info(profiles[1]),profiles[1][@"digest"]) mutableCopy];
        forged[@"reason"]=reason;
        Check(!PPOSceneCapabilityNormalize(forged) && !PPOSceneCapabilityIsMessengerTrial(forged),"wire rejects unreviewed trial reason");
    }
    printf("Messenger trial profile tests passed: %u checks; synthetic digest/profile, not installed app or hosting\n",checks);
} return 0; }
