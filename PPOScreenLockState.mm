#import "PPOScreenLockState.h"
#import "tools/app-launch/PPOLaunchABI.h"
#import <objc/message.h>

static NSDictionary *LockUnknown(NSString *status) {
    return @{@"status": status, @"locked": NSNull.null, @"waitingToLock": NSNull.null};
}
static Method LockMethod(Class cls, const char *name) {
    SEL selector = sel_registerName(name);
    for (NSUInteger depth = 0; cls && depth < 64; depth++, cls = class_getSuperclass(cls)) {
        unsigned count = 0;
        Method *methods = class_copyMethodList(cls, &count), found = NULL;
        for (unsigned i = 0; i < count; i++) {
            if (method_getName(methods[i]) == selector) { found = methods[i]; break; }
        }
        free(methods);
        if (found) return found;
    }
    return NULL;
}
static BOOL LockShape(Class cls, const char *name, const char *result) {
    Method method = LockMethod(cls, name);
    return method && method_getNumberOfArguments(method) == 2 &&
        PPOTypeMatches(method_copyReturnType(method), result) &&
        PPOTypeMatches(method_copyArgumentType(method, 0), @encode(id)) &&
        PPOTypeMatches(method_copyArgumentType(method, 1), @encode(SEL));
}
static BOOL LockFlagsSupported(Class cls) {
    return LockShape(cls, "isUILocked", @encode(bool)) &&
        LockShape(cls, "isWaitingToLockUI", @encode(bool));
}
template<typename T> static T LockGet(id receiver, const char *name) {
    if (!receiver || !LockShape(object_getClass(receiver), name, @encode(T)))
        [NSException raise:@"PPOLockStateABI" format:@"getter"];
    return ((T (*)(id, SEL))objc_msgSend)(receiver, sel_registerName(name));
}

NSDictionary *PPOReadScreenLockState(Class managerClass, BOOL firmwareMatches) {
    if (!NSThread.isMainThread) return LockUnknown(@"wrong-thread");
    if (!firmwareMatches) return LockUnknown(@"firmware-refused");
    @try {
        if (!managerClass || !object_isClass((id)managerClass) ||
            !LockShape(object_getClass((id)managerClass), "sharedInstanceIfExists", @encode(id)) ||
            !LockFlagsSupported(managerClass))
            return LockUnknown(@"unsupported-abi");
        // Exact23A355 sharedInstanceIfExists passes createIfNeeded=NO. It only
        // loads an existing instance; never substitute a constructing factory.
        id manager = LockGet<id>((id)managerClass, "sharedInstanceIfExists");
        if (!manager) return LockUnknown(@"manager-unavailable");
        if (![manager isKindOfClass:managerClass]) return LockUnknown(@"unexpected-manager");
        // Validate both actual receiver accessors before invoking either flag.
        if (!LockFlagsSupported(object_getClass(manager))) return LockUnknown(@"unsupported-abi");
        bool locked = LockGet<bool>(manager, "isUILocked");
        bool waiting = LockGet<bool>(manager, "isWaitingToLockUI");
        return @{@"status": @"sampled", @"locked": @(locked), @"waitingToLock": @(waiting)};
    } @catch (NSException *exception) {
        (void)exception;
        return LockUnknown(@"read-exception");
    }
}
