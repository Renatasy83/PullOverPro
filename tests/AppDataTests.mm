#import "../PPOAppData.h"
#include <stdio.h>
#include <stdlib.h>

static void Check(BOOL condition, const char *name) {
    if (!condition) { fprintf(stderr, "FAIL: %s\n", name); exit(1); }
}
static NSData *Report(NSArray *apps) {
    return [NSJSONSerialization dataWithJSONObject:@{
        @"schema": @1, @"source": @"LSApplicationWorkspace.allInstalledApplications",
        @"count": @(apps.count), @"apps": apps
    } options:0 error:NULL];
}
int main(void) {
    @autoreleasepool {
        NSMutableArray *apps = [NSMutableArray array];
        for (NSUInteger i = 0; i < 443; i++) {
            [apps addObject:@{@"bundleIdentifier": [NSString stringWithFormat:@"test.app.%lu", (unsigned long)i],
                @"name": [NSString stringWithFormat:@"Aplicație %lu", (unsigned long)i]}];
        }
        Check(PPOAppsFromData(Report(apps), NULL).count == 443, "443 entries");
        NSArray *empty = PPOAppsFromData(Report(@[]), NULL);
        Check(empty != nil && empty.count == 0, "valid empty report");
        Check(PPOAppsFromData([@"invalid" dataUsingEncoding:NSUTF8StringEncoding], NULL) == nil, "bad JSON");
        Check(PPOAppsFromData([@"[]" dataUsingEncoding:NSUTF8StringEncoding], NULL) == nil, "wrong root");
        Check(PPOAppsFromData(Report(@[@{@"name": @1, @"bundleIdentifier": @"test.a"}]), NULL) == nil, "wrong field type");
        Check(PPOAppsFromData(Report(@[apps[0], apps[0]]), NULL) == nil, "duplicate id");
        Check(PPOAppsFromData([NSMutableData dataWithLength:2*1024*1024+1], NULL) == nil, "oversized report");
        NSDictionary *selected = apps[17];
        Check([PPOSelectionFromData(PPOSelectionData(selected, NULL)) isEqual:selected], "selection round trip");
        Check(PPOSelectionFromData([@"bad" dataUsingEncoding:NSUTF8StringEncoding]) == nil, "bad selection");
        Check(PPOSelectionData(@{@"name": @"App"}, NULL) == nil, "missing selection id");
        NSString *temporary = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
        [@"12345" writeToFile:temporary atomically:YES encoding:NSUTF8StringEncoding error:NULL];
        Check(PPOReadBoundedFile(temporary, 5, NULL).length == 5, "bounded read");
        Check(PPOReadBoundedFile(temporary, 4, NULL) == nil, "oversized file");
        [NSFileManager.defaultManager removeItemAtPath:temporary error:NULL];
        Check(PPOReadBoundedFile(temporary, 5, NULL) == nil, "missing file");
        printf("App data tests passed\n");
    }
    return 0;
}
