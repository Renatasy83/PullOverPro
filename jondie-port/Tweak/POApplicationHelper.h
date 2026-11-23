//
//  POApplicationHelper.h
//  PullOverPro
//
//  Created by Will Smillie on 4/8/19.
//  Rootless port (iOS 15-16): Jond-ie.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "headers.h"
#import <objc/runtime.h>
#import "../Shared/POShared.h"

// Set by the frontDisplayDidChange: hook.
FOUNDATION_EXTERN void POSetFrontMostBundleId(NSString *bundleId);

@interface POApplicationHelper : NSObject

+(NSArray *)recentAppsWithCount:(int)count;
+(UIImage *)imageForBundleId:(NSString *)bundleId;
+(NSString *)frontMostBundleId;

+(NSDictionary *)settings;
+(void)reloadSettings;
+(NSUserDefaults *)state;

@end
