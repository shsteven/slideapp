//
//  MvrWiFi.m
//  Network
//
//  Created by ∞ on 12/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrWiFi.h"

#import "MvrModernWiFi.h"
#import "MvrLegacyWiFi.h"

@implementation MvrWiFi

- (id) initWithPlatformInfo:(id <MvrPlatformInfo>) info modernPort:(int) modernPort legacyPort:(int) legacyPort;
{
	self = [super init];
	if (self != nil) {
		self.modernWiFi = [[[MvrModernWiFi alloc] initWithPlatformInfo:info serverPort:modernPort] autorelease];
		self.legacyWiFi = [[[MvrLegacyWiFi alloc] initWithPlatformInfo:info serverPort:legacyPort] autorelease];
	}
	return self;
}


@synthesize modernWiFi, legacyWiFi;

- (void) dealloc;
{
	self.modernWiFi = nil;
	self.legacyWiFi = nil;
	[super dealloc];
}

@end
