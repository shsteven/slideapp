//
//  Mover3_iPadViewController.m
//  Mover3-iPad
//
//  Created by ∞ on 14/04/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "MvrTableController_iPad.h"
#import <QuartzCore/QuartzCore.h>

@implementation MvrTableController_iPad

- (ILRotationStyle) rotationStyle;
{
	return kILRotateAny;
}


- (void) awakeFromNib;
{
	itemControllers = [NSMutableSet new];
}

- (NSSet*) itemControllers;
{	
	return [[itemControllers copy] autorelease];
}

- (void) addItemController:(MvrItemViewController*) ic;
{
	[itemControllers addObject:ic];
	[self addDraggableView:ic.draggableView];
}

- (void) removeItemController:(MvrItemViewController*) ic;
{
	if (ic.draggableView.superview == draggableViewsLayer)
		[ic.draggableView removeFromSuperview];
	
	[itemControllers removeObject:ic];
}



- (void) addDraggableView:(MvrDraggableView*) v;
{
	v.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
	
	v.autoresizingMask = UIViewAutoresizingNone;
	v.delegate = self;
	[draggableViewsLayer addSubview:v];
}



- (void) draggableViewCenterDidMove:(MvrDraggableView *)view;
{
	for (MvrItemViewController* ic in itemControllers) {
		if (ic.view == view) {
			[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideActionButtonOfController:) object:ic];
			
			[ic setActionButtonHidden:NO animated:YES];
			return;
		}
	}
}

- (void) draggableViewCenterDidStopMoving:(MvrDraggableView *)view;
{
	for (MvrItemViewController* ic in itemControllers) {
		if (ic.view == view) {
			[self performSelector:@selector(hideActionButtonOfController:) withObject:ic afterDelay:5.0];
			return;
		}
	}
}

- (void) hideActionButtonOfController:(MvrItemViewController*) ic;
{
	[ic setActionButtonHidden:YES animated:YES];
}

@end
