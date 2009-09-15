//
//  MvrLegacyWiFiChannel.m
//  Network+Storage
//
//  Created by ∞ on 15/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrLegacyWiFiChannel.h"
#import "MvrLegacyWiFiIncoming.h"

#import <MuiKit/MuiKit.h>

@implementation MvrLegacyWiFiChannel

#pragma mark -
#pragma mark Incoming transfers.

- (void) addIncomingTransferWithConnection:(BLIPConnection*) conn;
{
	MvrLegacyWiFiIncoming* incoming = [[MvrLegacyWiFiIncoming alloc] initWithConnection:conn];
	[incoming observeUsingDispatcher:self.dispatcher invokeAtItemOrCancelledChange:@selector(incomingTransfer:didChangeItemOrCancelledKey:)];

	[self.mutableIncomingTransfers addObject:incoming];
	[incoming release];
}

- (void) incomingTransfer:(MvrLegacyWiFiIncoming*) incoming didChangeItemOrCancelledKey:(NSDictionary*) change;
{
	if (incoming.cancelled || incoming.item) {
		[incoming endObservingUsingDispatcher:self.dispatcher];
		[self.mutableIncomingTransfers removeObject:incoming];
	}
}

#pragma mark -
#pragma mark Outgoing



@end
