#import "../tools/app-launch/PPOLaunchABI.h"
#include <stdio.h>
#include <stdlib.h>

@interface PPOABIFixture : NSObject
+ (id)workspace;
- (BOOL)openObject:(id)value;
- (id)objectResult:(id)value;
- (BOOL)openInteger:(NSInteger)value;
- (BOOL)boolResult;
@end
@implementation PPOABIFixture
+ (id)workspace { return nil; }
- (BOOL)openObject:(id)value { (void)value; return YES; }
- (id)objectResult:(id)value { return value; }
- (BOOL)openInteger:(NSInteger)value { return value != 0; }
- (BOOL)boolResult { return YES; }
@end
static void Check(BOOL value, const char *name) {
    if (!value) { fprintf(stderr, "FAIL: %s\n", name); exit(1); }
}
int main(void) {
    @autoreleasepool {
        Class cls = PPOABIFixture.class;
        Check(PPOGetterABI(class_getClassMethod(cls, @selector(workspace))), "object getter");
        Check(PPOLaunchABI(class_getInstanceMethod(cls, @selector(openObject:))), "BOOL object argument");
        Check(!PPOLaunchABI(class_getInstanceMethod(cls, @selector(objectResult:))), "reject object return");
        Check(!PPOLaunchABI(class_getInstanceMethod(cls, @selector(openInteger:))), "reject integer argument");
        Check(!PPOLaunchABI(class_getInstanceMethod(cls, @selector(boolResult))), "reject wrong arity");
        Check(!PPOGetterABI(class_getInstanceMethod(cls, @selector(boolResult))), "reject BOOL getter");
        Check(!PPOLaunchABI(NULL) && !PPOGetterABI(NULL), "reject missing method");
        printf("Launch ABI tests passed; no private API called\n");
    }
    return 0;
}
