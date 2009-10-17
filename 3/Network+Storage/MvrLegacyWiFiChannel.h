//
//  MvrLegacyWiFiChannel.h
//  Network+Storage
//
//  Created by ∞ on 15/09/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MvrWiFiChannel.h"

@class BLIPConnection;

@interface MvrLegacyWiFiChannel : MvrWiFiChannel {}

- (void) addIncomingTransferWithConnection:(BLIPConnection*) conn;

@property(readonly, getter=isLegacyLegacy) BOOL legacyLegacy;

@end
