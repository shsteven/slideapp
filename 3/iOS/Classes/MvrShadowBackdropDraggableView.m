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

- (CGFloat) margin;
{
	return 10.0;
}

- (CGRect) contentBounds;
{
	return CGRectInset(self.bounds, self.margin, self.margin);
}

- (void) drawRect:(CGRect)rect;
{
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	[super drawRect:rect];
	
	CGRect whitePart = self.contentBounds;
	CGContextSetShadow(ctx, CGSizeMake(0, 0), self.margin);
	[self.contentAreaBackgroundColor setFill];
	UIRectFill(whitePart);
}

@end
