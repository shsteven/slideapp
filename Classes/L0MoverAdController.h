//
//  L0MoverAdController.h
//  Mover
//
//  Created by ∞ on 12/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#if kL0MoverInsertAdvertising
#import <ARRollerView.h>
#import <ARRollerProtocol.h>
#endif

#define kL0MoverAdSize (CGSizeMake(320, 50))

@interface L0MoverAdController : NSObject
#if kL0MoverInsertAdvertising
<ARRollerDelegate>
#endif
{
	UIView* superview;
	ARRollerView* view;
	CGPoint origin;
}

+ sharedController;

@property(assign) UIView* superview;
@property CGPoint origin;
- (void) start;

@end
