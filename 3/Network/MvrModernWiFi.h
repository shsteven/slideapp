//
//  MvrModernWiFi.h
//  Network
//
//  Created by ∞ on 12/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MvrWiFiScanner.h"

#define kMvrModernWiFiBonjourServiceType @"_x-mover2._tcp."
#define kMvrModernWiFiPort (25252)

@class AsyncSocket;

@interface MvrModernWiFi : MvrWiFiScanner {
	AsyncSocket* serverSocket;
}

@end
