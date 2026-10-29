#import "PPOSceneLayerProbe.h"
#import "tools/app-launch/PPOLaunchABI.h"
#import <objc/message.h>

static Method ProbeMethod(Class cls, SEL selector) {
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
static BOOL ProbeShape(id receiver, const char *name, const char *result) {
    if (!receiver) return NO;
    Method method = ProbeMethod(object_getClass(receiver), sel_registerName(name));
    return method && method_getNumberOfArguments(method) == 2 &&
        PPOTypeMatches(method_copyReturnType(method), result) &&
        PPOTypeMatches(method_copyArgumentType(method, 0), @encode(id)) &&
        PPOTypeMatches(method_copyArgumentType(method, 1), @encode(SEL));
}
template<typename T> static T ProbeGet(id receiver, const char *name) {
    if (!ProbeShape(receiver, name, @encode(T)))
        [NSException raise:@"PPOProbeABI" format:@"getter"];
    return ((T (*)(id, SEL))objc_msgSend)(receiver, sel_registerName(name));
}
NSDictionary *PPOReadSceneLayerState(id scene, Class sceneClass, Class managerClass,
                                    Class layerClass, Class settingsClass) {
    if (!NSThread.isMainThread) return @{@"status": @"wrong-thread"};
    @try {
        if (!sceneClass || !managerClass || !layerClass || !settingsClass ||
            ![scene isKindOfClass:sceneClass]) return @{@"status": @"unexpected-scene"};
        // Validate all scene accessors before invoking any of them.
        if (!ProbeShape(scene, "layerManager", @encode(id)) ||
            !ProbeShape(scene, "settings", @encode(id)) ||
            !ProbeShape(scene, "isActive", @encode(bool)))
            return @{@"status": @"unsupported-scene-abi"};
        id manager = ProbeGet<id>(scene, "layerManager");
        id settings = ProbeGet<id>(scene, "settings");
        if (![manager isKindOfClass:managerClass] || ![settings isKindOfClass:settingsClass])
            return @{@"status": @"unexpected-source-object"};
        if (!ProbeShape(manager, "layers", @encode(id)) ||
            !ProbeShape(settings, "isBackgrounded", @encode(bool)))
            return @{@"status": @"unsupported-source-abi"};
        id layers = ProbeGet<id>(manager, "layers");
        if (![layers isKindOfClass:NSOrderedSet.class])
            return @{@"status": @"unexpected-layers"};
        NSUInteger count = [layers count];
        if (count > 32) return @{@"status": @"layer-limit", @"layerCount": @(count)};
        NSMutableArray *types = [NSMutableArray arrayWithCapacity:count];
        for (NSUInteger i = 0; i < count; i++) {
            id layer = [layers objectAtIndex:i];
            if (![layer isKindOfClass:layerClass] || !ProbeShape(layer, "type", @encode(long long)))
                return @{@"status": @"unsupported-layer"};
            [types addObject:@(ProbeGet<long long>(layer, "type"))];
        }
        return @{@"status": @"sampled", @"layerCount": @(count), @"layerTypes": types,
            @"sceneActive": @(ProbeGet<bool>(scene, "isActive")),
            @"settingsBackgrounded": @(ProbeGet<bool>(settings, "isBackgrounded"))};
    } @catch (NSException *exception) {
        (void)exception;
        return @{@"status": @"read-exception"};
    }
}
