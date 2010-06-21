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

#import "MvrItemAction.h"

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
	documentInteractionController.delegate = nil;
	[documentInteractionController release];
	[actions release];
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
		
		if (!item) {
			documentInteractionController.delegate = nil;
			[documentInteractionController release];
			documentInteractionController = nil;
		}
		
		[self itemDidChange];
	}
}

- (void) itemDidChange;
{}

- (void) itemDidFinishReceivingFromNetwork;
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
	BOOL anyAvailable = NO;
	
	for (MvrItemAction* a in self.actions) {
		if ([a isAvailableForItem:self.item]) {
			anyAvailable = YES;
			break;
		}
	}
	
	if (!anyAvailable)
		return;
	
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
	[self.view.superview bringSubviewToFront:self.view];
	
	actionMenuShown = YES;
	
	PLActionSheet* as = [[PLActionSheet new] autorelease];

	for (MvrItemAction* a in self.actions) {
		if ([a isAvailableForItem:self.item]) {
			[as addButtonWithTitle:a.displayName action:^{
				[a performActionWithItem:self.item];
				if (!a.continuesInteractionOnTable)
					[self didFinishAction];
			}];
		}
	}
	
	[as addDestructiveButtonWithTitle:NSLocalizedString(@"Delete", @"Delete button in action menu") action:^{
		
		[self.itemsTable removeItemOfControllerFromTable:self];
		
	}];
		
	
	[as setCancelledAction:^{
		[self didFinishAction];
	}];
	
	[as showFromRect:self.actionButton.bounds inView:self.actionButton animated:YES];
	
	
	// "Pop" transition.
	[self performSelector:@selector(makeViewPop) withObject:nil afterDelay:0.001];
}

- (void) makeViewPop;
{
	CGAffineTransform t = self.view.transform;

	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationDuration:0.1];
	
	self.view.transform = CGAffineTransformScale(t, 1.05, 1.05);
	
	[UIView commitAnimations];
	
	[self performSelector:@selector(makeViewPopDown:) withObject:[NSValue valueWithCGAffineTransform:t] afterDelay:0.1];
}

- (void) makeViewPopDown:(NSValue*) origTransform;
{
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationDuration:0.1];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
	
	self.view.transform = [origTransform CGAffineTransformValue];
	
	[UIView commitAnimations];
}

- (void) draggableViewCenterDidMove:(MvrDraggableView *)view;
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideActionButton) object:nil];
	
	[self setActionButtonHidden:NO animated:YES];
}

- (void) beginShowingActionButton;
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideActionButton) object:nil];
	
	[self setActionButtonHidden:NO animated:YES];
	[self performSelector:@selector(hideActionButton) withObject:nil afterDelay:5.0];	
}

- (void) draggableViewCenterDidStopMoving:(MvrDraggableView *)view velocity:(CGPoint) v;
{
	[self beginShowingActionButton];
	[self.itemsTable itemControllerViewDidFinishMoving:self velocity:v];
}

- (void) draggableViewDidBeginTouching:(MvrDraggableView *)view;
{
	[self beginShowingActionButton];
}

- (void) hideActionButton;
{
	if (actionMenuShown)
		return;
	
	[self setActionButtonHidden:YES animated:YES];
}

- (UIDocumentInteractionController*) documentInteractionController;
{
	if (!documentInteractionController) {
		documentInteractionController = [UIDocumentInteractionController new];
	
		documentInteractionController.URL = [NSURL fileURLWithPath:[self.item storage].path];
		documentInteractionController.UTI = [self.item type];
		if ([self.item title] && ![[self.item title] isEqual:@""])
			documentInteractionController.name = [self.item title];
		else
			documentInteractionController.name = @"Preview"; // TODO
		
		documentInteractionController.delegate = self;
		
		[self didPrepareDocumentInteractionController:documentInteractionController];
	}
	
	return documentInteractionController;
}

- (void) didPrepareDocumentInteractionController:(UIDocumentInteractionController*) d;
{
	// Overridden by subclasses.
}

- (void) showOpeningOptionsMenu;
{	
	if (![self.documentInteractionController presentOptionsMenuFromRect:self.actionButton.bounds inView:self.actionButton animated:YES]) {
		UIAlertView* alert = [UIAlertView alertNamed:@"MvrNoOpeningOptions"];
		[alert setTitleFormat:nil, [UIDevice currentDevice].localizedModel];
		[alert show];
		[self didFinishAction];
	}
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
	return MvrApp_iPad().viewController;
}

- (void) didFinishAction;
{
	actionMenuShown = NO;
	[self performSelector:@selector(hideActionButton) withObject:nil afterDelay:5.0];	
}

- (void) documentInteractionControllerDidDismissOptionsMenu:(UIDocumentInteractionController *)controller;
{
	L0Note();
	[self didFinishAction];
}

- (void) documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller;
{
	L0Note();
	[self didFinishAction];
}

- (void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController *)controller;
{
	L0Note();
	[self didFinishAction];
}

- (void) documentInteractionController:(UIDocumentInteractionController *)controller didEndSendingToApplication:(NSString *)application;
{
	L0Note();
	[self didFinishAction];
}

- (MvrItemAction*) showOpeningOptionsMenuAction;
{
	MvrItemAction* a = [MvrItemAction actionWithDisplayName:@"Open\u2026" target:self selector:@selector(showOpeningOptionsMenu)];
	a.continuesInteractionOnTable = YES;
	return a;
}

@synthesize actions;
- (NSArray*) actions;
{
	if (!actions)
		self.actions = [self defaultActions];
	
	return actions;
}

- (NSArray*) defaultActions { return [NSArray array]; }

@end
