//
//  MvrTableController.m
//  Mover3
//
//  Created by ∞ on 18/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrTableController.h"

#import "MvrSlidesView.h"

@implementation MvrTableController

- (void) awakeFromNib;
{
	self.backdropStratum.frame = self.hostView.bounds;
	[self.hostView addSubview:self.backdropStratum];
	
	self.slidesStratum = [[MvrSlidesView alloc] initWithFrame:self.hostView.bounds];
	[self.hostView addSubview:self.slidesStratum];
}

@synthesize hostView, backdropStratum, slidesStratum;

- (void) dealloc;
{
	[hostView release];
	[backdropStratum release];
	[slidesStratum release];
	
	[super dealloc];
}

@end
