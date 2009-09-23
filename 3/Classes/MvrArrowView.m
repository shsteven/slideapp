//
//  MvrArrowView.m
//  Mover3
//
//  Created by ∞ on 22/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrArrowView.h"


@implementation MvrArrowView

+ (CGAffineTransform) clockwiseHalfTurn;
{
	return CGAffineTransformMakeRotation(M_PI/2.0);
}

+ (CGAffineTransform) counterclockwiseHalfTurn;
{
	return CGAffineTransformMakeRotation(-M_PI/2.0);
}

- (id)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
        [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil];
		preferredSize = contentView.frame.size;
		
		if (CGRectIsEmpty(frame)) {
			if (CGRectIsNull(frame))
				frame.origin = CGPointZero;
			
			frame.size = preferredSize;
			self.frame = frame;
		}
		
		self.contentView.frame = self.bounds;
		[self addSubview:self.contentView];
    }

    return self;
}

- (void) sizeToFit;
{
	CGRect frame;
	frame.origin = self.frame.origin;
	frame.size = preferredSize;
	self.frame = frame;
}

@synthesize nameLabel, contentView, arrowView;

- (void)dealloc {
	[contentView release];
	[arrowView release];
	[nameLabel release];
    [super dealloc];
}


@end
