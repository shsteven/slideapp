//
//  MvrWiFiIncomingTransfer.m
//  Mover
//
//  Created by ∞ on 25/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrModernWiFiIncoming.h"

#import "AsyncSocket.h"
#import "MvrItemStorage.h"
#import "MvrModernWiFi.h"
#import "MvrModernWiFiChannel.h"
#import "MvrItem.h"
#import "MvrProtocol.h"

#import <MuiKit/MuiKit.h>

@interface MvrModernWiFiIncoming ()

- (void) checkMetadataIfNeeded;
- (void) cancel;
- (void) produceItem;
- (void) clear;

@end

static BOOL MvrWriteDataToOutputStreamSynchronously(NSOutputStream* stream, NSData* data, NSError** e) {
	
	NSInteger written = 0; const void* bytes = [data bytes];
	while (written < [data length]) {
		
		if ([stream hasSpaceAvailable]) {
			NSInteger newlyWritten = [stream write:(bytes + written) maxLength:([data length] - written)];
			
			if (newlyWritten == -1) {
				if (e) *e = [stream streamError];
				return NO;
			}
			
			written += newlyWritten;
			
		}
		
		usleep(50 * 1000);
	}
	
	return YES;
	
}


@implementation MvrModernWiFiIncoming

- (id) initWithSocket:(AsyncSocket*) s scanner:(MvrModernWiFi*) sc;
{
	if (self = [super init]) {
		socket = [s retain];
		[s setDelegate:self];
		
		parser = [[MvrPacketParser alloc] initWithDelegate:self];
		isNewPacket = YES;
		
		scanner = sc; // It owns us.
		metadata = [NSMutableDictionary new];
	}
	
	return self;
}

- (void) dealloc;
{
	[self cancel];
	[parser release];

	[super dealloc];
}

#pragma mark -
#pragma mark Sockets.

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port;
{
	L0Log(@"%@: %@:%d", self, host, port);
	channel = [[scanner channelForAddress:[sock connectedHostAddress]] retain];
	if (!channel)
		[self cancel];
	L0Log(@" => %@", channel);
	
	[[channel mutableSetValueForKey:@"incomingTransfers"] addObject:self];
	
	[sock readDataWithTimeout:120 tag:0];
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)d withTag:(long)tag;
{
	L0Log(@"%llu bytes received", (unsigned long long) [d length]);
	
	[parser appendData:d isKnownStartOfNewPacket:isNewPacket];
	isNewPacket = NO;
	
	unsigned long long size = parser.expectedSize;
	L0Log(@"Now expecting %llu bytes. (0 == no limit)", size);
	if (size == 0)
		[sock readDataWithTimeout:120 tag:0];
	else
		[sock readDataToLength:size withTimeout:120 tag:0];
}

- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err;
{
	L0Log(@"%@: %@", self, err);
	
	if (err)
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
	if (self.cancelled) return;
	
	self.progress = p.progress;
	[metadata setObject:value forKey:key];
}

- (void) packetParser:(MvrPacketParser*) p willReceivePayloadForKey:(NSString*) key size:(unsigned long long) size;
{
	if (![key isEqual:kMvrProtocolExternalRepresentationPayloadKey])
		return;
	
	NSAssert(!itemStorage, @"No item storage must have been created");
	NSAssert(!itemStorageStream, @"No item storage stream must have been created");
	
	itemStorage = [[MvrItemStorage itemStorage] retain];
	itemStorageStream = [[itemStorage outputStreamForContentOfAssumedSize:size] retain];
	[itemStorageStream open];
}

- (void) packetParser:(MvrPacketParser*) p didReceivePayloadPart:(NSData*) d forKey:(NSString*) key;
{
	if (self.cancelled) return;
	
	[self checkMetadataIfNeeded];
	if (self.cancelled) return; // could cancel in checkMetadata...
	
	if (![key isEqual:kMvrProtocolExternalRepresentationPayloadKey])
		return;
	
	self.progress = p.progress;
	NSAssert(itemStorageStream && [itemStorageStream streamStatus] != NSStreamStatusNotOpen, @"We have a stream and it's open.");
	
	NSError* e;
	if (!MvrWriteDataToOutputStreamSynchronously(itemStorageStream, d, &e)) {
		L0LogAlways(@"Got an error while writing to the offloading stream: %@", e);
		[self cancel];
	}
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
	self.item = nil;
	self.cancelled = YES;
	[self clear];
}

- (void) produceItem;
{
	self.progress = 1.0;
	[socket writeData:[AsyncSocket LFData] withTimeout:-1 tag:0];
	[socket disconnectAfterWriting];
	
	NSString* title = [metadata objectForKey:kMvrProtocolMetadataTitleKey], 
		* type = [metadata objectForKey:kMvrProtocolMetadataTypeKey];
	
	[itemStorageStream close];
	[itemStorageStream release];
	itemStorageStream = nil;
	[itemStorage endUsingOutputStream];
	
	MvrItem* i = [MvrItem itemWithStorage:itemStorage type:type metadata:[NSDictionary dictionaryWithObject:title forKey:kMvrItemTitleMetadataKey]];
	
	self.item = i;
	self.cancelled = (i == nil);

	[self clear];
}

- (void) clear;
{
	self.progress = kMvrIndeterminateProgress;
	
	[channel release]; channel = nil;
	
	[socket disconnect];
	[socket setDelegate:nil];
	[socket release]; socket = nil;
	
	[metadata release]; metadata = nil;
	
	if (itemStorageStream) {
		[itemStorageStream close];
		[itemStorage endUsingOutputStream];
		[itemStorageStream release];
		itemStorageStream = nil;
	}
	
	if (itemStorage) {
		[itemStorage release];
		itemStorage = nil;
	}
}

@end