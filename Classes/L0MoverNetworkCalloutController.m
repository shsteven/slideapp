//
//  L0MoverNetworkCalloutController.m
//  Mover
//
//  Created by ∞ on 05/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0MoverNetworkCalloutController.h"

#import "MvrNetworkExchange.h"
#import "L0MoverWiFiScanner.h"
#import "L0MoverBluetoothScanner.h"

#import "L0MoverNetworkSettingsPane.h"
#import "L0MoverAppDelegate.h"

#import <QuartzCore/QuartzCore.h>

@interface L0MoverNetworkCalloutController ()

- (NSSet*) allScanners;
- (NSArray*) unjammedScanners; // TODO NSSet.

- (UIColor*) colorForCurrentStatus;
- (UIColor*) selectedColorForCurrentStatus;
- (NSString*) descriptionForUnjammedScanners:(NSArray*) ujs; // TODO NSSet

- (void) updateAndShowIfNeeded;
- (void) hideCallout;
- (void) hideCalloutAfterDelay;

@end


@implementation L0MoverNetworkCalloutController

@synthesize networkLabel, availableNetworksLabel;
@synthesize networkCalloutView;

- (void) awakeFromNib;
{
	L0AssertOutlet(self.networkCalloutView);
	L0AssertOutlet(self.networkLabel);
	L0AssertOutlet(self.availableNetworksLabel);
	
	availableNetworksLabel.text = [self descriptionForUnjammedScanners:[self unjammedScanners]];
	dispatcher = [[L0KVODispatcher alloc] initWithTarget:self];
}

- (void) dealloc;
{
	[dispatcher release];
	[networkLabel release];
	[availableNetworksLabel release];
	[networkCalloutView release];
	[super dealloc];
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
	[self showNetworkSettingsPane];	
}

- (void) showNetworkSettingsPane;
{
	L0MoverAppDelegate* delegate = (L0MoverAppDelegate*) UIApp.delegate;
	[delegate showNetworkSettingsPane];
}

#pragma mark -
#pragma mark Showing and hiding

- (void) toggleCallout;
{
	if (!self.networkCalloutView.superview)
		[self showCallout];
	else
		[self hideCalloutUnlessJammed];
}

- (void) showCallout;
{
	if (self.networkCalloutView.superview) return;
	
	UIView* view = self.anchorView;
	
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

	[self hideCalloutAfterDelay];
	
	if (!allJammed)
		[self hideCalloutAfterDelay];
}

- (void) hideCalloutAfterDelay;
{
	if (waitingForHide || allJammed) return;

	waitingForHide = YES;
	[self performSelector:@selector(hideCalloutUnlessJammed) withObject:nil afterDelay:7.0];
}

- (void) hideCallout;
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideCalloutUnlessJammed) object:nil];
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.2];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(hideAnimation:didEndByFinishing:context:)];
	
	self.networkCalloutView.alpha = 0.0;
	
	[UIView commitAnimations];
}

- (void) hideAnimation:(NSString*) ani didEndByFinishing:(BOOL) finished context:(void*) nothing;
{
	[self.networkCalloutView removeFromSuperview];
}

- (void) hideCalloutUnlessJammed;
{
	waitingForHide = NO;
	if (!allJammed)
		[self hideCallout];
}

#pragma mark -
#pragma mark Jamming detector

- (void) startWatchingForJams;
{
	L0Log(@"Started watching for jams.");
	
	for (id scanner in [self allScanners]) {
		[dispatcher observe:@"jammed" ofObject:scanner usingSelector:@selector(networkStateOfObject:changed:) options:0];
		[dispatcher observe:@"enabled" ofObject:scanner usingSelector:@selector(networkStateOfObject:changed:) options:0];
	}
	
	[dispatcher observe:@"availableScanners" ofObject:[MvrNetworkExchange sharedExchange] usingSelector:@selector(networkStateOfObject:changed:) options:0];
}

- (IBAction) showNetworkCalloutIfJammed;
{
	BOOL anyJammed = NO;
	for (id <L0MoverPeerScanner> s in [[MvrNetworkExchange sharedExchange] availableScanners]) {
		if (s.enabled && s.jammed) {
			anyJammed = YES; break;
		}
	}
	
	if (anyJammed)
		[self showCallout];
}

