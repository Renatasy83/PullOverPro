#import "../PPOScenePresenter.h"
#import <dispatch/dispatch.h>
#include <stdio.h>
#include <stdlib.h>

static unsigned checks, creates, activations, invalidations, resolutions;
static BOOL badView, foreignID, throwCreate, throwView, throwActivate, throwClose, failInvalidate;
static BOOL reenter;
static PPOScenePresenter *current;
static void Check(BOOL ok, const char *message) {
    checks++;
    if (!ok) { fprintf(stderr, "FAIL: %s\n", message); exit(1); }
}
@interface FixtureView : NSObject @end
@implementation FixtureView @end
@interface FixturePresenter : NSObject
@property(nonatomic,copy) NSString *identifier;
@property(nonatomic) BOOL invalid;
- (id)presentationView;
- (void)activate;
- (void)invalidate;
- (bool)isInvalidated;
- (bool)isActive;
- (bool)isHosting;
@end
@implementation FixturePresenter
- (id)presentationView {
    if (throwView) [NSException raise:@"fixture" format:@"view"];
    return badView ? (id)@"bad" : [FixtureView new];
}
- (void)activate {
    activations++;
    if (reenter) Check(![current close], "reentrant close refuses while activating");
    if (throwActivate) [NSException raise:@"fixture" format:@"activate"];
}
- (void)invalidate {
    invalidations++;
    if (throwClose) [NSException raise:@"fixture" format:@"close"];
    if (!failInvalidate) self.invalid = YES;
}
- (bool)isInvalidated { return self.invalid; }
- (bool)isActive { return activations > 0 && !self.invalid; }
- (bool)isHosting { return false; } // may be asynchronous, never equate with pixels
@end
@interface FixtureManager : NSObject
- (id)createPresenterWithIdentifier:(id)identifier;
@end
@implementation FixtureManager
- (id)createPresenterWithIdentifier:(id)identifier {
    creates++;
    if (throwCreate) [NSException raise:@"fixture" format:@"factory"];
    FixturePresenter *p = [FixturePresenter new];
    p.identifier = foreignID ? @"system-owned" : identifier;
    return p;
}
@end
@interface FixtureScene : NSObject
- (id)uiPresentationManager;
@end
@implementation FixtureScene
- (id)uiPresentationManager { return [FixtureManager new]; }
@end
@interface BadManager : NSObject
- (int)createPresenterWithIdentifier:(id)identifier;
@end
@implementation BadManager
- (int)createPresenterWithIdentifier:(id)identifier { (void)identifier; abort(); }
@end
@interface MissingScene : NSObject @end
@implementation MissingScene
+ (BOOL)resolveInstanceMethod:(SEL)sel { (void)sel; resolutions++; return NO; }
@end
@interface BadPresenter : NSObject
- (int)activate;
@end
@implementation BadPresenter
- (int)activate { abort(); }
@end

@interface WrongManagerScene : FixtureScene @end
@implementation WrongManagerScene
- (id)uiPresentationManager { return @"not a manager"; }
@end
@interface WrongFactory : FixtureManager @end
@implementation WrongFactory
- (id)createPresenterWithIdentifier:(id)identifier { (void)identifier; creates++; return @"foreign object"; }
@end
@interface WrongFactoryScene : FixtureScene @end
@implementation WrongFactoryScene
- (id)uiPresentationManager { return [WrongFactory new]; }
@end
@interface BadGetterScene : NSObject
- (int)uiPresentationManager;
@end
@implementation BadGetterScene
- (int)uiPresentationManager { abort(); }
@end

