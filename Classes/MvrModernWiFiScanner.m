//
//  MvrModernWiFiScanner.m
//  Mover
//
//  Created by ∞ on 25/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrModernWiFiScanner.h"
#import "MvrWiFiIncomingTransfer.h"
#import "MvrWiFiChannel.h"

#import <sys/socket.h>
#import <sys/types.h>
#import <netinet/in.h>
#import <ifaddrs.h>

@interface MvrModernWiFiScanner ()

- (void) start;
- (void) stop;

@end


@implementation MvrModernWiFiScanner

L0ObjCSingletonMethod(sharedScanner)

- (id) init;
{
	if (self = [super init])
		availableChannels = [NSMutableSet new];
	
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

	servicesBeingResolved = [NSMutableSet new];
	
	browser = [[NSNetServiceBrowser alloc] init];
	[browser setDelegate:self];
	[browser searchForServicesOfType:kMvrModernBonjourServiceName inDomain:@"local."];
	
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
	
	[browser setDelegate:nil];
	[browser stop];
	[browser release]; browser = nil;
	
	[transfers release]; transfers = nil;
	
	for (NSNetService* s in servicesBeingResolved) {
		[s setDelegate:nil];
		[s stop];
	}
	
	[servicesBeingResolved release];
}

- (void) dealloc;
{
	[self stop];
	[availableChannels release];
	[super dealloc];
}

- (BOOL) jammed;
{
	return NO; // TODO
}

#pragma mark -
#pragma mark Service browsing.

- (void) netServiceBrowser:(NSNetServiceBrowser*) aNetServiceBrowser didFindService:(NSNetService*) aNetService moreComing:(BOOL) moreComing;
{
	[aNetService setDelegate:self];
	[aNetService resolve];
	[servicesBeingResolved addObject:aNetService];
}

- (void) netServiceDidResolveAddress:(NSNetService*) sender;
{
	[sender autorelease];
	
	L0Log(@"For service %@:", sender);
	for (NSData* d in [sender addresses])
		L0Log(@"Found address: %@", [d socketAddressStringValue]);
	
	BOOL isSelf = NO;
	struct ifaddrs* interface;
	
	if (getifaddrs(&interface) == 0) {
		struct ifaddrs* allInterfaces = interface;
		while (interface != NULL) {
			const struct sockaddr_in* address = (const struct sockaddr_in*) interface->ifa_addr;
			
			NSData* addressData = [NSData dataWithBytesNoCopy:&address length:address->sin_len freeWhenDone:NO];
			
			for (NSData* senderAddress in [sender addresses]) {
				if ([senderAddress socketAddressIsEqualToAddress:addressData]) {
					isSelf = YES;
					break;
				}
			}
			
			if (isSelf) break;
			interface = interface->ifa_next;
		}
		
		freeifaddrs(allInterfaces);
	}
	
	if (isSelf) return;
	
	MvrWiFiChannel* channel = [[MvrWiFiChannel alloc] initWithNetService:sender];
	[[self mutableSetValueForKey:@"availableChannels"] addObject:channel];
	[channel release];
}

- (MvrWiFiChannel*) channelForAddress:(NSData*) a;
{
	for (MvrWiFiChannel* aPeer in availableChannels) {
		for (NSData* peerAddress in [aPeer.service addresses]) {
			if ([a socketAddressIsEqualToAddress:peerAddress])
				return aPeer;
		}
	}
	
	return nil;
}

#pragma mark -
#pragma mark Socket delegate methods.

- (void) onSocket:(AsyncSocket*) sock didAcceptNewSocket:(AsyncSocket*) newSocket;
{
	MvrWiFiChannel* channel = [self channelForAddress:[newSocket connectedHostAddress]];
	if (!channel) {
		[newSocket disconnect];
		return;
	}
	
	MvrWiFiIncomingTransfer* transfer = [[MvrWiFiIncomingTransfer alloc] initWithSocket:newSocket channel:channel];
	[transfers addObject:transfer];
	[transfer release];
}

@end
