#import "PPOBundleSceneReader.h"
#import "../../PPOSceneCapability.h"
#import "../app-launch/PPOLaunchABI.h"
#import <objc/message.h>
#include <mach-o/dyld.h>
#include <mach-o/loader.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <stdint.h>
#include <string.h>
#include <cmath>

namespace {
constexpr size_t InfoLimit = 256 * 1024;
struct BundleFD {
    int descriptor;
    explicit BundleFD(int value) : descriptor(value) {}
    ~BundleFD() { if (descriptor >= 0) close(descriptor); }
    BundleFD(const BundleFD &) = delete;
    BundleFD &operator=(const BundleFD &) = delete;
};

BOOL ValidInput(NSString *identifier, NSTimeInterval now) {
    return PPOSceneApplicationIdentifierAllowed(identifier) && std::isfinite(now) && now >= 0;
}

NSDictionary *Unknown(NSString *identifier, NSString *reason, NSTimeInterval now) {
    return PPOSceneCapabilityUnknown(identifier, reason, now);
}

BOOL DescendsFrom(Class cls, Class expected) {
    for (NSUInteger depth = 0; cls && depth < 64; depth++, cls = class_getSuperclass(cls))
        if (cls == expected) return YES;
    return NO;
}

Class GetterOwner(Class cls, Method *methodOut) {
    if (methodOut) *methodOut = NULL;
    SEL selector = sel_registerName("bundleURL");
    for (NSUInteger depth = 0; cls && depth < 64; depth++, cls = class_getSuperclass(cls)) {
        unsigned count = 0;
        Method *methods = class_copyMethodList(cls, &count), found = NULL;
        for (unsigned i = 0; i < count; i++) {
            if (method_getName(methods[i]) == selector) { found = methods[i]; break; }
        }
        free(methods);
        if (found) {
            if (methodOut) *methodOut = found;
            return cls;
        }
    }
    return Nil;
}

BOOL LocalBundleURL(id value) {
    if (![value isKindOfClass:NSURL.class]) return NO;
    NSURL *url = value;
    NSString *path = url.path;
    if (!url.isFileURL || url.host.length || url.user.length || url.password.length || url.port ||
        url.query.length || url.fragment.length ||
        ![path isKindOfClass:NSString.class] || !path.isAbsolutePath || path.length > 4096 ||
        ![path.pathExtension isEqual:@"app"]) return NO;
    for (NSUInteger i = 0; i < path.length; i++) if ([path characterAtIndex:i] == 0) return NO;
    for (NSString *component in path.pathComponents)
        if ([component isEqual:@"."] || [component isEqual:@".."]) return NO;
    return YES;
}
}

BOOL PPOBundleCapabilityFrameworkMatches(void) {
    const char *suffix = "/CoreServices.framework/CoreServices";
    uint32_t images = _dyld_image_count();
    for (uint32_t index = 0; index < images; index++) {
        const char *name = _dyld_get_image_name(index);
        if (!name) continue;
        size_t length = strlen(name), tail = strlen(suffix);
        if (length < tail || strcmp(name + length - tail, suffix)) continue;
        const mach_header *header = _dyld_get_image_header(index);
        if (!header || header->magic != MH_MAGIC_64) return NO;
        const auto *wide = reinterpret_cast<const mach_header_64 *>(header);
        if (wide->sizeofcmds > 65536 || wide->ncmds > 1024) return NO;
        const uint8_t *cursor = reinterpret_cast<const uint8_t *>(wide + 1);
        size_t remaining = wide->sizeofcmds;
        for (uint32_t command = 0; command < wide->ncmds; command++) {
            if (remaining < sizeof(load_command)) return NO;
            const auto *load = reinterpret_cast<const load_command *>(cursor);
            if (load->cmdsize < sizeof(load_command) || load->cmdsize > remaining ||
                load->cmdsize % 4 != 0) return NO;
            if (load->cmd == LC_UUID) {
                if (load->cmdsize != sizeof(uuid_command)) return NO;
                NSString *uuid = [[NSUUID alloc] initWithUUIDBytes:
                    reinterpret_cast<const uuid_command *>(load)->uuid].UUIDString;
                return [uuid isEqual:@"0FFF723A-7DE6-3705-B327-ADD82FAEF345"];
            }
            remaining -= load->cmdsize; cursor += load->cmdsize;
        }
    }
    return NO;
}

