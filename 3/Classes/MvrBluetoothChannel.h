//
//  MvrBluetoothChannel.h
//  Mover3
//
//  Created by ∞ on 05/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Network+Storage/MvrChannel.h"

#import "Network+Storage/MvrIncoming.h"
#import "Network+Storage/MvrOutgoing.h"
#import "Network+Storage/MvrPacketParser.h"
#import "Network+Storage/MvrPacketBuilder.h"
#import "Network+Storage/MvrItemStorage.h"
#import "Network+Storage/MvrProtocol.h"
#import "Network+Storage/MvrBuffer.h"

@class MvrBluetoothScanner, MvrItem, GKSession;

// We have the interfaces here because MvrBluetoothChannel needs at least the outgoing one, but the implementations are in MvrBluetoothScanner.m as they're tied to its GKSession stuff.

@interface MvrBluetoothIncoming : NSObject <MvrIncoming, MvrPacketParserDelegate>
{
	MvrItemStorage* storage;
	MvrPacketParser* parser;
	NSMutableDictionary* metadata;
	
	NSOutputStream* itemStorageStream;

	float progress;
	MvrItem* item;
	BOOL cancelled;
}

@property float progress;
@property(retain) MvrItem* item;
@property BOOL cancelled;

- (void) appendData:(NSData*) data;

- (void) checkMetadataIfNeeded;
- (void) cancel;
- (void) produceItem;
- (void) clear;

@end

@interface MvrBluetoothOutgoing : NSObject <MvrOutgoing, MvrPacketBuilderDelegate>
{
	MvrItem* item;
	MvrBluetoothScanner* scanner;
	MvrPacketBuilder* builder;
	MvrBuffer* buffer;
	
	BOOL finished;
	NSError* error;
}

- (id) initWithItem:(MvrItem*) i scanner:(MvrBluetoothScanner*) s;
@property(retain) NSError* error;
@property BOOL finished;

- (void) start;
- (void) sendPacketPart;
- (void) acknowledge;

- (void) endWithError:(NSError*) e;

@end

@interface MvrBluetoothChannel : NSObject <MvrChannel> {
	MvrBluetoothScanner* scanner;
	NSString* peerIdentifier;
	
	MvrBluetoothIncoming* incomingTransfer;
	MvrBluetoothOutgoing* outgoingTransfer;
}

- (id) initWithScanner:(MvrBluetoothScanner*) s peerIdentifier:(NSString*) peerID;

@property(copy) NSString* peerIdentifier;

@property(retain) MvrBluetoothIncoming* incomingTransfer;
@property(retain) MvrBluetoothOutgoing* outgoingTransfer;

@end
