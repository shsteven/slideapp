//
//  MvrModernWiFiScanner.m
//  Mover
//
//  Created by ∞ on 25/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrModernWiFiScanner.h"
#import "MvrWiFiIncomingTransfer.h"

@interface MvrModernWiFiScanner ()

- (void) start;
- (void) stop;

@end


@implementation MvrModernWiFiScanner

L0ObjCSingletonMethod(sharedScanner)

- (id) init;
{
	if (self = [super init]) {
		availableChannels = [NSMutableSet new];
	}
	
	return self;
}

@synthesize availableChannels, service, transfers;

@synthesize enabled;
- (void) setEnabled:(BOOL) e;
{
	BOOL wasEnabled = enabled;
	
	if (e && !wasEnabled)
		[self start];
	else if (!e && wasEnabled)
		[self stop];

	enabled = e;
}

- (void) start;
{
	if (enabled) return;
	NSError* e = nil;
	
	server = [[AsyncSocket alloc] initWithDelegate:self];
	BOOL serverStarted = [server acceptOnPort:25252 error:&e];
	NSString* assertion = serverStarted? nil : [NSString stringWithFormat:@"Could not start the server due to error %@", e];
	NSAssert(serverStarted, assertion);
	
	NSAssert(!netService, @"Service should be nil");
	netService = [[NSNetService alloc] initWithDomain:@"local." type:kMvrModernBonjourServiceName name:[UIDevice currentDevice].name port:25252];
	[netService setDelegate:self];
	[netService publish];
	
	transfers = [NSMutableSet new];
}

- (void) stop;
{
	if (!enabled) return;
	
	[netService setDelegate:nil];
	[netService stop];
	[netService release]; netService = nil;

	[server disconnect];
	[server release]; server = nil;
		
	[transfers release]; transfers = nil;
}

- (void) dealloc;
{
	[self stop];
	[availableChannels release];
	[super dealloc];
}

- (BOOL) jammed;
{
	return NO;
}

#pragma mark -
#pragma mark Socket delegate methods.

- (void) onSocket:(AsyncSocket*) sock didAcceptNewSocket:(AsyncSocket*) newSocket;
{
	MvrWiFiIncomingTransfer* transfer = [[MvrWiFiIncomingTransfer alloc] initWithSocket:newSocket];
	[transfers addObject:transfer];
	[transfer release];
}

@end
