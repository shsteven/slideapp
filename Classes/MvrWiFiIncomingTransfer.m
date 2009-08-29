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

@property(assign) CGFloat progress;

@end


@implementation MvrWiFiIncomingTransfer

- (id) initWithSocket:(AsyncSocket*) s scanner:(MvrModernWiFiScanner*) sc;
{
	if (self = [super init]) {
		socket = [s retain];
		[s setDelegate:self];
		
		parser = [[MvrPacketParser alloc] initWithDelegate:self];
		isNewPacket = YES;
		
		data = [NSMutableData new];
		scanner = sc; // It owns us.		
	}
	
	return self;
}

@synthesize finished, progress;

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
	channel = [[scanner channelForAddress:[sock connectedHostAddress]] retain];
	if (!channel)
		[self cancel];
	
	[[MvrNetworkExchange sharedExchange] channelWillBeginReceiving:channel];
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
	self.progress = p.progress;
}

- (void) packetParser:(MvrPacketParser*) p didReceiveMetadataItemWithKey:(NSString*) key value:(NSString*) value;
{
	if (isCancelled) return;
	
	self.progress = p.progress;
	[metadata setObject:value forKey:key];
}

- (void) packetParser:(MvrPacketParser*) p didReceivePayloadPart:(NSData*) d forKey:(NSString*) key;
{
	if (isCancelled) return;
	
	[self checkMetadataIfNeeded];
	if (isCancelled) return; // could cancel in checkMetadata...
	
	if (![key isEqual:kMvrProtocolExternalRepresentationPayloadKey])
		return;
	
	self.progress = p.progress;
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
	if (channel)
		[[MvrNetworkExchange sharedExchange] channelDidCancelReceivingItem:channel];
	isCancelled = YES;
	[self clear];
}

- (void) produceItem;
{
	self.progress = 1.0;
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
