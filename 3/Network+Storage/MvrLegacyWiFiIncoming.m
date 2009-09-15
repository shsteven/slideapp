//
//  MvrLegacyWiFiIncoming.m
//  Network+Storage
//
//  Created by ∞ on 15/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrLegacyWiFiIncoming.h"
#import "MvrLegacyWiFi.h" // has the BLIP additions to MvrItem.

@implementation MvrLegacyWiFiIncoming

- (id) initWithConnection:(BLIPConnection*) c;
{
	if (self = [super init]) {
		connection = [c retain];
		connection.delegate = self;
	}
	
	return self;
}

- (void) dealloc;
{
	[connection close];
	connection.delegate = nil;
	[connection release]; connection = nil;
	
	[super dealloc];
}

- (void) connection: (BLIPConnection*)connection receivedRequest: (BLIPRequest*)request;
{
	// we could get released soon!
	[[self retain] autorelease];
	
	MvrItem* item = [MvrItem itemWithContentsOfBLIPRequest:request];
	self.item = item;
	self.cancelled = (item == nil);
	
	[request respondWithString:@"OK"];	
}

@end
