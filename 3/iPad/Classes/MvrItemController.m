//
//  MvrItemViewController.m
//  Mover3-iPad
//
//  Created by ∞ on 23/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MvrItemController.h"
#import <MuiKit/MuiKit.h>

#import "Network+Storage/MvrItemStorage.h"

#import "PLActionSheet.h"
#import "MvrAppDelegate_iPad.h"
#import "MvrTableController_iPad.h"

@implementation MvrItemController

static L0Map* MvrItemViewControllerClasses = nil;

+ (void) setItemControllerClass:(Class) vcc forItemClass:(Class) ic;
{
	if (!MvrItemViewControllerClasses)
		MvrItemViewControllerClasses = [L0Map new];
	
	[MvrItemViewControllerClasses setObject:vcc forKey:ic];
}

+ (Class) itemControllerClassForItem:(MvrItem*) i;
{
	for (Class ic in [MvrItemViewControllerClasses allKeys]) {
		if ([i isKindOfClass:ic])
			return [MvrItemViewControllerClasses objectForKey:ic];
	}
	
	return nil; // TODO generic.
}

+ (NSSet*) supportedItemClasses;
{
	L0AbstractMethod();
	return nil;
}

+ (void) registerClass;
{
	for (Class c in [self supportedItemClasses])
		[MvrItemController setItemControllerClass:self forItemClass:c];
}

+ (MvrItemController*) itemControllerWithItem:(MvrItem*) i;
{
	MvrItemController* ic = [[[MvrItemController itemControllerClassForItem:i] new] autorelease];
	
	ic.item = i;
	return ic;
}

- (void) dealloc
{
	doc.delegate = nil;
	[doc release];
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

	[as addButtonWithTitle:@"Open \u203a" action:^{
		[self showOpeningOptionsMenu];
	}];
	
	[as setCancelledAction:^{
		NSLog(@"Cleanup!");
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

- (void) draggableViewCenterDidStopMoving:(MvrDraggableView *)view velocity:(CGPoint) v;
{
	[self performSelector:@selector(hideActionButton) withObject:nil afterDelay:5.0];
	[self.itemsTable itemControllerViewDidFinishMoving:self velocity:v];
}

- (void) hideActionButton;
{
	if (actionMenuShown)
		return;
	
	[self setActionButtonHidden:YES animated:YES];
}

- (void) showOpeningOptionsMenu;
{	
	if (!doc)
		doc = [UIDocumentInteractionController new];
	
	doc.URL = [NSURL fileURLWithPath:[self.item storage].path];
	doc.UTI = [self.item type];
	if ([self.item title] && ![[self.item title] isEqual:@""])
		doc.name = [self.item title];
	else
		doc.name = @"Preview"; // TODO
	
	doc.delegate = self;
	
	[doc presentOptionsMenuFromRect:self.actionButton.bounds inView:self.actionButton animated:YES];
}

- (UIView *) documentInteractionControllerViewForPreview:(UIDocumentInteractionController *)controller;
{
	return self.draggableView;
}

- (CGRect) documentInteractionControllerRectForPreview:(UIDocumentInteractionController *)controller;
{
	return self.draggableView.bounds;
}

- (UIViewController*) documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller;
{
	return MvrApp().viewController;
}

- (void) didEndShowingActionMenu;
{
	actionMenuShown = NO;
	[self performSelector:@selector(hideActionButton) withObject:nil afterDelay:5.0];	
}

- (void) documentInteractionControllerDidDismissOptionsMenu:(UIDocumentInteractionController *)controller;
{
	L0Note();
	[self didEndShowingActionMenu];
}

- (void) documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller;
{
	L0Note();
	[self didEndShowingActionMenu];
}

- (void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController *)controller;
{
	L0Note();
	[self didEndShowingActionMenu];
}

- (void) documentInteractionController:(UIDocumentInteractionController *)controller didEndSendingToApplication:(NSString *)application;
{
	L0Note();
	[self didEndShowingActionMenu];
}

@end
