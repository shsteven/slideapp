//
//  MvrChunkedBuffer.m
//  Mover
//
//  Created by ∞ on 24/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrChunkedBuffer.h"


@implementation MvrChunkedBuffer

- (id) init;
{
	if (self = [super init]) {
		data = [NSMutableData new];
		chunkSize = 10240;
	}
	
	return self;
}

- (void) dealloc
{
	[data release];
	[super dealloc];
}


@synthesize chunkSize;
@synthesize delegate;

- (void) appendData:(NSData*) d;
{
	NSUInteger previousLength = [data length];
	[data appendData:d];
	if (previousLength < chunkSize && [data length] >= chunkSize)
		[delegate chunkedBufferDidReachOrExceedChunkSize:self];
}

- (NSData*) extractChunk;
{
	NSRange chunkRange = NSMakeRange(0, MIN(chunkSize, [data length]));
	
	NSUInteger previousLength = [data length];
	NSData* d = [data subdataWithRange:chunkRange];
	[data replaceBytesInRange:chunkRange withBytes:NULL length:0];
	
	if (previousLength >= chunkSize && [data length] < chunkSize)
		[delegate chunkedBufferDidFreeBufferBelowChunkSize:self];
	
	return d;
}

@end
