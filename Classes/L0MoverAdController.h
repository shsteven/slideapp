//
//  L0MoverAdController.h
//  Mover
//
//  Created by ∞ on 12/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface L0MoverAdController : NSObject {
	UIView* superview;
}

+ sharedController;

@property(assign) UIView* superview;
- (void) start;

@end
