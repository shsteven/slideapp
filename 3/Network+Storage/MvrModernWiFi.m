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
#import "MvrModernWiFiIncoming.h"

#import <MuiKit/MuiKit.h>

@implementation MvrModernWiFi

- (id) initWithBroadcastedName:(NSString*) name;
{
	self = [super init];
	if (self != nil) {
		[self addServiceWithName:name type:kMvrModernWiFiBonjourServiceType port:kMvrModernWiFiPort TXTRecord:[NSDictionary dictionary] /* TODO */];
		[self addBrowserForServicesWithType:kMvrModernWiFiBonjourServiceType];
		
		incomingTransfers = [NSMutableSet new];
		dispatcher = [[L0KVODispatcher alloc] initWithTarget:self];
		
		serverPort = kMvrModernWiFiPort;
 	}

	return self;
}

@synthesize serverPort;
- (void) setServerPort:(int) port;
{
	NSAssert(!self.enabled, @"Can only change port when the server is stopped");
	serverPort = port;
}

- (void) start;
{
	[super start];	
	serverSocket = [[AsyncSocket alloc] initWithDelegate:self];
	
	NSError* e;
	if (![serverSocket acceptOnPort:serverPort error:&e]) {
		[NSException raise:@"MvrModernWiFiServerException" format:@"Could not listen on the given port (%d). Error: %@", serverPort, e];
	}
}

- (void) stop;
{
	[serverSocket disconnect];
	[serverSocket release]; serverSocket = nil;
	[super stop];
}

- (void) dealloc
{
	[dispatcher release];
	[incomingTransfers release];
	[super dealloc];
}


#pragma mark -
#pragma mark Channel management

- (MvrModernWiFiChannel*) channelForAddress:(NSData*) address;
{
	for (MvrModernWiFiChannel* chan in [[channels copy] autorelease]) {
		if ([chan isReachableThroughAddress:address])
			return chan;
	}
	
	return nil;
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
	MvrModernWiFiIncoming* incoming = [[MvrModernWiFiIncoming alloc] initWithSocket:newSocket scanner:self];
	[incomingTransfers addObject:incoming];
	
	[incoming observeUsingDispatcher:dispatcher invokeAtItemChange:@selector(itemOrCancelledOfTransfer:changed:) atCancelledChange:@selector(itemOrCancelledOfTransfer:changed:)];
	
	[incoming release];
}

- (void) itemOrCancelledOfTransfer:(MvrModernWiFiIncoming*) transfer changed:(NSDictionary*) changed;
{
	if (transfer.item || transfer.cancelled) {
		[transfer endObservingUsingDispatcher:dispatcher];
		[incomingTransfers removeObject:transfer];
	}
}

@end
