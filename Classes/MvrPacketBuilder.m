//
//  MvrPacketBuilder.m
//  Mover
//
//  Created by ∞ on 23/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrPacketBuilder.h"

@interface MvrPacketBuilder ()

- (void) stopWithoutNotifying;

@end

NSString* const kMvrPacketBuilderErrorDomain = @"kMvrPacketBuilderErrorDomain";

@implementation MvrPacketBuilder

- (id) initWithDelegate:(id <MvrPacketBuilderDelegate>) d;
{
	if (self = [super init]) {
		delegate = d;
		metadata = [NSMutableDictionary new];
	}
	
	return self;
}

- (void) dealloc;
{
	[self stop];
	[metadata release];
	[body release];
	[super dealloc];
}

- (void) setMetadataValue:(NSString*) v forKey:(NSString*) k;
{
	NSAssert(!sealed, @"You can't modify the metadata while a packet is being built.");
	
	NSCharacterSet* nullCharset = [NSCharacterSet characterSetWithRange:NSMakeRange(0, 1)];
	NSAssert([v rangeOfCharacterFromSet:nullCharset].location == NSNotFound, @"No NULL characters in the value!");
	NSAssert([k rangeOfCharacterFromSet:nullCharset].location == NSNotFound, @"No NULL characters in the key!");
	
	[metadata setObject:v forKey:k];
}

- (void) setBody:(id) b length:(unsigned long long) l;
{
	NSAssert(!sealed, @"You can't modify the body while a packet is being built.");
	
	if ([b isKindOfClass:[NSData class]])
		l = [b length];
	
	if (body != b) {
		[body release];
		
		if ([b isKindOfClass:[NSData class]])
			body = [b copy];
		else
			body = [b retain];
	}
	
	bodyLength = body? 0 : l;
}

- (void) start;
{
	if (sealed) return;
	cancelled = NO;
	
	[self setMetadataValue:[NSString stringWithFormat:@"%ull", bodyLength] forKey:kMvrPacketParserSizeKey];
	sealed = YES;
	
	[delegate packetBuilderWillStart:self];
	if (cancelled) return;
	
	// The header.
	NSData* d = [NSData dataWithBytesNoCopy:(void*) kMvrPacketParserStartingBytes length:kMvrPacketParserStartingBytesLength freeWhenDone:NO];
	[delegate packetBuilder:self didProduceData:d];
	if (cancelled) return;
	
	// The metadata.
	const char nullCharacter = 0;
	
	for (NSString* k in metadata) {
		NSMutableData* d = [NSMutableData new];
		[d appendData:[k dataUsingEncoding:NSUTF8StringEncoding]];
		[d appendBytes:&nullCharacter length:1];
		[d appendData:[[metadata objectForKey:k] dataUsingEncoding:NSUTF8StringEncoding]];
		[d appendBytes:&nullCharacter length:1];
		[delegate packetBuilder:self didProduceData:d];
		[d release];
		if (cancelled) return;
	}
	
	[delegate packetBuilder:self didProduceData:[NSData dataWithBytesNoCopy:(void*) &nullCharacter length:1 freeWhenDone:NO]];
	if (cancelled) return;
	
	if ([body isKindOfClass:[NSData class]]) {
		[delegate packetBuilder:self didProduceData:body];
		sealed = NO;
		if (cancelled) return;
		[delegate packetBuilder:self didEndWithError:nil];
	} else if ([body isKindOfClass:[NSStream class]]) {
		toBeRead = bodyLength;
		[body scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
		[body setDelegate:self];
		[body open];
	}
}

#define kMvrPacketBuilderStackBufferSize 10240

- (void) stream:(NSInputStream*) aStream handleEvent:(NSStreamEvent) eventCode;
{	
	switch (eventCode) {
		case NSStreamEventHasBytesAvailable: {
			uint8_t* buffer; NSUInteger bufferSize;
			uint8_t stackBuffer[kMvrPacketBuilderStackBufferSize];
			
			if (![aStream getBuffer:&buffer length:&bufferSize]) {
				buffer = stackBuffer;
				bufferSize = [aStream read:buffer maxLength:kMvrPacketBuilderStackBufferSize];
			}
			
			bufferSize = MIN(bufferSize, toBeRead);
			toBeRead -= bufferSize;
			
			[delegate packetBuilder:self didProduceData:[NSData dataWithBytesNoCopy:buffer length:bufferSize freeWhenDone:NO]];
			if (cancelled) return;
			
			if (toBeRead == 0) {
				[delegate packetBuilder:self didEndWithError:nil];
				[self stopWithoutNotifying];
			}
		}
			break;
			
		case NSStreamEventErrorOccurred: {
			[delegate packetBuilder:self didEndWithError:[aStream streamError]];
			[self stopWithoutNotifying];
		}
			break;
			
		case NSStreamEventEndEncountered: {
			if (sealed) {
				NSError* e = nil;
				if (toBeRead > 0)
					e = [NSError errorWithDomain:kMvrPacketBuilderErrorDomain code:kMvrPacketBuilderNotEnoughDataInStreamError userInfo:nil];
				[delegate packetBuilder:self didEndWithError:e];
				[self stopWithoutNotifying];
			}
		}
			break;
			
		default:
			break;
	}
}

- (void) stop;
{
	if (!sealed) return;
	[self stopWithoutNotifying];
	[delegate packetBuilder:self didEndWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
}

- (void) stopWithoutNotifying;
{
	if (!sealed) return;
	cancelled = YES;
	
	if ([body isKindOfClass:[NSStream class]]) {
		[body setDelegate:nil];
		[body close];
		[self setBody:nil length:kMvrPacketBuilderDefaultLength];
	}
	
	sealed = NO;
}

@end
