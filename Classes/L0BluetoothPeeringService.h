//
//  L0BluetoothPeeringService.h
//  Mover
//
//  Created by ∞ on 05/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

#import "L0PeerDiscovery.h"

@class L0BluetoothPeer, L0MoverItem;

@interface L0BluetoothPeeringService : NSObject <GKSessionDelegate> {
	id <L0PeerDiscoveryDelegate> delegate;
	GKSession* session;
	
	NSMutableDictionary* currentPeers;
	NSMutableDictionary* pendingItemsToSendByPeer;
}

+ sharedService;

- (void) start;
- (void) stop;

@property(assign) id <L0PeerDiscoveryDelegate> delegate;

- (void) sendItem:(L0MoverItem*) i toBluetoothPeer:(L0BluetoothPeer*) peer;

@end
