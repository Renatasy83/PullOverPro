#import "../tools/bridge/PPOBundleSceneReader.h"
#import "../PPOSceneCapability.h"
#import <dispatch/dispatch.h>
#import <objc/runtime.h>
#include <TargetConditionals.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <cmath>

// Native files/getter fixtures only. No installed iOS app or private framework
// is queried by these tests; the injected classes are ordinary local objects.
static unsigned checks, getterReads, overrideReads, constructions, resolutions;
static BOOL throwGetter;
static id fixtureURL;
static NSString *const Identifier = @"com.example.reader";
static void Check(BOOL condition, const char *message) {
    checks++;
    if (!condition) { fprintf(stderr, "FAIL: %s\n", message); exit(1); }
}
static void Unknown(NSDictionary *value, NSString *reason) {
    Check([value[@"status"] isEqual:@"unknown"] && [value[@"eligible"] isEqual:@NO],
          "failed read remains unknown and ineligible");
    if (reason) Check([value[@"reason"] isEqual:reason], "unknown reason is bounded and specific");
    Check(value.count == 7 && [value[@"bundleIdentifier"] isEqual:Identifier],
          "result contains only normalized fields bound to the requested app");
    NSData *data = [NSJSONSerialization dataWithJSONObject:value options:0 error:NULL];
    NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    Check([text rangeOfString:@"/tmp/"].location == NSNotFound &&
          [text rangeOfString:@"FixtureDelegate"].location == NSNotFound,
          "bundle paths and raw configuration names are not serialized");
}
static NSDictionary *Info(NSString *identifier, BOOL multiple) {
    return @{@"CFBundleIdentifier": identifier, @"CFBundlePackageType": @"APPL",
        @"UIDeviceFamily": @[@1],
        @"UIApplicationSceneManifest": @{@"UIApplicationSupportsMultipleScenes": @(multiple),
            @"UISceneConfigurations": @{@"UIWindowSceneSessionRoleApplication":
                @[@{@"UISceneConfigurationName": @"Main", @"UISceneDelegateClassName": @"FixtureDelegate"}]}}};
}
static void WriteInfo(NSString *path, id info, NSPropertyListFormat format) {
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:info format:format options:0 error:NULL];
    Check(data && [data writeToFile:path options:NSDataWritingAtomic error:NULL], "fixture plist written");
}
static void Remove(NSString *path) {
    Check([NSFileManager.defaultManager removeItemAtPath:path error:NULL], "only owned fixture entry removed");
}

@interface BundleReaderFixtureBase : NSObject
- (id)bundleURL;
@end
@implementation BundleReaderFixtureBase
- (instancetype)init { constructions++; return [super init]; }
- (id)bundleURL {
    getterReads++;
    if (throwGetter) [NSException raise:@"fixture" format:@"bundle getter"];
    return fixtureURL;
}
@end
@interface BundleReaderFixtureApplication : BundleReaderFixtureBase @end
@implementation BundleReaderFixtureApplication @end
@interface BundleReaderFixtureSubclass : BundleReaderFixtureApplication @end
@implementation BundleReaderFixtureSubclass @end
@interface BundleReaderFixtureOverride : BundleReaderFixtureApplication @end
@implementation BundleReaderFixtureOverride
- (id)bundleURL { overrideReads++; abort(); }
@end
@interface BundleReaderBadBase : NSObject
- (int)bundleURL;
@end
@implementation BundleReaderBadBase
- (int)bundleURL { getterReads++; abort(); }
@end
@interface BundleReaderBadApplication : BundleReaderBadBase @end
@implementation BundleReaderBadApplication @end
@interface BundleReaderMissingBase : NSObject @end
@implementation BundleReaderMissingBase
+ (BOOL)resolveInstanceMethod:(SEL)selector { (void)selector; resolutions++; return NO; }
@end
@interface BundleReaderMissingApplication : BundleReaderMissingBase @end
@implementation BundleReaderMissingApplication @end
@interface BundleReaderSpoof : NSProxy @end
@implementation BundleReaderSpoof
- (Class)class { return BundleReaderFixtureApplication.class; }
- (BOOL)isKindOfClass:(Class)cls { return cls == BundleReaderFixtureApplication.class; }
@end
static int WrongActualGetter(id object, SEL selector) {
    (void)object; (void)selector; overrideReads++; abort();
}
static Class WrongActualClass(void) {
    static Class cls;
    if (!cls) {
        cls = objc_allocateClassPair(BundleReaderFixtureApplication.class, "BundleReaderWrongActualABI", 0);
        Check(cls && class_addMethod(cls, @selector(bundleURL), (IMP)WrongActualGetter, "i@:"),
              "wrong actual getter ABI fixture created");
        objc_registerClassPair(cls);
    }
    return cls;
}
static NSDictionary *ProxyRead(id proxy, BOOL firmware = YES) {
    return PPOCapabilityFromApplicationProxy(proxy, BundleReaderFixtureApplication.class,
        BundleReaderFixtureBase.class, firmware, Identifier, 100);
}

