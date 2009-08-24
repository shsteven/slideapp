//
//  MvrPacketBuilder.h
//  Mover
//
//  Created by ∞ on 23/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MvrProtocol.h"

enum {
	// use with setBody:length:'s second parameter
	// if the first parameter is nil, or a NSData object.
	// (nil resets the length to zero regardless, while
	// NSData objects are directly queried for their length.)
	kMvrPacketBuilderDefaultLength = 0,
};

extern NSString* const kMvrPacketBuilderErrorDomain;
enum {
	kMvrPacketBuilderNotEnoughDataInStreamError = 1,
};

@class MvrPacketBuilder;
@protocol MvrPacketBuilderDelegate <NSObject>

- (void) packetBuilderWillStart:(MvrPacketBuilder*) builder;
- (void) packetBuilder:(MvrPacketBuilder*) builder didProduceData:(NSData*) d;
- (void) packetBuilder:(MvrPacketBuilder*) builder didEndWithError:(NSError*) e;

@end

@interface MvrPacketBuilder : NSObject {
	id <MvrPacketBuilderDelegate> delegate;
	NSMutableDictionary* metadata;
	NSMutableArray* payloadOrder;
	NSMutableDictionary* payloadObjects;
	NSMutableDictionary* payloadLengths;
	unsigned long long toBeRead;
	
	BOOL isWorkingOnStreamPayload;
	NSUInteger currentPayloadIndex;
	
	BOOL sealed, cancelled;
}

- (id) initWithDelegate:(id <MvrPacketBuilderDelegate>) d;

- (void) setMetadataValue:(NSString*) v forKey:(NSString*) k;

// Sets a payload for a specific key. Payloads are ordered in the order they're added.
// Adding a payload for a key that's already there will remove the current payload from its position and readd it to the end.
// body can be:
// - a NSData object. If so, length is ignored (pass kMvrPacketBuilderDefaultLength).
// - an UNOPENED NSInputStream. It will be scheduled on this thread's run loop on the common modes. If you pass a NSInputStream, you must also specify the stream's length. No more than length bytes will be read from it before closing.
// If the stream ends before length bytes, packetBuilder:didEndWithError: will be called with an appropriate error (kMvrPacketParserErrorDomain/kMvrPacketBuilderNotEnoughDataInStreamError)
- (void) addPayload:(id) payload length:(unsigned long long) length forKey:(NSString*) key;

// Convenience methods for addPayload:length:forKey:.
- (void) addPayloadWithData:(NSData*) d forKey:(NSString*) key;
- (BOOL) addPayloadByReferencingFile:(NSString*) s forKey:(NSString*) key error:(NSError**) e;

// Removing payloads from the packet.
- (void) removePayloadForKey:(NSString*) key;
- (void) removeAllPayloads;

// Produces a packet!
- (void) start;

// YES if we're between willStart: and didEnd: as seen by the delegate.
@property(readonly, getter=isRunning) BOOL running;

// call this from willStart or didProduceData to end.
// will call didEndWithError: with a NSCocoaErrorDomain/NSUserCancelledError.
- (void) stop;

@end
