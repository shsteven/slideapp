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
	for (NSString* s in [NSArray arrayWithObjects:@"northDestination", @"eastDestination", @"westDestination", nil]) {
		
		id dest = [self valueForKey:s];
		if (!dest)
			continue;
		
		[[self.arrowsView viewAtDirection:[self directionForDestination:dest]] setBusy:([[dest outgoingTransfers] count] > 0)];
		
	}
}

@end
