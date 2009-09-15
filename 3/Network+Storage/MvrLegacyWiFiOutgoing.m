//
//  MvrLegacyWiFiOutgoing.m
//  Network+Storage
//
//  Created by ∞ on 15/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrLegacyWiFiOutgoing.h"

#import "MvrLegacyWiFi.h"

@interface MvrLegacyWiFiOutgoing ()

- (void) finish;

@property BOOL finished;

@end


@implementation MvrLegacyWiFiOutgoing

- (id) initWithItem:(MvrItem*) i toNetService:(NSNetService*) s;
{
	self = [super init];
	if (self != nil) {
		item = [i retain];
		service = [s retain];
	}
	return self;
}

@synthesize finished;

- (void) dealloc
{
	[self finish];
	[super dealloc];
}

#pragma mark -
#pragma mark Sending.

- (void) start;
{
	connection = [[BLIPConnection alloc] initToNetService:service];
	connection.delegate = self;
}

- (void) finish;
{
	[connection closeWithTimeout:5.0];
	connection.delegate = nil;
	[connection release]; connection = nil;
	
	[item release]; item = nil;
	[service release]; service = nil;
	
	self.finished = YES;
}

- (void) connectionDidOpen: (TCPConnection*)c;
{
	[connection sendRequest:[item contentsAsBLIPRequest]];
}

- (void) connection: (BLIPConnection*)connection receivedResponse: (BLIPResponse*)response;
{
	[self finish];
}

- (BOOL) connectionReceivedCloseRequest: (BLIPConnection*)connection;
{
	[self finish];
	return YES;
}

@end
