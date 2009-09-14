//
//  MvrModernWiFiChannel.m
//  Network
//
//  Created by ∞ on 12/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrModernWiFiChannel.h"

#import <MuiKit/MuiKit.h>
#import "MvrModernWiFiOutgoing.h"
#import "MvrModernWiFiIncoming.h"

@implementation MvrModernWiFiChannel

- (id) initWithNetService:(NSNetService*) ns;
{
	self = [super init];
	if (self != nil) {
		netService = [ns retain];
		outgoingTransfers = [NSMutableSet new];
		incomingTransfers = [NSMutableSet new];
		dispatcher = [[L0KVODispatcher alloc] initWithTarget:self];
	}
	return self;
}

- (void) dealloc
{
	[dispatcher release];
	[outgoingTransfers release];
	[incomingTransfers release];
	[netService release];
	[super dealloc];
}

- (NSString*) displayName;
{
	return [netService name];
}

- (BOOL) hasSameServiceAs:(NSNetService*) n;
{
	return n == netService || ([n.name isEqual:netService.name] && [n.type isEqual:netService.type]);
}

- (BOOL) isReachableThroughAddress:(NSData*) address;
{
	for (NSData* d in netService.addresses) {
		if ([d socketAddressIsEqualToAddress:address])
			return YES;
	}
	
	return NO;
}

#pragma mark Outgoing transfers

- (void) beginSendingItem:(MvrItem*) item;
{
	MvrModernWiFiOutgoing* outgoing = [[MvrModernWiFiOutgoing alloc] initWithItem:item toAddresses:netService.addresses];
	[dispatcher observe:@"finished" ofObject:outgoing usingSelector:@selector(outgoingTransfer:finishedDidChange:) options:0];
	
	[outgoing start];
	
	[[self mutableSetValueForKey:@"outgoingTransfers"] addObject:outgoing];
	[outgoing release];
}

- (void) outgoingTransfer:(MvrModernWiFiOutgoing*) transfer finishedDidChange:(NSDictionary*) change;
{
	if (!transfer.finished)
		return;
	
	[dispatcher endObserving:@"finished" ofObject:transfer];
	[[self mutableSetValueForKey:@"outgoingTransfers"] removeObject:transfer];
}

+ keyPathsForValuesAffectingHasOutgoingTransfers;
{
	return [NSSet setWithObject:@"outgoingTransfers"];
}

- (BOOL) hasOutgoingTransfers;
{
	return [outgoingTransfers count] > 0;
}

#pragma mark Incoming transfers

- (void) addIncomingTransfersObject:(MvrModernWiFiIncoming*) incoming;
{
	[incoming observeUsingDispatcher:dispatcher invokeAtItemOrCancelledChange:@selector(incomingTransfer:itemOrCancelledChanged:)];
	[incomingTransfers addObject:incoming];
}
	 
- (void) incomingTransfer:(MvrModernWiFiIncoming*) transfer itemOrCancelledChanged:(NSDictionary*) changed;
{
	[transfer endObservingUsingDispatcher:dispatcher];
	[[self mutableSetValueForKey:@"incomingTransfers"] removeObject:transfer];
}

- (NSSet*) incomingTransfers;
{
	return incomingTransfers;
}

@end
