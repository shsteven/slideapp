//
//  MvrWiFiIncomingTransfer.m
//  Mover
//
//  Created by ∞ on 25/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrWiFiIncomingTransfer.h"
#import "L0MoverItem.h"

@interface MvrWiFiIncomingTransfer ()

- (void) checkMetadataIfNeeded;
- (void) cancel;
- (void) produceItem;

@end


@implementation MvrWiFiIncomingTransfer

- (id) initWithSocket:(AsyncSocket*) s channel:(id <L0MoverPeerChannel>) c;
{
	if (self = [super init]) {
		socket = [s retain];
		[s setDelegate:self];
		
		parser = [[MvrPacketParser alloc] initWithDelegate:self];
		isNewPacket = YES;
		
		data = [NSMutableData new];
		channel = [c retain];
		
		[[MvrNetworkExchange sharedExchange] channelWillBeginReceiving:c];
	}
	
	return self;
}

@synthesize finished;

- (void) clear;
{
	[channel release]; channel = nil;
	
	[socket disconnect];
	[socket setDelegate:nil];
	[socket release]; socket = nil;
	
	[metadata release]; metadata = nil;
	
	[parser release]; parser = nil;
}

- (void) dealloc;
{
	[self clear];
	[super dealloc];
}

#pragma mark -
#pragma mark Sockets.

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port;
{
	[sock readDataWithTimeout:15 tag:0];
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)d withTag:(long)tag;
{
	[parser appendData:d isKnownStartOfNewPacket:isNewPacket];
	isNewPacket = NO;
}

- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err;
{
	L0Log(@"%@: %@", self, err);
	[self cancel];
}

#pragma mark -
#pragma mark Parsing.

- (void) packetParserDidStartReceiving:(MvrPacketParser*) p;
{
	// o well.
}

- (void) packetParser:(MvrPacketParser*) p didReceiveMetadataItemWithKey:(NSString*) key value:(NSString*) value;
{
	if (isCancelled) return;
	
	[metadata setObject:value forKey:key];
}

- (void) packetParser:(MvrPacketParser*) p didReceivePayloadPart:(NSData*) d forKey:(NSString*) key;
{
	if (isCancelled) return;
	
	[self checkMetadataIfNeeded];
	if (isCancelled) return; // could cancel in checkMetadata...
	
	if (![key isEqual:kMvrProtocolExternalRepresentationPayloadKey])
		return;
	
	[data appendData:d];
}

// e == nil if no error.
- (void) packetParser:(MvrPacketParser*) p didReturnToStartingStateWithError:(NSError*) e;
{
	if (e) {
		L0Log(@"An error happened while parsing: %@", e);
		[self cancel];
	} else
		[self produceItem];
}

- (void) checkMetadataIfNeeded;
{
	if (![metadata objectForKey:kMvrProtocolMetadataTitleKey] || ![metadata objectForKey:kMvrProtocolMetadataTypeKey])
		[self cancel];
}

#pragma mark -
#pragma mark Flow control.

- (void) cancel;
{
	[[MvrNetworkExchange sharedExchange] channelDidCancelReceivingItem:channel];
	isCancelled = YES;
	[self clear];
}

- (void) produceItem;
{
	NSString* title = [metadata objectForKey:kMvrProtocolMetadataTitleKey], 
		* type = [metadata objectForKey:kMvrProtocolMetadataTypeKey];
	L0MoverItem* i = [[[[L0MoverItem classForType:type] alloc] initWithExternalRepresentation:data type:type title:title] autorelease];
	
	if (i) {
		// TODO
		[[MvrNetworkExchange sharedExchange] channel:channel didReceiveItem:i];
	}
	
	[self clear];
}

@end
