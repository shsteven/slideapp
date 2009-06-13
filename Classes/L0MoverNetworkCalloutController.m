//
//  L0MoverNetworkCalloutController.m
//  Mover
//
//  Created by ∞ on 05/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0MoverNetworkCalloutController.h"

#import "L0MoverPeering.h"
#import "L0MoverWiFiScanner.h"
#import "L0MoverBluetoothScanner.h"

#import <QuartzCore/QuartzCore.h>

@interface L0MoverNetworkCalloutController ()

- (NSSet*) allScanners;
- (NSArray*) unjammedScanners; // TODO NSSet.

- (UIColor*) colorForCurrentStatus;
- (UIColor*) selectedColorForCurrentStatus;
- (NSString*) descriptionForUnjammedScanners:(NSArray*) ujs; // TODO NSSet

- (void) updateAndShowIfNeeded;

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

#pragma mark -
#pragma mark Jamming detector

L0UniquePointerConstant(kL0MoverCalloutControllerObservationContext);

- (void) startWatchingForJams;
{
	L0Log(@"Started watching for jams.");
	
	for (id scanner in [self allScanners]) {
		[scanner addObserver:self forKeyPath:@"jammed" options:NSKeyValueObservingOptionInitial context:(void*) kL0MoverCalloutControllerObservationContext];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
{
	if ([keyPath isEqual:@"jammed"])
		[self updateAndShowIfNeeded];
}

- (void) updateAndShowIfNeeded;
{
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
	
	// TODO show if needed.
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
	L0MoverPeering* peering = [L0MoverPeering sharedService];
	
	for (id <L0MoverPeerScanner> scanner in [self allScanners]) {
		if (!scanner.jammed && scanner.enabled && [[peering availableScanners] containsObject:scanner])
			[scanners addObject:scanner];
	}
	
	return scanners;
}

- (NSString*) descriptionForUnjammedScanners:(NSArray*) ujs;
{
	L0MoverPeering* peering = [L0MoverPeering sharedService];
	
	if ([ujs count] == 0)
		return NSLocalizedStringFromTable(@"Disconnected", @"L0MoverNetworkUI", @"Shown on the callout bubble in red if all services are unavailable.");
	else if ([ujs count] == 1 && [[peering availableScanners] count] == 1)
		return NSLocalizedStringFromTable(@"On", @"L0MoverNetworkUI", @"Shown on the callout bubble if one service is available and unjammed.");
	else {
		NSMutableArray* scannerNames = [NSMutableArray array];
		if ([ujs containsObject:[L0MoverWiFiScanner sharedScanner]])
			[scannerNames addObject:
			 NSLocalizedStringFromTable(@"Wi-Fi", @"L0MoverNetworkUI", @"Shown on the callout bubble if Wi-Fi is on (eg the Wi-Fi in 'Wi-Fi, Bluetooth, Web').")
			 ];
		if ([ujs containsObject:[L0MoverBluetoothScanner sharedScanner]])
			[scannerNames addObject:
			 NSLocalizedStringFromTable(@"Bluetooth", @"L0MoverNetworkUI", @"Shown on the callout bubble if Bluetooth is on (eg the Bluetooth in 'Wi-Fi, Bluetooth, Web').")
			 ];
		
		return [scannerNames componentsJoinedByString:@", "];
	}
}

@end

