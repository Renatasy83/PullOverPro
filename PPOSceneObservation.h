#pragma once
#import <Foundation/Foundation.h>
// Explicit Messenger refusal only. No launch, create, activate, present or mutation.
NSDictionary *PPOObserveMessengerScene(NSDictionary *capability);
// Native fixture boundary. No private class lookup until all input gates pass.
NSDictionary *PPOReadMessengerSceneObservation(NSDictionary<NSString *, Class> *classes,
    NSDictionary *capability, NSTimeInterval now, BOOL frameworkMatches, BOOL enabled);
