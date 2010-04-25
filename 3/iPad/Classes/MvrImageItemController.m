//
//  MvrImageItemController.m
//  Mover3-iPad
//
//  Created by ∞ on 23/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MvrImageItemController.h"
#import <QuartzCore/QuartzCore.h>
#import <MuiKit/MuiKit.h>


@interface MvrImageItemBackdropView ()

- (void) addBackdropLayer;

@end


@implementation MvrImageItemBackdropView

- (id) initWithFrame:(CGRect) r;
{
	if (self = [super initWithFrame:r])
		[self addBackdropLayer];
	
	return self;
}

- (void) awakeFromNib;
{
	[self addBackdropLayer];
}

- (void) addBackdropLayer;
{
	return;
	
//	backdrop = [[CALayer layer] retain];
//	backdrop.frame = CGRectInset(self.bounds, 10, 10);
//	backdrop.shadowColor = [UIColor blackColor].CGColor;
//	backdrop.shadowRadius = 1.0;
//	backdrop.shadowOffset = CGSizeMake(0, 0);
//	backdrop.shadowOpacity = 3.0;
//	backdrop.backgroundColor = [UIColor whiteColor].CGColor;
//	
//	[self.layer addSublayer:backdrop];
}

- (void) drawRect:(CGRect)rect;
{
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	[super drawRect:rect];
	
	CGRect whitePart = CGRectInset(self.bounds, 10, 10);
	CGContextSetShadow(ctx, CGSizeMake(0, 0), 3.0);
	[[UIColor whiteColor] setFill];
	UIRectFill(whitePart);
}

- (UIView*) hitTest:(CGPoint)point withEvent:(UIEvent *)event;
{
	UIView* v = [super hitTest:point withEvent:event];
	L0Log(@"Hit test -> %@", v);
	return v;
}

@end


@implementation MvrImageItemController

- (void) viewDidLoad;
{
	[super viewDidLoad];
	
	[self addManagedOutletKeys:@"imageView", nil];
	
	imageViewMargin = imageView.frame.origin.x;
	[self itemDidChange];
	
	UIButton* action = self.actionButton;
	CGPoint c;
	c.x = CGRectGetMidX(self.view.bounds);
	c.y = self.view.bounds.size.height - action.bounds.size.height;
	action.center = c;
	[self.view addSubview:action];
}

- (void) itemDidChange;
{
	if (self.item) {
		UIImage* i = [[self.item image] imageByRenderingRotationAndScalingWithMaximumSide:450];

		CGRect r = imageView.frame;
		r.origin = CGPointMake(imageViewMargin, imageViewMargin);
		r.size = i.size;
		
		imageView.frame = r;
		imageView.image = i;
		
		r = self.view.bounds;
		r.size = CGSizeMake(i.size.width + 2 * imageViewMargin, i.size.height + 2 * imageViewMargin);
		self.view.bounds = r;
		[self.view setNeedsDisplay];
	}
}

@end
