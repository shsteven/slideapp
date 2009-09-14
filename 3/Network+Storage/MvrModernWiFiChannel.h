//
//  MvrModernWiFiChannel.h
//  Network
//
//  Created by ∞ on 12/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MvrChannel.h"

@class L0KVODispatcher;

@interface MvrModernWiFiChannel : NSObject <MvrChannel> {
	NSNetService* netService;
	NSMutableSet* outgoingTransfers;
	NSMutableSet* incomingTransfers;
	
	L0KVODispatcher* dispatcher;
}

- (id) initWithNetService:(NSNetService*) ns;

- (BOOL) hasSameServiceAs:(NSNetService*) n;
- (BOOL) isReachableThroughAddress:(NSData*) address;

@end
