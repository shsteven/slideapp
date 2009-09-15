//
//  MvrLegacyScanner.h
//  Network+Storage
//
//  Created by ∞ on 14/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MvrWiFiScanner.h"
#import "MvrPlatformInfo.h"

#import "BLIP.h"

#define kMvrLegacyWiFiApplicationVersionKey @"L0AppVersion"
#define kMvrLegacyWiFiUserVisibleApplicationVersionKey @"L0UserAppVersion"
#define kMvrLegacyWiFiUniqueIdentifierKey @"L0PeerID"

#define kMvrLegacyWiFiServiceName_1_0 @"_x-infinitelabs-slides._tcp."
#define kMvrLegacyWiFiServiceName_2_0 @"_x-mover._tcp."

#define kMvrLegacyWiFiPort (52525)

@interface MvrLegacyWiFi : MvrWiFiScanner <TCPListenerDelegate> {
	BLIPListener* listener;
}

- (id) initWithPlatformInfo:(id <MvrPlatformInfo>) info;

@end

#pragma mark -
#pragma mark BLIP additions to MvrItem.

#import "MvrItem.h"

@interface MvrItem (MvrLegacyWiFi)

- (BLIPRequest*) contentsAsBLIPRequest;
+ (id) itemWithContentsOfBLIPRequest:(BLIPRequest*) req;

@end
