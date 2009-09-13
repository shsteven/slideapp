//
//  MvrModernWiFi.m
//  Network
//
//  Created by ∞ on 12/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrModernWiFi.h"

#import "MvrModernWiFiChannel.h"
#import "AsyncSocket.h"

@implementation MvrModernWiFi

- (id) initWithBroadcastedName:(NSString*) name;
{
	self = [super init];
	if (self != nil) {
		[self addServiceWithName:name type:kMvrModernWiFiBonjourServiceType port:kMvrModernWiFiPort TXTRecord:[NSDictionary dictionary] /* TODO */];
		[self addBrowserForServicesWithType:kMvrModernWiFiBonjourServiceType];
	}

	return self;
}

- (void) start;
{
	[super start];	
	serverSocket = [[AsyncSocket alloc] initWithDelegate:self];
}

- (void) stop;
{
	[serverSocket disconnect];
	[serverSocket release]; serverSocket = nil;
	[super stop];
}

- (void) foundService:(NSNetService *)s;
{
	L0Log(@"%@", s);
	
	MvrModernWiFiChannel* chan = [[MvrModernWiFiChannel alloc] initWithNetService:s];
	[self addChannelsObject:chan];
	[chan release];
}

- (void) lostService:(NSNetService *)s;
{
	L0Log(@"%@", s);
	
	for (MvrModernWiFiChannel* chan in [[channels copy] autorelease]) {
		if ([chan hasSameServiceAs:s])
			[self removeChannelsObject:chan];
	}
}

#pragma mark -
#pragma mark Server sockets

- (void) onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket;
{
	// TODO
}

@end
