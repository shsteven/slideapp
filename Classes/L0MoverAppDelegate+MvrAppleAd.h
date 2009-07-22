//
//  L0MoverAppDelegate+MvrAppleAd.h
//  Mover
//
//  Created by ∞ on 20/07/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "L0MoverAppDelegate.h"

#define kMvrDelayBetweenSendAndReceive 2.0
#define Mover ((L0MoverAppDelegate*) UIApp.delegate)

@interface L0MoverAppDelegate (MvrAppleAd)

- (void) beginReceivingForAppleAd;
- (void) receiveItemForAppleAd;

- (void) beginSendingForAppleAdWithItem:(L0MoverItem*) i;
- (void) returnItemAfterSendForAppleAd;

@end
