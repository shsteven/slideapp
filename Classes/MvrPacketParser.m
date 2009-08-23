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

// code == 0 means that we reset without reporting any error.
- (void) resetAndReportError:(NSUInteger) code;
- (NSInteger) locationOfFirstNullInCurrentBuffer;

// These methods return YES if we can continue consuming, or NO if we need
// to be woken up when more data is available.
- (BOOL) consumeStartOfPacket;
- (BOOL) consumeMetadataItemTitle;
- (BOOL) consumeMetadataItemValue;
- (BOOL) consumeBody;

@end

NSString* const kMvrPacketParserErrorDomain = @"kMvrPacketParserErrorDomain";

@implementation MvrPacketParser

- (id) initWithDelegate:(id <MvrPacketParserDelegate>) d;
{
	if (self = [super init]) {
		delegate = d;
		currentBuffer = [NSMutableData new];
		[self resetAndReportError:0];
	}
	
	return self;
}

- (void) dealloc;
{
	self.lastSeenMetadataItemTitle = nil;
	[super dealloc];
}

@synthesize state, lastSeenMetadataItemTitle;

- (void) appendData:(NSData*) data;
{
	[currentBuffer appendData:data];
	[self consumeCurrentBuffer];
}

- (void) consumeCurrentBuffer;
{
	while ([currentBuffer length] > 0) {
		switch (self.state) {
			case kMvrPacketParserExpectingStart:
				if (![self consumeStartOfPacket])
					return;
				
				break;
				
			case kMvrPacketParserExpectingMetadataItemTitle:
				if (![self consumeMetadataItemTitle])
					return;
				
				break;
				
			case kMvrPacketParserExpectingMetadataItemValue:
				if (![self consumeMetadataItemValue])
					return;
				
				break;
				
			case kMvrPacketParserExpectingBody:
				if (![self consumeBody])
					return;
				
				break;
				
			default:
				NSAssert(NO, @"Unknown state reached");
				return;
		}
	}
}

- (void) resetAndReportError:(NSUInteger) errorCode;
{
	lastReportedBodySize = -1;
	sizeOfReportedBytes = 0;
	self.lastSeenMetadataItemTitle = nil;
	
	self.state = kMvrPacketParserExpectingStart;
	if (errorCode != 0) {
		NSError* e = [NSError errorWithDomain:kMvrPacketParserErrorDomain code:errorCode userInfo:nil];
		[delegate packetParser:self didReturnToStartingStateWithError:e];
	}
}

static const char kMvrPacketParserStartingBytes[] = { 'M', 'O', 'V', 'R', '2' };
static const size_t kMvrPacketParserStartingBytesLength =
	sizeof(kMvrPacketParserStartingBytes) / sizeof(char);

- (BOOL) consumeStartOfPacket;
{
	if ([currentBuffer length] >= 5) {
		const char* bytes = (const char*) [currentBuffer bytes];
		if (memcmp(kMvrPacketParserStartingBytes, bytes,
				   kMvrPacketParserStartingBytesLength) == 0) {
			
			self.state = kMvrPacketParserExpectingMetadataItemTitle;
			[delegate packetParserDidStartReceiving:self];
			
		} else
			[self resetAndReportError:kMvrPacketParserDidNotFindStartError];
		
		[currentBuffer replaceBytesInRange:NSMakeRange(0, 5) withBytes:NULL length:0];
		return YES;
	}
	
	return NO;
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
		else {
			self.lastSeenMetadataItemTitle = s;
			self.state = kMvrPacketParserExpectingMetadataItemValue;
		}
		[s release];
		
	} else {
		if (lastReportedBodySize == 0) {
			// we'd grab the body here, but since the body is empty, we go on.
			[delegate packetParser:self didReceiveBodyDataPart:[NSData data]];
			[self resetAndReportError:0];
		} else
			self.state = kMvrPacketParserExpectingBody;
	}
	
	[currentBuffer replaceBytesInRange:NSMakeRange(0, loc + 1) withBytes:NULL length:0];
	return YES;
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
		if ([self.lastSeenMetadataItemTitle isEqual:kMvrPacketParserSizeKey])
			lastReportedBodySize = [s longLongValue];
				
		self.state = kMvrPacketParserExpectingMetadataItemTitle;
		[delegate packetParser:self didReceiveMetadataItemWithKey:self.lastSeenMetadataItemTitle value:s];
		self.lastSeenMetadataItemTitle = nil;
	}
	[s release];
	
	[currentBuffer replaceBytesInRange:NSMakeRange(0, loc + 1) withBytes:NULL length:0];
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
	NSAssert(sizeOfReportedBytes < lastReportedBodySize, @"Should not report more bytes than I have been told to report");
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

@end
