//
//  L0MoverBluetoothChannel.h
//  Mover
//
//  Created by ∞ on 11/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

#import "MvrNetworkExchange.h"
#import "L0MoverBluetoothScanner.h"

@interface L0MoverBluetoothChannel : NSObject <L0MoverPeerChannel> {
	L0MoverBluetoothScanner* scanner;
	NSString* peerID;
	NSString* name;
	
	NSString* uniquePeerIdentifier;
	
	L0MoverItem* itemToBeSent;
	NSMutableData* dataToBeSent;
	NSMutableData* dataReceived;
}

- (id) initWithScanner:(L0MoverBluetoothScanner*) scanner peerID:(NSString*) peerID;

@property(readonly) NSString* peerID;

- (void) communicateWithOtherEndpoint;
- (void) endCommunicationWithOtherEndpoint;
- (void) receiveDataFromOtherEndpoint:(NSData*) data;

@end
