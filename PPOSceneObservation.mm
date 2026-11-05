#import "PPOSceneObservation.h"
#import "PPOScenePreflight.h"
#import "PPOSceneLayerProbe.h"
#import "PPOSceneCapability.h"
#import "tools/app-launch/PPOLaunchABI.h"
#import <objc/message.h>
#include <sys/stat.h>
#include <errno.h>

static Method ObservationMethod(Class cls, SEL selector) {
    for (NSUInteger depth=0; cls && depth<64; depth++,cls=class_getSuperclass(cls)) {
        unsigned count=0; Method *methods=class_copyMethodList(cls,&count), found=NULL;
        for (unsigned i=0;i<count;i++) if (method_getName(methods[i])==selector) { found=methods[i]; break; }
        free(methods); if (found) return found;
    }
    return NULL;
}
static id ObservationGet(id receiver, const char *name) {
    SEL selector=sel_registerName(name);
    if (!receiver || !PPOGetterABI(ObservationMethod(object_getClass(receiver),selector)))
        [NSException raise:@"PPOObservationABI" format:@"getter"];
    return ((id (*)(id,SEL))objc_msgSend)(receiver,selector);
}
NSDictionary *PPOReadMessengerSceneObservation(NSDictionary<NSString *, Class> *classes,
    NSDictionary *capability, NSTimeInterval now, BOOL frameworkMatches, BOOL enabled) {
    NSMutableDictionary *report=[@{@"schema":@1,@"version":@"1.0.8~rc9",
        @"hostingRequested":@NO,@"sceneMutationRequested":@NO} mutableCopy];
    if (!NSThread.isMainThread) { report[@"state"]=@"wrong-thread"; return report; }
    if (!enabled) { report[@"state"]=@"disabled"; return report; }
    NSDictionary *proof=PPOSceneCapabilityNormalize(capability);
    if (!proof || !PPOSceneCapabilityFresh(proof,now) ||
        ![proof[@"bundleIdentifier"] isEqual:@"com.facebook.Messenger"] ||
        ![proof[@"status"] isEqual:@"unknown"] ||
        ![proof[@"reason"] isEqual:@"scene-manifest-missing"]) {
        report[@"state"]=@"not-requested"; return report;
    }
    report[@"bundleIdentifier"]=@"com.facebook.Messenger";
    if (!frameworkMatches) { report[@"state"]=@"framework-mismatch"; return report; }
    @try {
        NSArray *names=@[@"FBSceneManager",@"FBScene",@"FBSSceneDefinition",
            @"UIApplicationSceneSpecification",@"FBSceneLayerManager",@"FBSceneLayer",@"FBSSceneSettings"];
        for (NSString *name in names) if (!classes[name] || !object_isClass((id)classes[name])) {
            report[@"state"]=@"missing-class"; return report;
        }
        id source=nil;
        NSDictionary *selection=PPOFindUniqueScene(classes[@"FBSceneManager"],classes[@"FBScene"],
            @"com.facebook.Messenger",&source);
        // Deliberately omit scene identifiers, pointers, paths and content.
        report[@"state"]=selection[@"state"];
        report[@"inspected"]=selection[@"inspected"];
        report[@"matched"]=selection[@"matched"];
        if (!source || ![selection[@"state"] isEqual:@"unique"]) return report;
        id definition=ObservationGet(source,"definition");
        if (![definition isKindOfClass:classes[@"FBSSceneDefinition"]]) {
            report[@"state"]=@"unexpected-definition"; return report;
        }
        id specification=ObservationGet(definition,"specification");
        BOOL normal=object_getClass(specification)==classes[@"UIApplicationSceneSpecification"];
        report[@"normalApplicationSpecification"]=@(normal);
        if (!normal) { report[@"state"]=@"unsupported-source-specification"; return report; }
        id role=ObservationGet(specification,"uiSceneSessionRole");
        BOOL normalRole=[role isKindOfClass:NSString.class] && [role isEqual:@"UIWindowSceneSessionRoleApplication"];
        report[@"normalApplicationRole"]=@(normalRole);
        if (!normalRole) { report[@"state"]=@"unsupported-source-role"; return report; }
        report[@"layers"]=PPOReadSceneLayerState(source,classes[@"FBScene"],classes[@"FBSceneLayerManager"],
            classes[@"FBSceneLayer"],classes[@"FBSSceneSettings"]);
        report[@"state"]=@"observed";
    } @catch (NSException *exception) {
        (void)exception; report[@"state"]=@"read-exception";
    }
    return [report copy];
}
NSDictionary *PPOObserveMessengerScene(NSDictionary *capability) {
    struct stat marker={};
    BOOL enabled=lstat("/var/mobile/.ppo_disable",&marker)!=0 && errno==ENOENT;
    NSDictionary *frameworks=PPOSceneFrameworkIdentity();
    NSMutableDictionary *classes=[NSMutableDictionary dictionary];
    if (NSThread.isMainThread && enabled && [frameworks[@"matches"] boolValue]) {
        for (NSString *name in @[@"FBSceneManager",@"FBScene",@"FBSSceneDefinition",
            @"UIApplicationSceneSpecification",@"FBSceneLayerManager",@"FBSceneLayer",@"FBSSceneSettings"]) {
            Class cls=objc_lookUpClass(name.UTF8String); if (cls) classes[name]=cls;
        }
    }
    NSMutableDictionary *report=[PPOReadMessengerSceneObservation(classes,capability,
        NSProcessInfo.processInfo.systemUptime,[frameworks[@"matches"] boolValue],enabled) mutableCopy];
    report[@"frameworks"]=frameworks;
    return [report copy];
}
