//
//  MvrBluetoothChannel.h
//  Mover3
//
//  Created by ∞ on 05/10/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Network+Storage/MvrChannel.h"

#import "MvrBluetoothIncomingOutgoing.h"

@class MvrBluetoothScanner, GKSession;

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
