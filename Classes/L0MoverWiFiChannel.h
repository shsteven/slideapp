//
//  L0MoverWiFiChannel.h
//  Mover
//
//  Created by ∞ on 10/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MvrNetworkExchange.h"
#import "L0MoverWiFiScanner.h"
#import "BLIP.h"

@interface L0MoverWiFiChannel : NSObject <L0MoverPeerChannel, BLIPConnectionDelegate> {
	NSNetService* service;
	NSString* name;
	NSString* type;
	NSInteger port;
	NSArray* addresses;
	
	CFMutableDictionaryRef itemsBeingSentByConnection;
	NSMutableSet* finalizingConnections;
	
	double applicationVersion;
	NSString* userVisibleApplicationVersion;
	NSString* uniquePeerIdentifier;
	
	L0MoverWiFiScanner* scanner;
}

- (id) initWithScanner:(L0MoverWiFiScanner*) scanner netService:(NSNetService*) s;

@property(readonly) NSNetService* service;

@end
