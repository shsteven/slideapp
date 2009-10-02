//
//  MvrWiFiMode.m
//  Mover3
//
//  Created by ∞ on 22/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrWiFiMode.h"

#import <QuartzCore/QuartzCore.h>

#import "Network+Storage/MvrModernWiFi.h"
#import "Network+Storage/MvrLegacyWiFi.h"
#import "Network+Storage/MvrChannel.h"

#import "MvrAppDelegate.h"

@implementation MvrWiFiMode

@synthesize connectionStateDrawerView, connectionStateInfo, connectionStateImage, connectionStateContainer;

- (void) awakeFromNib;
{
	wifi = [[MvrWiFi alloc] initWithPlatformInfo:MvrApp() modernPort:kMvrModernWiFiPort legacyPort:kMvrLegacyWiFiPort];
	observer = [[MvrScannerObserver alloc] initWithScanner:wifi delegate:self];
	
	if (self.delegate) // we're on!
		wifi.enabled = YES;
}

- (void) dealloc;
{
	[observer release];

	[wifi release];
	[connectionStateDrawerView release];
	[super dealloc];
}

#pragma mark Jamming

- (void) scanner:(id <MvrScanner>)s didChangeJammedKey:(BOOL)jammed;
{
	if (!jammed) {
		
		self.connectionStateInfo.text = NSLocalizedString(@"Wi-Fi On", @"Wi-Fi unjammed text");
		self.connectionStateImage.image = [UIImage imageNamed:@"GreenDot.png"];
		
	} else {
		
		self.connectionStateInfo.text = NSLocalizedString(@"Wi-Fi Disconnected", @"Wi-Fi jammed text");
		self.connectionStateImage.image = [UIImage imageNamed:@"RedDot.png"];
		
	}
	
	[self.connectionStateContainer setAccessibilityValue:self.connectionStateInfo.text];
}

#pragma mark Channels

- (void) scanner:(id <MvrScanner>) s didAddChannel:(id <MvrChannel>) channel;
{
	[self.mutableDestinations addObject:channel];
}

- (void) scanner:(id <MvrScanner>) s didRemoveChannel:(id <MvrChannel>) channel;			
{
	[self.mutableDestinations removeObject:channel];
}

- (NSString*) displayNameForDestination:(id) dest;
{
	return [dest displayName];
}

- (void) channel:(id <MvrChannel>)c didChangeSupportsStreamsKey:(BOOL)supportsStreams;
{
	MvrArrowView* arrow = [self arrowViewForDestination:c];
	
	CATransition* fade = [CATransition animation];
	fade.type = kCATransitionFade;
	[arrow.nameLabel.layer addAnimation:fade forKey:@"MvrWiFiModeStreamSupportFade"];
	arrow.normalColor = supportsStreams? [UIColor blackColor] : [UIColor grayColor];
	arrow.nameLabel.textColor = arrow.normalColor;
}

#pragma mark Sending items

- (void) sendItem:(MvrItem*) i toDestinationAtDirection:(MvrDirection) dest;
{
	[[self destinationAtDirection:dest] beginSendingItem:i];
}

- (void) channel:(id <MvrChannel>)c didBeginSendingWithOutgoingTransfer:(id <MvrOutgoing>)outgoing;
{
	MvrDirection dir = [self directionForDestination:c];
	if (dir == kMvrDirectionNone)
		return;
	
	[[self.arrowsView viewAtDirection:dir] setBusy:YES];
}

- (void) outgoingTransferDidEndSending:(id <MvrOutgoing>) outgoing;
{
	const MvrDirection directions[] = { kMvrDirectionNorth, kMvrDirectionEast, kMvrDirectionWest };
	const size_t directionsCount = 3;
	
	int i;
	for (i = 0; i < directionsCount; i++) {
		
		id dest = [self destinationAtDirection:directions[i]];
		if (!dest)
			continue;
		
		[[self.arrowsView viewAtDirection:directions[i]] setBusy:([[dest outgoingTransfers] count] > 0)];
	}
}

#pragma mark Receiving items

- (void) channel:(id <MvrChannel>) c didBeginReceivingWithIncomingTransfer:(id <MvrIncoming>) incoming;
{
	[self.delegate UIMode:self willBeginReceivingItemWithTransfer:incoming fromDirection:[self directionForDestination:c]];
}

#pragma mark Enabling/disabling

- (void) modeDidBecomeCurrent:(BOOL) ani;
{
	wifi.enabled = YES;
}

- (void) modeWillStopBeingCurrent:(BOOL)animated;
{
	wifi.enabled = NO;
}

@end
