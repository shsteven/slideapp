//
//  MvrWiFiIncomingTransfer.h
//  Mover
//
//  Created by ∞ on 25/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MvrModernWiFiScanner.h"
#import "MvrPacketParser.h"
#import "AsyncSocket.h"

@interface MvrWiFiIncomingTransfer : NSObject <MvrPacketParserDelegate> {
	AsyncSocket* socket;
	BOOL finished;
	MvrPacketParser* parser;
	BOOL isNewPacket;
	BOOL isCancelled;
	BOOL hasCheckedForMetadata;
	
	NSMutableData* data; // TODO to file
	
	NSMutableDictionary* metadata;
	id <L0MoverPeerChannel> channel;
	MvrModernWiFiScanner* scanner;
	
	CGFloat progress;
}

- (id) initWithSocket:(AsyncSocket*) s scanner:(MvrModernWiFiScanner*) scanner;

@property(readonly) BOOL finished;
@property(readonly) CGFloat progress;

@end
