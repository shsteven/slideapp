//
//  MvrBTIncomingOutgoing.m
//  Mover3
//
//  Created by ∞ on 20/10/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrBTIncomingOutgoing.h"

#pragma mark Data utilities.

static BOOL MvrSameDataAs(NSData* data, void* comparison, size_t size) {
	if ([data length] != size)
		return NO;
	
	return (memcmp([data bytes], comparison, size) == 0);
}

static BOOL MvrSubdataSameAs(NSData* data, NSUInteger at, void* comparison, size_t size) {
	if ([data length] - at < size)
		return NO;
	
	return MvrSameDataAs([data subdataWithRange:NSMakeRange(at, size)], comparison, size);
}

#pragma mark -
#pragma mark Packet production

static unsigned char kMvrStarterPacket[] =
	{ 'M', '3', 'G', 'O', 0x0, 0x0, 0x0 };
static size_t kMvrStarterPacket_Size = 7;

static unsigned char kMvrIncomingPacketHeader[] = 
	{ 'M', '3', 'S', 'T' };
static size_t kMvrIncomingPacketHeader_Size = 4;

static unsigned char kMvrAckPacketHeader[] =
	{ 'M', '3', 'O', 'K' };
static size_t kMvrAckPacketHeader_Size = 4;

static unsigned char kMvrNackPacketHeader[] =
	{ 'M', '3', 'N', 'O' };
static size_t kMvrNackPacketHeader_Size = 4;


static NSUInteger MvrNumberFromNumberedPacketWithHeader(NSData* data, unsigned char* header, size_t headerSize) {
	if ([data length] < headerSize + sizeof(uint16_t) + sizeof(uint8_t))
		return NSNotFound;
	
	if (!MvrSubdataSameAs(data, 0, header, headerSize))
		return NSNotFound;
	
	const void* terminatorPosition = (const void*) [data bytes] + headerSize + sizeof(uint16_t);
	if (*((const uint8_t*) terminatorPosition) != 0)
		return NSNotFound;
	
	const void* numberPosition = [data bytes] + headerSize;
	uint16_t numberInNetworkOrder = *((const uint16_t*) numberPosition);
	NSUInteger number = ntohs(numberInNetworkOrder);
	return number;
}

#define kMvrInvalidSize (0)

static size_t MvrSizeFromIncomingPacket(NSData* data) {
	const size_t headerSize = kMvrIncomingPacketHeader_Size + sizeof(uint16_t) + sizeof(uint8_t);
	
	if ([data length] < headerSize + sizeof(uint16_t) + sizeof(uint8_t))
		return kMvrInvalidSize;
	
	if (!MvrSubdataSameAs(data, 0, kMvrIncomingPacketHeader, kMvrIncomingPacketHeader_Size))
		return kMvrInvalidSize;
	
	const void* terminatorPosition = [data bytes] + headerSize + sizeof(uint16_t);
	if (*((uint8_t*) terminatorPosition) != 0)
		return kMvrInvalidSize;
	
	const void* numberPosition = [data bytes] + headerSize;
	uint16_t numberInNetworkOrder = *((const uint16_t*) numberPosition);
	size_t number = ntohs(numberInNetworkOrder);
	return number;
}

static NSData* MvrNumberedPacket(unsigned char* header, size_t headerSize, NSUInteger seqNo) {
	static size_t kMvrNumberedPacket_AdditionalSize = 3;
	
	NSMutableData* data = [NSMutableData dataWithBytes:header length:headerSize];
	uint16_t seqNoAltered = htons(seqNo);
	[data appendBytes:(const void*) &seqNoAltered length:sizeof(uint16_t)];
	
	const uint8_t endingNull = 0x0;
	[data appendBytes:(const void*) &endingNull length:sizeof(uint8_t)];
	
	NSCAssert([data length] == headerSize + kMvrNumberedPacket_AdditionalSize, @"Numbered packet produced of the wrong lenght");
	return data;
}

