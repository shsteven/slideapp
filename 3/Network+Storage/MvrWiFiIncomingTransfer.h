//
//  MvrWiFiIncomingTransfer.h
//  Mover
//
//  Created by ∞ on 25/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MvrChannel.h"
#import "MvrPacketParser.h"
#import "MvrIncoming.h"

@class AsyncSocket, MvrItemStorage;
@class MvrModernWiFi, MvrModernWiFiChannel;
@class MvrItem;

@class L0KVODispatcher;

@interface MvrWiFiIncomingTransfer : NSObject <MvrPacketParserDelegate, MvrIncoming> {
	AsyncSocket* socket;
	BOOL finished;
	MvrPacketParser* parser;
	BOOL isNewPacket;
	BOOL isCancelled;
	BOOL hasCheckedForMetadata;
	
	MvrItemStorage* itemStorage;
	NSOutputStream* itemStorageStream;
	
	NSMutableDictionary* metadata;
	MvrModernWiFiChannel* channel;
	MvrModernWiFi* scanner;
	
	float progress;
	
	MvrItem* item;
}

- (id) initWithSocket:(AsyncSocket*) s scanner:(MvrModernWiFi*) scanner;

@property(readonly) BOOL finished;
@property(readonly) float progress;

@property(readonly, retain) MvrItem* item;
@property(readonly) BOOL cancelled;

@end

@interface MvrWiFiIncomingTransfer (MvrKVOUtilityMethods)

- (void) observeUsingDispatcher:(L0KVODispatcher*) d invokeAtItemChange:(SEL) itemSel atCancelledChange:(SEL) cancelSel;
- (void) endObservingUsingDispatcher:(L0KVODispatcher*) d;

@end