//
//  MvrWiFiMode.m
//  Mover3
//
//  Created by ∞ on 22/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrWiFiMode.h"

#import "Network+Storage/MvrModernWiFi.h"
#import "Network+Storage/MvrLegacyWiFi.h"
#import "Network+Storage/MvrChannel.h"

#import "MvrAppDelegate.h"

@implementation MvrWiFiMode

@synthesize connectionStateDrawerView;

- (void) dealloc;
{
	[connectionStateDrawerView release];
	[super dealloc];
}

- (void) awakeFromNib;
{
	wifi = [[MvrWiFi alloc] initWithPlatformInfo:MvrApp() modernPort:kMvrModernWiFiPort legacyPort:kMvrLegacyWiFiPort];
	observer = [[MvrScannerObserver alloc] initWithScanner:wifi delegate:self];
	wifi.enabled = YES;
}

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

@end
