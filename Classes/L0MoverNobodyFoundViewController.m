//
//  L0MoverTroubleshootingController.m
//  Mover
//
//  Created by ∞ on 24/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0MoverNobodyFoundViewController.h"
#import "L0MoverItemsTableController.h"
#import "L0MoverPeering.h"
#import "L0MoverAppDelegate.h"

@interface L0MoverNobodyFoundViewController ()

- (void) displayNobodyFoundView;
- (void) hideNobodyFoundViewAnimated:(BOOL) ani;

@property(readonly) BOOL shouldShowNobodyFoundView;

@end


@implementation L0MoverNobodyFoundViewController

@synthesize tableController;
@synthesize nobodyFoundView, nobodyFoundViewSpinner, nobodyFoundViewHost;

L0UniquePointerConstant(kL0MoverTroubleshootingControllerObservationContext);

- (void) awakeFromNib;
{	
	nobodyFoundViewFrame = self.nobodyFoundView.frame;
	[self hideNobodyFoundViewAnimated:NO];
	[self performSelector:@selector(updateDisplayOfNobodyFoundViewImmediately) withObject:nil afterDelay:3.0];
	
	[[L0MoverPeering sharedService] addObserver:self forKeyPath:@"disconnected" options:0 context:(void*) kL0MoverTroubleshootingControllerObservationContext];
}

- (void) observeValueForKeyPath:(NSString*) keyPath ofObject:(id) object change:(NSDictionary*) change context:(void*) context;
{
	if (context != kL0MoverTroubleshootingControllerObservationContext)
		return;
	
	L0Log(@"%@ had key path changed = %@", object, keyPath);
	[self updateDisplayOfNobodyFoundView];
}

- (BOOL) shouldShowNobodyFoundView;
{
	if ([[L0MoverPeering sharedService] disconnected])
		return NO;
	
	return !tableController.westPeer && !tableController.eastPeer && !tableController.northPeer;
}

- (void) updateDisplayOfNobodyFoundView;
{
	if (self.shouldShowNobodyFoundView) {
		[self performSelector:@selector(updateDisplayOfNobodyFoundViewImmediately) withObject:nil afterDelay:3.0];
	} else
		[self hideNobodyFoundViewAnimated:YES];
}

- (void) updateDisplayOfNobodyFoundViewImmediately;
{
	if (self.shouldShowNobodyFoundView)
		[self displayNobodyFoundView];
	else
		[self hideNobodyFoundViewAnimated:YES];	
}

#pragma mark -
#pragma mark Actions

- (IBAction) showNetworkHelp;
{
	[L0Mover showNetworkHelpPane];
}

- (IBAction) showNetworkState;
{
	[L0Mover showNetworkSettingsPane];
}

#pragma mark -
#pragma mark "Nobody found" view display

- (void) hideNobodyFoundViewAnimated:(BOOL) ani;
{	
	if (!self.nobodyFoundView.superview)
		return;
	
	if (!ani) {
		[self.nobodyFoundViewSpinner stopAnimating];
		[self.nobodyFoundView removeFromSuperview];
		return;
	}
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.5];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(hideAnimation:didEndByFinishing:context:)];
	self.nobodyFoundView.alpha = 0.0;
	[UIView commitAnimations];
}

- (void) hideAnimation:(NSString*) ani didEndByFinishing:(BOOL) finished context:(void*) context;
{
	[self.nobodyFoundViewSpinner stopAnimating];
	[self.nobodyFoundView removeFromSuperview];
}

- (void) displayNobodyFoundView;
{
	if (self.nobodyFoundView.superview)
		return;

	self.nobodyFoundView.alpha = 0.0;
	self.nobodyFoundView.frame = nobodyFoundViewFrame;
	[self.nobodyFoundViewHost addSubview:self.nobodyFoundView];
	
	[self.nobodyFoundViewSpinner startAnimating];
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.5];
	self.nobodyFoundView.alpha = 1.0;
	[UIView commitAnimations];
}

- (void) dealloc;
{
	[[L0MoverPeering sharedService] removeObserver:self forKeyPath:@"disconnected"];
	self.nobodyFoundView = nil;
	[super dealloc];
}

@end
