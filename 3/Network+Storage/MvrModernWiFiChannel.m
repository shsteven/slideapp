//
//  MvrModernWiFiChannel.m
//  Network
//
//  Created by ∞ on 12/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrModernWiFiChannel.h"

#import <MuiKit/MuiKit.h>
#import "MvrWiFiOutgoingTransfer.h"

@implementation MvrModernWiFiChannel

- (id) initWithNetService:(NSNetService*) ns;
{
	self = [super init];
	if (self != nil) {
		netService = [ns retain];
		outgoingTransfers = [NSMutableSet new];
		dispatcher = [[L0KVODispatcher alloc] initWithTarget:self];
	}
	return self;
}

- (void) dealloc
{
	[dispatcher release];
	[outgoingTransfers release];
	[netService release];
	[super dealloc];
}

- (NSString*) displayName;
{
	return [netService name];
}

// Can be KVO'd. Contains id <MvrIncoming>s.
- (NSSet*) incomingTransfers;
{
	return [NSSet set]; // TODO
}

- (BOOL) hasSameServiceAs:(NSNetService*) n;
{
	return n == netService || ([n.name isEqual:netService.name] && [n.type isEqual:netService.type]);
}

#pragma mark Outgoing transfers

- (void) beginSendingItem:(MvrItem*) item;
{
	MvrWiFiOutgoingTransfer* outgoing = [[MvrWiFiOutgoingTransfer alloc] initWithItem:item toAddresses:netService.addresses];
	[dispatcher observe:@"finished" ofObject:outgoing usingSelector:@selector(outgoingTransfer:finishedDidChange:) options:0];
	
	[outgoing start];
	
	[[self mutableSetValueForKey:@"outgoingTransfers"] addObject:outgoing];
	[outgoing release];
}

- (void) outgoingTransfer:(MvrWiFiOutgoingTransfer*) transfer finishedDidChange:(NSDictionary*) change;
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

@end
