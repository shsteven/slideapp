//
//  L0MoverAdController.h
//  Mover
//
//  Created by ∞ on 12/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ARRollerView;

#if kL0MoverInsertAdvertising
#import <AdMob/AdMobView.h>
#import <AdMob/AdMobDelegateProtocol.h>
#endif

#define kL0MoverAdSize (CGSizeMake(320, 48))

@class AdMobView;

@interface L0MoverAdController : NSObject
#if kL0MoverInsertAdvertising
<AdMobDelegate>
#endif
{
	UIView* superview;
	AdMobView* view;
	CGPoint origin;
}

+ sharedController;
+ (BOOL) isPaidVersion;

@property(assign) UIView* superview;
@property CGPoint origin;
- (void) start;

@end
