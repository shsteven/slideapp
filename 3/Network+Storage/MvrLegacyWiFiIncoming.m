//
//  MvrLegacyWiFiIncoming.m
//  Network+Storage
//
//  Created by ∞ on 15/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrLegacyWiFiIncoming.h"
#import "MvrLegacyWiFi.h" // has the BLIP additions to MvrItem.

@interface MvrLegacyWiFiIncoming ()
- (void) endWithItem:(MvrItem*) i;
@end


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
	[self endWithItem:nil];
	[super dealloc];
}

- (void) connection: (BLIPConnection*)connection receivedRequest: (BLIPRequest*)request;
{
	// we could get released soon!
	[self endWithItem:[MvrItem itemWithContentsOfBLIPRequest:request]];
	[request respondWithString:@"OK"];
}

- (void) connectionDidClose: (TCPConnection*)connection;
{
	[self endWithItem:nil];
}

- (void) endWithItem:(MvrItem*) i;
{
	if (!didEnd) {
		[[self retain] autorelease];
		self.item = i;
		self.cancelled = (i == nil);

		[connection close];
		connection.delegate = nil;
		[connection release]; connection = nil;
		
		didEnd = YES;
	}
}

@end
