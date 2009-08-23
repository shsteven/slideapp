//
//  MvrPacketParser.m
//  Mover
//
//  Created by ∞ on 23/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrPacketParser.h"

@interface MvrPacketParser ()

- (void) consumeCurrentBuffer;
@property(assign, setter=private_setState:) MvrPacketParserState state;
@property(copy) NSString* lastSeenMetadataItemTitle;

@property(copy) NSArray* payloadStops;
- (BOOL) setPayloadStopsFromString:(NSString*) string;

@property(copy) NSArray* payloadKeys;
- (BOOL) setPayloadKeysFromString:(NSString*) string;

// code == 0 means that we reset reporting no error (nil).
- (void) resetAndReportError:(NSInteger) code;
- (void) reset;

- (NSInteger) locationOfFirstNullInCurrentBuffer;


// These methods return YES if we can continue consuming, or NO if we need
// to be woken up when more data is available.
- (BOOL) consumeStartOfPacket;
- (BOOL) consumeMetadataItemTitle;
- (BOOL) consumeMetadataItemValue;
- (BOOL) consumeBody;

// These methods do state changes.
- (void) expectMetadataItemTitle;
- (void) expectMetadataItemValueWithTitle:(NSString*) s;
- (void) expectBody; // This starts body consumption.

- (void) processAndReportMetadataItemWithTitle:(NSString*) title value:(NSString*) s;

@end

NSString* const kMvrPacketParserErrorDomain = @"kMvrPacketParserErrorDomain";

@implementation MvrPacketParser

- (id) initWithDelegate:(id <MvrPacketParserDelegate>) d;
{
	if (self = [super init]) {
		delegate = d;
		currentBuffer = [NSMutableData new];
		[self reset];
	}
	
	return self;
}

- (void) dealloc;
{
	[self reset];
	[super dealloc];
}

@synthesize state, lastSeenMetadataItemTitle, payloadStops, payloadKeys;

- (void) appendData:(NSData*) data;
{
	[self appendData:data isKnownStartOfNewPacket:NO];
}

- (void) appendData:(NSData*) data isKnownStartOfNewPacket:(BOOL) reset;
{
	if (reset && !self.expectingNewPacket) {
		[self resetAndReportError:0];
	}
	
	[currentBuffer appendData:data];
	[self consumeCurrentBuffer];
}

- (void) consumeCurrentBuffer;
{
	beingReset = NO;
	BOOL shouldContinueParsingForData = YES;
	while ([currentBuffer length] > 0 && shouldContinueParsingForData && !beingReset) {
		switch (self.state) {
			case kMvrPacketParserExpectingStart:
				shouldContinueParsingForData = [self consumeStartOfPacket];
				break;
				
			case kMvrPacketParserExpectingMetadataItemTitle:
				shouldContinueParsingForData = [self consumeMetadataItemTitle];				
				break;
				
			case kMvrPacketParserExpectingMetadataItemValue:
				shouldContinueParsingForData = [self consumeMetadataItemValue];
				break;
				
			case kMvrPacketParserExpectingBody:
				shouldContinueParsingForData = [self consumeBody];				
				break;
				
			default:
				NSAssert(NO, @"Unknown state reached");
				return;
		}
	}
}

- (void) reset;
{
	lastReportedBodySize = -1;
	sizeOfReportedBytes = 0;
	self.lastSeenMetadataItemTitle = nil;
	self.payloadStops = nil;
	self.payloadKeys = nil;
	
	self.state = kMvrPacketParserExpectingStart;
}	

- (void) resetAndReportError:(NSInteger) errorCode;
{
	[self reset];
	
	NSError* e = nil;
	if (errorCode != 0) 
		e = [NSError errorWithDomain:kMvrPacketParserErrorDomain code:errorCode userInfo:nil];
	[delegate packetParser:self didReturnToStartingStateWithError:e];

	BOOL shouldResetAfterGoodPacket = NO;
	
	if (!e) {
		shouldResetAfterGoodPacket = [delegate respondsToSelector:@selector(packetParserShouldResetAfterCompletingPacket:)]? [delegate packetParserShouldResetAfterCompletingPacket:self] : YES;
	}
	
	if (e || shouldResetAfterGoodPacket) {
		[currentBuffer release];
		currentBuffer = [NSMutableData new];
		
		beingReset = YES;
	}
	
	if (e) {
		if ([delegate respondsToSelector:@selector(packetParserDidResetAfterError:)])
			[delegate packetParserDidResetAfterError:self];
	}
}

- (BOOL) consumeStartOfPacket;
{
	if ([currentBuffer length] >= kMvrPacketParserStartingBytesLength) {
		const uint8_t* bytes = (const uint8_t*) [currentBuffer bytes];
		if (memcmp(kMvrPacketParserStartingBytes, bytes,
				   kMvrPacketParserStartingBytesLength) == 0) {
			
			[delegate packetParserDidStartReceiving:self];
			[self expectMetadataItemTitle];
			
		} else
			[self resetAndReportError:kMvrPacketParserDidNotFindStartError];
		
		if (!beingReset)
			[currentBuffer replaceBytesInRange:NSMakeRange(0, kMvrPacketParserStartingBytesLength) withBytes:NULL length:0];
		return YES;
	}
	
	return NO;
}

- (void) expectMetadataItemTitle;
{
	self.state = kMvrPacketParserExpectingMetadataItemTitle;
	self.lastSeenMetadataItemTitle = nil;
}

