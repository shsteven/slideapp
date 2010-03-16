//
//  MvrModernWiFiChannel.h
//  Network
//
//  Created by ∞ on 12/09/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <Foundation/Foundation.h>
#import <stdint.h>

#import "MvrWiFiChannel.h"


#define kMvrModernWiFiBonjourCapabilitiesKey @"MvrCaps"

enum {
	kMvrCapabilityExtendedMetadata = 1 << 0,
	
	kMvrCapabilityMaximum = UINT32_MAX,
};
typedef unsigned long long MvrCapabilities;



@interface MvrModernWiFiChannel : MvrWiFiChannel {
	BOOL supportsExtendedMetadata;
}

@property(readonly) BOOL supportsExtendedMetadata;

@end
