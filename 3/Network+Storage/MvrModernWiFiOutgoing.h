//
//  MvrWiFiOutgoingTransfer.h
//  Mover
//
//  Created by ∞ on 29/08/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MvrOutgoing.h"

@class MvrItem;
@class AsyncSocket;

#import "MvrPacketBuilder.h"

@interface MvrModernWiFiOutgoing : NSObject <MvrPacketBuilderDelegate, MvrOutgoing> {
	MvrItem* item;
	NSArray* addresses;
	
	AsyncSocket* outgoingSocket;
	MvrPacketBuilder* builder;
	
	NSMutableSet* failedSockets;
	
	BOOL finished, finishing;
	float progress;
	NSError* error;
	
	unsigned long chunksPending;
	BOOL canFinish;
	
	int retries;
	
	BOOL didSendAtLeastPart;
#if kMvrModernWiFiOutgoingSimulateBreaking
	int simulatedBreaks;
#endif
}

+ (void) allowIPv6;
- (id) initWithItem:(MvrItem*) i toAddresses:(NSArray*) a;

@property(readonly, assign) BOOL finished;
@property(readonly, assign) float progress;
@property(readonly, retain) NSError* error;

- (void) start;

@end
