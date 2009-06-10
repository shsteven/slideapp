//
//  L0MoverWiFiChannel.h
//  Mover
//
//  Created by ∞ on 10/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "L0MoverPeering.h"
#import "L0MoverWiFiScanner.h"
#import "BLIP.h"

@interface L0MoverWiFiChannel : NSObject <L0MoverPeerChannel, BLIPConnectionDelegate> {
	NSNetService* service;
	
	CFMutableDictionaryRef itemsBeingSentByConnection;
	double applicationVersion;
	NSString* userVisibleApplicationVersion;
	NSString* uniquePeerIdentifier;
	
	L0MoverWiFiScanner* scanner;
}

- (id) initWithScanner:(L0MoverWiFiScanner*) scanner netService:(NSNetService*) s;

@property(readonly) NSNetService* service;

@end
