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
};
typedef NSUInteger MvrPacketParserState;

extern NSString* const kMvrPacketParserErrorDomain;
enum {
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
// state is now again expectingStart.
- (void) packetParser:(MvrPacketParser*) p didReturnToStartingStateWithError:(NSError*) e;

@end


@interface MvrPacketParser : NSObject {
	NSMutableData* currentBuffer;
	id <MvrPacketParserDelegate> delegate;
	MvrPacketParserState state;
	NSString* lastSeenMetadataItemTitle;
	long long lastReportedBodySize;
	unsigned long long sizeOfReportedBytes;
}

- (id) initWithDelegate:(id <MvrPacketParserDelegate>) delegate;
- (void) appendData:(NSData*) data;

@property(readonly, assign) MvrPacketParserState state;

@end
