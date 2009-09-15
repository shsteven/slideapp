//
//  MvrLegacyWiFiChannel.h
//  Network+Storage
//
//  Created by ∞ on 15/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MvrWiFiChannel.h"

@class BLIPConnection;

@interface MvrLegacyWiFiChannel : MvrWiFiChannel {

}

- (void) addIncomingTransferWithConnection:(BLIPConnection*) conn;

@end
