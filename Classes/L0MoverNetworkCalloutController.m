//
//  L0MoverNetworkCalloutController.m
//  Mover
//
//  Created by ∞ on 05/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0MoverNetworkCalloutController.h"

@interface L0MoverNetworkCalloutController ()

@end


@implementation L0MoverNetworkCalloutController

@synthesize networkLabel, availableNetworksLabel;
@synthesize networkCalloutView;

- (void) dealloc;
{
	[networkLabel release];
	[availableNetworksLabel release];
	[networkCalloutView release];
	[super dealloc];
}

- (void) awakeFromNib;
{
	L0AssertOutlet(self.networkCalloutView);
	L0AssertOutlet(self.networkLabel);
	L0AssertOutlet(self.availableNetworksLabel);
}

- (IBAction) highlightCallout;
{
	networkLabel.highlighted = YES;
	availableNetworksLabel.highlighted = YES;
}

- (IBAction) unhighlightCallout;
{
	networkLabel.highlighted = NO;
	availableNetworksLabel.highlighted = NO;
}

- (IBAction) pressedCallout;
{
	[self unhighlightCallout];
	L0Log(@"Yay!"); // TODO
}

- (void) showAboveView:(UIView*) view;
{
	if (self.networkCalloutView.superview) return;
	
	CGRect frame = view.frame;
	CGSize calloutSize = self.networkCalloutView.frame.size;
	
	CGPoint newOrigin;
	/* centered over the view's frame */
	newOrigin.x = frame.origin.x + (frame.size.width / 2) - (calloutSize.width / 2);
	/* overlapping by a fifth of our size at the top of the view. */
	newOrigin.y = frame.origin.y - (calloutSize.height * 4.0/5.0);
	
	// TODO better animation/animation control from outside/fine tuning
	CGRect newFrame;
	newFrame.origin = newOrigin;
	newFrame.size = calloutSize;
	self.networkCalloutView.frame = newFrame;
	self.networkCalloutView.alpha = 0.0;
	[view.superview addSubview:self.networkCalloutView];
	[view.superview bringSubviewToFront:self.networkCalloutView];
	 
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.3];
	self.networkCalloutView.alpha = 1.0;
	[UIView commitAnimations];
}

@end

