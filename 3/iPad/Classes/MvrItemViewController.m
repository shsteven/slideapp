//
//  MvrItemViewController.m
//  Mover3-iPad
//
//  Created by ∞ on 23/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MvrItemViewController.h"
#import <MuiKit/MuiKit.h>

@implementation MvrItemViewController

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

- (void) showActionMenu;
{
#warning TODO
	UIActionSheet* testSheet = [[UIActionSheet new] autorelease];
	[testSheet addButtonWithTitle:@"Test"];
	[testSheet addButtonWithTitle:@"Test 2"];
	
	[testSheet showFromRect:self.actionButton.bounds inView:self.actionButton animated:YES];
}

@end
