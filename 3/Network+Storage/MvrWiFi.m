//
//  MvrWiFi.m
//  Network
//
//  Created by ∞ on 12/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrWiFi.h"
#import "MvrModernWiFi.h"

@implementation MvrWiFi

- (id) initWithPlatformInfo:(id <MvrPlatformInfo>) info;
{
	self = [super init];
	if (self != nil) {
		self.modernWiFi = [[[MvrModernWiFi alloc] initWithPlatformInfo:info] autorelease];
	}
	return self;
}


@synthesize modernWiFi;

- (void) dealloc;
{
	self.modernWiFi = nil;
	[super dealloc];
}

@end
