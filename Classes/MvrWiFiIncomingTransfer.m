//
//  MvrWiFiIncomingTransfer.m
//  Mover
//
//  Created by ∞ on 25/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrWiFiIncomingTransfer.h"
#import "L0MoverItem.h"
#import "MvrStorageCentral.h"

@interface MvrWiFiIncomingTransfer ()

- (void) checkMetadataIfNeeded;
- (void) cancel;
- (void) produceItem;
- (void) setItem:(L0MoverItem*) i;
- (void) setCancelled:(BOOL)c;

@property(assign) CGFloat progress;

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


@implementation MvrWiFiIncomingTransfer

- (id) initWithSocket:(AsyncSocket*) s scanner:(MvrModernWiFiScanner*) sc;
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

@synthesize finished, progress;

- (void) clear;
{
	self.progress = kMvrPacketIndeterminateProgress;
	
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

- (void) dealloc;
{
	[self clear];
	[self setItem:nil];
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
	
	[[MvrNetworkExchange sharedExchange] channel:channel didStartReceiving:self];
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
	if (isCancelled) return;
	
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
	if (isCancelled) return;
	
	[self checkMetadataIfNeeded];
	if (isCancelled) return; // could cancel in checkMetadata...
	
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
	if (channel) {
		[self setItem:nil];
		[self setCancelled:YES];
	}
	
	isCancelled = YES;
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
	
	L0MoverItem* i = [L0MoverItem itemWithStorage:itemStorage type:type title:title];
	
	[self setItem:i];
	[self setCancelled:(i == nil)];

	[self clear];
}

@synthesize item;
- (void) setItem:(L0MoverItem*) i;
{
	if (i != item) {
		[item release];
		item = [i retain];
	}
}

@synthesize cancelled = isCancelled;
- (void) setCancelled:(BOOL) c;
{
	isCancelled = c;
}

@end
