//
//  MvrBluetoothScanner.m
//  Mover3
//
//  Created by ∞ on 05/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrBluetoothScanner.h"

#import "Network+Storage/MvrItem.h"
#import "Network+Storage/MvrItemStorage.h"

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

// We have the code here for channels because they're intrinsically tied to the scanner (which holds the single GKSession we want to have).

// -- - --

@implementation MvrBluetoothScanner

@synthesize enabled, channel, session;

- (id) init
{
	self = [super init];
	if (self != nil) {
		session = [[GKSession alloc] initWithSessionID:kMvrBluetoothSessionID displayName:[UIDevice currentDevice].name sessionMode:GKSessionModePeer];
		session.delegate = self;
		[session setDataReceiveHandler:self withContext:NULL];
	}
	return self;
}

- (void) dealloc
{
	self.enabled = NO;
	session.delegate = nil;
	[session setDataReceiveHandler:nil withContext:NULL];
	[session release];
	[channel release];
	[super dealloc];
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
	return self.channel? [NSSet setWithObject:self.channel] : [NSSet set];
}

+ (NSSet *) keyPathsForValuesAffectingChannels;
{
	return [NSSet setWithObject:@"channel"];
}

- (void) receiveData:(NSData*) data fromPeer:(NSString*) peerID inSession:(GKSession*) s context:(void*) context;
{
	const char acknowledger[] = { 'M', '2', 'O', 'K', 0x0 };
	const size_t acknowledgerLength = sizeof(acknowledger) / sizeof(const char);
	
	BOOL isAck = [data length] == acknowledgerLength && (memcmp(acknowledger, [data bytes], acknowledgerLength) == 0);
	
	if (self.channel.outgoingTransfer && isAck) {
		[self.channel.outgoingTransfer acknowledge];
		return;
	}
	
	if (!self.channel.incomingTransfer) {
		MvrBluetoothIncoming* incoming = [[MvrBluetoothIncoming new] autorelease];
		self.channel.incomingTransfer = incoming;
	}
	
	[self.channel.incomingTransfer appendData:data];
	[session sendData:[NSData dataWithBytesNoCopy:(void*) acknowledger length:acknowledgerLength freeWhenDone:NO] toPeers:[NSArray arrayWithObject:peerID] withDataMode:GKSendDataReliable error:NULL];
}

- (void) session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state;
{
	if ([self.channel.peerIdentifier isEqual:peerID] && state == GKPeerStateDisconnected || state == GKPeerStateUnavailable)
		self.channel = nil;
}

@end

@implementation MvrBluetoothIncoming

- (id) init
{
	self = [super init];
	if (self != nil) {
		storage = [[MvrItemStorage itemStorage] retain];
		parser = [[MvrPacketParser alloc] initWithDelegate:self];
		metadata = [NSMutableDictionary new];
	}
	return self;
}

@synthesize progress, item, cancelled;

- (void) dealloc
{
	[self clear];
	[super dealloc];
}


- (void) appendData:(NSData*) data;
{
	[parser appendData:data];
}

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
	
	itemStorageStream = [[storage outputStreamForContentOfAssumedSize:size] retain];
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

- (void) checkMetadataIfNeeded;
{
	if (![metadata objectForKey:kMvrProtocolMetadataTitleKey] || ![metadata objectForKey:kMvrProtocolMetadataTypeKey])
		[self cancel];
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


- (void) cancel;
{
	self.item = nil;
	self.cancelled = YES;
	[self clear];
}

- (void) produceItem;
{
	self.progress = 1.0;
	
	NSString* title = [metadata objectForKey:kMvrProtocolMetadataTitleKey], 
		* type = [metadata objectForKey:kMvrProtocolMetadataTypeKey];
	
	[itemStorageStream close];
	[itemStorageStream release]; itemStorageStream = nil;
	[storage endUsingOutputStream];
	
	MvrItem* i = [MvrItem itemWithStorage:storage type:type metadata:[NSDictionary dictionaryWithObject:title forKey:kMvrItemTitleMetadataKey]];
	
	self.item = i;
	self.cancelled = (i == nil);
	
	[self clear];
}

- (void) clear;
{
	self.progress = kMvrIndeterminateProgress;
	
	[metadata release]; metadata = nil;
	
	if (itemStorageStream) {
		[itemStorageStream close];
		[storage endUsingOutputStream];
		[itemStorageStream release]; itemStorageStream = nil;
	}
	
	if (storage) {
		[storage release]; storage = nil;
	}
}

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
		buffer.consumptionSize = 2048;
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
	[builder setMetadataValue:item.title forKey:kMvrProtocolMetadataTitleKey];
	[builder setMetadataValue:item.type forKey:kMvrProtocolMetadataTypeKey];
	
	[builder addPayload:[item.storage preferredContentObject] length:item.storage.contentLength forKey:kMvrProtocolExternalRepresentationPayloadKey];
	
	[builder start];
}

- (void) packetBuilder:(MvrPacketBuilder *)b didProduceData:(NSData *)d;
{
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
			
		}
	} else
		builder.paused = NO;

}

- (void) acknowledge;
{
	[self sendPacketPart];
}

- (void) packetBuilder:(MvrPacketBuilder *)b didEndWithError:(NSError *)e;
{
	if (self.finished)
		return;
	
	if (e)
		[self endWithError:e];
}

- (void) endWithError:(NSError*) e;
{
	if (self.finished) return;
	
	self.error = e;
	self.finished = YES;
	
	[builder stop];
	[builder release]; builder = nil;
	
	[buffer release]; buffer = nil;
	
	[item release]; item = nil;
}

@end

