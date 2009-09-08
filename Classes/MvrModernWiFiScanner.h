//
//  MvrModernWiFiScanner.h
//  Mover
//
//  Created by ∞ on 25/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AsyncSocket.h"
#import "MvrNetworkExchange.h"

#import "MvrWiFiChannel.h"

#import "MvrWiFiScanner.h"

#define kMvrModernBonjourServiceName @"_x-mover2._tcp."

@interface MvrModernWiFiScanner : MvrWiFiScanner <L0MoverPeerScanner> {
	MvrNetworkExchange* service;
	NSMutableSet* availableChannels;
	NSMutableSet* transfers;
	BOOL enabled;
	BOOL jammed;
	
	AsyncSocket* server;
	NSNetService* netService;
	NSNetServiceBrowser* browser;
	
	NSMutableSet* servicesBeingResolved;
	
	AsyncSocket* selfWarmer;
}

+ sharedScanner;

// Can be KVO'd.
@property(readonly) NSSet* transfers;

- (MvrWiFiChannel*) channelForAddress:(NSData*) a;

@end
