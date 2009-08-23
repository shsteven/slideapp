//
//  MvrPacketParser.h
//  Mover
//
//  Created by ∞ on 23/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MvrProtocol.h"

enum {	
	kMvrPacketParserExpectingStart,
	kMvrPacketParserExpectingMetadataItemTitle,
	kMvrPacketParserExpectingMetadataItemValue,
	kMvrPacketParserExpectingBody,
	
	kMvrPacketParserStartingState = kMvrPacketParserExpectingStart,
};
typedef NSUInteger MvrPacketParserState;

extern NSString* const kMvrPacketParserErrorDomain;
enum {
	// After enough bytes have been collected for a new packet, the parser couldn't find the start of a packet. The bytes will have been consumed.
	kMvrPacketParserDidNotFindStartError = 1,	
	kMvrPacketParserNotUTF8StringError = 2,
	kMvrPacketParserMetadataDidNotIncludeSize = 3,
};

@class MvrPacketParser;
@protocol MvrPacketParserDelegate <NSObject>

- (void) packetParserDidStartReceiving:(MvrPacketParser*) p;
- (void) packetParser:(MvrPacketParser*) p didReceiveMetadataItemWithKey:(NSString*) key value:(NSString*) value;
- (void) packetParser:(MvrPacketParser*) p didReceiveBodyDataPart:(NSData*) d;

// e == nil if no error.
- (void) packetParser:(MvrPacketParser*) p didReturnToStartingStateWithError:(NSError*) e;

@optional

// Indicates that the parser has found an error and has discarded whatever data was previously buffered. Called after every didReturnToStartingStateWithError: where the error is non-nil.
- (void) packetParserDidResetAfterError:(MvrPacketParser*) p;

// Indicates that the parser has completed a packet successfully. Return NO to allow the parser to read any leftover data past the packet, or YES to discard that data.
// Defaults to YES (reset the parser after every packet).
- (BOOL) packetParserShouldResetAfterCompletingPacket:(MvrPacketParser*) p;

@end

/*
 
 The packet parser works like some sort of state machine-driven thingie. When
 just created, it's in a 'starting state' with an empty buffer. As you append data,
 it progresses through a set of states, sending events to the delegate as it finds
 interesting stuff.
 
 It's possible that what got passed was truncated with partially-valid
 data, not enough to emit an event. In that case, the leftover data will be stored by
 the parser in a buffer until subsequent appendData:... calls complete the data or
 produce an invalid packet. If a packet is completed successfully, parsing will restart
 
 */

@interface MvrPacketParser : NSObject {
	NSMutableData* currentBuffer;
	id <MvrPacketParserDelegate> delegate;
	MvrPacketParserState state;
	NSString* lastSeenMetadataItemTitle;
	long long lastReportedBodySize;
	unsigned long long sizeOfReportedBytes;
	
	BOOL beingReset;
}

- (id) initWithDelegate:(id <MvrPacketParserDelegate>) delegate;

// Appends data to the parser's internal buffer, then moves the parsing
// machinery until all data produces events to the delegate.
// If reset == YES, the current state of the parser will be discarded before
// considering the new data (a reset).
- (void) appendData:(NSData*) data isKnownStartOfNewPacket:(BOOL) reset;

// Convenience for appendData:data isKnownStartOfNewPacket:NO.
- (void) appendData:(NSData*) data;

@property(readonly, assign) MvrPacketParserState state;

// Returns YES if the parsers is expecting a brand-new packet.
// If NO, it means either that we're not in the starting state of the
// parser, or that we are but there is data in the queue.
// This is YES immediately after every reset.
@property(readonly) BOOL expectingNewPacket;

@end
