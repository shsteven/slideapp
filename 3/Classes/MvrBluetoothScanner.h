//
//  MvrBluetoothScanner.h
//  Mover3
//
//  Created by ∞ on 05/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

#import "Network+Storage/MvrScanner.h"

#import "MvrBluetoothChannel.h"

#define kMvrBluetoothSessionID @"net.infinite-labs.Mover3"

@interface MvrBluetoothScanner : NSObject <MvrScanner, GKSessionDelegate> {
	BOOL enabled;
	MvrBluetoothChannel* channel;
	
	GKSession* session;
}

@property(retain) MvrBluetoothChannel* channel;
@property(readonly) GKSession* session;

@end
