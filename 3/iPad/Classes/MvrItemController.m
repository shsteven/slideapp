//
//  MvrItemViewController.m
//  Mover3-iPad
//
//  Created by ∞ on 23/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MvrItemController.h"
#import <MuiKit/MuiKit.h>

#import "PLActionSheet.h"

@implementation MvrItemController

static L0Map* MvrItemViewControllerClasses = nil;

+ (void) setViewControllerClass:(Class) vcc forItemClass:(Class) ic;
{
	if (!MvrItemViewControllerClasses)
		MvrItemViewControllerClasses = [L0Map new];
	
	[MvrItemViewControllerClasses setObject:vcc forKey:ic];
}

+ (Class) viewControllerClassForItem:(MvrItem*) i;
{
	for (Class ic in [MvrItemViewControllerClasses allKeys]) {
		if ([i isKindOfClass:ic])
			return [MvrItemViewControllerClasses objectForKey:ic];
	}
	
	return nil; // TODO generic.
}

- (void) dealloc
{
	[item release];
	[super dealloc];
}


@synthesize itemsTable;


@synthesize item;
- (void) setItem:(id) i;
{
	if (i != item) {
		[item release];
		item = [i retain];
		
		[self itemDidChange];
	}
}

- (void) itemDidChange;
{}

- (MvrDraggableView*) draggableView;
{
	return (MvrDraggableView*) self.view;
}

- (void) clearOutlets;
{
	[super clearOutlets];
	
	[actionButton release];
	actionButton = nil;
}

- (UIButton*) actionButton;
{
	if (!actionButton) {
		actionButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
		CGSize s = [UIImage imageNamed:@"ActionButton.png"].size;
		actionButton.frame = CGRectMake(0, 0, s.width, s.height);
		
		[actionButton setImage:[UIImage imageNamed:@"ActionButton.png"] forState:UIControlStateNormal];
		[actionButton setImage:[UIImage imageNamed:@"ActionButton_Pressed.png"] forState:UIControlStateHighlighted];
		[actionButton addTarget:self action:@selector(showActionMenu) forControlEvents:UIControlEventTouchUpInside];
		actionButton.alpha = 0.0;
		actionButton.userInteractionEnabled = YES;
		
	}
	
	return actionButton;
}

- (void) setActionButtonHidden:(BOOL) hidden animated:(BOOL) animated;
{	
	if (animated)
		[UIView beginAnimations:nil context:NULL];
	
	self.actionButton.alpha = hidden? 0.0 : 1.0;
	
	if (animated)
		[UIView commitAnimations];
}

- (void) viewDidLoad;
{
	[super viewDidLoad];
	self.draggableView.delegate = self;
}

- (void) showActionMenu;
{
	actionMenuShown = YES;
	
	PLActionSheet* as = [[PLActionSheet new] autorelease];
	[as addButtonWithTitle:@"Test 1" action:^{
		NSLog(@"Uno!");
		actionMenuShown = NO;
		[self performSelector:@selector(hideActionButton) withObject:nil afterDelay:5.0];
	}];
	[as addButtonWithTitle:@"Test 2" action:^{
		NSLog(@"Due!");
		actionMenuShown = NO;
		[self performSelector:@selector(hideActionButton) withObject:nil afterDelay:5.0];
	}];
	[as addCancelButtonWithTitle:@"Cancel" action:^{
		actionMenuShown = NO;
		[self performSelector:@selector(hideActionButton) withObject:nil afterDelay:5.0];
	}];
	
	[as showFromRect:self.actionButton.bounds inView:self.actionButton animated:YES];
}

- (void) draggableViewCenterDidMove:(MvrDraggableView *)view;
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideActionButton) object:nil];
	
	[self setActionButtonHidden:NO animated:YES];
}

- (void) draggableViewCenterDidStopMoving:(MvrDraggableView *)view;
{
	[self performSelector:@selector(hideActionButton) withObject:nil afterDelay:5.0];
	[self.itemsTable itemControllerViewDidFinishMoving:self];
}

- (void) hideActionButton;
{
	if (actionMenuShown)
		return;
	
	[self setActionButtonHidden:YES animated:YES];
}


@end
