#import <Foundation/Foundation.h>

// Explicit user action, main thread only. Metadata and bounded scene reads;
// never creates, presents, activates, resizes, destroys or invalidates a scene.
NSDictionary *PPOScenePreflight(NSString *bundleIdentifier);

// Core dependency injection for native fixtures. Production uses the wrapper
// above, which checks loaded framework UUIDs before resolving private classes.
NSDictionary *PPOReadSceneSelection(Class managerClass, Class sceneClass,
                                   NSString *bundleIdentifier);
NSDictionary *PPOSceneFrameworkIdentity(void);

// Internal main-thread lookup: the strong result is used synchronously by the
// hosting adapter only, after complete, unique enumeration. Never dispatch it.
NSDictionary *PPOFindUniqueScene(Class managerClass, Class sceneClass,
    NSString *bundleIdentifier, id __strong *sceneOut);
