//
//  MvrBTScanner.m
//  Mover3
//
//  Created by ∞ on 20/10/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrBTScanner.h"
#import "MvrAppDelegate.h"
#import "MvrBTIncomingOutgoing.h"

@implementation MvrBTScanner

- (id) init
{
	self = [super init];
	if (self != nil) {
		channels = [NSMutableSet new];
	}
	return self;
}


@synthesize enabled, channels, session;

- (void) dealloc
{
	self.enabled = NO;
	self.session = nil;
	[channels release];
	[super dealloc];
}

- (GKSession*) configuredSession;
{
	GKSession* s = [[GKSession alloc] initWithSessionID:kMvrBluetoothSessionID displayName:[MvrApp() displayNameForSelf] sessionMode:GKSessionModePeer];
	return [s autorelease];
}

- (void) setSession:(GKSession *) s;
{
	if (s != session) {
		session.delegate = nil;
		[session setDataReceiveHandler:nil withContext:NULL];
		
		[session release];
		session = [s retain];
		
		session.delegate = self;
		[session setDataReceiveHandler:self withContext:NULL];
		
		self.channel = nil;
		session.available = self.enabled;
	}
}

- (void) setEnabled:(BOOL) e;
{
	BOOL was = enabled;
	enabled = e;
	
	session.available = e;
	
	if (was && !enabled)
		self.channel = nil;
}

- (BOOL) jammed;
{
	return NO;
}

- (MvrBTChannel*) channel;
{
	return [channels anyObject];
}

- (void) setChannel:(MvrBTChannel*) c;
{
	NSMutableSet* chans = [self mutableSetValueForKey:@"channels"];
	[chans removeAllObjects];
	if (c)
		[chans addObject:c];
}

+ (NSSet*) keyPathsForValuesAffectingChannel;
{
	return [NSSet setWithObject:@"channels"];
}

- (void) acceptPeerWithIdentifier:(NSString*) peerID;
{
	MvrBTChannel* chan = [[[MvrBTChannel alloc] initWithScanner:self peerID:peerID] autorelease];
	self.channel = chan;
}

#pragma mark -
#pragma mark Session control

// Question: should we handle them? Doesn't the peer picker manage all of this?

- (void)session:(GKSession *)s didReceiveConnectionRequestFromPeer:(NSString *)peerID;
{
	if (self.channel)
		[s denyConnectionFromPeer:peerID];
	else {
		NSError* e;
		if ([s acceptConnectionFromPeer:peerID error:&e])
			[self acceptPeerWithIdentifier:peerID];
		else
			L0LogAlways(@"Could not accept a connection from peer with id %@", peerID);
	}
}

- (void)session:(GKSession *)s connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error;
{
	L0Log(@"A connection attempt failed to peer %@ with error %@", peerID, error);
	
	if ([self.channel.peerID isEqual:peerID])
		self.channel = nil;
}

// Error checking

- (void)session:(GKSession *)s didFailWithError:(NSError *)error;
{
	L0Log(@"The GameKit session failed with error %@", error);
	[session disconnectFromAllPeers];
}

- (void) receiveData:(NSData*) data fromPeer:(NSString*) peerID inSession:(GKSession*) s context:(void*) context;
{
	if ([MvrBTIncoming isLiteWarningPacket:data]) {

#if kMvrIsLite
		self.channel = nil;
		[[NSNotificationCenter defaultCenter] postNotificationName:kMvrBTConnectionToLiteVersionBeingDroppedNotification object:self];
#endif
		
		return;
		
	}
	
	[self.channel didReceiveData:data];
}

- (void) session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state;
{
	if (!self.channel || ![peerID isEqual:self.channel.peerID]) {
		L0Log(@"Got a status change for a peer other than our current channel: %@, %lu", peerID, (unsigned long) state);
		return;
	}
	
	L0Log(@"State change for our channel! => %d", (unsigned long) state);
	
	if (state == GKPeerStateDisconnected)
		self.channel = nil;
}

@end

@implementation MvrBTChannel

- (id) initWithScanner:(MvrBTScanner*) s peerID:(NSString*) p;
{
	if (self = [super init]) {
		scanner = [s retain];
		peerID = [p copy];
		incomingTransfers = [NSMutableSet new];
		outgoingTransfers = [NSMutableSet new];
		kvo = [[L0KVODispatcher alloc] initWithTarget:self];
		
#if kMvrIsLite
		[self sendData:[MvrBTIncoming liteWarningPacket] error:NULL];
#endif
	}
	
	return self;
}

