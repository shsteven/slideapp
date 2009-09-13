//
//  MvrWiFiOutgoingTransfer.m
//  Mover
//
//  Created by ∞ on 29/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrWiFiOutgoingTransfer.h"

#import <MuiKit/MuiKit.h>

#import "AsyncSocket.h"
#import "MvrItem.h"
#import "MvrPacketBuilder.h"
#import "MvrModernWiFiChannel.h"
#import "MvrItemStorage.h"

@interface MvrWiFiOutgoingTransfer ()

- (void) cancel;
- (void) endWithError:(NSError *)e;

- (void) buildPacket;

@property(assign) BOOL finished;
@property(assign) float progress;

- (NSData*) bestCandidateAddress;

@end


@implementation MvrWiFiOutgoingTransfer

- (id) initWithItem:(MvrItem*) i toAddresses:(NSArray*) a;
{
	if (self = [super init]) {
		item = [i retain];
		addresses = [a copy];
	}
	
	return self;
}

- (void) dealloc;
{
	[self cancel];
	[item release];
	[addresses release];
	[super dealloc];
}

@synthesize finished, progress;

#pragma mark -
#pragma mark Socket and state management.

- (NSData*) bestCandidateAddress;
{
	NSData* address = nil;
	for (NSData* potentialAddress in addresses) {
		if ([potentialAddress socketAddressIsIPAddressOfVersion:kL0IPAddressVersion4]) {
			address = potentialAddress;
			break;
		}
	}
	
	return address;
}

- (void) start;
{
	NSData* address = [self bestCandidateAddress];
	
	if (!address) {
		[self cancel];
		return;
	}
	
	NSAssert(!socket, @"No socket before starting");
	socket = [[AsyncSocket alloc] initWithDelegate:self];
	
	NSError* e = nil;
	BOOL done = [socket connectToAddress:address withTimeout:15 error:&e];
	if (!done) {
		L0Log(@"Did not connect: %@", e);
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
	
	L0Log(@"%@", e);
	
	[builder stop];
	[builder release]; builder = nil;
	
	[socket setDelegate:nil];
	[socket release]; socket = nil;
	
	[[self retain] autorelease]; // people watching -finished could release us. Prevent nastiness.
	self.finished = YES;
}

- (void) onSocket:(AsyncSocket*) sock didConnectToHost:(NSString*) host port:(UInt16) port;
{
	L0Log(@"%@: %@:%d", self, host, port);
	[self buildPacket];
}

- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err;
{
	if (err)
		[self endWithError:err];
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag;
{
	L0Note();
	[self endWithError:nil];
}

- (void) onSocketDidDisconnect:(AsyncSocket *)sock;
{
	L0Note();
	[self endWithError:nil];
}

#pragma mark -
#pragma mark Packet building.

- (void) buildPacket;
{
	builder = [[MvrPacketBuilder alloc] initWithDelegate:self];
	
	[builder setMetadataValue:item.title forKey:kMvrProtocolMetadataTitleKey];
	[builder setMetadataValue:item.type forKey:kMvrProtocolMetadataTypeKey];
	
	[builder addPayload:[item.storage preferredContentObject] length:item.storage.contentLength forKey:kMvrProtocolExternalRepresentationPayloadKey];
	
	[builder start];
}

- (void) packetBuilderWillStart:(MvrPacketBuilder *)b;
{
	self.progress = builder.progress;
}

- (void) packetBuilder:(MvrPacketBuilder*) b didProduceData:(NSData*) d;
{
	[socket writeData:d withTimeout:-1 tag:0];
	self.progress = builder.progress;

	L0Log(@"Writing %llu bytes, %u chunks now pending", (unsigned long long) [d length], chunksPending);
}

- (void) packetBuilder:(MvrPacketBuilder*) b didEndWithError:(NSError*) e;
{
	L0Log(@"%@", e);
	
	self.progress = builder.progress;
	
	[socket readDataToLength:1 withTimeout:120 tag:0];
}

@end
