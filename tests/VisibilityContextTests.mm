#import "../PPOScenePresenter.h"
#import <dispatch/dispatch.h>
#include <stdio.h>
#include <stdlib.h>

// Native fake-object contracts only. These do not model UIKit visibility graph
// propagation, independent app rendering or process/background execution.
static unsigned checks, creates, modifierCalls, setters, readbacks, invalidations, activations, resolutions, contextGetterCalls;
static BOOL foreignIdentifier, failInvalidate, throwInvalidate, throwSetter;
static BOOL zeroCallback, doubleCallback, lateCallback, wrongCallbackObject, workerCallback, originalCallback;
static BOOL throwModifierBefore, throwModifierAfter, discardModifiedCopy, throwContextGetter, throwContextReadback, wrongReadbackObject;
static BOOL reenterModifier, reenterSetter;
static Class factoryClass, callbackClass;
static PPOScenePresenter *current;
static void (^retainedCallback)(id);
static void Check(BOOL condition, const char *message) {
    checks++;
    if (!condition) { fprintf(stderr, "FAIL: %s\n", message); exit(1); }
}

@interface VisibilityView : NSObject @end
@implementation VisibilityView @end
@interface VisibilityContext : NSObject {
@protected
    bool _enabled;
}
- (instancetype)initWithEnabled:(bool)enabled;
- (bool)_isVisibilityPropagationEnabled;
@end
@implementation VisibilityContext
- (instancetype)initWithEnabled:(bool)enabled {
    if ((self = [super init])) _enabled = enabled;
    return self;
}
- (bool)_isVisibilityPropagationEnabled { readbacks++; return _enabled; }
@end
@interface VisibilityMutableContext : VisibilityContext
- (void)_setVisibilityPropagationEnabled:(bool)enabled;
@end
@implementation VisibilityMutableContext
- (void)_setVisibilityPropagationEnabled:(bool)enabled {
    setters++;
    if (reenterSetter) {
        reenterSetter = NO;
        Check(![current enableVisibilityPropagationWithContextClass:VisibilityContext.class
            mutableContextClass:VisibilityMutableContext.class], "setter reentry cannot configure twice");
        Check(![current close] && ![current activate], "setter reentry cannot close/activate while busy");
    }
    if (throwSetter) [NSException raise:@"fixture" format:@"setter"];
    _enabled = enabled;
}
@end
static VisibilityContext *sharedDefault;
static id initialContext;

