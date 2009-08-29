//
//  MvrWiFiOutgoingTransfer.m
//  Mover
//
//  Created by ∞ on 29/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrWiFiOutgoingTransfer.h"
#import <MuiKit/MuiKit.h>

@interface MvrWiFiOutgoingTransfer ()

- (void) cancel;
- (void) endWithError:(NSError *)e;

- (void) buildPacket;

@property(assign) BOOL finished;
@property(assign) CGFloat progress;

@end


@implementation MvrWiFiOutgoingTransfer

- (id) initWithItem:(L0MoverItem*) i toChannel:(MvrWiFiChannel*) c;
{
	if (self = [super init]) {
		item = [i retain];
		channel = c; // The channel owns transfers.
	}
	
	return self;
}

- (void) dealloc;
{
	[self cancel];
	[item release];
	[super dealloc];
}

@synthesize finished, progress;

#pragma mark -
#pragma mark Socket and state management.

- (void) start;
{
	[[MvrNetworkExchange sharedExchange] channel:channel willSendItemToOtherEndpoint:item];
	
	NSData* address = nil;
	for (NSData* potentialAddress in [channel.service addresses]) {
		if ([potentialAddress socketAddressIsIPAddressOfVersion:kL0IPAddressVersion4]) {
			address = potentialAddress;
			break;
		}
	}
	
	if (!address) {
		[self cancel];
		return;
	}
	
	NSAssert(!socket, @"No socket before starting");
	socket = [[AsyncSocket alloc] initWithDelegate:self];
	
	NSError* e;
	BOOL done = [socket connectToAddress:address error:&e];
	if (!done) {
		[self cancel];
		return;
	}
}

- (void) cancel;
{
	[self endWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
}

- (void) endWithError:(NSError*) e;
{
	if (self.finished) return;
	self.finished = YES;
	
	L0Log(@"%@", e);
	
	[socket disconnectAfterWriting];
	[socket release]; socket = nil;
	
	[builder stop];
	[builder release]; builder = nil;
	
	[[MvrNetworkExchange sharedExchange] channel:channel didSendItemToOtherEndpoint:item];
}

- (void) onSocket:(AsyncSocket*) sock didConnectToHost:(NSString*) host port:(UInt16) port;
{
	[self buildPacket];
}

- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err;
{
	[self endWithError:err];
}

#pragma mark -
#pragma mark Packet building.

- (void) buildPacket;
{
	builder = [[MvrPacketBuilder alloc] initWithDelegate:self];
	[builder setMetadataValue:kMvrProtocolMetadataTitleKey forKey:item.title];
	[builder setMetadataValue:kMvrProtocolMetadataTypeKey forKey:item.type];
	
	// TODO allow use of NSStreams alongside NSData in items.
	NSData* exp = [item externalRepresentation];
	[builder addPayloadWithData:exp forKey:kMvrProtocolExternalRepresentationPayloadKey];
}

- (void) packetBuilderWillStart:(MvrPacketBuilder *)b;
{
	self.progress = builder.progress;
}

- (void) packetBuilder:(MvrPacketBuilder*) b didProduceData:(NSData*) d;
{
	[socket writeData:d withTimeout:20 tag:0];
	self.progress = builder.progress;
}

- (void) packetBuilder:(MvrPacketBuilder*) b didEndWithError:(NSError*) e;
{
	self.progress = builder.progress;
	[self endWithError:e];
}

@end
