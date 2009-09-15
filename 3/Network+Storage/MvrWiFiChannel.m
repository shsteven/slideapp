//
//  MvrWiFiChannel.m
//  Network+Storage
//
//  Created by ∞ on 15/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrWiFiChannel.h"

#import <MuiKit/MuiKit.h>

@implementation MvrWiFiChannel

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

#pragma mark -
#pragma mark Accessors for subclasses

@synthesize dispatcher, netService;

// Subclasses should use these to edit the outgoing/incoming sets...
- (NSMutableSet*) mutableOutgoingTransfers;
{
	return [self mutableSetValueForKey:@"outgoingTransfers"];
}

- (NSMutableSet*) mutableIncomingTransfers;
{
	return [self mutableSetValueForKey:@"outgoingTransfers"];
}

- (NSSet*) incomingTransfers;
{
	return incomingTransfers;
}

- (NSSet*) outgoingTransfers;
{
	return incomingTransfers;
}

// ... and override these to get notifications for outgoings/incomings being added/removed.

- (void) addOutgoingTransfersObject:(id) transfer;
{
	[outgoingTransfers addObject:transfer];
}

- (void) removeOutgoingTransfersObject:(id) transfer;
{
	[outgoingTransfers removeObject:transfer];
}

- (void) addIncomingTransfersObject:(id) transfer;
{
	[incomingTransfers addObject:transfer];
}

- (void) removeIncomingTransfersObject:(id) transfer;
{
	[incomingTransfers removeObject:transfer];
}

- (void) beginSendingItem:(MvrItem *)item; // abstract
{
	L0AbstractMethod();
}

@end
