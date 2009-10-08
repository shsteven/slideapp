//
//  MvrVisor.m
//  Mover3
//
//  Created by ∞ on 03/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrVisor.h"

#import "MvrItemUI.h"
#import "MvrAppDelegate.h"

@implementation MvrVisor

- (id) initWithItem:(MvrItem*) i;
{
	if (self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil])
		self.item = i;
	
	return self;
}

@synthesize item, changesStatusBarStyleOnAppearance;

- (void) dealloc;
{
	[item release];
	[super dealloc];
}

- (UIStatusBarStyle) preferredStatusBarStyle;
{
	return UIStatusBarStyleBlackTranslucent;
}

- (void) viewWillAppear:(BOOL)animated;
{
	[super viewWillAppear:animated];
	
	if (self.changesStatusBarStyleOnAppearance) {
		UIApplication* app = [UIApplication sharedApplication];
		previousStatusBarStyle = app.statusBarStyle;
		[app setStatusBarStyle:self.preferredStatusBarStyle animated:animated];
	}
	
	didChangeStatusBarStyle = self.changesStatusBarStyleOnAppearance;
}

- (void) viewWillDisappear:(BOOL)animated;
{
	[super viewWillDisappear:animated];
	
	if (didChangeStatusBarStyle) {
		UIApplication* app = [UIApplication sharedApplication];
		[app setStatusBarStyle:previousStatusBarStyle animated:animated];
	}
}

+ visorWithItem:(MvrItem*) i;
{
	return [[[self alloc] initWithItem:i] autorelease];
}

+ modalVisorWithItem:(MvrItem*) i;
{
	MvrVisor* me = [self visorWithItem:i];
	me.changesStatusBarStyleOnAppearance = YES;
	
	// The Done button
	me.navigationItem.leftBarButtonItem = me.doneButton;
	// The action button
	if (me.item && [[MvrItemUI UIForItem:me.item] hasAdditionalActionsAvailableForItem:i] > 0)
		me.navigationItem.rightBarButtonItem = me.actionButton;
	
	UINavigationController* nav = [[[UINavigationController alloc] initWithRootViewController:me] autorelease];
	nav.navigationBar.barStyle = UIBarStyleBlackTranslucent;
	return nav;
}

#pragma mark -
#pragma mark Modal buttons implementation

- (UIBarButtonItem*) doneButton;
{
	return [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)] autorelease];
}

- (UIBarButtonItem*) actionButton;
{
	return [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(action)] autorelease];
}

- (IBAction) done;
{
	[self dismissModalViewControllerAnimated:YES];
}

- (IBAction) action;
{
	[MvrApp() displayActionMenuForItem:item withRemove:NO withSend:YES withMainAction:NO];
}

@end
