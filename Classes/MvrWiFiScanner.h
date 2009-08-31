//
//  MvrWiFiScanner.h
//  Mover
//
//  Created by ∞ on 30/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "MvrNetworkExchange.h"


@interface MvrWiFiScanner : NSObject {
	SCNetworkReachabilityRef reach;
}

- (void) startMonitoringReachability;
- (void) stopMonitoringReachability;
- (void) checkReachability;

@end
