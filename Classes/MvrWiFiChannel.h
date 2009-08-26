//
//  MvrWiFiChannel.h
//  Mover
//
//  Created by ∞ on 26/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MvrNetworkExchange.h"

@interface MvrWiFiChannel : NSObject <L0MoverPeerChannel> {

}

- (id) initWithNetService:(NSNetService*) s;

@property(readonly, retain) NSNetService* service;

@end
