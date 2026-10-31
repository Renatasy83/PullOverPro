#import "PPOScenePreflight.h"
#import "PPOBridgeProtocol.h"
#import "PPOOwnedApplicationPolicy.h"
#import "tools/app-launch/PPOLaunchABI.h"
#import <objc/message.h>
#include <mach-o/dyld.h>
#include <mach-o/loader.h>
#include <sys/stat.h>
#include <errno.h>

static NSDictionary *PPOSceneResult(NSString *state, NSUInteger inspected,
    NSUInteger matched, NSString *identifier) {
    NSMutableDictionary *result = [@{@"state": state, @"inspected": @(inspected),
        @"matched": @(matched), @"hostingRequested": @NO} mutableCopy];
    if (identifier) result[@"sceneIdentifier"] = identifier;
    return result;
}

static BOOL PPOSceneText(id text) {
    return [text isKindOfClass:NSString.class] && [(NSString *)text length] > 0 &&
        [(NSString *)text length] <= 512;
}

// Read declared method tables without asking a private class to resolve a
// missing selector. A missing method must not execute +resolveInstanceMethod:.
static Method PPOSceneMethod(Class cls, SEL selector, BOOL factory = NO) {
    if (factory && cls) cls = object_getClass((id)cls);
    for (NSUInteger depth = 0; cls && depth < 64; depth++, cls = class_getSuperclass(cls)) {
        unsigned int count = 0;
        Method *methods = class_copyMethodList(cls, &count);
        Method found = NULL;
        for (unsigned int index = 0; index < count; index++) {
            if (method_getName(methods[index]) == selector) { found = methods[index]; break; }
        }
        free(methods);
        if (found) return found;
    }
    return NULL;
}

// Getter names below use Cocoa's +0 accessor convention. Recheck each actual
// receiver's method before dispatch; never use KVC or invoke a guessed IMP.
static id PPOSceneGet(id receiver, const char *name, BOOL *valid) {
    if (!*valid || !receiver) { *valid = NO; return nil; }
    SEL selector = sel_registerName(name);
    Method method = PPOSceneMethod(object_getClass(receiver), selector);
    if (!PPOGetterABI(method)) { *valid = NO; return nil; }
    return ((id (*)(id, SEL))objc_msgSend)(receiver, selector);
}

static BOOL PPOSceneEnumeratorABI(Method method) {
    return method && method_getNumberOfArguments(method) == 3 &&
        PPOTypeMatches(method_copyReturnType(method), @encode(void)) &&
        PPOTypeMatches(method_copyArgumentType(method, 0), @encode(id)) &&
        PPOTypeMatches(method_copyArgumentType(method, 1), @encode(SEL)) &&
        PPOTypeMatches(method_copyArgumentType(method, 2), "@?");
}

NSDictionary *PPOReadSceneSelection(Class managerClass, Class sceneClass, NSString *bundleIdentifier) {
    return PPOFindUniqueScene(managerClass, sceneClass, bundleIdentifier, NULL);
}

