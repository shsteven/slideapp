//
//  MvrModernWiFi.m
//  Network
//
//  Created by ∞ on 12/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrModernWiFi.h"


@implementation MvrModernWiFi

- (id) initWithBroadcastedName:(NSString*) name;
{
	self = [super init];
	if (self != nil) {
		[self addServiceWithName:name type:kMvrModernWiFiBonjourServiceType port:kMvrModernWiFiPort];
		[self addBrowserForServicesWithType:kMvrModernWiFiBonjourServiceType];
	}

	return self;
}

- (void) foundService:(NSNetService *)s;
{
	L0Log(@"%@", s);
}

- (void) lostService:(NSNetService *)s;
{
	L0Log(@"%@", s);	
}

@end
