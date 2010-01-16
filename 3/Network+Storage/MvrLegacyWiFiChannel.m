//
//  MvrLegacyWiFiChannel.m
//  Network+Storage
//
//  Created by ∞ on 15/09/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrLegacyWiFi.h"
#import "MvrLegacyWiFiChannel.h"

#import <MuiKit/MuiKit.h>

#import "MvrLegacyWiFiIncoming.h"
#import "MvrLegacyWiFiOutgoing.h"

@implementation MvrLegacyWiFiChannel

- (BOOL) isLegacyLegacy;
{
	return [self.netService.type isEqual:kMvrLegacyWiFiServiceName_1_0];
}

#pragma mark -
#pragma mark Incoming transfers.

- (void) addIncomingTransferWithConnection:(BLIPConnection*) conn;
{
	MvrLegacyWiFiIncoming* incoming = [[MvrLegacyWiFiIncoming alloc] initWithConnection:conn];
	SEL iOC = @selector(incomingTransfer:didChangeItemOrCancelledKey:);
	[incoming observeUsingDispatcher:self.dispatcher invokeAtItemChange:iOC atCancelledChange:iOC atKeyChange:NULL];

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

- (void) beginSendingItem:(MvrItem *)item;
{
	MvrLegacyWiFiOutgoing* outgoing = [[MvrLegacyWiFiOutgoing alloc] initWithItem:item toNetService:self.netService];
	[self.dispatcher observe:@"finished" ofObject:outgoing usingSelector:@selector(outgoingTransfer:didChangeFinishedKey:) options:0];	
	[self.mutableOutgoingTransfers addObject:outgoing];
	
	[outgoing start];
	[outgoing release];
}

- (void) outgoingTransfer:(MvrLegacyWiFiOutgoing*) outgoing didChangeFinishedKey:(NSDictionary*) d;
{
	if (outgoing.finished) {
		[self.dispatcher endObserving:@"finished" ofObject:outgoing];
		[self.mutableOutgoingTransfers removeObject:outgoing];
	}
}

@end
