//
//  MvrBTIncomingOutgoing.m
//  Mover3
//
//  Created by ∞ on 20/10/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrBTIncomingOutgoing.h"

#import "MvrBTDebugTracker.h"

#pragma mark Data utilities.

static BOOL MvrSameDataAs(NSData* data, void* comparison, size_t size) {
	BOOL result = ([data length] == size) && (memcmp([data bytes], comparison, size) == 0);
	return result;
}

static BOOL MvrSubdataSameAs(NSData* data, NSUInteger at, void* comparison, size_t size) {
	if ([data length] - at < size)
		return NO;
	
	return MvrSameDataAs([data subdataWithRange:NSMakeRange(at, size)], comparison, size);
}

#pragma mark -
#pragma mark Packet production

static uint8_t kMvrStarterPacket[] =
	{ 'M', '3', 'G', 'O', 0x0, 0x0, 0x0 };
static size_t kMvrStarterPacket_Size = 7;

static uint8_t kMvrCancelPacket[] =
	{ 'M', '3', 'K', 'O', 0x0, 0x0, 0x0 };
static size_t kMvrCancelPacket_Size = 7;

static uint8_t kMvrIncomingPacketHeader[] = 
	{ 'M', '3', 'S', 'T' };
static size_t kMvrIncomingPacketHeader_Size = 4;

static uint8_t kMvrAckPacketHeader[] =
	{ 'M', '3', 'O', 'K' };
static size_t kMvrAckPacketHeader_Size = 4;

static uint8_t kMvrNackPacketHeader[] =
	{ 'M', '3', 'N', 'O' };
static size_t kMvrNackPacketHeader_Size = 4;

static uint8_t kMvrIsLitePacket[] = 
	{ 'M', '3', 'L', 'T', 0x0, 0x0, 0x0 };
static size_t kMvrIsLitePacket_Size = 7;

static NSUInteger MvrNumberFromNumberedPacketWithHeader(NSData* data, uint8_t* header, size_t headerSize) {
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
	
	const void* sizePosition = [data bytes] + headerSize;
	uint16_t sizeInNetworkOrder = *((const uint16_t*) sizePosition);
	size_t size = (size_t) ntohs(sizeInNetworkOrder);
		
	return size;
}

const size_t kMvrNumberedPacket_AdditionalSize = sizeof(uint16_t) + sizeof(uint8_t);

static NSData* MvrNumberedPacket(uint8_t* header, size_t headerSize, NSUInteger seqNo) {	
	NSMutableData* data = [NSMutableData dataWithBytes:header length:headerSize];
	uint16_t networkOrderSeqNo = htons(seqNo);
	[data appendBytes:(const void*) &networkOrderSeqNo length:sizeof(uint16_t)];
	
	const uint8_t endingNull = 0x0;
	[data appendBytes:(const void*) &endingNull length:sizeof(uint8_t)];
	
	NSCAssert([data length] == headerSize + kMvrNumberedPacket_AdditionalSize, @"Numbered packet produced of the wrong lenght");
	return data;
}

static NSData* MvrIncomingPacket(NSUInteger seqNo, size_t announcedSize) {
	NSMutableData* data = [NSMutableData dataWithData:MvrNumberedPacket(kMvrIncomingPacketHeader, kMvrIncomingPacketHeader_Size, seqNo)];
	
	NSCAssert(announcedSize <= UINT16_MAX, @"Can't send packets more than UINT16_MAX in length");
	
	uint16_t announcedSizeSeqNo = htons(announcedSize);
	[data appendBytes:(const void*) &announcedSizeSeqNo length:sizeof(uint16_t)];
	
	const uint8_t endingNull = 0x0;
	[data appendBytes:(const void*) &endingNull length:sizeof(uint8_t)];
	
	NSCAssert([data length] == kMvrIncomingPacketHeader_Size + kMvrNumberedPacket_AdditionalSize + sizeof(uint16_t) + sizeof(uint8_t), @"Incoming packet produced of the wrong lenght");
	
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
		self.channel = chan; // it owns us.
		proto = [MvrBTProtocolIncoming new];
		proto.delegate = self;
	}
	return self;
}

- (void) dealloc
{
	[self stopWaiting];
	[proto release];
	[super dealloc];
}


+ incomingTransferWithChannel:(MvrBTChannel*) chan;
{
	return [[[self alloc] initWithChannel:chan] autorelease];
}

