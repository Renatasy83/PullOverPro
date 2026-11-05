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
// Observe UIKit's current ownership; never assign a root controller or force-load its view.
static BOOL CurrentRootOwned(UIWindow *window) {
    UIViewController *root=window.rootViewController;
    return window && root && root.parentViewController==nil && root.viewIfLoaded && root.viewIfLoaded.window==window;
}
@interface PPOMessengerReturnAgent:NSObject
- (void)publish;
- (void)sample;
- (void)restoreAfterDisconnect:(UIWindowScene *)scene;
- (void)disconnect:(NSNotification *)notification;
- (void)stopTimer;
- (void)startTimer;
- (void)event:(NSNotification *)notification;
- (void)prepareForExplicitRequest;
@end
@implementation PPOMessengerReturnAgent {
    __weak UIWindow *_primaryWindow;
    UIWindow *_handoffWindow; // Exact captured object, retained only through the bounded disconnect handoff.
    __weak UIWindowScene *_primaryScene;
    __weak UIViewController *_primaryRoot;
    __weak UIWindowScene *_movedScene;
    PPOReturnState _state;
    int _token;
    int _prepareToken;
    NSArray *_observers;
    dispatch_source_t _timer;
    BOOL _originalHidden;
    BOOL _needsUnhide;
    double _deadline;
}
- (void)prepareForExplicitRequest {
    if (!NSThread.isMainThread) return;
    @try {
        [self sample];
        UIApplication *app=UIApplication.sharedApplication;
        UIWindow *window=_primaryWindow;UIWindowScene *target=_primaryScene;
        BOOL noOwned=YES;
        for (UIScene *scene in app.connectedScenes) if (Owned((UIWindowScene *)scene)) noOwned=NO;
        if (_state.prepare(true,window!=nil,window && target && window.windowScene==target &&
            [app.connectedScenes containsObject:target] && !Owned(target) &&
            [target.session.role isEqual:UIWindowSceneSessionRoleApplication],CurrentRootOwned(window),
            app.applicationState==UIApplicationStateActive && target.activationState==UISceneActivationStateForegroundActive &&
            window.isKeyWindow && !window.hidden && window.windowLevel==UIWindowLevelNormal,
            app.protectedDataAvailable,noOwned,!_timer && !_handoffWindow && !_needsUnhide)) {
            _primaryRoot=window.rootViewController;_movedScene=nil;
            [self publish];
        }
    } @catch (NSException *e) { (void)e;_state.flags|=64;_state.phase=PPOReturnPhase::Refused;[self publish]; }
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
        // the comparison baseline. Never assign that old root back to a window.
        if (_state.phase==PPOReturnPhase::Captured && !ownedConnected && !(_state.flags&2) &&
            _primaryWindow.windowScene==_primaryScene && _primaryWindow.rootViewController)
            _primaryRoot=_primaryWindow.rootViewController;
        if (_state.phase==PPOReturnPhase::Captured && _primaryWindow.windowScene &&
            _primaryWindow.windowScene!=_primaryScene && !Owned(_primaryWindow.windowScene)) {
            _state.flags|=128;_state.phase=PPOReturnPhase::Refused;
        }
        if (_state.phase==PPOReturnPhase::Captured && Owned(_primaryWindow.windowScene)) {
            UIWindowScene *current=_primaryWindow.windowScene;
            UIWindow *window=_primaryWindow;
            if (_state.migration(true,window!=nil,CurrentRootOwned(window),current!=_primaryScene,
                !_primaryRoot || window.rootViewController!=_primaryRoot)) {
                _movedScene=current;_handoffWindow=window;[self startTimer];
            }
        }
        if (_state.phase==PPOReturnPhase::Restored && _needsUnhide && _primaryWindow &&
            _primaryWindow.windowScene==_primaryScene && CurrentRootOwned(_primaryWindow) &&
            app.applicationState==UIApplicationStateActive && app.protectedDataAvailable &&
            _primaryScene.activationState==UISceneActivationStateForegroundActive) {
            _primaryWindow.hidden=_originalHidden;_needsUnhide=NO;_state.flags&=~32u;
        }
        [self publish];
    } @catch (NSException *e) { (void)e;_state.flags|=64;_state.phase=PPOReturnPhase::Refused;[self publish]; }
}
- (void)restoreAfterDisconnect:(UIWindowScene *)closed {
    if (!Owned(closed) || (_movedScene && closed!=_movedScene)) return;
    [self sample];
    UIWindow *window=_primaryWindow;UIWindowScene *target=_primaryScene;
    BOOL safe=_state.canRestore(closed==_movedScene,window && window==_handoffWindow,CurrentRootOwned(window),
        target && [UIApplication.sharedApplication.connectedScenes containsObject:target],
        target && !Owned(target) && [target.session.role isEqual:UIWindowSceneSessionRoleApplication],
        target && target.screen==closed.screen,window && (!window.windowScene || window.windowScene==closed));
    if (safe) @try {
        // Public UIKit API, inside Messenger, only its exact previously tracked window.
        // Do not request a key window, app activation, input focus or change any FBScene.
        BOOL visibilityAllowed=UIApplication.sharedApplication.applicationState==UIApplicationStateActive &&
            UIApplication.sharedApplication.protectedDataAvailable && target.activationState==UISceneActivationStateForegroundActive;
        if (!visibilityAllowed) window.hidden=YES;
        window.windowScene=target;
        BOOL verified=window.windowScene==target && CurrentRootOwned(window);
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
- (void)disconnect:(NSNotification *)notification {
    UIWindowScene *closed=notification.object;
    if (!Owned(closed)) return;
    uint64_t ticket=_state.generation;
    if (!_state.acceptsDisconnect(ticket,closed==_movedScene,_primaryWindow.windowScene==closed)) return;
    // Revalidate after UIKit/app disconnection callbacks have unwound.
    // Keep only this already identified closing scene for one queue turn.
    __weak PPOMessengerReturnAgent *weakSelf=self;
    dispatch_async(dispatch_get_main_queue(),^{
        PPOMessengerReturnAgent *agent=weakSelf;
        if (agent && agent->_state.acceptsDisconnect(ticket,closed==agent->_movedScene,
            agent->_primaryWindow.windowScene==closed)) [agent restoreAfterDisconnect:closed];
    });
}
- (void)stopTimer {
    if (_timer) { dispatch_source_cancel(_timer);_timer=nil; }
    _handoffWindow=nil;
}
- (void)startTimer {
    if (_timer) return;
        _deadline=NSProcessInfo.processInfo.systemUptime+20;
        _timer=dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,0,0,dispatch_get_main_queue());
        if (!_timer) { _state.phase=PPOReturnPhase::Refused;_state.flags|=128;_handoffWindow=nil;[self publish];return; }
        __weak PPOMessengerReturnAgent *weakSelf=self;
        dispatch_source_set_timer(_timer,dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC/4),NSEC_PER_SEC/4,NSEC_PER_MSEC*25);
        dispatch_source_set_event_handler(_timer,^{
            PPOMessengerReturnAgent *agent=weakSelf;if (!agent) return;[agent sample];
            if (NSProcessInfo.processInfo.systemUptime>=agent->_deadline) {
                if (agent->_state.phase!=PPOReturnPhase::Restored) { agent->_state.phase=PPOReturnPhase::Refused;agent->_state.flags|=128; }
                [agent stopTimer];[agent publish];
            }
        });dispatch_resume(_timer);

}
- (void)event:(NSNotification *)notification {
    [self sample];
    UIWindowScene *scene=[notification.object isKindOfClass:UIWindowScene.class]?notification.object:nil;
    if (Owned(scene) && (_state.phase==PPOReturnPhase::Captured || _state.phase==PPOReturnPhase::Migrated)) {
        _state.flags|=2;[self startTimer];
    }
    [self publish];
}
- (instancetype)init {
    if (!(self=[super init])) return nil;
    _token=-1;_prepareToken=-1;
    if (notify_register_check("com.renatasy83.ppo.messenger.return.v3",&_token)!=NOTIFY_STATUS_OK) return nil;
    [self publish];
    NSNotificationCenter *center=NSNotificationCenter.defaultCenter;NSMutableArray *tokens=[NSMutableArray array];
    __weak PPOMessengerReturnAgent *weakSelf=self;
    if (notify_register_dispatch("com.renatasy83.ppo.messenger.return.prepare.v3",&_prepareToken,
        dispatch_get_main_queue(),^(int token){ (void)token;[weakSelf prepareForExplicitRequest]; })!=NOTIFY_STATUS_OK) {
        notify_cancel(_token);_token=-1;return nil;
    }
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
