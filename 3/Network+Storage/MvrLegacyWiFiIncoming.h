//
//  MvrLegacyWiFiIncoming.h
//  Network+Storage
//
//  Created by ∞ on 15/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MvrGenericIncoming.h"
#import "BLIP.h"

@interface MvrLegacyWiFiIncoming : MvrGenericIncoming <BLIPConnectionDelegate> {
	BLIPConnection* connection;
}

- (id) initWithConnection:(BLIPConnection*) connection;

@end