static NSData* MvrAcknowledgmentPacket(NSUInteger seqNo) {
	return MvrNumberedPacket(kMvrAckPacketHeader, kMvrAckPacketHeader_Size, seqNo);
}

static NSData* MvrNegativeAcknowledgmentPacket(NSUInteger seqNo) {
	return MvrNumberedPacket(kMvrNackPacketHeader, kMvrNackPacketHeader_Size, seqNo);
}

#pragma mark -
#pragma mark Incoming

@implementation MvrBTIncoming

- (id) initWithChannel:(MvrBTChannel*) chan;
{
	self = [super init];
	if (self != nil) {
		channel = chan; // it owns us.
		proto = [MvrBTProtocolIncoming new];
		proto.delegate = self;
	}
	return self;
}

- (void) dealloc
{
	[proto release];
	[super dealloc];
}


+ incomingTransferWithChannel:(MvrBTChannel*) chan;
{
	return [[[self alloc] initWithChannel:chan] autorelease];
}

+ (BOOL) shouldStartReceivingWithData:(NSData*) data;
{
	return MvrSameDataAs(data, kMvrStarterPacket, kMvrStarterPacket_Size);
}

- (void) didReceiveDataFromBluetooth:(NSData *)data
{
	if (MvrSameDataAs(data, kMvrStarterPacket, kMvrStarterPacket_Size))
		[proto didReceiveStarter];
	else {
		NSUInteger n = MvrNumberFromNumberedPacketWithHeader(data, kMvrIncomingPacketHeader, kMvrIncomingPacketHeader_Size);
		size_t size = (n == NSNotFound)? kMvrInvalidSize : MvrSizeFromIncomingPacket(data);
		if (n != NSNotFound && size != kMvrInvalidSize) {
			[proto didReceivePacketStartWithSequenceNumber:n length:size];
			return;
		}
		
		[self appendData:data];
		[proto didReceivePacketPart:data];
	}
}

- (void) sendAcknowledgementForSequenceNumber:(NSUInteger) seq;
{
	if (self.cancelled)
		return;
	
	NSData* ackPacket = MvrAcknowledgmentPacket(seq);
	NSError* e;
	if (![channel sendData:ackPacket error:&e]) {
		L0LogAlways(@"Cancelling incoming %@ due to error %@", self, e);
		[self cancel];
	}
}

- (void) signalErrorForSequenceNumber:(NSUInteger) seq reason:(MvrBTProtocolErrorReason) reason;
{
	if (self.cancelled)
		return;
	
	NSData* ackPacket = MvrNegativeAcknowledgmentPacket(seq);
	NSError* e;
	if (![channel sendData:ackPacket error:&e]) {
		L0LogAlways(@"Cancelling incoming %@ due to error %@", self, e);
		[self cancel];
	}
}

- (void) startMonitoringTimeout;
{
	[self performSelector:@selector(timeout) withObject:nil afterDelay:15.0];
}

- (void) stopMonitoringTimeout;
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
}

- (void) timeout;
{
	L0LogAlways(@"Cancelling incoming %@ due to a timeout.");
	[self cancel];
}

- (BOOL) isPayloadAllReceived;
{
	return self.item != nil;
}

- (void) endConnectionWithReason:(MvrBTProtocolErrorReason) reason;
{
	L0Log(@"Ending connection due to this reason with code %d (0 == all done)", reason);
	if (reason != kMvrBTProtocolFinishedWithoutErrors)
		[self cancel];
}

@end

@implementation MvrBTOutgoing

- (id) initWithItem:(MvrItem*) i channel:(MvrBTChannel*) chan;
{
	if (self = [super init]) {
		channel = chan; // it owns us
		item = [i retain];
		builder = [(MvrPacketBuilder*)[MvrPacketBuilder alloc] initWithDelegate:self];

		buffer = [MvrBuffer new];
		buffer.consumptionSize = kMvrBTProtocolPacketSize;
		
		baseIndex = 1;
		savedPackets = [NSMutableArray new];
	}
	
	return self;
}

