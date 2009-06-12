//
//  L0MoverAdController.m
//  Mover
//
//  Created by ∞ on 12/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0MoverAdController.h"


@implementation L0MoverAdController

#if kL0MoverInsertAdvertising
L0ObjCSingletonMethod(sharedController)
#else
+ sharedController { return nil; }
#endif

@synthesize superview;

- (void) start;
{
#if kL0MoverInsertAdvertising
	
#endif
}

#if kL0MoverInsertAdvertising

- (NSString*)adWhirlApplicationKey;
{
	// Not really needed, but triggers a build error if we've forgotten the key.
	NSAssert(kL0MoverAdWhirlKey != nil, @"Needs to have the AdWhirl key to build with ads");
	return kL0MoverAdWhirlKey;
}

#endif

@end
