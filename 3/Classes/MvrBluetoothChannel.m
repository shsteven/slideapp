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
	[incomingTransfer release];
	[outgoingTransfer release];
	[peerIdentifier release];
	[super dealloc];
}

- (NSSet*) incomingTransfers;
{
	return self.incomingTransfer? [NSSet setWithObject:self.incomingTransfer] : [NSSet set];
}
+ (NSSet*) keyPathsForValuesAffectingIncomingTransfers;
{
	return [NSSet setWithObject:@"incomingTransfer"];
}

- (NSSet*) outgoingTransfers;
{
	return self.outgoingTransfer? [NSSet setWithObject:self.outgoingTransfer] : [NSSet set];
}
+ (NSSet*) keyPathsForValuesAffectingOutgoingTransfers;
{
	return [NSSet setWithObject:@"outgoingTransfer"];
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