@synthesize error, finished, progress;

- (void) dealloc
{
	[error release];
	[item release];
	[super dealloc];
}


+ outgoingTransferWithItem:(MvrItem*) i channel:(MvrBTChannel*) chan;
{
	return [[[self alloc] initWithItem:i channel:chan] autorelease];
}

- (void) start;
{
	[builder setMetadataValue:item.title forKey:kMvrProtocolMetadataTitleKey];
	[builder setMetadataValue:item.type forKey:kMvrProtocolMetadataTypeKey];
	
	[builder addPayload:[item.storage preferredContentObject] length:item.storage.contentLength forKey:kMvrProtocolExternalRepresentationPayloadKey];
	
	[builder start];
}

- (void) endWithError:(NSError*) e;
{
	if (self.finished)
		return;
	
	self.error = e;
	self.finished = YES;
}

#pragma mark -
#pragma mark Packet builder.

- (void) packetBuilder:(MvrPacketBuilder*) b didProduceData:(NSData*) d;
{
	[buffer appendData:d];
	
	NSData* packet;
	while ((packet = [buffer consume]) != nil)
		[savedPackets addObject:packet];
	
	if ([savedPackets count] > 10)
		b.paused = YES;
	
	if (needsToSendAPacket)
		needsToSendAPacket = ![self sendNextPacket];
}

- (void) packetBuilder:(MvrPacketBuilder*) b didEndWithError:(NSError*) e;
{
	if (e)
		[self endWithError:e];
}

#pragma mark -
#pragma mark Protocol.

- (void) didReceiveDataFromBluetooth:(NSData*) data;
{
	NSUInteger n;
	
	if ((n = MvrNumberFromNumberedPacketWithHeader(data, kMvrAckPacketHeader, kMvrAckPacketHeader_Size)) != NSNotFound)
		[proto didAcknowledgeWithSequenceNumber:n];
	else if ((n = MvrNumberFromNumberedPacketWithHeader(data, kMvrNackPacketHeader, kMvrNackPacketHeader_Size)) != NSNotFound)
		[proto didAcknowledgeWithSequenceNumber:n];
	else
		[self endWithError:[NSError errorWithDomain:@"MvrBTProtocolErrorDomain" code:kMvrBTProtocolUnexpectedPacket userInfo:nil]];
}

- (void) sendStarter;
{
	NSData* starter = [NSData dataWithBytes:kMvrStarterPacket length:kMvrStarterPacket_Size];
	NSError* e;
	if (![channel sendData:starter error:&e])
		[self endWithError:e];
}

- (BOOL) isPastPacketAvailableWithSequenceNumber:(NSUInteger) sequenceNumber;
{
	return (sequenceNumber >= baseIndex);
}

- (BOOL) sendNextPacket;
{
	if ([savedPackets count] == 0)
		return NO;
	
	NSData* packet = [[[savedPackets objectAtIndex:0] retain] autorelease];
	[savedPackets removeObjectAtIndex:0];
	baseIndex++;
	
	NSError* e;
	if (![channel sendData:packet error:&e])
		[self endWithError:e];
	
	return YES;
}

- (void) sendPacketWithSequenceNumber:(NSUInteger) sequenceNumber;
{
	NSInteger index = sequenceNumber - baseIndex;
	if (index < [savedPackets count]) {
		NSError* e;
		if (![channel sendData:[savedPackets objectAtIndex:index] error:&e]) {
			[self endWithError:e];
			return;
		}
	} else
		needsToSendAPacket = YES;
}

- (BOOL) isPayloadAllSent;
{
	return self.finished;
}

- (void) endConnectionWithReason:(MvrBTProtocolErrorReason) reason;
{
	NSError* e = (reason != kMvrBTProtocolFinishedWithoutErrors)?
		[NSError errorWithDomain:@"MvrBTProtocolErrorDomain" code:reason userInfo:nil] : nil;
	[self endWithError:e];
}

@end
