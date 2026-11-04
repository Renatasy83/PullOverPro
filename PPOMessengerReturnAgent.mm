#import <UIKit/UIKit.h>
#import <notify.h>
#import <CommonCrypto/CommonDigest.h>
#include <mach-o/dyld.h>
#include <mach-o/loader.h>
#include <cstring>
#import "PPOSceneCapability.h"
#include "PPOMessengerReturnState.h"

static BOOL AgentUIKitMatches(void) {
    const char *suffix="/UIKitCore.framework/UIKitCore";
    for (uint32_t i=0;i<_dyld_image_count();i++) {
        const char *name=_dyld_get_image_name(i); if (!name) continue;
        size_t n=strlen(name),s=strlen(suffix); if (n<s || strcmp(name+n-s,suffix)) continue;
        const mach_header *header=_dyld_get_image_header(i); if (!header || header->magic!=MH_MAGIC_64) return NO;
        const auto *wide=reinterpret_cast<const mach_header_64 *>(header);
        if (wide->sizeofcmds>65536 || wide->ncmds>1024) return NO;
        const uint8_t *cursor=reinterpret_cast<const uint8_t *>(wide+1); size_t remaining=wide->sizeofcmds;
        for (uint32_t j=0;j<wide->ncmds;j++) {
            if (remaining<sizeof(load_command)) return NO;
            const auto *load=reinterpret_cast<const load_command *>(cursor);
            if (load->cmdsize<sizeof(load_command) || load->cmdsize>remaining) return NO;
            if (load->cmd==LC_UUID) {
                if (load->cmdsize!=sizeof(uuid_command)) return NO;
                return [[[NSUUID alloc] initWithUUIDBytes:reinterpret_cast<const uuid_command *>(load)->uuid].UUIDString
                    isEqual:@"C98EAB32-B273-3430-B0C5-46522C904CBB"];
            }
            remaining-=load->cmdsize;cursor+=load->cmdsize;
        }
    }
    return NO;
}
static BOOL AgentProfile(void) {
    if (![NSBundle.mainBundle.bundleIdentifier isEqual:@"com.facebook.Messenger"] || !AgentUIKitMatches()) return NO;
    NSString *path=[NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"Info.plist"];
    NSDictionary *attrs=[NSFileManager.defaultManager attributesOfItemAtPath:path error:NULL];
    if (!attrs || [attrs fileSize]>262144) return NO;
    NSData *data=[NSData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:NULL];
    if (!data || data.length>262144) return NO;
    unsigned char digest[CC_SHA256_DIGEST_LENGTH]; CC_SHA256(data.bytes,(CC_LONG)data.length,digest);
    NSMutableString *hex=[NSMutableString string];
    for (unsigned i=0;i<CC_SHA256_DIGEST_LENGTH;i++) [hex appendFormat:@"%02x",digest[i]];
    id info=[NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:NULL error:NULL];
    return PPOSceneCapabilityIsMessengerTrial(PPOSceneCapabilityFromInfoWithDigest(info,@"com.facebook.Messenger",
        NSProcessInfo.processInfo.systemUptime,hex));
}
static BOOL Owned(UIWindowScene *scene) {
    if (![scene isKindOfClass:UIWindowScene.class] || ![scene.session.role isEqual:UIWindowSceneSessionRoleApplication]) return NO;
    NSString *name=scene.session.persistentIdentifier,*prefix=@"com.renatasy83.ppo.scene.";
    return [name hasPrefix:prefix] && name.length==prefix.length+36 &&
        [[NSUUID alloc] initWithUUIDString:[name substringFromIndex:prefix.length]]!=nil;
}
@interface PPOMessengerReturnAgent:NSObject
@end
@implementation PPOMessengerReturnAgent {
    __weak UIWindow *_primaryWindow;
    __weak UIWindowScene *_primaryScene;
    __weak UIViewController *_primaryRoot;
    __weak UIWindowScene *_movedScene;
    PPOReturnState _state;
    int _token;
    NSArray *_observers;
    dispatch_source_t _timer;
    BOOL _originalHidden;
    BOOL _needsUnhide;
    double _deadline;
}
- (void)publish {
    if (_token>=0) (void)notify_set_state(_token,_state.packed(NSProcessInfo.processInfo.systemUptime));
}
- (void)sample {
    if (!NSThread.isMainThread) return;
    @try {
        UIApplication *app=UIApplication.sharedApplication;
        if (_state.phase==PPOReturnPhase::Waiting && app.applicationState==UIApplicationStateActive && app.protectedDataAvailable) {
            NSMutableArray<UIWindow *> *candidates=[NSMutableArray array];
            for (UIScene *scene in app.connectedScenes) if ([scene isKindOfClass:UIWindowScene.class] && !Owned((UIWindowScene *)scene) &&
                [scene.session.role isEqual:UIWindowSceneSessionRoleApplication] && scene.activationState==UISceneActivationStateForegroundActive) {
                for (UIWindow *window in ((UIWindowScene *)scene).windows)
                    if (window.isKeyWindow && window.windowLevel==UIWindowLevelNormal && window.rootViewController) [candidates addObject:window];
            }
            if (candidates.count==1 && _state.capture(true,true)) {
                _primaryWindow=candidates[0];_primaryScene=_primaryWindow.windowScene;
                _primaryRoot=_primaryWindow.rootViewController;_originalHidden=_primaryWindow.hidden;
            }
        }
        BOOL ownedConnected=NO;
        for (UIScene *scene in app.connectedScenes) if (Owned((UIWindowScene *)scene)) { ownedConnected=YES;_state.flags|=2; }
        // A legitimate app root replacement before any PPO connection becomes
        // the current baseline. Never adopt a changed root during the trial.
        if (_state.phase==PPOReturnPhase::Captured && !ownedConnected && !(_state.flags&2) &&
            _primaryWindow.windowScene==_primaryScene && _primaryWindow.rootViewController)
            _primaryRoot=_primaryWindow.rootViewController;
        if (_state.phase==PPOReturnPhase::Captured && _primaryWindow.windowScene &&
            _primaryWindow.windowScene!=_primaryScene && !Owned(_primaryWindow.windowScene)) {
            _state.flags|=128;_state.phase=PPOReturnPhase::Refused;
        }
        if (_state.phase==PPOReturnPhase::Captured && Owned(_primaryWindow.windowScene)) {
            UIWindowScene *current=_primaryWindow.windowScene;
            if (_state.migration(true,_primaryWindow && _primaryRoot && _primaryWindow.rootViewController==_primaryRoot,current!=_primaryScene))
                _movedScene=current;
        }
        if (_state.phase==PPOReturnPhase::Restored && _needsUnhide && _primaryWindow && _primaryRoot &&
            _primaryWindow.windowScene==_primaryScene && _primaryWindow.rootViewController==_primaryRoot &&
            app.applicationState==UIApplicationStateActive && app.protectedDataAvailable &&
            _primaryScene.activationState==UISceneActivationStateForegroundActive) {
            _primaryWindow.hidden=_originalHidden;_needsUnhide=NO;_state.flags&=~32u;
        }
        [self publish];
    } @catch (NSException *e) { (void)e;_state.flags|=64;_state.phase=PPOReturnPhase::Refused;[self publish]; }
}
- (void)disconnect:(NSNotification *)notification {
    UIWindowScene *closed=notification.object;
    if (!Owned(closed) || (_movedScene && closed!=_movedScene)) return;
    [self sample];
    UIWindow *window=_primaryWindow;UIWindowScene *target=_primaryScene;
    BOOL safe=_state.canRestore(closed==_movedScene,window!=nil,_primaryRoot && window.rootViewController==_primaryRoot,
        target && [UIApplication.sharedApplication.connectedScenes containsObject:target],
        target && !Owned(target) && [target.session.role isEqual:UIWindowSceneSessionRoleApplication],
        target && target.screen==closed.screen,window && (!window.windowScene || window.windowScene==closed));
    if (safe) @try {
        // Public UIKit API, inside Messenger, only its exact previously tracked window.
        // Do not request a key window, app activation, input focus or change any FBScene.
        window.hidden=YES; window.windowScene=target;
        BOOL verified=window.windowScene==target && window.rootViewController==_primaryRoot;
        _needsUnhide=verified;
        if (verified && UIApplication.sharedApplication.applicationState==UIApplicationStateActive &&
            UIApplication.sharedApplication.protectedDataAvailable && target.activationState==UISceneActivationStateForegroundActive)
            { window.hidden=_originalHidden; _needsUnhide=NO; }
        if (_needsUnhide) _state.flags|=32;
        _state.finish(verified);
    } @catch (NSException *e) { (void)e;_state.flags|=64;_state.finish(false); }
    if (!safe && _state.phase!=PPOReturnPhase::Restored) {
        _state.phase=PPOReturnPhase::Refused;_state.flags|=128;
    }
    [self stopTimer];[self publish];
}
- (void)stopTimer { if (_timer) { dispatch_source_cancel(_timer);_timer=nil; } }
- (void)event:(NSNotification *)notification {
    [self sample];
    UIWindowScene *scene=[notification.object isKindOfClass:UIWindowScene.class]?notification.object:nil;
    if (Owned(scene) && !_timer && _state.phase==PPOReturnPhase::Captured) {
        _state.flags|=2;_deadline=NSProcessInfo.processInfo.systemUptime+20;
        _timer=dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,0,0,dispatch_get_main_queue());
        if (!_timer) return;
        __weak PPOMessengerReturnAgent *weakSelf=self;
        dispatch_source_set_timer(_timer,dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC/4),NSEC_PER_SEC/4,NSEC_PER_MSEC*25);
        dispatch_source_set_event_handler(_timer,^{
            PPOMessengerReturnAgent *agent=weakSelf;if (!agent) return;[agent sample];
            if (NSProcessInfo.processInfo.systemUptime>=agent->_deadline) [agent stopTimer];
        });dispatch_resume(_timer);
    }
    [self publish];
}
- (instancetype)init {
    if (!(self=[super init])) return nil;
    _token=-1;if (notify_register_check("com.renatasy83.ppo.messenger.return.v1",&_token)!=NOTIFY_STATUS_OK) return nil;
    [self publish];
    NSNotificationCenter *center=NSNotificationCenter.defaultCenter;NSMutableArray *tokens=[NSMutableArray array];
    __weak PPOMessengerReturnAgent *weakSelf=self;
    for (NSString *name in @[UIWindowDidBecomeKeyNotification,UIWindowDidBecomeVisibleNotification,
        UIApplicationDidBecomeActiveNotification,UISceneDidActivateNotification,UISceneWillDeactivateNotification])
        [tokens addObject:[center addObserverForName:name object:nil queue:NSOperationQueue.mainQueue
            usingBlock:^(NSNotification *note){ [weakSelf event:note]; }]];
    [tokens addObject:[center addObserverForName:UISceneDidDisconnectNotification object:nil queue:NSOperationQueue.mainQueue
        usingBlock:^(NSNotification *note){ [weakSelf disconnect:note]; }]];
    _observers=[tokens copy];[self sample];return self;
}
@end
__attribute__((constructor)) static void PPOReturnStart(void) {
    dispatch_async(dispatch_get_main_queue(), ^{ @autoreleasepool { @try {
        if (AgentProfile()) { static PPOMessengerReturnAgent *agent;agent=[PPOMessengerReturnAgent new];(void)agent; }
    } @catch (NSException *e) { (void)e; } } });
}
