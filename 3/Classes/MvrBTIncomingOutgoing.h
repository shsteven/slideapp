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

#import "MvrBTProtocol.h"

@interface MvrBTIncoming : MvrStreamedIncoming <MvrIncoming, MvrBTProtocolIncomingDelegate> {
	MvrBTChannel* channel;
	MvrBTProtocolIncoming* proto;
}

+ (BOOL) shouldStartReceivingWithData:(NSData*) data;

- (id) initWithChannel:(MvrBTChannel*) chan;
+ incomingTransferWithChannel:(MvrBTChannel*) chan;

- (void) didReceiveDataFromBluetooth:(NSData*) data;

@end

@interface MvrBTOutgoing : NSObject <MvrOutgoing> {
	MvrBTChannel* channel;
}

- (id) initWithChannel:(MvrBTChannel*) chan;
+ outgoingTransferWithItem:(MvrItem*) i channel:(MvrBTChannel*) chan;

- (void) start;

- (void) didReceiveDataFromBluetooth:(NSData*) data;

@end
