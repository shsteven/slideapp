//
//  MvrLegacyWiFiIncoming.h
//  Network+Storage
//
//  Created by ∞ on 15/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MvrWiFiIncoming.h"
#import "BLIP.h"

@interface MvrLegacyWiFiIncoming : MvrWiFiIncoming <BLIPConnectionDelegate> {
	BLIPConnection* connection;
}

- (id) initWithConnection:(BLIPConnection*) connection;

@end
