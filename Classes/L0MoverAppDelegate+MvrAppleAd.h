//
//  L0MoverAppDelegate+MvrAppleAd.h
//  Mover
//
//  Created by ∞ on 20/07/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "L0MoverAppDelegate.h"

@interface L0MoverAppDelegate (MvrAppleAd)

- (void) beginReceivingForAppleAd;
- (void) beginSendingForAppleAdWithItem:(L0MoverItem*) i;

@end