@synthesize peerID, incomingTransfers, outgoingTransfers;

- (void) dealloc
{
	[kvo release];
	
	[scanner release];
	[peerID release];
	
	[self.incomingTransfer cancel];
	[incomingTransfers release];
	
	[self.outgoingTransfer cancel];
	[outgoingTransfers release];
	
	[super dealloc];
}

- (MvrBTIncoming*) incomingTransfer;
{
	return [incomingTransfers anyObject];
}
- (void) setIncomingTransfer:(MvrBTIncoming*) c;
{
	NSMutableSet* set = [self mutableSetValueForKey:@"incomingTransfers"];
	
	if (self.incomingTransfer) {
		[kvo endObserving:@"item" ofObject:self.incomingTransfer];
		[kvo endObserving:@"finished" ofObject:self.incomingTransfer];
	}
	
	[set removeAllObjects];
	if (c) {
		[set addObject:c];
		
		[kvo observe:@"item" ofObject:c usingSelector:@selector(incomingTransferMightHaveFinished:change:) options:0];
		[kvo observe:@"finished" ofObject:c usingSelector:@selector(incomingTransferMightHaveFinished:change:) options:0];
	}
}

- (MvrBTOutgoing*) outgoingTransfer;
{
	return [outgoingTransfers anyObject];
}
- (void) setOutgoingTransfer:(MvrBTOutgoing*) c;
{
	NSMutableSet* set = [self mutableSetValueForKey:@"outgoingTransfers"];

	if (self.outgoingTransfer)
		[kvo endObserving:@"finished" ofObject:self.outgoingTransfer];
	
	[set removeAllObjects];
	
	if (c) {
		[set addObject:c];
		[kvo observe:@"finished" ofObject:c usingSelector:@selector(outgoingTransferDidChangeFinished:change:) options:0];
	}
}

#if !kMvrIsLite

- (void) outgoingTransferDidChangeFinished:(MvrBTOutgoing*) outgoing change:(NSDictionary*) change;
{
	if (self.outgoingTransfer.finished)
		self.outgoingTransfer = nil;
}

#endif

- (void) incomingTransferMightHaveFinished:(MvrBTIncoming*) incoming change:(NSDictionary*) change;
{
	if (self.incomingTransfer.item || self.incomingTransfer.cancelled)
		self.incomingTransfer = nil;
}

+ (NSSet*) keyPathsForValuesAffectingIncomingTransfer;
{
	return [NSSet setWithObject:@"incomingTransfers"];
}
+ (NSSet*) keyPathsForValuesAffectingOutgoingTransfer;
{
	return [NSSet setWithObject:@"outgoingTransfers"];
}

- (void) didReceiveData:(NSData*) data;
{
	if (self.outgoingTransfer)
		[self.outgoingTransfer didReceiveDataFromBluetooth:data];
	else if (self.incomingTransfer)
		[self.incomingTransfer didReceiveDataFromBluetooth:data];
	else if ([MvrBTIncoming shouldStartReceivingWithData:data]) {
		MvrBTIncoming* inc = [MvrBTIncoming incomingTransferWithChannel:self];
		self.incomingTransfer = inc;
		[inc didReceiveDataFromBluetooth:data];
	}
}

- (BOOL) sendData:(NSData*) data error:(NSError**) e;
{
	BOOL sent = [scanner.session sendData:data toPeers:[NSArray arrayWithObject:self.peerID] withDataMode:GKSendDataReliable error:e];
	
	if (!sent) {
		if (e)
			L0Log(@"An error occurred when sending data: %@", *e);
	}
	
	return sent;
}

- (BOOL) supportsStreams;
{
	return YES;
}

- (void) beginSendingItem:(MvrItem*) i;
{
	if (self.outgoingTransfer)
		return;
	
#if !kMvrIsLite
	MvrBTOutgoing* outg = [MvrBTOutgoing outgoingTransferWithItem:i channel:self];
	self.outgoingTransfer = outg;
	[outg start];
#else
	[[NSNotificationCenter defaultCenter] postNotificationName:kMvrBTOutgoingUnavailableInLiteVersionNotification object:self];
#endif
}

- (NSString*) displayName;
{
	return [scanner.session displayNameForPeer:self.peerID];
}

@end