NSDictionary *PPOReadBundleSceneCapability(NSURL *bundleURL, NSString *identifier, NSTimeInterval now) {
    if (!ValidInput(identifier, now)) return nil;
    if (!NSThread.isMainThread) return Unknown(identifier, @"unsupported-abi", now);
    @try {
        if (!LocalBundleURL(bundleURL)) return Unknown(identifier, @"no-bundle-url", now);
        const char *path = bundleURL.path.fileSystemRepresentation;
        if (!path) return Unknown(identifier, @"no-bundle-url", now);
        // O_NOFOLLOW protects the final app directory. The trusted system URL
        // may contain OS directory aliases such as /var in earlier components.
        BundleFD directory(open(path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_NONBLOCK | O_CLOEXEC));
        if (directory.descriptor < 0) return Unknown(identifier, @"bundle-unavailable", now);
        BundleFD file(openat(directory.descriptor, "Info.plist",
            O_RDONLY | O_NOFOLLOW | O_NONBLOCK | O_CLOEXEC));
        if (file.descriptor < 0)
            return Unknown(identifier, errno == ELOOP ? @"file-invalid" : @"file-unavailable", now);
        struct stat initial = {};
        if (fstat(file.descriptor, &initial) != 0 || !S_ISREG(initial.st_mode) || initial.st_size < 0)
            return Unknown(identifier, @"file-invalid", now);
        if (static_cast<uint64_t>(initial.st_size) > InfoLimit)
            return Unknown(identifier, @"file-too-large", now);
        NSMutableData *data = [NSMutableData data];
        uint8_t bytes[8192];
        while (data.length <= InfoLimit) {
            size_t remaining = InfoLimit + 1 - data.length;
            size_t wanted = remaining < sizeof(bytes) ? remaining : sizeof(bytes);
            ssize_t count = read(file.descriptor, bytes, wanted);
            if (count < 0) {
                if (errno == EINTR) continue;
                return Unknown(identifier, @"file-unavailable", now);
            }
            if (count == 0) break;
            [data appendBytes:bytes length:static_cast<NSUInteger>(count)];
        }
        if (data.length > InfoLimit) return Unknown(identifier, @"file-too-large", now);
        struct stat after = {};
        if (fstat(file.descriptor, &after) != 0 || !S_ISREG(after.st_mode) ||
            after.st_dev != initial.st_dev || after.st_ino != initial.st_ino ||
            after.st_size != initial.st_size || after.st_mtime != initial.st_mtime ||
            data.length != static_cast<uint64_t>(initial.st_size))
            return Unknown(identifier, @"file-invalid", now);
        id info = [NSPropertyListSerialization propertyListWithData:data
            options:NSPropertyListImmutable format:NULL error:NULL];
        if (!info) return Unknown(identifier, @"plist-invalid", now);
        return PPOSceneCapabilityFromInfo(info, identifier, now);
    } @catch (NSException *exception) {
        (void)exception;
        return Unknown(identifier, @"file-invalid", now);
    }
}

NSDictionary *PPOCapabilityFromApplicationProxy(id proxy, Class applicationClass,
    Class bundleClass, BOOL imageMatches, NSString *identifier, NSTimeInterval now) {
    if (!ValidInput(identifier, now)) return nil;
    if (!NSThread.isMainThread) return Unknown(identifier, @"unsupported-abi", now);
    if (!imageMatches) return Unknown(identifier, @"unsupported-framework", now);
    @try {
        if (!proxy || !applicationClass || !bundleClass ||
            !object_isClass((id)applicationClass) || !object_isClass((id)bundleClass) ||
            applicationClass == bundleClass || !DescendsFrom(applicationClass, bundleClass) ||
            !DescendsFrom(object_getClass(proxy), applicationClass))
            return Unknown(identifier, @"unsupported-abi", now);
        Method getter = NULL;
        if (GetterOwner(object_getClass(proxy), &getter) != bundleClass || !PPOGetterABI(getter))
            return Unknown(identifier, @"unsupported-abi", now);
        // Exact23A355 LSBundleProxy.bundleURL is a cached object getter. A
        // subclass override, even with the same encoding, is not this proof.
        id url = ((id (*)(id, SEL))objc_msgSend)(proxy, sel_registerName("bundleURL"));
        return PPOReadBundleSceneCapability(url, identifier, now);
    } @catch (NSException *exception) {
        (void)exception;
        return Unknown(identifier, @"unsupported-abi", now);
    }
}
