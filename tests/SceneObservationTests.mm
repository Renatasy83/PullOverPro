#import "../PPOSceneObservation.h"
#import "../PPOSceneCapability.h"
#import <dispatch/dispatch.h>
#include <stdio.h>
#include <stdlib.h>
static unsigned checks,enumerations,specReads,resolutions;
static NSArray *scenes;
static void Check(BOOL yes,const char *message) { checks++; if (!yes) { fprintf(stderr,"FAIL: %s\n",message); exit(1); } }
@interface OIdentity:NSObject
@property(nonatomic,copy) NSString *bundleIdentifier;
@end
@implementation OIdentity
@end
@interface OSpecification:NSObject
@property(nonatomic,copy) NSString *uiSceneSessionRole;
@end
@implementation OSpecification
@end
@interface OOtherSpecification:OSpecification
@end
@implementation OOtherSpecification
@end
@interface ODefinition:NSObject
@property(nonatomic,strong) id clientIdentity;
@property(nonatomic,strong) id value;
- (id)specification;
@end
@implementation ODefinition
- (id)specification { specReads++; return self.value; }
@end
@interface OSettings:NSObject
@property(nonatomic) bool backgrounded;
- (bool)isBackgrounded;
@end
@implementation OSettings
- (bool)isBackgrounded { return self.backgrounded; }
@end
@interface OLayer:NSObject
@property(nonatomic) long long type;
@end
@implementation OLayer
@end
@interface OLayers:NSObject
@property(nonatomic,strong) id layers;
@end
@implementation OLayers
@end
@interface OScene:NSObject
@property(nonatomic,strong) id clientHandle;
@property(nonatomic,strong) id definition;
@property(nonatomic,copy) NSString *identifier;
@property(nonatomic,strong) id layerManager;
@property(nonatomic,strong) id settings;
@property(nonatomic) bool active;
- (bool)isActive;
@end
@implementation OScene
- (bool)isActive { return self.active; }
@end
@interface OManager:NSObject
+ (id)sharedInstance;
- (void)enumerateScenesWithBlock:(void (^)(id,BOOL *))visit;
@end
@implementation OManager
+ (id)sharedInstance { return [self new]; }
- (void)enumerateScenesWithBlock:(void (^)(id,BOOL *))visit {
    enumerations++; BOOL stop=NO;
    for (id scene in scenes) { visit(scene,&stop); if (stop) break; }
}
@end
@interface OMissing:NSObject
@end
@implementation OMissing
+ (BOOL)resolveInstanceMethod:(SEL)selector { (void)selector; resolutions++; return NO; }
@end
static NSDictionary *Classes(void) {
    return @{@"FBSceneManager":OManager.class,@"FBScene":OScene.class,@"FBSSceneDefinition":ODefinition.class,
        @"UIApplicationSceneSpecification":OSpecification.class,@"FBSceneLayerManager":OLayers.class,
        @"FBSceneLayer":OLayer.class,@"FBSSceneSettings":OSettings.class};
}
static OScene *Scene(void) {
    OIdentity *identity=[OIdentity new]; identity.bundleIdentifier=@"com.facebook.Messenger";
    OSpecification *spec=[OSpecification new]; spec.uiSceneSessionRole=@"UIWindowSceneSessionRoleApplication";
    ODefinition *definition=[ODefinition new]; definition.clientIdentity=identity; definition.value=spec;
    OLayer *layer=[OLayer new]; layer.type=1;
    OLayers *layers=[OLayers new]; layers.layers=[NSOrderedSet orderedSetWithObject:layer];
    OScene *scene=[OScene new]; scene.clientHandle=identity; scene.definition=definition;
    scene.identifier=@"PRIVATE-SCENE-TOKEN"; scene.layerManager=layers; scene.settings=[OSettings new]; scene.active=true;
    return scene;
}
static NSDictionary *Proof(void) { return PPOSceneCapabilityUnknown(@"com.facebook.Messenger",@"scene-manifest-missing",100); }
static NSDictionary *Read(void) { return PPOReadMessengerSceneObservation(Classes(),Proof(),100,YES,YES); }
static void State(NSDictionary *report,NSString *state) {
    Check([report[@"state"] isEqual:state],"expected bounded observation outcome");
    Check([report[@"hostingRequested"] isEqual:@NO] && [report[@"sceneMutationRequested"] isEqual:@NO],"read-only in all outcomes");
    NSData *json=[NSJSONSerialization dataWithJSONObject:report options:0 error:NULL];
    NSString *text=[[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
    Check(text && ![text containsString:@"PRIVATE-SCENE-TOKEN"] && ![text containsString:@"sceneIdentifier"],"no raw scene token in serializable report");
}
int main(void) { @autoreleasepool {
    scenes=@[Scene()];
    NSDictionary *r=Read(); State(r,@"observed");
    Check([r[@"normalApplicationSpecification"] boolValue] && [r[@"normalApplicationRole"] boolValue],"normal class and role observed");
    Check([r[@"layers"][@"status"] isEqual:@"sampled"] && [r[@"layers"][@"layerCount"] isEqual:@1],"existing layer probe reused");
    OScene *s=scenes[0]; ((OSettings *)s.settings).backgrounded=true; s.active=false;
    r=Read(); State(r,@"observed");
    Check([r[@"layers"][@"settingsBackgrounded"] boolValue] && ![r[@"layers"][@"sceneActive"] boolValue],"background state is observed without changing it");
    scenes=@[]; State(Read(),@"not-found");
    scenes=@[Scene(),Scene()]; unsigned before=specReads; State(Read(),@"ambiguous");
    Check(specReads==before,"ambiguous scenes never read specification/layers");
    s=Scene(); scenes=@[s]; ((ODefinition *)s.definition).value=[OOtherSpecification new];
    State(Read(),@"unsupported-source-specification");
    s=Scene(); scenes=@[s]; ((OSpecification *)((ODefinition *)s.definition).value).uiSceneSessionRole=@"OtherRole";
    State(Read(),@"unsupported-source-role");
    s=Scene(); scenes=@[s]; ((ODefinition *)s.definition).value=[OMissing new];
    State(Read(),@"unsupported-source-specification"); Check(resolutions==0,"no dynamic method resolution");
    s=Scene(); scenes=@[s]; s.settings=@"wrong";
    r=Read(); State(r,@"observed"); Check([r[@"layers"][@"status"] isEqual:@"unexpected-source-object"],"malformed layers do not authorize hosting");
    before=enumerations;
    State(PPOReadMessengerSceneObservation(Classes(),Proof(),100,YES,NO),@"disabled");
    State(PPOReadMessengerSceneObservation(Classes(),Proof(),100,NO,YES),@"framework-mismatch");
    for (id proof in @[NSNull.null,@{},PPOSceneCapabilityUnknown(@"com.example.other",@"scene-manifest-missing",100),
        PPOSceneCapabilityUnknown(@"com.facebook.Messenger",@"manifest-unknown",100),
        PPOSceneCapabilityUnknown(@"com.facebook.Messenger",@"multiple-scenes-undeclared",100)])
        State(PPOReadMessengerSceneObservation(Classes(),proof,100,YES,YES),@"not-requested");
    State(PPOReadMessengerSceneObservation(Classes(),Proof(),106,YES,YES),@"not-requested");
    State(PPOReadMessengerSceneObservation(@{},Proof(),100,YES,YES),@"missing-class");
    Check(enumerations==before,"all rejected gates precede enumeration");
    __block NSDictionary *worker=nil;
    dispatch_semaphore_t done=dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT,0), ^{
        worker=PPOReadMessengerSceneObservation(Classes(),Proof(),100,YES,YES);
        dispatch_semaphore_signal(done);
    });
    Check(dispatch_semaphore_wait(done,dispatch_time(DISPATCH_TIME_NOW,5*NSEC_PER_SEC))==0,"worker fixture completes");
    State(worker,@"wrong-thread"); Check(enumerations==before,"worker thread cannot enumerate scenes");
    printf("Scene observation tests passed: %u checks; read-only synthetic scenes, not Messenger runtime\n",checks);
} return 0; }
