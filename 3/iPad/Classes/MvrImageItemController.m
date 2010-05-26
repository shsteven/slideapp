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

#import "MvrImageItem.h"
#import "MvrItemAction.h"

@interface MvrImageItemBackdropView ()

@end


@implementation MvrImageItemController

+ (NSSet *) supportedItemClasses;
{
	return [NSSet setWithObject:[MvrImageItem class]];
}

- (void) viewDidLoad;
{
	[super viewDidLoad];
	
	[self addManagedOutletKeys:@"imageView", nil];
	
	imageViewMargin = imageView.frame.origin.x;
	[self didChangeItem];
	
	UIButton* action = self.actionButton;
	CGPoint c;
	c.x = CGRectGetMidX(self.view.bounds);
	c.y = self.view.bounds.size.height - action.bounds.size.height;
	action.center = c;
	[self.view addSubview:action];
}

- (void) didChangeItem;
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

- (void) didFinishReceivingItem;
{
	UIImageWriteToSavedPhotosAlbum([self.item image], nil, NULL, NULL);
}

- (NSArray *) defaultActions;
{
	MvrItemActionBlock copyBlock = ^(MvrItem* theItem) {
		
		UIImage* i = [self.item image];
		[UIPasteboard generalPasteboard].image = i;
		
	};
	
	return [NSArray arrayWithObjects:
			[self showOpeningOptionsMenuAction],
			
			[MvrItemAction actionWithDisplayName:NSLocalizedString(@"Copy", @"Copy action button") block:copyBlock],
			
			nil];
}

@end
