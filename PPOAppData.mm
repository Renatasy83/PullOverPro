#import "PPOAppData.h"

static BOOL PPOValidText(id value) {
    return [value isKindOfClass:NSString.class] &&
        [(NSString *)value length] > 0 && [(NSString *)value length] <= 512;
}
static BOOL PPODataError(NSError **error) {
    if (error) *error = [NSError errorWithDomain:@"PullOverPro.AppData" code:1
        userInfo:@{NSLocalizedDescriptionKey: @"Date PPO nevalide"}];
    return NO;
}
NSArray<NSDictionary *> *PPOAppsFromData(NSData *data, NSError **error) {
    if (!data.length || data.length > 2 * 1024 * 1024) {
        PPODataError(error); return nil;
    }
    id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
    if (![json isKindOfClass:NSDictionary.class] ||
        ![json[@"schema"] isKindOfClass:NSNumber.class] ||
        ![json[@"schema"] isEqual:@1] ||
        ![json[@"source"] isEqual:@"LSApplicationWorkspace.allInstalledApplications"] ||
        ![json[@"apps"] isKindOfClass:NSArray.class] ||
        ![json[@"count"] isKindOfClass:NSNumber.class]) {
        PPODataError(error); return nil;
    }
    NSArray *raw = json[@"apps"];
    if (raw.count > 4096 || [json[@"count"] unsignedIntegerValue] != raw.count) {
        PPODataError(error); return nil;
    }
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:raw.count];
    NSMutableSet *seen = [NSMutableSet set];
    for (id item in raw) {
        if (![item isKindOfClass:NSDictionary.class] ||
            !PPOValidText(item[@"bundleIdentifier"]) || !PPOValidText(item[@"name"]) ||
            [seen containsObject:item[@"bundleIdentifier"]]) {
            PPODataError(error); return nil;
        }
        [seen addObject:item[@"bundleIdentifier"]];
        [items addObject:@{@"bundleIdentifier": item[@"bundleIdentifier"], @"name": item[@"name"]}];
    }
    [items sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
        return [a[@"name"] localizedCaseInsensitiveCompare:b[@"name"]];
    }];
    return [items copy];
}
NSDictionary *PPOSelectionFromData(NSData *data) {
    if (!data.length || data.length > 16384) return nil;
    id value = [NSPropertyListSerialization propertyListWithData:data
        options:NSPropertyListImmutable format:NULL error:NULL];
    if (![value isKindOfClass:NSDictionary.class] ||
        !PPOValidText(value[@"bundleIdentifier"]) || !PPOValidText(value[@"name"])) return nil;
    return @{@"bundleIdentifier": value[@"bundleIdentifier"], @"name": value[@"name"]};
}
NSData *PPOSelectionData(NSDictionary *selection, NSError **error) {
    if (![selection isKindOfClass:NSDictionary.class] ||
        !PPOValidText(selection[@"bundleIdentifier"]) || !PPOValidText(selection[@"name"])) {
        PPODataError(error); return nil;
    }
    NSDictionary *clean = @{@"bundleIdentifier": selection[@"bundleIdentifier"], @"name": selection[@"name"]};
    return [NSPropertyListSerialization dataWithPropertyList:clean
        format:NSPropertyListXMLFormat_v1_0 options:0 error:error];
}
NSData *PPOReadBoundedFile(NSString *path, NSUInteger limit, NSError **error) {
    NSDictionary *attributes = [NSFileManager.defaultManager attributesOfItemAtPath:path error:error];
    if (![attributes[NSFileType] isEqual:NSFileTypeRegular]) {
        PPODataError(error); return nil;
    }
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingFromURL:
        [NSURL fileURLWithPath:path] error:error];
    if (!handle) return nil;
    NSData *data = nil;
    @try {
        data = [handle readDataUpToLength:limit + 1 error:error];
    } @finally {
        [handle closeAndReturnError:NULL];
    }
    if (data.length > limit) { PPODataError(error); return nil; }
    return data;
}
