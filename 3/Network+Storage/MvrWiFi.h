//
//  MvrWiFi.h
//  Network
//
//  Created by ∞ on 12/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MvrModernWiFi.h"
#import "MvrPlatformInfo.h"

@interface MvrWiFi : NSObject {
	MvrModernWiFi* modernWiFi;
}

- (id) initWithPlatformInfo:(id <MvrPlatformInfo>) info;

@property(retain) MvrModernWiFi* modernWiFi;

@end
