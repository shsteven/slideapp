//
//  L0MoverBluetoothScanner.h
//  Mover
//
//  Created by ∞ on 11/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

#import "L0MoverPeering.h"

#define kL0MoverBTSessionIdentifier @"net.infinite-labs.Mover"

@interface L0MoverBluetoothScanner : NSObject <L0MoverPeerScanner, GKSessionDelegate> {
	L0MoverPeering* service;
	GKSession* bluetoothSession;
	
	NSMutableDictionary* channelsByPeerID;
	BOOL jammed;
	int retries;
	
#if DEBUG
	BOOL isJammingSimulated;
	BOOL simulatedJammedValue;
#endif
}

+ sharedScanner;

@property(readonly) GKSession* bluetoothSession;

#if DEBUG
- (void) testBySimulatingJamming:(BOOL) simulatedJam;
- (void) testByStoppingJamSimulation;
#endif

@end
