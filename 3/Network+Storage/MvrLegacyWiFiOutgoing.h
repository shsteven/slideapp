//
//  MvrLegacyWiFiOutgoing.h
//  Network+Storage
//
//  Created by ∞ on 15/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BLIP.h"
#import "MvrOutgoing.h"

@interface MvrLegacyWiFiOutgoing : NSObject <BLIPConnectionDelegate, MvrOutgoing> {
	BOOL finished;
	
	MvrItem* item;
	NSNetService* service;
	
	BLIPConnection* connection;
}

- (id) initWithItem:(MvrItem*) i toNetService:(NSNetService*) s;
- (void) start;

@end
