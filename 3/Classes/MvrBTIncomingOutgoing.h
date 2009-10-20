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

@interface MvrBTIncoming : NSObject <MvrIncoming> {
	MvrBTChannel* channel;
}

+ (BOOL) shouldStartReceivingWithData:(NSData*) data;

- (id) initWithChannel:(MvrBTChannel*) chan;
+ incomingTransferWithChannel:(MvrBTChannel*) chan;

- (void) didReceiveData:(NSData*) data;

@end

@interface MvrBTOutgoing : NSObject <MvrOutgoing> {
	MvrBTChannel* channel;
}

- (id) initWithChannel:(MvrBTChannel*) chan;
+ outgoingTransferWithItem:(MvrItem*) i channel:(MvrBTChannel*) chan;

- (void) start;

- (void) didReceiveData:(NSData*) data;

@end
