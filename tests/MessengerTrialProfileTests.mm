#import "../PPOSceneCapability.h"
#import "../PPOOwnedAdmission.h"
#import "../PPOBridgeProtocol.h"
#include <stdio.h>
#include <stdlib.h>
static unsigned checks;
static void Check(BOOL yes,const char *message) { checks++; if (!yes) { fprintf(stderr,"FAIL: %s\n",message);exit(1); } }
static NSString *const ID=@"com.facebook.Messenger";
static NSString *const Digest=@"741517f9808a10ac225c6490d2af5bd835ff56b112464c5d53ce670d7ff92e30";
static NSMutableDictionary *Info(void) { return [@{@"CFBundleIdentifier":ID,@"CFBundleExecutable":@"Messenger",
    @"CFBundlePackageType":@"APPL",@"CFBundleVersion":@"1101076820",@"CFBundleShortVersionString":@"585.0.0",
    @"UIDeviceFamily":@[@1,@2]} mutableCopy]; }
static NSDictionary *Read(id info,id digest=Digest) { return PPOSceneCapabilityFromInfoWithDigest(info,ID,100,digest); }
static void Refused(id info,id digest=Digest) {
    NSDictionary *p=Read(info,digest);
    Check(!PPOSceneCapabilityIsMessengerTrial(p),"unreviewed metadata cannot mint a Messenger trial proof");
    Check(!PPOOwnedAdmissionSnapshot(ID,p,100),"unreviewed missing-manifest metadata cannot gain admission");
}
int main(void) { @autoreleasepool {
    NSDictionary *p=Read(Info());
    Check(PPOSceneCapabilityIsMessengerTrial(p),"exact scalar profile plus supplied digest yields reviewed-only reason");
    Check([p[@"status"] isEqual:@"unknown"] && [p[@"eligible"] isEqual:@NO],"trial is never declared general multiscene eligibility");
    Check([PPOOwnedAdmissionSnapshot(ID,p,105)[@"basis"] isEqual:@"reviewed-messenger-warm-trial"],"admission retains explicit experimental provenance");
    Check(!PPOOwnedAdmissionSnapshot(ID,p,105.0001) && !PPOOwnedAdmissionSnapshot(@"com.example.other",p,100),"freshness and same-app binding mandatory");
    Check(!PPOOwnedAdmissionSnapshot(ID,PPOSceneCapabilityFromInfo(Info(),ID,100),100),"ordinary missing-manifest policy stays closed");
    for (id digest in @[NSNull.null,@"",@"741517",@"741517F9808A10AC225C6490D2AF5BD835FF56B112464C5D53CE670D7FF92E30",@1]) Refused(Info(),digest);
    for (NSString *key in @[@"CFBundleExecutable",@"CFBundleVersion",@"CFBundleShortVersionString"]) {
        for (id value in @[@"other",@YES,@1,NSNull.null,@[],@{}]) { NSMutableDictionary *i=Info();i[key]=value;Refused(i); }
        NSMutableDictionary *i=Info();[i removeObjectForKey:key];Refused(i);
    }
    for (id families in @[@[@1],@[@2],@[@2,@1],@[@YES,@2],@[@1,@2,@3],NSNull.null]) { NSMutableDictionary *i=Info();i[@"UIDeviceFamily"]=families;Refused(i); }
    for (NSString *key in @[@"UIApplicationSceneManifest",@"UIWindowOptions",@"UnexpectedSCENEOption",@"NSExtension",@"LSBackgroundOnly"]) {
        NSMutableDictionary *i=Info();i[key]=@YES;Refused(i);
    }
    for (NSString *idValue in @[@"com.example.other",@"com.apple.MobileSMS",@"com.facebook.messenger"]) {
        NSMutableDictionary *i=Info();i[@"CFBundleIdentifier"]=idValue;
        Check(!PPOSceneCapabilityIsMessengerTrial(PPOSceneCapabilityFromInfoWithDigest(i,idValue,100,Digest)),"profile cannot cross identifiers or case");
        Check(!PPOSceneCapabilityUnknown(idValue,@"reviewed-messenger585-warm-trial",100),"reserved reason cannot bind other identifiers");
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
    printf("Messenger trial profile tests passed: %u checks; synthetic digest/profile, not installed app or hosting\n",checks);
} return 0; }
