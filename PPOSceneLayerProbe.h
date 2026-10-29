#import <Foundation/Foundation.h>

// Internal read-only adapter; caller must establish exact loaded firmware UUIDs.
// Injected classes permit native rejection fixtures without loading iOS classes.
// Main thread only. No KVC, dynamic resolution, source mutation or layer IDs.
NSDictionary *PPOReadSceneLayerState(id scene, Class sceneClass, Class managerClass,
                                    Class layerClass, Class settingsClass);