+ (BOOL) isLiteWarningPacket:(NSData*) data;
{
	return MvrSameDataAs(data, kMvrIsLitePacket, kMvrIsLitePacket_Size);
}

+ (NSData*) liteWarningPacket;
{
	return [NSData dataWithBytesNoCopy:kMvrIsLitePacket length:kMvrIsLitePacket_Size];
}

+ (BOOL) shouldStartReceivingWithData:(NSData*) data;
{
	BOOL result = MvrSameDataAs(data, kMvrStarterPacket, kMvrStarterPacket_Size);
	MvrBTTrack(@"Should start receiving with %@? result = %d", data, result);
	return result;
}

- (void) didReceiveDataFromBluetooth:(NSData *)data
{
	MvrBTTrack(@"Received %lu bytes from Bluetooth.", (unsigned long) [data length]);
	
	if (MvrSameDataAs(data, kMvrStarterPacket, kMvrStarterPacket_Size)) {
		MvrBTTrack(@"Received a starter packet!");
		awaitingSequenceNo = 0;
		[proto didReceiveStarter];
	} else {
		NSUInteger n = MvrNumberFromNumberedPacketWithHeader(data, kMvrIncomingPacketHeader, kMvrIncomingPacketHeader_Size);
		size_t size = (n == NSNotFound)? kMvrInvalidSize : MvrSizeFromIncomingPacket(data);
		if (n != NSNotFound && size != kMvrInvalidSize) {
			MvrBTTrack(@"Received an incoming warning packet! number = %lu, size = %zu", (unsigned long) n, size);
			[proto didReceivePacketStartWithSequenceNumber:n length:size];
			return;
		}
		
		MvrBTTrack(@"Received %lu bytes of actual data", (unsigned long) [data length]);
		[self appendData:data];
		[proto didReceivePacketPart:data];
	}
	
	[self startWaiting];
}

- (void) sendAcknowledgementForSequenceNumber:(NSUInteger) seq;
{
	if (self.cancelled) {
		MvrBTTrack(@"Not sending ack since we're cancelled already.");
		return;
	}
	
	attemptsAtBacktracking = 0;
	awaitingSequenceNo = seq + 1;
	
	MvrBTTrack(@"Sending an ack");
	NSData* ackPacket = MvrAcknowledgmentPacket(seq);
	NSError* e;
	if (![(MvrBTChannel*)self.channel sendData:ackPacket error:&e]) {
		MvrBTTrack(@"Cancelling due to error on ack %@", e);
		[self cancel];
	}
	
	[self startWaiting];
}

- (void) signalErrorForSequenceNumber:(NSUInteger) seq reason:(MvrBTProtocolErrorReason) reason;
{
	if (self.cancelled) {
		MvrBTTrack(@"Not sending Nack since we're cancelled already.");
		return;
	}
	
	MvrBTTrack(@"Sending a Nack");
	NSData* ackPacket = MvrNegativeAcknowledgmentPacket(seq);
	NSError* e;
	if (![(MvrBTChannel*)self.channel sendData:ackPacket error:&e]) {
		L0LogAlways(@"Cancelling due to error on nack %@", e);
		[self cancel];
	}
	
	[self startWaiting];
}

- (void) startWaiting;
{
	[self stopWaiting];
	
	if (self.item || self.cancelled)
		return;
	
	MvrBTTrack(@"Starting timeout monitoring for %f seconds", (double) kMvrBTProtocolTimeout);
	[self performSelector:@selector(timeout) withObject:nil afterDelay:kMvrBTProtocolTimeout];
}

- (void) stopWaiting;
{
	MvrBTTrack(@"Stopping timeout monitoring");
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
}

- (void) timeout;
{
	attemptsAtBacktracking++;
	if (attemptsAtBacktracking == 10) {
		L0LogAlways(@"Cancelling due to a timeout.");
		[self cancel];
	} else
		[self signalErrorForSequenceNumber:awaitingSequenceNo reason:kMvrBTProtocolDidTimeOut];
}

- (void) cancel;
{
	if (!self.cancelled && !self.item) {
		NSData* cancelPacket = [NSData dataWithBytes:kMvrCancelPacket length:kMvrCancelPacket_Size];
 		[(MvrBTChannel*)self.channel sendData:cancelPacket error:NULL];
		
		[self stopWaiting];
		MvrBTTrackEnd();
	}
	
	[super cancel];
}

- (BOOL) isPayloadAllReceived;
{
	return self.item != nil;
}

