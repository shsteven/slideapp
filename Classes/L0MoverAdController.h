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

@interface L0MoverAdController : NSObject
#if kL0MoverInsertAdvertising
<ARRollerDelegate>
#endif
{
	UIView* superview;
	ARRollerView* view;
}

+ sharedController;

@property(assign) UIView* superview;
- (void) start;

@end
