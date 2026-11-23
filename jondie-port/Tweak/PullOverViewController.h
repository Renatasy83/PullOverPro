//
//  PullOverViewController.h
//  PullOverPro
//
//  Created by Will Smillie on 4/8/19.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>


#import "BaseScrollView.h"
#import "POHandle.h"
#import "QuickSwitchTableView.h"
#import "ContextHostManager.h"

#import "headers.h"


@interface PullOverViewController : UIViewController <UIScrollViewDelegate, POHandleDelegate, QuickSwitchSelectionDelegate>

-(void)open;
-(void)close;
-(void)endHosting;
-(void)retryHostingIfNeeded;
-(void)updateHandleVisibility:(float)progress;
@property (nonatomic) BOOL isOpened;

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIScrollView *handleScrollView;
@property (nonatomic, strong) UIView *backgroundView;

@property (nonatomic, strong) POHandle *handle;
@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, strong) QuickSwitchTableView *quickSwitchTableView;


@end

