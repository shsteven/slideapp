//
//  MvrImageVisor.m
//  Mover3
//
//  Created by ∞ on 03/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrImageVisor.h"
#import "MvrImageItem.h"
#import "MvrAppDelegate.h"
#import "MvrItemUI.h"


@interface MvrImageVisor ()

@property BOOL changesStatusBarStyleOnAppearance;
@property(readonly) UIBarButtonItem* doneButton, * actionButton;

@end


@implementation MvrImageVisor

- (id) initWithImageItem:(MvrImageItem*) i;
{
	if (self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil]) {
		
		item = [i retain];
		self.title = NSLocalizedString(@"Preview", @"Image preview pane title");
		
	}
	
	return self;
}

@synthesize changesStatusBarStyleOnAppearance;

- (void) dealloc
{
	[super viewDidUnload];
    [super dealloc];
}

- (void) viewWillAppear:(BOOL)animated;
{
	if (self.changesStatusBarStyleOnAppearance) {
		UIApplication* app = [UIApplication sharedApplication];
		previousStatusBarStyle = app.statusBarStyle;
		[app setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:animated];
	}
}

- (void) viewWillDisappear:(BOOL)animated;
{
	if (self.changesStatusBarStyleOnAppearance) {
		UIApplication* app = [UIApplication sharedApplication];
		[app setStatusBarStyle:previousStatusBarStyle animated:animated];
	}
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void) viewDidLoad;
{
    [super viewDidLoad];
	imageView.image = item.image;
	
	scrollView.minimumZoomScale = 1.0;
	scrollView.maximumZoomScale = 2.5;
}

- (void) viewDidUnload;
{
	[imageView release]; imageView = nil;
	[scrollView release]; scrollView = nil;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView;
{
	return imageView;
}

#pragma mark -
#pragma mark Convenience constructors

+ visorWithImageItem:(MvrImageItem*) i;
{
	return [[[self alloc] initWithImageItem:i] autorelease];
}

+ modalVisorWithImageItem:(MvrImageItem*) i;
{
	MvrImageVisor* me = [self visorWithImageItem:i];
	me.changesStatusBarStyleOnAppearance = YES;
	
	// The Done button
	me.navigationItem.leftBarButtonItem = me.doneButton;
	// The action button
	if ([[[MvrItemUI UIForItem:i] additionalActionsForItem:i] count] > 0)
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
	[MvrApp() displayActionMenuForItem:item withRemove:NO withMainAction:NO];
}

@end
