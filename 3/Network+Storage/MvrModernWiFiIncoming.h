//
//  MvrWiFiIncomingTransfer.h
//  Mover
//
//  Created by ∞ on 25/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MvrWiFiIncoming.h"

#import "MvrChannel.h"
#import "MvrPacketParser.h"
#import "MvrIncoming.h"

@class AsyncSocket, MvrItemStorage;
@class MvrModernWiFi, MvrModernWiFiChannel;
@class MvrItem;

@class L0KVODispatcher;

@interface MvrModernWiFiIncoming : MvrWiFiIncoming <MvrPacketParserDelegate> {
	AsyncSocket* socket;
	MvrPacketParser* parser;
	BOOL isNewPacket;
	BOOL hasCheckedForMetadata;
	
	MvrItemStorage* itemStorage;
	NSOutputStream* itemStorageStream;
	
	NSMutableDictionary* metadata;
	MvrModernWiFiChannel* channel;
	MvrModernWiFi* scanner;	
}

- (id) initWithSocket:(AsyncSocket*) s scanner:(MvrModernWiFi*) scanner;

@end
