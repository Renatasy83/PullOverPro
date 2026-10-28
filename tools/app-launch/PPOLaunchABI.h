#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#include <stdlib.h>
#include <string.h>

static inline BOOL PPOTypeMatches(char *actual, const char *expected) {
    BOOL matches = actual && strcmp(actual, expected) == 0;
    free(actual);
    return matches;
}
static inline BOOL PPOGetterABI(Method method) {
    return method && method_getNumberOfArguments(method) == 2 &&
        PPOTypeMatches(method_copyReturnType(method), @encode(id)) &&
        PPOTypeMatches(method_copyArgumentType(method, 0), @encode(id)) &&
        PPOTypeMatches(method_copyArgumentType(method, 1), @encode(SEL));
}
static inline BOOL PPOLaunchABI(Method method) {
    return method && method_getNumberOfArguments(method) == 3 &&
        PPOTypeMatches(method_copyReturnType(method), @encode(BOOL)) &&
        PPOTypeMatches(method_copyArgumentType(method, 0), @encode(id)) &&
        PPOTypeMatches(method_copyArgumentType(method, 1), @encode(SEL)) &&
        PPOTypeMatches(method_copyArgumentType(method, 2), @encode(id));
}
