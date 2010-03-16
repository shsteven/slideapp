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

#if !defined(kMvrModernWiFiOutgoingSimulateBreaking)
#define kMvrModernWiFiOutgoingSimulateBreaking 0
#endif

enum {
	kMvrModernWiFiOutgoingAllowExtendedMetadata = 1 << 0,
};
typedef NSInteger MvrModernWiFiOutgoingOptions;

@interface MvrModernWiFiOutgoing : NSObject <MvrPacketBuilderDelegate, MvrOutgoing> {
	BOOL allowExtendedMetadata;
	
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
- (id) initWithItem:(MvrItem*) i toAddresses:(NSArray*) a options:(MvrModernWiFiOutgoingOptions) opts;

@property(readonly, assign) BOOL finished;
@property(readonly, assign) float progress;
@property(readonly, retain) NSError* error;

- (void) start;

@end