NSDictionary *PPOFindUniqueScene(Class managerClass, Class sceneClass, NSString *bundleIdentifier,
                               id __strong *sceneOut) {
    if (sceneOut) *sceneOut = nil;
    if (!NSThread.isMainThread) return PPOSceneResult(@"wrong-thread", 0, 0, nil);
    if (!PPOBridgeValidIdentifier(bundleIdentifier) ||
        [bundleIdentifier isEqual:@"com.apple.springboard"] ||
        [bundleIdentifier isEqual:@"com.apple.backboardd"])
        return PPOSceneResult(@"invalid-application", 0, 0, nil);
    if (!managerClass || !sceneClass ||
        !PPOGetterABI(PPOSceneMethod(managerClass, sel_registerName("sharedInstance"), YES)) ||
        !PPOSceneEnumeratorABI(PPOSceneMethod(managerClass, sel_registerName("enumerateScenesWithBlock:"))))
        return PPOSceneResult(@"unsupported-abi", 0, 0, nil);
    __block NSUInteger inspected = 0, matched = 0;
    __block NSString *selected = nil;
    __block id selectedScene = nil;
    __block NSString *failure = nil;
    NSTimeInterval deadline = NSProcessInfo.processInfo.systemUptime + 0.1;
    @try {
        BOOL valid = YES;
        id manager = PPOSceneGet((id)managerClass, "sharedInstance", &valid);
        if (!valid || ![manager isKindOfClass:managerClass] ||
            !PPOSceneEnumeratorABI(PPOSceneMethod(object_getClass(manager),
                sel_registerName("enumerateScenesWithBlock:"))))
            return PPOSceneResult(@"unsupported-manager", 0, 0, nil);
        // Callback shape is supported by exact23A355 implementation at
        // 0x1a8419a94: scene in x1, local stop-byte pointer in x2.
        // No retained callback or asynchronous completion is assumed/allowed.
        void (^visit)(id, BOOL *) = ^(id scene, BOOL *stop) {
            if (!stop) { failure = @"invalid-callback"; return; }
            if (failure) { *stop = YES; return; }
            if (inspected >= 256 || NSProcessInfo.processInfo.systemUptime > deadline) {
                failure = @"enumeration-limit"; *stop = YES; return;
            }
            inspected++;
            if (![scene isKindOfClass:sceneClass]) { failure = @"unexpected-scene"; *stop = YES; return; }
            BOOL gettersValid = YES;
            id handle = PPOSceneGet(scene, "clientHandle", &gettersValid);
            if (gettersValid && !handle) return;
            id handleID = PPOSceneGet(handle, "bundleIdentifier", &gettersValid);
            if (!gettersValid) { failure = @"unsupported-identity"; *stop = YES; return; }
            // System scenes may have no application bundle identifier.
            if (!handleID) return;
            if (!PPOSceneText(handleID)) { failure = @"invalid-identity"; *stop = YES; return; }
            if (![handleID isEqual:bundleIdentifier]) return;
            id definition = PPOSceneGet(scene, "definition", &gettersValid);
            id identity = PPOSceneGet(definition, "clientIdentity", &gettersValid);
            id definitionID = PPOSceneGet(identity, "bundleIdentifier", &gettersValid);
            id sceneID = PPOSceneGet(scene, "identifier", &gettersValid);
            if (!gettersValid || !PPOSceneText(sceneID) || ![definitionID isEqual:bundleIdentifier]) {
                failure = @"conflicting-identity"; *stop = YES; return;
            }
            matched++;
            if (matched == 1) { selected = [sceneID copy]; selectedScene = scene; }
            // A duplicate callback is ambiguous too; never select a first match.
            if (matched > 1) { failure = @"ambiguous"; *stop = YES; }
        };
        ((void (*)(id, SEL, id))objc_msgSend)(manager,
            sel_registerName("enumerateScenesWithBlock:"), visit);
    } @catch (NSException *exception) {
        (void)exception; failure = @"scene-exception";
    }
    if (sceneOut && !failure && matched == 1) *sceneOut = selectedScene;
    return PPOSceneResult(failure ?: (matched == 1 ? @"unique" : @"not-found"),
        inspected, matched, failure ? nil : selected);
}

static NSString *PPOUUIDForLoadedImage(const char *suffix) {
    uint32_t images = _dyld_image_count();
    for (uint32_t index = 0; index < images; index++) {
        const char *name = _dyld_get_image_name(index);
        if (!name) continue;
        size_t length = strlen(name), tail = strlen(suffix);
        if (length < tail || strcmp(name + length - tail, suffix)) continue;
        // Headers are owned/validated by dyld, not supplied by a request file.
        const mach_header *header = _dyld_get_image_header(index);
        if (!header || header->magic != MH_MAGIC_64) return nil;
        const mach_header_64 *wide = reinterpret_cast<const mach_header_64 *>(header);
        if (wide->sizeofcmds > 65536 || wide->ncmds > 1024) return nil;
        const uint8_t *cursor = reinterpret_cast<const uint8_t *>(wide + 1);
        size_t remaining = wide->sizeofcmds;
        for (uint32_t command = 0; command < wide->ncmds; command++) {
            if (remaining < sizeof(load_command)) return nil;
            const load_command *load = reinterpret_cast<const load_command *>(cursor);
            if (load->cmdsize < sizeof(load_command) || load->cmdsize > remaining) return nil;
            if (load->cmd == LC_UUID) {
                if (load->cmdsize != sizeof(uuid_command)) return nil;
                return [[NSUUID alloc] initWithUUIDBytes:
                    reinterpret_cast<const uuid_command *>(load)->uuid].UUIDString;
            }
            remaining -= load->cmdsize; cursor += load->cmdsize;
        }
    }
    return nil;
}