- (void) endConnectionWithReason:(MvrBTProtocolErrorReason) reason;
{
	MvrBTTrack(@"Ending connection due to reason with code %d (0 == all done)", reason);
	MvrBTTrackEnd();
	if (reason != kMvrBTProtocolFinishedWithoutErrors)
		[self cancel];
}

@end

#if !kMvrIsLite

#pragma mark -
#pragma mark Outgoing

#if !DEBUG && kMvrBTOutgoingSimulateBreaking
#error Connection break testing code must NOT be left in the release build.
#endif

@implementation MvrBTOutgoing

- (id) initWithItem:(MvrItem*) i channel:(MvrBTChannel*) chan;
{
	if (self = [super init]) {
		channel = chan; // it owns us
		item = [i retain];
	}
	
	return self;
}

@synthesize error, finished, progress;

- (void) dealloc
{
	[error release];
	[item release];
	[proto release];
	[savedPackets release];
	[buffer release];
	
	[super dealloc];
}


+ outgoingTransferWithItem:(MvrItem*) i channel:(MvrBTChannel*) chan;
{
	return [[[self alloc] initWithItem:i channel:chan] autorelease];
}

- (void) start;
{
	didSendAtLeastPart = NO;
	
	builder = [(MvrPacketBuilder*)[MvrPacketBuilder alloc] initWithDelegate:self];
	
	buffer = [MvrBuffer new];
	buffer.consumptionSize = kMvrBTProtocolPacketSize;
	
	baseIndex = 1;
	seqNoThatNeedsSending = 0;
	savedPackets = [NSMutableArray new];
	
	proto = [MvrBTProtocolOutgoing new];
	proto.delegate = self;
	
	MvrBTTrack(@"Starting outgoing connection for item %@", item);
	
	[builder setMetadataValue:item.title forKey:kMvrProtocolMetadataTitleKey];
	[builder setMetadataValue:item.type forKey:kMvrProtocolMetadataTypeKey];
	
	[builder addPayload:[item.storage preferredContentObject] length:item.storage.contentLength forKey:kMvrProtocolExternalRepresentationPayloadKey];
	
	[builder start];
	
	[self sendStarter];
}

