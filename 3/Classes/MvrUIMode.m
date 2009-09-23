//
//  MvrUIMode.m
//  Mover3
//
//  Created by ∞ on 22/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrUIMode.h"

#import "MvrArrowsView.h"

@implementation MvrUIMode

- (UIView*) arrowsStratum;
{
	if (!arrowsStratum) {
		self.arrowsStratum = [[[MvrArrowsView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)] autorelease];
	}
	
	return arrowsStratum;
}

- (MvrArrowsView*) arrowsView;
{
	id x = self.arrowsStratum;
	return [x isKindOfClass:[MvrArrowsView class]]? x : nil;
}

@synthesize arrowsStratum, backdropStratum;

- (void) dealloc;
{
	[backdropStratum release];
	[arrowsStratum release];
	
	[super dealloc];
}

@end