NSDictionary *PPOSceneFrameworkIdentity(void) {
    NSDictionary *expected = @{
        @"FrontBoard": @"ED43ADA7-7107-3242-928F-09708F2FD9F3",
        @"UIKitCore": @"C98EAB32-B273-3430-B0C5-46522C904CBB",
        @"FrontBoardServices": @"CB9A7EAD-B91A-3F19-86F1-461027284416",
        @"SpringBoard": @"8676BE2A-9484-3492-888E-7DE10333250F"};
    NSString *front = PPOUUIDForLoadedImage("/FrontBoard.framework/FrontBoard");
    NSString *ui = PPOUUIDForLoadedImage("/UIKitCore.framework/UIKitCore");
    NSString *services = PPOUUIDForLoadedImage("/FrontBoardServices.framework/FrontBoardServices");
    NSString *springboard = PPOUUIDForLoadedImage("/SpringBoard.framework/SpringBoard");
    return @{@"expected": expected,
        @"observed": @{@"FrontBoard": front ?: @"missing", @"UIKitCore": ui ?: @"missing",
            @"FrontBoardServices": services ?: @"missing", @"SpringBoard": springboard ?: @"missing"},
        @"matches": @([front isEqual:expected[@"FrontBoard"]] && [ui isEqual:expected[@"UIKitCore"]] &&
            [services isEqual:expected[@"FrontBoardServices"]] && [springboard isEqual:expected[@"SpringBoard"]])};
}

static NSArray *PPOSceneABIMetadata(void) {
    struct Entry { const char *className; const char *selector; BOOL factory; };
    const Entry entries[] = {
        {"FBSceneManager", "sharedInstance", YES},
        {"FBSceneManager", "enumerateScenesWithBlock:", NO},
        {"FBScene", "identifier", NO}, {"FBScene", "clientHandle", NO},
        {"FBScene", "definition", NO}, {"FBSceneClientHandle", "bundleIdentifier", NO},
        {"FBSSceneDefinition", "clientIdentity", NO},
        {"FBSSceneClientIdentity", "bundleIdentifier", NO},
        {"FBScene", "uiPresentationManager", NO},
        {"UIScenePresentationManager", "createPresenterWithIdentifier:", NO},
        {"_UIScenePresenter", "presentationView", NO},
        {"_UIScenePresenter", "activate", NO}, {"_UIScenePresenter", "invalidate", NO},
    };
    NSMutableArray *metadata = [NSMutableArray array];
    for (const Entry &entry : entries) {
        Class cls = objc_lookUpClass(entry.className);
        SEL selector = sel_registerName(entry.selector);
        Method method = PPOSceneMethod(cls, selector, entry.factory);
        const char *types = method ? method_getTypeEncoding(method) : NULL;
        [metadata addObject:@{@"class": [NSString stringWithUTF8String:entry.className],
            @"selector": [NSString stringWithUTF8String:entry.selector],
            @"factory": @(entry.factory), @"types": types ? ([NSString stringWithUTF8String:types] ?: @"invalid") : @"missing"}];
    }
    return metadata;
}

NSDictionary *PPOScenePreflight(NSString *bundleIdentifier) {
    NSDictionary *frameworks = PPOSceneFrameworkIdentity();
    NSDictionary *selection;
    struct stat marker = {};
    BOOL disabled = lstat("/var/mobile/.ppo_disable", &marker) == 0 || errno != ENOENT;
    if (!NSThread.isMainThread) selection = PPOSceneResult(@"wrong-thread", 0, 0, nil);
    else if (disabled) selection = PPOSceneResult(@"disabled", 0, 0, nil);
    else if (!PPOOwnedApplicationAllowed(bundleIdentifier))
        selection = PPOSceneResult(@"application-not-eligible", 0, 0, nil);
    else if (![frameworks[@"matches"] boolValue])
        selection = PPOSceneResult(@"framework-mismatch", 0, 0, nil);
    else selection = PPOReadSceneSelection(objc_lookUpClass("FBSceneManager"),
        objc_lookUpClass("FBScene"), bundleIdentifier);
    return @{@"schema": @1, @"frameworks": frameworks, @"selection": selection,
        @"os": NSProcessInfo.processInfo.operatingSystemVersionString,
        @"methods": PPOSceneABIMetadata(),
        @"hostingRequested": @NO};
}
