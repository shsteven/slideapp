//
//  MvrModernWiFi.h
//  Network
//
//  Created by ∞ on 12/09/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MvrWiFiScanner.h"
#import "MvrPlatformInfo.h"

#define kMvrModernWiFiDifficultyStartingListenerNotification @"MvrModernWiFiDifficultyStartingListenerNotification"

#define kMvrModernWiFiBonjourServiceType @"_x-mover3._tcp."
#define kMvrModernWiFiBonjourConduitServiceType @"_x-mover-conduit._tcp."

#define kMvrModernWiFiPort (25252)
#define kMvrModernWiFiConduitPort (25277)

#define kMvrModernWiFiPeerIdentifierKey @"MvrID"

enum {
	kMvrUseMobileService = 1 << 0,
	kMvrUseConduitService = 1 << 1,
	kMvrAllowBrowsingForConduitService = 1 << 2,
};
typedef NSInteger MvrModernWiFiOptions;

@class L0KVODispatcher;

@class AsyncSocket, MvrModernWiFiChannel;

@interface MvrModernWiFi : MvrWiFiScanner {
	AsyncSocket* serverSocket;
	int serverPort;
	
	BOOL useMobileService;
	BOOL useConduitService;
	BOOL allowBrowsingForConduit;
	
	NSMutableSet* incomingTransfers;
	L0KVODispatcher* dispatcher;
}

- (id) initWithPlatformInfo:(id <MvrPlatformInfo>) info serverPort:(int) port options:(MvrModernWiFiOptions) opts;

- (MvrModernWiFiChannel*) channelForAddress:(NSData*) address;

@end