- (void) networkStateOfObject:(id) o changed:(NSDictionary*) change;
{
	[self updateAndShowIfNeeded];
}

- (void) updateAndShowIfNeeded;
{
	BOOL wasAllJammed = allJammed;
	
	NSArray* ujs = [self unjammedScanners];
	allJammed = ([ujs count] == 0);
	
	L0Log(@"Unjammed scanners: %@", ujs);
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.3];
	
	CATransition* t = [CATransition animation];
	t.type = kCATransitionFade;
	[availableNetworksLabel.layer addAnimation:t forKey:@"L0FadeAnimation"];

	t = [CATransition animation];
	t.type = kCATransitionFade;
	[networkLabel.layer addAnimation:t forKey:@"L0FadeAnimation"];
	
	networkLabel.textColor = [self colorForCurrentStatus];
	networkLabel.highlightedTextColor = [self selectedColorForCurrentStatus];
	availableNetworksLabel.textColor = [self colorForCurrentStatus];
	availableNetworksLabel.highlightedTextColor = [self selectedColorForCurrentStatus];
	
	availableNetworksLabel.text = [self descriptionForUnjammedScanners:ujs];
	
	[UIView commitAnimations];
	
	if (allJammed)
		[self showCallout];
	else if (wasAllJammed)
		[self hideCalloutAfterDelay];
}

- (UIColor*) colorForCurrentStatus;
{
	return allJammed? [UIColor redColor] : [UIColor blackColor];
}

- (UIColor*) selectedColorForCurrentStatus;
{
	// ffd5d5
	return allJammed? [UIColor colorWithRed:0xFF/255.0 green:0xD5/255.0 blue:0xD5/255.0 alpha:1.0] : [UIColor whiteColor];	
}

- (NSSet*) allScanners;
{
	static NSSet* s = nil; if (!s)
		s = [[NSSet alloc] initWithObjects:
			 [L0MoverWiFiScanner sharedScanner],
			 [L0MoverBluetoothScanner sharedScanner],
			 nil];
	return s;
}

- (NSArray*) unjammedScanners;
{
	NSMutableArray* scanners = [NSMutableArray array];
	//MvrNetworkExchange* peering = [MvrNetworkExchange sharedExchange];
//	
//	for (id <L0MoverPeerScanner> scanner in [self allScanners]) {
//		if (!scanner.jammed && scanner.enabled && [[peering availableScanners] containsObject:scanner])
//			[scanners addObject:scanner];
//	}
	
	// evil I know.
	
	L0MoverWiFiScanner* wifi = [L0MoverWiFiScanner sharedScanner];
	if (wifi.enabled && !wifi.jammed)
		[scanners addObject:wifi];
	
	L0MoverBluetoothScanner* bt = [L0MoverBluetoothScanner sharedScanner];
	if (bt.enabled && !bt.jammed)
		[scanners addObject:bt];
	
	return scanners;
}

- (NSString*) descriptionForUnjammedScanners:(NSArray*) ujs;
{	
	if ([ujs count] == 0)
		return NSLocalizedStringFromTable(@"Disconnected", @"L0MoverNetworkUI", @"Shown on the callout bubble in red if all services are unavailable.");
	else {
		NSMutableArray* scannerNames = [NSMutableArray array];
		if ([ujs containsObject:[L0MoverWiFiScanner sharedScanner]])
			[scannerNames addObject:
			 NSLocalizedStringFromTable(@"Wi-Fi", @"L0MoverNetworkUI", @"Shown on the callout bubble if Wi-Fi is on (eg the Wi-Fi in 'Network: Wi-Fi, Bluetooth, Web').")
			 ];
		if ([ujs containsObject:[L0MoverBluetoothScanner sharedScanner]])
			[scannerNames addObject:
			 NSLocalizedStringFromTable(@"Bluetooth", @"L0MoverNetworkUI", @"Shown on the callout bubble if Bluetooth is on (eg the Bluetooth in 'Network: Wi-Fi, Bluetooth, Web').")
			 ];
		
		return [scannerNames componentsJoinedByString:@", "];
	}
}

@synthesize anchorView;

@end

