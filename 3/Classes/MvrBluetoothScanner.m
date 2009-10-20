//
//  MvrBluetoothScanner.m
//  Mover3
//
//  Created by ∞ on 05/10/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrBluetoothScanner.h"

#import "Network+Storage/MvrItem.h"
#import "Network+Storage/MvrItemStorage.h"

#import "MvrAppDelegate.h"

#import <stdio.h>

// We have the code here for channels because they're intrinsically tied to the scanner (which holds the single GKSession we want to have).

// -- - --

@implementation MvrBluetoothScanner

@synthesize enabled, channel, session;

- (void) dealloc
{
	self.enabled = NO;
	self.session = nil;
	[channel release];
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

- (NSSet*) channels;
{
	L0Log(@"Returning a set of channel: %@ (empty if nil)", self.channel);
	return self.channel? [NSSet setWithObject:self.channel] : [NSSet set];
}

- (void) setChannel:(MvrBluetoothChannel *) c;
{
	if (channel != c) {
		[self willChangeValueForKey:@"channels" withSetMutation:NSKeyValueSetSetMutation usingObjects:c? [NSSet setWithObject:c] : [NSSet set]];
		
		[channel release];
		channel = [c retain];
		
		[self didChangeValueForKey:@"channels" withSetMutation:NSKeyValueSetSetMutation usingObjects:c? [NSSet setWithObject:c] : [NSSet set]];
	}
}

static const char starter[] = { 'M', '3', 'G', 'O', 0x0 };
static const size_t starterLength = sizeof(starter) / sizeof(const char);

- (void) receiveData:(NSData*) data fromPeer:(NSString*) peerID inSession:(GKSession*) s context:(void*) context;
{
	const char acknowledger[] = { 'M', '3', 'O', 'K', 0x0 };
	const size_t acknowledgerLength = sizeof(acknowledger) / sizeof(const char);
	
	BOOL isAck = [data length] == acknowledgerLength && (memcmp(acknowledger, [data bytes], acknowledgerLength) == 0);
	
	if (self.channel.outgoingTransfer && isAck) {
		[self.channel.outgoingTransfer acknowledge];
		return;
	}
	
	BOOL isStarter = [data length] == starterLength && (memcmp(starter, [data bytes], starterLength) == 0);
	
	if (!self.channel.incomingTransfer && isStarter) {
		L0Log(@"Received the starter. Acknowledging.");
		
		MvrBluetoothIncoming* incoming = [[MvrBluetoothIncoming new] autorelease];
		self.channel.incomingTransfer = incoming;
		[session sendData:[NSData dataWithBytesNoCopy:(void*) acknowledger length:acknowledgerLength freeWhenDone:NO] toPeers:[NSArray arrayWithObject:peerID] withDataMode:GKSendDataReliable error:NULL];
		return;
	}
	
	[self.channel.incomingTransfer appendData:data];
	[session sendData:[NSData dataWithBytesNoCopy:(void*) acknowledger length:acknowledgerLength freeWhenDone:NO] toPeers:[NSArray arrayWithObject:peerID] withDataMode:GKSendDataReliable error:NULL];
}

- (void) session:(GKSession *)s peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state;
{
#if DEBUG
	fflush(stdout);
	fflush(stderr);
#endif
	
	L0Log(@"Observed: %@'s peer %@ changed state to %d", s, peerID, state);
	if ([self.channel.peerIdentifier isEqual:peerID] && state == GKPeerStateDisconnected || state == GKPeerStateUnavailable) {
		[self willChangeValueForKey:@"channels"];
		self.channel = nil;
		[self didChangeValueForKey:@"channels"];
	}
}

- (void) acceptPeerWithIdentifier:(NSString*) peerID;
{
	if (![[session peersWithConnectionState:GKPeerStateConnected] containsObject:peerID]) {
		L0Log(@"Cannot accept peer %@ because it's not connected to our session!", peerID);
		return;
	}
	
	L0Log(@"Accepted peer %@ as our channel.", peerID);
	self.channel = [[[MvrBluetoothChannel alloc] initWithScanner:self peerIdentifier:peerID] autorelease];
}

- (void) session:(GKSession *)s didReceiveConnectionRequestFromPeer:(NSString *)peerID;
{
	[s acceptConnectionFromPeer:peerID error:NULL];
}

@end

@implementation MvrBluetoothIncoming

// Here if we ever need customizing it.

@end

@implementation MvrBluetoothOutgoing

- (id) initWithItem:(MvrItem*) i scanner:(MvrBluetoothScanner*) s;
{
	self = [super init];
	if (self != nil) {
		item = [i retain];
		scanner = s; // it owns us indirectly
		builder = [(MvrPacketBuilder*)[MvrPacketBuilder alloc] initWithDelegate:self];
		buffer = [MvrBuffer new];
		buffer.consumptionSize = 20000;
	}
	return self;
}

@synthesize error, finished;

- (void) dealloc
{
	[self endWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
	[error release];
	[super dealloc];
}

- (void) start;
{
	L0Log(@"Sending the starter.");
	
	starting = YES;
	
	NSData* data = [NSData dataWithBytesNoCopy:(void*) starter length:starterLength freeWhenDone:NO];
	NSError* e;
	if (![scanner.session sendData:data toPeers:[NSArray arrayWithObject:scanner.channel.peerIdentifier] withDataMode:GKSendDataReliable error:&e]) {
		
		L0LogAlways(@"%@", e);
		[self endWithError:e];
		return;
	}
}

- (void) packetBuilder:(MvrPacketBuilder *)b didProduceData:(NSData *)d;
{
	L0Log(@"Producing a packet for Bluetooth. Progress = %f", builder.progress);
	[buffer appendData:d];
	builder.paused = YES;
	
	[self sendPacketPart];
}

- (void) sendPacketPart;
{
	NSData* consumed = [buffer consume];
	if (consumed) {
		NSError* e;
		if (![scanner.session sendData:consumed toPeers:[NSArray arrayWithObject:scanner.channel.peerIdentifier] withDataMode:GKSendDataReliable error:&e]) {
			
			L0LogAlways(@"%@", e);
			[self endWithError:e];
			
		} else {
			acknowledgesEnequeued++;
			// L0Log(@"Now expecting %d acks", acknowledgesEnequeued);
		}
	} else
		builder.paused = NO;

}

- (void) acknowledge;
{
	// L0Log(@"Ack'd. Now expecting %d more acks.", acknowledgesEnequeued);
	if (starting) {
		
		[builder setMetadataValue:item.title forKey:kMvrProtocolMetadataTitleKey];
		[builder setMetadataValue:item.type forKey:kMvrProtocolMetadataTypeKey];
		
		[builder addPayload:[item.storage preferredContentObject] length:item.storage.contentLength forKey:kMvrProtocolExternalRepresentationPayloadKey];
		
		[builder start];
		
	} else if (finishing)
		[self endWithError:nil];
	else
		[self performSelector:@selector(sendPacketPart) withObject:nil afterDelay:0.05];
}

- (void) packetBuilder:(MvrPacketBuilder *)b didEndWithError:(NSError *)e;
{
	if (e)
		[self endWithError:e];
	else
		finishing = YES;
}

- (void) endWithError:(NSError*) e;
{
	if (self.finished) return;
	
	L0Log(@"Will end with error %@", e);
	
	self.error = e;
	self.finished = YES;
	
	[builder stop];
	[builder release]; builder = nil;
	
	[buffer release]; buffer = nil;
	
	[item release]; item = nil;
}

@end