int main(void) {
    @autoreleasepool {
        char temporary[] = "/tmp/ppo-cap-XXXXXX";
        Check(mkdtemp(temporary) != NULL, "isolated temporary fixture root created");
        NSString *root = [NSString stringWithUTF8String:temporary];
        NSString *app = [root stringByAppendingPathComponent:@"Reader.app"];
        NSString *infoPath = [app stringByAppendingPathComponent:@"Info.plist"];
        Check([NSFileManager.defaultManager createDirectoryAtPath:app
            withIntermediateDirectories:NO attributes:nil error:NULL], "fixture app directory created");
        NSURL *url = [NSURL fileURLWithPath:app isDirectory:YES];
        WriteInfo(infoPath, Info(Identifier, YES), NSPropertyListBinaryFormat_v1_0);
        NSDictionary *value = PPOReadBundleSceneCapability(url, Identifier, 100);
        Check([value[@"status"] isEqual:@"eligible"] && [value[@"eligible"] isEqual:@YES] &&
              [value[@"bundleIdentifier"] isEqual:Identifier], "bounded binary Info.plist parsed");
        WriteInfo(infoPath, Info(Identifier, YES), NSPropertyListXMLFormat_v1_0);
        value = PPOReadBundleSceneCapability(url, Identifier, 100);
        Check([value[@"status"] isEqual:@"eligible"], "XML Info.plist parsed without a format assumption");

        WriteInfo(infoPath, Info(Identifier, NO), NSPropertyListBinaryFormat_v1_0);
        value = PPOReadBundleSceneCapability(url, Identifier, 101);
        Check([value[@"status"] isEqual:@"ineligible"] &&
              [value[@"reason"] isEqual:@"multiple-scenes-disabled"], "each read observes fresh metadata");
        WriteInfo(infoPath, Info(Identifier, YES), NSPropertyListBinaryFormat_v1_0);
        Check([PPOReadBundleSceneCapability(url, Identifier, 102)[@"eligible"] isEqual:@YES],
              "no capability result is cached across changed files");
        value = PPOReadBundleSceneCapability(url, @"com.example.other", 100);
        Check([value[@"status"] isEqual:@"unknown"] &&
              [value[@"reason"] isEqual:@"identifier-mismatch"] &&
              [value[@"bundleIdentifier"] isEqual:@"com.example.other"], "installed ID must match the requested ID");

        Remove(infoPath);
        Unknown(PPOReadBundleSceneCapability(url, Identifier, 100), @"file-unavailable");
        Check([[@"invalid plist" dataUsingEncoding:NSUTF8StringEncoding] writeToFile:infoPath atomically:YES],
              "malformed owned fixture written");
        Unknown(PPOReadBundleSceneCapability(url, Identifier, 100), @"plist-invalid");
        Check([[NSData data] writeToFile:infoPath atomically:YES], "empty owned fixture written");
        Unknown(PPOReadBundleSceneCapability(url, Identifier, 100), @"plist-invalid");
        Check([[NSMutableData dataWithLength:256 * 1024 + 1] writeToFile:infoPath atomically:YES],
              "oversized fixture written");
        Unknown(PPOReadBundleSceneCapability(url, Identifier, 100), @"file-too-large");
        Remove(infoPath);
        Check([NSFileManager.defaultManager createDirectoryAtPath:infoPath
            withIntermediateDirectories:NO attributes:nil error:NULL], "nonregular Info entry created");
        Unknown(PPOReadBundleSceneCapability(url, Identifier, 100), @"file-invalid");
        Remove(infoPath);

        NSString *payload = [root stringByAppendingPathComponent:@"Payload.plist"];
        WriteInfo(payload, Info(Identifier, YES), NSPropertyListBinaryFormat_v1_0);
        NSData *before = [NSData dataWithContentsOfFile:payload];
        Check(symlink(payload.fileSystemRepresentation, infoPath.fileSystemRepresentation) == 0,
              "Info symlink fixture created");
        Unknown(PPOReadBundleSceneCapability(url, Identifier, 100), @"file-invalid");
        Check([[NSData dataWithContentsOfFile:payload] isEqual:before], "symlink target remains unchanged");
        Remove(infoPath);
        Check(mkfifo(infoPath.fileSystemRepresentation, 0600) == 0, "FIFO fixture created");
        NSTimeInterval start = NSProcessInfo.processInfo.systemUptime;
        Unknown(PPOReadBundleSceneCapability(url, Identifier, 100), @"file-invalid");
        Check(NSProcessInfo.processInfo.systemUptime - start < 1, "FIFO is rejected without waiting for a writer");
        Remove(infoPath);
        int socketFD = socket(AF_UNIX, SOCK_STREAM, 0);
        Check(socketFD >= 0, "socket fixture opened");
        sockaddr_un address = {};
        address.sun_family = AF_UNIX;
        Check(strlen(infoPath.fileSystemRepresentation) < sizeof(address.sun_path), "socket fixture path bounded");
        strcpy(address.sun_path, infoPath.fileSystemRepresentation);
        Check(bind(socketFD, reinterpret_cast<sockaddr *>(&address), sizeof(address)) == 0,
              "socket fixture bound");
        start = NSProcessInfo.processInfo.systemUptime;
        Unknown(PPOReadBundleSceneCapability(url, Identifier, 100), nil);
        Check(NSProcessInfo.processInfo.systemUptime - start < 1, "socket path cannot block a metadata read");
        close(socketFD); Remove(infoPath);
        WriteInfo(infoPath, Info(Identifier, YES), NSPropertyListBinaryFormat_v1_0);

        NSString *link = [root stringByAppendingPathComponent:@"Alias.app"];
        Check(symlink(app.fileSystemRepresentation, link.fileSystemRepresentation) == 0, "app directory symlink created");
        Unknown(PPOReadBundleSceneCapability([NSURL fileURLWithPath:link], Identifier, 100), @"bundle-unavailable");
        NSString *plain = [root stringByAppendingPathComponent:@"File.app"];
        Check([[NSData data] writeToFile:plain atomically:YES], "non-directory app fixture written");
        Unknown(PPOReadBundleSceneCapability([NSURL fileURLWithPath:plain], Identifier, 100), @"bundle-unavailable");
        for (id invalidURL in @[@42, NSNull.null,
                [NSURL URLWithString:@"https://example.invalid/Reader.app"],
                [NSURL URLWithString:@"file://remote.invalid/tmp/Reader.app"],
                [NSURL URLWithString:@"file:///tmp/Reader.app?query=1"],
                [NSURL URLWithString:@"file:///tmp/Reader.app#fragment"],
                [NSURL fileURLWithPath:[root stringByAppendingPathComponent:@"NotAnApp.appex"]]])
            Unknown(PPOReadBundleSceneCapability(invalidURL, Identifier, 100), @"no-bundle-url");
        Unknown(PPOReadBundleSceneCapability(nil, Identifier, 100), @"no-bundle-url");
        Check(PPOReadBundleSceneCapability(url, @"com.apple.springboard", 100) == nil &&
              PPOReadBundleSceneCapability(url, Identifier, NAN) == nil &&
              PPOReadBundleSceneCapability(url, Identifier, -1) == nil,
              "invalid identifier and clock refuse before metadata access");

        fixtureURL = url;
        id proxy = [BundleReaderFixtureApplication new];
        unsigned made = constructions;
        value = ProxyRead(proxy);
        Check([value[@"eligible"] isEqual:@YES] && getterReads == 1 && constructions == made,
              "only the exact inherited owner getter is called and no manager is constructed");
        proxy = [BundleReaderFixtureSubclass new]; made = constructions;
        Check([ProxyRead(proxy)[@"eligible"] isEqual:@YES] && getterReads == 2 && constructions == made,
              "a real application subtype can inherit the same verified cached getter");
        unsigned reads = getterReads;
        Unknown(ProxyRead(proxy, NO), @"unsupported-framework");
        Check(getterReads == reads, "framework mismatch prevents getter dispatch");
        for (id rejected in @[[BundleReaderFixtureOverride new], [WrongActualClass() new],
                              [NSObject new], [BundleReaderSpoof alloc]]) {
            Unknown(ProxyRead(rejected), @"unsupported-abi");
            Check(getterReads == reads && overrideReads == 0,
                  "actual hierarchy and declaration owner reject overrides and masquerading proxies");
        }
        Unknown(PPOCapabilityFromApplicationProxy([BundleReaderBadApplication new],
            BundleReaderBadApplication.class, BundleReaderBadBase.class, YES, Identifier, 100), @"unsupported-abi");
        Unknown(PPOCapabilityFromApplicationProxy([BundleReaderMissingApplication new],
            BundleReaderMissingApplication.class, BundleReaderMissingBase.class, YES, Identifier, 100), @"unsupported-abi");
        Check(getterReads == reads && overrideReads == 0 && resolutions == 0,
              "bad return type and absent selector cannot invoke accessors or dynamic resolution");
        Unknown(PPOCapabilityFromApplicationProxy(proxy, Nil, BundleReaderFixtureBase.class,
            YES, Identifier, 100), @"unsupported-abi");
        Unknown(PPOCapabilityFromApplicationProxy(proxy, BundleReaderFixtureApplication.class,
            (Class)(id)@1, YES, Identifier, 100), @"unsupported-abi");
        Unknown(PPOCapabilityFromApplicationProxy(proxy, BundleReaderFixtureBase.class,
            BundleReaderFixtureBase.class, YES, Identifier, 100), @"unsupported-abi");
        Check(getterReads == reads, "nil/non-Class/unrelated class inputs cannot dispatch");
        fixtureURL = nil; Unknown(ProxyRead(proxy), @"no-bundle-url");
        fixtureURL = @1; Unknown(ProxyRead(proxy), @"no-bundle-url");
        throwGetter = YES;
        Unknown(ProxyRead(proxy), @"unsupported-abi");
        throwGetter = NO; fixtureURL = url; reads = getterReads;
        __block NSDictionary *worker = nil;
        dispatch_group_t group = dispatch_group_create();
        dispatch_group_async(group, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
            worker = ProxyRead(proxy);
        });
        Check(dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC)) == 0,
              "worker fixture completes");
        Unknown(worker, @"unsupported-abi");
        Check(getterReads == reads, "worker thread cannot invoke the private cached getter");
#if TARGET_OS_OSX
        Check(!PPOBundleCapabilityFrameworkMatches(), "macOS fixture cannot impersonate the exact iOS framework UUID");
#endif
        Remove(root);
        printf("Bundle scene reader tests passed: %u checks; native fixtures, not installed iOS bundle access\n", checks);
    }
    return 0;
}
