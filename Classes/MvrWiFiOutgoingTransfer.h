//
//  MvrWiFiOutgoingTransfer.h
//  Mover
//
//  Created by ∞ on 29/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AsyncSocket.h"
#import "L0MoverItem.h"
#import "MvrWiFiChannel.h"
#import "MvrPacketBuilder.h"

@interface MvrWiFiOutgoingTransfer : NSObject <MvrPacketBuilderDelegate> {
	L0MoverItem* item;
	MvrWiFiChannel* channel;
	
	AsyncSocket* socket;
	MvrPacketBuilder* builder;
	
	BOOL finished;
	
	CGFloat progress;
}

- (id) initWithItem:(L0MoverItem*) i toChannel:(MvrWiFiChannel*) c;

@property(readonly, assign) BOOL finished;
@property(readonly, assign) CGFloat progress;

- (void) start;

@end
