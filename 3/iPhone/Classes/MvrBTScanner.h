//
//  MvrBTScanner.h
//  Mover3
//
//  Created by ∞ on 20/10/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>
#import <MuiKit/MuiKit.h>

#import "Network+Storage/MvrScanner.h"
#import "Network+Storage/MvrChannel.h"

#define kMvrBluetoothSessionID @"net.infinite-labs.Mover3"

#define kMvrBTOutgoingUnavailableInLiteVersionNotification @"kMvrBTOutgoingUnavailableInLiteVersionNotification"

@class MvrBTIncoming, MvrBTOutgoing, MvrBTChannel;

@interface MvrBTScanner : NSObject <MvrScanner, GKSessionDelegate> {
	BOOL enabled;
	NSMutableSet* channels;
	
	GKSession* session;
}

@property(retain) MvrBTChannel* channel;
@property(readonly) NSSet* channels;

- (GKSession*) configuredSession;
@property(retain) GKSession* session;

- (void) acceptPeerWithIdentifier:(NSString*) peerID;

@end

@interface MvrBTChannel : NSObject <MvrChannel> {
	MvrBTScanner* scanner;
	NSString* peerID;
	
	NSMutableSet* incomingTransfers, * outgoingTransfers;
	L0KVODispatcher* kvo;
}

- (id) initWithScanner:(MvrBTScanner*) s peerID:(NSString*) p;

@property(copy) NSString* peerID;

@property(retain) MvrBTIncoming* incomingTransfer;
@property(readonly) NSSet* incomingTransfers;
@property(retain) MvrBTOutgoing* outgoingTransfer;
@property(readonly) NSSet* outgoingTransfers;

- (void) didReceiveData:(NSData*) data;
- (BOOL) sendData:(NSData*) data error:(NSError**) e;

@end
