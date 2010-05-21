//
//  MvrArrowView_iPad.m
//  Mover3-iPad
//
//  Created by ∞ on 21/05/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MvrArrowView_iPad.h"


@implementation MvrArrowView_iPad


- (id) initWithFrame:(CGRect) frame;
{
    if ((self = [super initWithFrame:frame])) {
		[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil];
		self.bounds = CGRectMake(0, 0, contentView.bounds.size.width, contentView.bounds.size.width);
		contentView.frame = self.bounds;
		[self addSubview:contentView];
    }
	
    return self;
}

- (void) dealloc
{
	[contentView release];
	[mainLabel release];
	[spinner release];
	[super dealloc];
}


@synthesize mainLabel;



@end
