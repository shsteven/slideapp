//
//  MvrShadowBackdropDraggableView.m
//  Mover3-iPad
//
//  Created by ∞ on 01/05/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MvrShadowBackdropDraggableView.h"

@implementation MvrShadowBackdropDraggableView

- (void) dealloc
{
	[contentAreaBackgroundColor release];
	[super dealloc];
}


@synthesize contentAreaBackgroundColor;
- (UIColor*) contentAreaBackgroundColor;
{
	if (!contentAreaBackgroundColor)
		contentAreaBackgroundColor = [[UIColor whiteColor] retain];
	
	return contentAreaBackgroundColor;
}



- (void) drawRect:(CGRect)rect;
{
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	[super drawRect:rect];
	
	CGRect whitePart = CGRectInset(self.bounds, 10, 10);
	CGContextSetShadow(ctx, CGSizeMake(0, 0), 3.0);
	[self.contentAreaBackgroundColor setFill];
	UIRectFill(whitePart);
}

@end
