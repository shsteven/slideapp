//
//  MvrWiFiChannel.h
//  Mover
//
//  Created by ∞ on 26/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MvrNetworkExchange.h"

#define kMvrWiFiChannelUniqueIdentifierKey @"UUID"
#define kMvrWiFiChannelApplicationVersionKey @"Version"
#define kMvrWiFiChannelUserVisibleApplicationVersionKey @"UserVersion"

@interface MvrWiFiChannel : NSObject <L0MoverPeerChannel> {
	NSNetService* service;
	NSString* name, * uniquePeerIdentifier, * userVisibleApplicationVersion;
	double applicationVersion;
}

- (id) initWithNetService:(NSNetService*) s;

@property(readonly, retain) NSNetService* service;

@end