- (BOOL) consumeMetadataItemTitle;
{
	NSInteger loc = [self locationOfFirstNullInCurrentBuffer];
	if (loc == NSNotFound)
		return NO;
	
	if (loc != 0) {
	
		NSString* s = [[NSString alloc] initWithBytes:[currentBuffer bytes] length:loc encoding:NSUTF8StringEncoding];
		
		if (!s)
			[self resetAndReportError:kMvrPacketParserNotUTF8StringError];
		else
			[self expectMetadataItemValueWithTitle:s];
		
		[s release];
		
	} else
		[self expectBody];
	
	if (!beingReset)
		[currentBuffer replaceBytesInRange:NSMakeRange(0, loc + 1) withBytes:NULL length:0];
	return YES;
}

- (void) expectMetadataItemValueWithTitle:(NSString*) s;
{
	self.lastSeenMetadataItemTitle = s;
	self.state = kMvrPacketParserExpectingMetadataItemValue;	
}

- (void) expectBody;
{
	if (lastReportedBodySize == 0) {
		// we'd grab the body here, but since the body is empty, we go on.
		[delegate packetParser:self didReceiveBodyDataPart:[NSData data]];
		[self resetAndReportError:0];
	} else
		self.state = kMvrPacketParserExpectingBody;
}

- (BOOL) consumeMetadataItemValue;
{
	NSInteger loc = [self locationOfFirstNullInCurrentBuffer];
	if (loc == NSNotFound)
		return NO;
	
	NSString* s = nil;
	
	if (loc != 0)
		s = [[NSString alloc] initWithBytes:[currentBuffer bytes] length:loc encoding:NSUTF8StringEncoding];
	if (!s)
		[self resetAndReportError:kMvrPacketParserNotUTF8StringError];
	else {
		[self processAndReportMetadataItemWithTitle:self.lastSeenMetadataItemTitle value:s];
		[self expectMetadataItemTitle];
	}
	[s release];
	
	if (!beingReset)
		[currentBuffer replaceBytesInRange:NSMakeRange(0, loc + 1) withBytes:NULL length:0];
	return YES;
}

- (void) processAndReportMetadataItemWithTitle:(NSString*) title value:(NSString*) s;
{
	if ([title isEqual:kMvrPacketParserSizeKey])
		lastReportedBodySize = [s longLongValue];
	
	if ([title isEqual:kMvrProtocolPayloadStopsKey]) {
		if (![self setPayloadStopsFromString:s])
			return;
	}
	
	if ([title isEqual:kMvrProtocolPayloadKeysKey]) {
		if (![self setPayloadKeysFromString:s])
			return;
	}
	
	[delegate packetParser:self didReceiveMetadataItemWithKey:title value:s];
}

- (BOOL) setPayloadStopsFromString:(NSString*) string;
{
	NSScanner* s = [NSScanner scannerWithString:string];
	[s setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@" "]];
	
	NSMutableArray* stops = [NSMutableArray array];
	
	long long max = -1;
	while (![s isAtEnd]) {
		long long stop;
		if (![s scanLongLong:&stop] || stop < 0 || stop < max) {
			[self resetAndReportError:kMvrPacketParserHasInvalidStopsStringError];
			return NO;
		} else {
			[stops addObject:[NSNumber numberWithLongLong:stop]];
			max = stop;
		}
	}
	
	if (self.payloadKeys && [self.payloadKeys count] != [stops count]) {
		[self resetAndReportError:kMvrPacketParserKeysAndStopsDoNotMatchError];
		return NO;
	}

	self.payloadStops = stops;
	return YES;
}

- (BOOL) setPayloadKeysFromString:(NSString*) string;
{
	NSMutableArray* keys = [NSMutableArray arrayWithArray:
							 [string componentsSeparatedByString:@" "]];
	
	NSUInteger index;
	while ((index = [keys indexOfObject:@""]) != NSNotFound)
		[keys removeObjectAtIndex:index];
	
	if (self.payloadStops && [self.payloadStops count] != [keys count]) {
		[self resetAndReportError:kMvrPacketParserKeysAndStopsDoNotMatchError];
		return NO;
	}
	
	if ([[NSSet setWithArray:keys] count] != [keys count]) {
		[self resetAndReportError:kMvrPacketParserHasDuplicateKeysError];
		return NO;
	}
	
	self.payloadKeys = keys;
	return YES;
}

- (BOOL) consumeBody;
{
	if (lastReportedBodySize < 0) {
		[self resetAndReportError:kMvrPacketParserMetadataDidNotIncludeSize];
		return YES;
	}
		
	NSInteger i = MIN([currentBuffer length], lastReportedBodySize - sizeOfReportedBytes);
	sizeOfReportedBytes += i;
	NSAssert(sizeOfReportedBytes <= lastReportedBodySize, @"Should not report more bytes than I have been told to report");
	NSRange dataRange = NSMakeRange(0, i);
	
	[delegate packetParser:self didReceiveBodyDataPart:[currentBuffer subdataWithRange:dataRange]];
	[currentBuffer replaceBytesInRange:dataRange withBytes:NULL length:0];
	
	if (sizeOfReportedBytes == lastReportedBodySize)
		[self resetAndReportError:0];
	
	return YES;
}

- (NSInteger) locationOfFirstNullInCurrentBuffer;
{
	const size_t length = [currentBuffer length];
	const char* bytes = (const char*) [currentBuffer bytes];
	size_t i; for (i = 0; i < length; i++) {
		if (bytes[i] == 0)
			return i;
	}
	
	return NSNotFound;
}

- (BOOL) expectingNewPacket;
{
	return self.state == kMvrPacketParserStartingState && [currentBuffer length] == 0;
}

@end
