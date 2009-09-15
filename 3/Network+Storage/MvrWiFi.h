//
//  MvrWiFi.h
//  Network
//
//  Created by ∞ on 12/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MvrScanner.h"

#import "MvrPlatformInfo.h"

@class MvrModernWiFi, MvrLegacyWiFi, L0KVODispatcher;

@interface MvrWiFi : NSObject <MvrScanner> {
	MvrModernWiFi* modernWiFi;
	MvrLegacyWiFi* legacyWiFi;

	NSMutableDictionary* channelsByIdentifier;
	L0KVODispatcher* dispatcher;
}

- (id) initWithPlatformInfo:(id <MvrPlatformInfo>) info modernPort:(int) port legacyPort:(int) legacyPort;

@property(retain) MvrModernWiFi* modernWiFi;
@property(retain) MvrLegacyWiFi* legacyWiFi;

@end