static PPOScenePresenter *NewSession(Class manager = FixtureManager.class,
                                     Class presenter = FixturePresenter.class) {
    return [[PPOScenePresenter alloc] initWithManagerClass:manager presenterClass:presenter
        viewClass:FixtureView.class];
}
static void Reset(void) {
    badView = foreignID = throwCreate = throwView = throwActivate = throwClose = failInvalidate = reenter = NO;
    creates = activations = invalidations = resolutions = 0;
}
int main(void) {
    @autoreleasepool {
        Reset();
        current = NewSession();
        Check([current prepareScene:[FixtureScene new]], "prepares owned presenter");
        Check([current.presentationView isKindOfClass:FixtureView.class], "validates view");
        Check(![current prepareScene:[FixtureScene new]] && creates == 1, "no duplicate creation");
        reenter = YES;
        Check([current activate] && activations == 1, "activation once");
        Check(![current activate] && activations == 1, "no repeated activation");
        Check(![current.snapshot[@"hostingAfterActivation"] boolValue] &&
              ![current.snapshot[@"visiblePixelsVerified"] boolValue], "flags do not establish rendering");
        Check([current close] && invalidations == 1 && !current.presentationView, "cleanup releases owned references");
        Check([current close] && invalidations == 1, "idempotent close");
        Check(![current activate] && ![current prepareScene:[FixtureScene new]], "closed session cannot reopen");
        for (unsigned failure = 0; failure < 3; failure++) {
            Reset(); badView = failure == 0; throwView = failure == 1;
            current = NewSession();
            if (failure < 2) Check(![current prepareScene:[FixtureScene new]], "bad view refuses preparation");
            else {
                Check([current prepareScene:[FixtureScene new]], "prepare before activation exception");
                throwActivate = YES;
                Check(![current activate], "activation exception contained");
            }
            Check(invalidations == 1 && !current.poisoned && !current.presentationView,
                "owned failure invokes cleanup exactly once");
        }
        Reset(); foreignID = YES; current = NewSession();
        Check(![current prepareScene:[FixtureScene new]] && current.poisoned, "foreign identifier quarantined");
        Check(![current close] && invalidations == 0 && activations == 0, "never invalidates foreign presenter");
        Reset(); throwCreate = YES; current = NewSession();
        Check(![current prepareScene:[FixtureScene new]] && current.poisoned, "throwing factory stops retries");
        Check(![current prepareScene:[FixtureScene new]] && creates == 1, "factory never retried");
        for (unsigned failure = 0; failure < 2; failure++) {
            Reset(); current = NewSession();
            Check([current prepareScene:[FixtureScene new]], "prepare cleanup failure fixture");
            throwClose = failure == 0; failInvalidate = failure == 1;
            Check(![current close] && current.poisoned, "cleanup failure poisons session");
            Check(![current close] && invalidations == 1, "unknown cleanup is not automatically retried");
            Check(current.presentationView != nil, "unknown ownership retains references");
        }
        Reset(); current = NewSession();
        Check(![current prepareScene:[WrongManagerScene new]] && creates == 0,
              "actual manager type checked before factory invocation");
        current = NewSession();
        Check(![current prepareScene:[BadGetterScene new]] && creates == 0,
              "scene getter return ABI rejected before call");
        current = NewSession();
        Check(![current prepareScene:[WrongFactoryScene new]] && current.poisoned && invalidations == 0,
              "unexpected factory object quarantined without invalidation");
        Reset(); current = NewSession(BadManager.class);
        Check(![current prepareScene:[FixtureScene new]] && creates == 0, "factory ABI checked before invocation");
        current = NewSession(FixtureManager.class, BadPresenter.class);
        Check(![current prepareScene:[FixtureScene new]] && creates == 0, "all presenter ABIs checked before creation");
        current = NewSession();
        Check(![current prepareScene:[MissingScene new]] && resolutions == 0, "no dynamic method resolution");
        Reset(); current = NewSession();
        dispatch_group_t group = dispatch_group_create();
        dispatch_group_async(group, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
            Check(![current prepareScene:[FixtureScene new]] && ![current activate] && ![current close],
                "worker rejected without private calls");
        });
        Check(dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC)) == 0,
              "worker guard returns immediately");
        Check(creates == 0 && activations == 0 && invalidations == 0, "worker has no side effects");
        // Exercise the actual adapter's ownership transitions repeatedly with
        // fake receivers. This does not reproduce UIKit owner arbitration.
        for (unsigned cycle = 0; cycle < 100; cycle++) {
            @autoreleasepool {
                Reset(); current = NewSession();
                Check([current prepareScene:[FixtureScene new]], "repeat presenter preparation");
                Check([current activate], "repeat presenter activation");
                Check([current close] && invalidations == 1 && !current.presentationView,
                      "repeat presenter releases its owned references");
            }
        }
        printf("Scene presenter tests passed: %u checks; native fixtures, not iOS hosting\n", checks);
    }
    return 0;
}