- (void) cancel;
{
	[self endWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
}

- (void) endWithError:(NSError*) e;
{
	if (self.finished || finishing)
		return;
	
	finishing = YES;
	
	[builder release]; builder = nil;
	[buffer release]; buffer = nil;
	[proto release]; proto = nil;

	MvrBTTrack(@"Ending with error %@", e);
	MvrBTTrackEnd();
	
#if kMvrBTOutgoingRetrySending
	if (e) {
		retries++;
		
		if (retries < 5 && !([[e domain] isEqual:NSCocoaErrorDomain] && [e code] == NSUserCancelledError)) {
			MvrBTTrack(@"Will retry sending.");
			[self performSelector:@selector(start) withObject:nil afterDelay:1.0];
			finishing = NO;
			return;
		}
	}
#endif
		
	self.error = e;
	self.finished = YES;
	
	finishing = NO;
}

#pragma mark -
#pragma mark Packet builder.

- (void) packetBuilder:(MvrPacketBuilder*) b didProduceData:(NSData*) d;
{
#if kMvrBTOutgoingSimulateBreaking
	if (simulatedBreaks < 3 && didSendAtLeastPart) {
		[self endWithError:[NSError errorWithDomain:@"SimulatedError" code:1 userInfo:nil]];
		return;
	}
#endif
	
	MvrBTTrack(@"Heeding to the packet builder now...");
	[buffer appendData:d];
		
	NSData* packet;
	while ((packet = [buffer consume]) != nil)
		[savedPackets addObject:packet];
	
	MvrBTTrack(@"There are now %ld enqueued packets.", (long) [savedPackets count]);

	if ([savedPackets count] > 10) {
		b.paused = YES;
		MvrBTTrack(@"Pausing the packet builder until we deliver some of these packets.");
	}
	
	if (seqNoThatNeedsSending > 0) {
		MvrBTTrack(@"Trying to send a packet now that we have some more.");
		[self sendPacketWithSequenceNumber:seqNoThatNeedsSending];
	}
}

- (void) packetBuilder:(MvrPacketBuilder*) b didEndWithError:(NSError*) e;
{
	MvrBTTrack(@"The packet builder has finished building the AAP packet.");
	if (e)
		[self endWithError:e];
	finishedBuilding = YES;
}

#pragma mark -
#pragma mark Protocol.

- (void) didReceiveDataFromBluetooth:(NSData*) data;
{
	MvrBTTrack(@"Heeding to Bluetooth data reception now...");
	
	NSUInteger n;
	
	if ((n = MvrNumberFromNumberedPacketWithHeader(data, kMvrAckPacketHeader, kMvrAckPacketHeader_Size)) != NSNotFound) {
		MvrBTTrack(@"Found an ack packet.");
		[proto didAcknowledgeWithSequenceNumber:n];
	} else if ((n = MvrNumberFromNumberedPacketWithHeader(data, kMvrNackPacketHeader, kMvrNackPacketHeader_Size)) != NSNotFound) {
		MvrBTTrack(@"Found a Nack packet.");
		[proto didSignalErrorWithSequenceNumber:n];
	} else if (MvrSubdataSameAs(data, 0, kMvrCancelPacket, kMvrCancelPacket_Size)) {
		MvrBTTrack(@"Asked to cancel from the other side.");
		[self endWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
	} else {
		MvrBTTrack(@"Unknown kind of packet received!");
		[self endWithError:[NSError errorWithDomain:@"MvrBTProtocolErrorDomain" code:kMvrBTProtocolUnexpectedPacket userInfo:nil]];
	}
}

- (void) sendStarter;
{
	MvrBTTrack(@"Sending the starter packet.");
	
	NSData* starter = [NSData dataWithBytes:kMvrStarterPacket length:kMvrStarterPacket_Size];
	NSError* e;
	if (![channel sendData:starter error:&e])
		[self endWithError:e];
}

- (BOOL) isPastPacketAvailableWithSequenceNumber:(NSUInteger) sequenceNumber;
{
	BOOL isAvailable = (sequenceNumber >= baseIndex);
	MvrBTTrack(@"Asked whether past packet %ld is available. Since we're caching packets %ld-%ld (incl), I'm responding %d.", (long) sequenceNumber, (long) baseIndex, (long) baseIndex + (long) [savedPackets count], isAvailable);
	return isAvailable;
}

- (void) sendPacketWithSequenceNumber:(NSUInteger) sequenceNumber;
{
	MvrBTTrack(@"Sending packet number %ld. We have %ld-%ld (incl) in queue.", sequenceNumber, (long) baseIndex, (long) baseIndex + (long) [savedPackets count]);
	
	if (sequenceNumber > UINT16_MAX) {
		MvrBTTrack(@"Whoa, something's rotten here. We were asked for a bizarre sequenceNumber (%lu). Aborting.", (unsigned long) sequenceNumber);
		[self endWithError:/* TODO appropriate error */ nil];
		return;
	}
	
	NSInteger index = sequenceNumber - baseIndex;
	if (index < [savedPackets count]) {
		seqNoThatNeedsSending = 0;
		NSData* data = [savedPackets objectAtIndex:index];
		
		NSError* e;
		if (![channel sendData:MvrIncomingPacket(sequenceNumber, [data length]) error:&e]) {
			[self endWithError:e];
			return;
		}
		
		if (![channel sendData:data error:&e]) {
			[self endWithError:e];
			return;
		}
		
		if (finishedBuilding && index == [savedPackets count] - 1)
			hasSentLastPacket = YES; // prepares for landing.
		
		if (index > 10) {
			[savedPackets removeObjectsInRange:NSMakeRange(0, 5)];
			baseIndex += 5;
			MvrBTTrack(@"Cleared the oldest five sent packets. Now having %lu-%lu (incl) in queue.", (unsigned long)  baseIndex, (unsigned long) baseIndex + [savedPackets count]);
		}
		
	} else {
		MvrBTTrack(@"Don't have packet %lu (it's in the FUTURE!), so we're pausing until we get it. We'll retry once the packet builder gives it to us.", sequenceNumber);
		seqNoThatNeedsSending = sequenceNumber;
		builder.paused = NO;
	}
	
	didSendAtLeastPart = YES;
}

- (BOOL) isPayloadAllSent;
{
	return hasSentLastPacket;
}

- (void) endConnectionWithReason:(MvrBTProtocolErrorReason) reason;
{
	MvrBTTrack(@"Protocol asks to interrupt with reason %ld", (long) reason);
	
	NSError* e = (reason != kMvrBTProtocolFinishedWithoutErrors)?
		[NSError errorWithDomain:@"MvrBTProtocolErrorDomain" code:reason userInfo:nil] : nil;
	[self endWithError:e];
}

@end

#endif
