//
//  MvrChunkedBuffer.h
//  Mover
//
//  Created by ∞ on 24/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MvrChunkedBuffer;
@protocol MvrChunkedBufferDelegate <NSObject>

// These methods are called whenever operations on the chunked buffer pass the chunk size limit in one direction or the other.

// Called whenever data is appended to the buffer that causes it to exceed one chunk's size. Not called if the data already was more than one chunk size large before appending.
- (void) chunkedBufferDidReachOrExceedChunkSize:(MvrChunkedBuffer*) b;

// Called whenever data is extracted that causes the buffer to go from holding more than one chunk's worth of data to holding less. 
- (void) chunkedBufferDidFreeBufferBelowChunkSize:(MvrChunkedBuffer*) b;

@end

/*
 A chunked buffer is an object whose job is to enqueue data and provide it in "chunks" no larger than a specified limit. It can be used to collect variable amounts of data and provide them again so as not to go past the limits of restrictive channels (for example, GameKit's buffers).
 
 The chunked buffer uses the one-chunk size as a sort of "high water" limit which causes messages to be sent to its delegate whenever the amount of data it manages rises past or lowers below that amount, to allow clients to know when to "ease" the load and stop fetching data to append. This is designed to be used in conjunction with the .paused property of MvrPacketBuilder.
 */

@interface MvrChunkedBuffer : NSObject {
	size_t chunkSize;
	NSMutableData* data;
	id <MvrChunkedBufferDelegate> delegate;
}

@property size_t chunkSize; // defaults to 10 KB.
@property(assign) id <MvrChunkedBufferDelegate> delegate;

- (void) appendData:(NSData*) d;
- (NSData*) extractChunk;

@end