@interface VisibilityBasePresenter : NSObject
@property(nonatomic,copy) NSString *identifier;
@property(nonatomic) BOOL invalid;
- (id)presentationView;
- (void)activate;
- (void)invalidate;
- (bool)isInvalidated;
- (bool)isActive;
- (bool)isHosting;
@end
@implementation VisibilityBasePresenter
- (id)presentationView { return [VisibilityView new]; }
- (void)activate { activations++; }
- (void)invalidate {
    invalidations++;
    if (throwInvalidate) [NSException raise:@"fixture" format:@"invalidate"];
    if (!failInvalidate) self.invalid = YES;
}
- (bool)isInvalidated { return self.invalid; }
- (bool)isActive { return activations > 0 && !self.invalid; }
- (bool)isHosting { return activations > 0 && !self.invalid; }
@end
@interface VisibilityPresenter : VisibilityBasePresenter
@property(nonatomic,strong) id currentContext;
- (id)presentationContext;
- (void)modifyPresentationContext:(void (^)(id))body;
@end
@implementation VisibilityPresenter
- (instancetype)init {
    if ((self = [super init])) _currentContext = initialContext ?: sharedDefault;
    return self;
}
- (id)presentationContext {
    contextGetterCalls++;
    if (throwContextGetter || (throwContextReadback && contextGetterCalls > 1))
        [NSException raise:@"fixture" format:@"context"];
    return self.currentContext;
}
- (void)modifyPresentationContext:(void (^)(id))body {
    modifierCalls++;
    if (throwModifierBefore) [NSException raise:@"fixture" format:@"modifier-before"];
    if (reenterModifier) {
        reenterModifier = NO;
        Check(![current enableVisibilityPropagationWithContextClass:VisibilityContext.class
            mutableContextClass:VisibilityMutableContext.class], "modifier reentry cannot configure twice");
        Check(![current close] && ![current activate], "modifier reentry cannot close/activate while busy");
    }
    if (lateCallback) { retainedCallback = [body copy]; return; }
    if (zeroCallback) return;
    VisibilityContext *copy = [[callbackClass alloc] initWithEnabled:false];
    if (wrongCallbackObject) body(@"foreign-context");
    else if (originalCallback) body(self.currentContext);
    else if (workerCallback) {
        dispatch_group_t callbacks = dispatch_group_create();
        dispatch_group_async(callbacks, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
            Check(!NSThread.isMainThread, "worker callback fixture executes off the main thread");
            body(copy);
        });
        Check(dispatch_group_wait(callbacks, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 5)) == 0,
              "worker callback returns without a main-thread dispatch");
    } else body(copy);
    if (doubleCallback) body(copy);
    if (throwModifierAfter) [NSException raise:@"fixture" format:@"modifier-after"];
    // Publish an immutable copy for the owned presenter. Never mutate the shared
    // default; this mirrors only the copy boundary that the adapter relies on.
    if (!discardModifiedCopy)
        self.currentContext = wrongReadbackObject ? (id)@"wrong-readback-context" :
            [[VisibilityContext alloc] initWithEnabled:[copy _isVisibilityPropagationEnabled]];
}
@end
@interface VisibilityMissingPresenter : VisibilityBasePresenter @end
@implementation VisibilityMissingPresenter
+ (BOOL)resolveInstanceMethod:(SEL)selector { (void)selector; resolutions++; return NO; }
@end
@interface VisibilityBadModifier : VisibilityBasePresenter
- (id)presentationContext;
- (void)modifyPresentationContext:(id)body; // '@' must be rejected before a presumed block call.
@end
@implementation VisibilityBadModifier
- (id)presentationContext { return sharedDefault; }
- (void)modifyPresentationContext:(id)body { (void)body; modifierCalls++; abort(); }
@end
@interface VisibilityBadGetter : VisibilityBasePresenter
- (int)presentationContext;
- (void)modifyPresentationContext:(void (^)(id))body;
@end
@implementation VisibilityBadGetter
- (int)presentationContext { readbacks++; abort(); }
- (void)modifyPresentationContext:(void (^)(id))body { (void)body; modifierCalls++; abort(); }
@end
@interface VisibilityWrongBoolContext : NSObject
- (int)_isVisibilityPropagationEnabled;
@end
@implementation VisibilityWrongBoolContext
- (int)_isVisibilityPropagationEnabled { readbacks++; abort(); }
@end
@interface VisibilityMissingBoolContext : NSObject @end
@implementation VisibilityMissingBoolContext
+ (BOOL)resolveInstanceMethod:(SEL)selector { (void)selector; resolutions++; return NO; }
@end
@interface VisibilityWrongSetterContext : VisibilityContext
- (void)_setVisibilityPropagationEnabled:(int)enabled;
@end
@implementation VisibilityWrongSetterContext
- (void)_setVisibilityPropagationEnabled:(int)enabled { (void)enabled; setters++; abort(); }
@end
@interface VisibilityMissingSetterContext : VisibilityContext @end
@implementation VisibilityMissingSetterContext
+ (BOOL)resolveInstanceMethod:(SEL)selector { (void)selector; resolutions++; return NO; }
@end
@interface VisibilityManager : NSObject
- (id)createPresenterWithIdentifier:(id)identifier;
@end
static VisibilityBasePresenter *lastPresenter;
@implementation VisibilityManager
- (id)createPresenterWithIdentifier:(id)identifier {
    creates++;
    lastPresenter = [[factoryClass alloc] init];
    lastPresenter.identifier = foreignIdentifier ? @"foreign-system-presenter" : identifier;
    return lastPresenter;
}
@end
@interface VisibilityScene : NSObject
- (id)uiPresentationManager;
@end
@implementation VisibilityScene
- (id)uiPresentationManager { return [VisibilityManager new]; }
@end
static void Reset(void) {
    creates = modifierCalls = setters = readbacks = invalidations = activations = resolutions = contextGetterCalls = 0;
    foreignIdentifier = failInvalidate = throwInvalidate = throwSetter = NO;
    zeroCallback = doubleCallback = lateCallback = wrongCallbackObject = workerCallback = originalCallback = NO;
    throwModifierBefore = throwModifierAfter = discardModifiedCopy = throwContextGetter = throwContextReadback = wrongReadbackObject = NO;
    reenterModifier = reenterSetter = NO;
    retainedCallback = nil; initialContext = nil; lastPresenter = nil;
    sharedDefault = [[VisibilityContext alloc] initWithEnabled:false];
    factoryClass = VisibilityPresenter.class; callbackClass = VisibilityMutableContext.class;
}
static PPOScenePresenter *NewSession(void) {
    return [[PPOScenePresenter alloc] initWithManagerClass:VisibilityManager.class
        presenterClass:VisibilityBasePresenter.class viewClass:VisibilityView.class];
}
static void Prepare(void) {
    current = NewSession();
    Check([current prepareScene:[VisibilityScene new]], "owned presenter prepares for context configuration");
}
static BOOL Configure(Class context = VisibilityContext.class,
                      Class mutableContext = VisibilityMutableContext.class) {
    return [current enableVisibilityPropagationWithContextClass:context mutableContextClass:mutableContext];
}
static void SharedUnchanged(void) {
    Check(![sharedDefault _isVisibilityPropagationEnabled], "shared/default context remains unchanged");
}
static void ClosedFailure(void) {
    Check(invalidations == 1 && !current.poisoned && !current.presentationView,
          "failed owned configuration closes exactly once");
    Check(![current.snapshot[@"visibilityPropagationConfigured"] boolValue],
          "failed configuration is not reported as configured");
    unsigned before = modifierCalls;
    Check(!Configure() && modifierCalls == before, "failed configuration is never retried");
    SharedUnchanged();
}
int main(void) {
    @autoreleasepool {
        Reset(); Prepare();
        Check(Configure(), "configures only newly owned presenter context");
        Check([current.state isEqual:@"prepared"] && setters == 1 && modifierCalls == 1,
              "success remains prepared with exactly one setter and modifier");
        Check([current.snapshot[@"visibilityPropagationConfigured"] boolValue] &&
              [current.snapshot[@"visibilityConfigurationAttempted"] boolValue], "historical success flags recorded");
        Check([current.snapshot[@"visibilityPropagationInitiallyEnabled"] isEqual:@NO],
              "initially disabled state is distinguished from an already-enabled context");
        SharedUnchanged();
        Check(!Configure() && setters == 1 && modifierCalls == 1, "success cannot configure twice");
        Check([current activate] && activations == 1, "configured owned presenter can activate");
        Check(!Configure() && setters == 1, "active presenter cannot be reconfigured");
        Check([current close] && invalidations == 1, "configured presenter releases through normal owned close");
        Check([current.snapshot[@"visibilityPropagationConfigured"] boolValue], "configuration history persists after close");

        Reset(); current = NewSession();
        Check(!Configure() && modifierCalls == 0 && setters == 0 && invalidations == 0,
              "unprepared session does not access or mutate a presenter");
        Reset(); Prepare(); Check([current activate], "fixture activates without configuring");
        Check(!Configure() && modifierCalls == 0 && setters == 0,
              "first configuration after activation is rejected");
        Check([current close], "unconfigured active fixture closes");

        Reset(); Prepare(); lastPresenter.invalid = YES;
        Check(!Configure() && modifierCalls == 0 && setters == 0,
              "already-invalidated owned presenter cannot acquire visibility");
        ClosedFailure();

        Reset(); initialContext = [[VisibilityContext alloc] initWithEnabled:true]; Prepare();
        Check(Configure() && modifierCalls == 0 && setters == 0,
              "already-enabled owned context needs no setter or modifier");
        Check([current.snapshot[@"visibilityPropagationInitiallyEnabled"] isEqual:@YES],
              "already-enabled context is recorded without claiming a new mutation");
        Check([current.snapshot[@"visibilityPropagationConfigured"] boolValue] && [current close],
              "already-enabled context is recorded and releases normally");
        SharedUnchanged();

        for (unsigned failure = 0; failure < 13; failure++) {
            Reset(); Prepare();
            zeroCallback = failure == 0; doubleCallback = failure == 1; lateCallback = failure == 2;
            wrongCallbackObject = failure == 3; workerCallback = failure == 4;
            throwSetter = failure == 5; throwModifierBefore = failure == 6;
            throwModifierAfter = failure == 7; discardModifiedCopy = failure == 8;
            throwContextGetter = failure == 9; originalCallback = failure == 10;
            throwContextReadback = failure == 11; wrongReadbackObject = failure == 12;
            Check(!Configure(), "malformed callback, exception or failed readback refuses configuration");
            ClosedFailure();
            if (failure == 0 || failure == 2 || failure == 3 || failure == 4 || failure == 6 || failure == 9 || failure == 10)
                Check(setters == 0, "no setter for missing/late/wrong-thread/wrong-object callback or early exception");
            if (failure == 1) Check(setters == 1, "duplicate callback never sets twice");
            if (failure == 2) {
                VisibilityMutableContext *later = [[VisibilityMutableContext alloc] initWithEnabled:false];
                Check(retainedCallback != nil, "late callback fixture retained the block");
                retainedCallback(later);
                Check(setters == 0 && ![later _isVisibilityPropagationEnabled],
                      "callback after modifier returned has no mutation authority");
                retainedCallback = nil;
            }
        }
        for (unsigned failure = 0; failure < 3; failure++) {
            Reset(); factoryClass = failure == 0 ? VisibilityMissingPresenter.class :
                (failure == 1 ? VisibilityBadModifier.class : VisibilityBadGetter.class);
            Prepare(); Check(!Configure(), "missing or wrong private presenter ABI refused");
            Check(modifierCalls == 0 && setters == 0 && resolutions == 0,
                  "bad presenter ABI does not dispatch or dynamically resolve");
            ClosedFailure();
        }
        for (unsigned failure = 0; failure < 4; failure++) {
            Reset(); Prepare();
            Class context = failure == 0 ? Nil : VisibilityContext.class;
            Class mutableContext = failure == 1 ? Nil :
                (failure == 2 ? VisibilityWrongSetterContext.class : VisibilityMissingSetterContext.class);
            if (failure >= 2) callbackClass = mutableContext;
            Check(!Configure(context, mutableContext), "missing context class or setter ABI refused");
            Check(setters == 0 && resolutions == 0, "bad context setter ABI never executes or resolves");
            ClosedFailure();
        }
        for (Class cls in @[VisibilityWrongBoolContext.class, VisibilityMissingBoolContext.class]) {
            Reset(); initialContext = [cls new]; Prepare();
            Check(!Configure(cls, VisibilityMutableContext.class), "wrong/missing context readback ABI refused");
            Check(resolutions == 0, "readback ABI rejection does not dynamically resolve");
            ClosedFailure();
        }
        Reset(); initialContext = @"unrelated-context"; Prepare();
        Check(!Configure(), "context receiver class mismatch is refused"); ClosedFailure();

        for (unsigned location = 0; location < 2; location++) {
            Reset(); Prepare(); reenterModifier = location == 0; reenterSetter = location == 1;
            Check(Configure() && setters == 1 && modifierCalls == 1, "reentry cannot disrupt outer successful configuration");
            Check([current close], "reentry success fixture closes"); SharedUnchanged();
        }
        Reset(); foreignIdentifier = YES; current = NewSession();
        Check(![current prepareScene:[VisibilityScene new]] && current.poisoned, "foreign presenter quarantined");
        Check(!Configure() && setters == 0 && modifierCalls == 0 && invalidations == 0,
              "foreign presenter is never configured or invalidated");
        for (unsigned failure = 0; failure < 2; failure++) {
            Reset(); Prepare(); zeroCallback = YES;
            throwInvalidate = failure == 0; failInvalidate = failure == 1;
            Check(!Configure() && current.poisoned && invalidations == 1,
                  "configuration cleanup uncertainty poisons the session");
            Check(current.presentationView != nil && !Configure() && ![current close] && invalidations == 1,
                  "uncertain cleanup retains resources without retry");
            SharedUnchanged();
        }
        Reset(); Prepare();
        dispatch_group_t group = dispatch_group_create();
        __block BOOL workerResult = YES;
        dispatch_group_async(group, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{ workerResult = Configure(); });
        Check(dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 5)) == 0,
              "worker fixture completes");
        Check(!workerResult && modifierCalls == 0 && setters == 0 && invalidations == 0,
              "worker configuration has no private operation side effects");
        Check(Configure(), "worker rejection does not consume main-thread configuration attempt");
        Check([current close], "worker fixture cleanup");

        for (unsigned cycle = 0; cycle < 100; cycle++) {
            @autoreleasepool {
                Reset(); Prepare(); Check(Configure(), "repeated owned context configuration");
                Check([current activate] && [current close] && invalidations == 1,
                      "repeated configure/activate/close owned lifecycle");
                SharedUnchanged();
            }
        }
        printf("Visibility context tests passed: %u checks; native fixtures, not iOS background rendering\n", checks);
    }
    return 0;
}
