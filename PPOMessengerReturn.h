#pragma once
#import <Foundation/Foundation.h>
NSDictionary *PPOMessengerReturnSnapshot(void);
void PPOMessengerPrepareReturn(void (^completion)(BOOL));
