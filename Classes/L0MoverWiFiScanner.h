//
//  L0MoverDummyScanner.h
//  Mover
//
//  Created by ∞ on 10/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "L0MoverPeering.h"
#import "BLIP.h"

#define kL0BonjourPeerApplicationVersionKey @"L0AppVersion"
#define kL0BonjourPeerUserVisibleApplicationVersionKey @"L0UserAppVersion"
#define kL0BonjourPeerUniqueIdentifierKey @"L0PeerID"

#define kL0BonjourPeeringServiceName @"_x-infinitelabs-slides._tcp."

@interface L0MoverWiFiScanner : NSObject <L0MoverPeerScanner, TCPListenerDelegate, TCPConnectionDelegate> {
	NSNetServiceBrowser* browser;
	BLIPListener* listener;
	NSMutableSet* pendingConnections;
	NSMutableSet* availableChannels;
}

@end
