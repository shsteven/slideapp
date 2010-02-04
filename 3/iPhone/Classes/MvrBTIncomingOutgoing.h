//
//  MvrBTIncomingOutgoing.h
//  Mover3
//
//  Created by ∞ on 20/10/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MvrBTScanner.h"

#import "Network+Storage/MvrItem.h"
#import "Network+Storage/MvrIncoming.h"
#import "Network+Storage/MvrOutgoing.h"
#import "Network+Storage/MvrStreamedIncoming.h"

#import "Network+Storage/MvrProtocol.h"
#import "Network+Storage/MvrPacketBuilder.h"
#import "Network+Storage/MvrBuffer.h"

#import "MvrBTProtocol.h"

#define kMvrBTProtocolPacketSize 4096
#define kMvrBTProtocolTimeout 7.0

@interface MvrBTIncoming : MvrStreamedIncoming <MvrIncoming, MvrBTProtocolIncomingDelegate> {
	MvrBTChannel* channel;
	MvrBTProtocolIncoming* proto;
	
	int attemptsAtBacktracking;
	NSUInteger awaitingSequenceNo;
}

+ (BOOL) shouldStartReceivingWithData:(NSData*) data;

- (id) initWithChannel:(MvrBTChannel*) chan;
+ incomingTransferWithChannel:(MvrBTChannel*) chan;

- (void) didReceiveDataFromBluetooth:(NSData*) data;

- (void) startWaiting;
- (void) stopWaiting;

+ (BOOL) isLiteWarningPacket:(NSData*) data;
+ (NSData*) liteWarningPacket;

@end

#if !kMvrIsLite

@interface MvrBTOutgoing : NSObject <MvrOutgoing, MvrBTProtocolOutgoingDelegate, MvrPacketBuilderDelegate> {
	MvrBTChannel* channel;
	MvrBTProtocolOutgoing* proto;
	MvrPacketBuilder* builder;
	MvrBuffer* buffer;
	
	NSUInteger baseIndex;
	NSMutableArray* savedPackets;
	NSUInteger seqNoThatNeedsSending;
	
	MvrItem* item;
	
	NSError* error;
	BOOL finishedBuilding, hasSentLastPacket, finished; float progress;
	
	int retries;
}

- (id) initWithItem:(MvrItem*) i channel:(MvrBTChannel*) chan;
+ outgoingTransferWithItem:(MvrItem*) i channel:(MvrBTChannel*) chan;

- (void) start;
- (void) endWithError:(NSError*) e;
- (void) cancel;

- (void) didReceiveDataFromBluetooth:(NSData*) data;

@property(retain) NSError* error;
@property BOOL finished;
@property float progress;

@end

#endif
