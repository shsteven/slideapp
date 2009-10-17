//
//  MvrLegacyWiFiOutgoing.h
//  Network+Storage
//
//  Created by ∞ on 15/09/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BLIP.h"
#import "MvrOutgoing.h"

enum {
	kMvrLegacyWiFiOutgoingItemRequiresStreamError = 1,
};

extern NSString* const kMvrLegacyWiFiOutgoingErrorDomain;

@interface MvrLegacyWiFiOutgoing : NSObject <BLIPConnectionDelegate, MvrOutgoing> {
	BOOL finished;
	
	MvrItem* item;
	NSNetService* service;
	
	BLIPConnection* connection;
	
	NSError* error;
}

- (id) initWithItem:(MvrItem*) i toNetService:(NSNetService*) s;
- (void) start;

@property(readonly, retain) NSError* error;

@end
