//
//  MvrBluetoothChannel.m
//  Mover3
//
//  Created by ∞ on 05/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrBluetoothChannel.h"
#import "MvrBluetoothScanner.h"

@implementation MvrBluetoothChannel

- (id) initWithScanner:(MvrBluetoothScanner*) s peerIdentifier:(NSString*) peerID;
{
	self = [super init];
	if (self != nil) {
		scanner = s;
		self.peerIdentifier = peerID;
	}
	
	return self;
}

@synthesize peerIdentifier, incomingTransfer, outgoingTransfer;

- (void) dealloc
{
	self.incomingTransfer = nil;
	self.outgoingTransfer = nil;
	
	[peerIdentifier release];
	[super dealloc];
}

- (NSSet*) incomingTransfers;
{
	return self.incomingTransfer? [NSSet setWithObject:self.incomingTransfer] : [NSSet set];
}
- (void) setIncomingTransfer:(MvrBluetoothIncoming *) i;
{
	if (incomingTransfer != i) {
		[self willChangeValueForKey:@"incomingTransfers" withSetMutation:NSKeyValueSetSetMutation usingObjects:i? [NSSet setWithObject:i] : [NSSet set]];
		
		[incomingTransfer release];
		incomingTransfer = [i retain];
		
		[self didChangeValueForKey:@"incomingTransfers" withSetMutation:NSKeyValueSetSetMutation usingObjects:i? [NSSet setWithObject:i] : [NSSet set]];
	}
}

- (NSSet*) outgoingTransfers;
{
	return self.outgoingTransfer? [NSSet setWithObject:self.outgoingTransfer] : [NSSet set];
}
- (void) setOutgoingTransfer:(MvrBluetoothOutgoing *) i;
{
	if (outgoingTransfer != i) {
		[self willChangeValueForKey:@"outgoingTransfers" withSetMutation:NSKeyValueSetSetMutation usingObjects:i? [NSSet setWithObject:i] : [NSSet set]];
		
		[outgoingTransfer release];
		outgoingTransfer = [i retain];
		
		[self didChangeValueForKey:@"outgoingTransfers" withSetMutation:NSKeyValueSetSetMutation usingObjects:i? [NSSet setWithObject:i] : [NSSet set]];
	}
}

- (NSString*) displayName;
{
	return [scanner.session displayNameForPeer:self.peerIdentifier];
}

- (BOOL) supportsStreams;
{
	return YES;
}

- (void) beginSendingItem:(MvrItem *)item;
{
	if (self.outgoingTransfer)
		return;
	
	self.outgoingTransfer = [[[MvrBluetoothOutgoing alloc] initWithItem:item scanner:scanner] autorelease];
	[self.outgoingTransfer start];
}

@end
