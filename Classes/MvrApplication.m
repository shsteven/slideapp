//
//  L0MoverAppDelegate+MvrTableCleaning.m
//  Mover
//
//  Created by ∞ on 13/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrApplication.h"


@implementation MvrApplication

- (void) motionBegan:(UIEventSubtype) motion withEvent:(UIEvent*) event;
{
	if ([L0Mover tableController].modalViewController)
		[super motionBegan:motion withEvent:event];
	else if (motion == UIEventTypeMotion)
		[L0Mover askWhetherToClearTable];
}

@end
