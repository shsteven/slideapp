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

- (MvrWiFiChannel*) channelForService:(NSNetService *)s;

@property(assign) BOOL jammed;

- (void) restartSearching;

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
	if (self.jammed) return;
	
	NSError* e = nil;
	
	NSAssert(service, @"Need the exchange service set before running!");
	
	NSAssert(!servicesBeingResolved, @"Services being resolved should be nil");
	servicesBeingResolved = [NSMutableSet new];

	NSAssert(!transfers, @"Transfers should be nil");
	transfers = [NSMutableSet new];

	
	NSAssert(!server, @"Server should be nil");
	server = [[AsyncSocket alloc] initWithDelegate:self];
	BOOL serverStarted = [server acceptOnPort:25252 error:&e];
	NSString* assertion = serverStarted? nil : [NSString stringWithFormat:@"Could not start the server due to error %@", e];
	NSAssert(serverStarted, assertion);
	
	
	NSAssert(!netService, @"Service should be nil");
	netService = [[NSNetService alloc] initWithDomain:@"local." type:kMvrModernBonjourServiceName name:[UIDevice currentDevice].name port:25252];
	[netService setDelegate:self];

	NSDictionary* txtDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								   [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"], kMvrWiFiChannelApplicationVersionKey,
								   [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"], kMvrWiFiChannelUserVisibleApplicationVersionKey,
								   [service uniquePeerIdentifierForSelf], kMvrWiFiChannelUniqueIdentifierKey,
								   nil];
	[netService setTXTRecordData:[NSNetService dataFromTXTRecordDictionary:txtDictionary]];
	
	[netService publish];
			
	NSAssert(!browser, @"Browser should be nil");
	browser = [[NSNetServiceBrowser alloc] init];
	[browser setDelegate:self];
	[self restartSearching];
	
	[self startMonitoringReachability];
}

- (void) stop;
{
	if (!enabled) return;
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(restartSearching) object:nil];
	
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
	
	[servicesBeingResolved release]; servicesBeingResolved = nil;
	
	[self stopMonitoringReachability];
	
	[selfWarmer disconnect];
	[selfWarmer release]; selfWarmer = nil;
	
	[[self mutableSetValueForKey:@"availableChannels"] removeAllObjects];
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

- (void) restartSearching;
{
	L0Note();
	[browser searchForServicesOfType:kMvrModernBonjourServiceName inDomain:@""];
}

- (void) netServiceBrowser:(NSNetServiceBrowser*) aNetServiceBrowser didNotSearch:(NSDictionary*) errorDict;
{
	L0Log(@"%@", errorDict);
	
	if ([[errorDict objectForKey:NSNetServicesErrorCode] integerValue] != NSNetServicesActivityInProgress)
		[self performSelector:@selector(restartSearching) withObject:nil afterDelay:7.0];
}

- (void) netServiceBrowserDidStopSearch:(NSNetServiceBrowser*) aNetServiceBrowser;
{
	L0Note();
	[self restartSearching];
}

- (void) netServiceBrowser:(NSNetServiceBrowser*) aNetServiceBrowser didFindService:(NSNetService*) aNetService moreComing:(BOOL) moreComing;
{
	[aNetService setDelegate:self];
	[servicesBeingResolved addObject:aNetService];
	[aNetService resolve];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing;
{
	MvrWiFiChannel* channel = [self channelForService:aNetService];
	L0Log(@"%@ => %@", aNetService, channel);
	if (channel)
		[[self mutableSetValueForKey:@"availableChannels"] removeObject:channel];
}

- (void) netServiceDidResolveAddress:(NSNetService*) sender;
{
	[[sender retain] autorelease];
	[servicesBeingResolved removeObject:sender];
	
	L0Log(@"For service %@:", sender);
	for (NSData* d in [sender addresses])
		L0Log(@"Found address: %@", [d socketAddressStringValue]);
	
	BOOL isSelf = NO;
	struct ifaddrs* interface;
	struct sockaddr_in selfAddress;
	
	if (getifaddrs(&interface) == 0) {
		struct ifaddrs* allInterfaces = interface;
		while (interface != NULL) {
			const struct sockaddr_in* address = (const struct sockaddr_in*) interface->ifa_addr;
			
			for (NSData* senderAddressData in [sender addresses]) {
				const struct sockaddr* senderAddress = (const struct sockaddr*) [senderAddressData bytes];
				if (senderAddress->sa_family != AF_INET)
					continue;
				
				const struct sockaddr_in* senderIPAddress = (const struct sockaddr_in*) senderAddress;
				if (address->sin_addr.s_addr == senderIPAddress->sin_addr.s_addr) {
					isSelf = YES;
					selfAddress = *address;
					break;
				}
			}
			
			if (isSelf) break;
			interface = interface->ifa_next;
		}
		
		freeifaddrs(allInterfaces);
	}
	
	if (isSelf && !selfWarmer) {
		selfAddress.sin_port = 65525; // a port we hope isn't used.
		selfWarmer = [[AsyncSocket alloc] initWithDelegate:self];
		[selfWarmer connectToAddress:[NSData dataWithBytes:&selfAddress length:selfAddress.sin_len] error:NULL];
		return;
	}
	
	MvrWiFiChannel* channel = [[MvrWiFiChannel alloc] initWithNetService:sender];
	[[self mutableSetValueForKey:@"availableChannels"] addObject:channel];
	[channel release];
}

- (void) onSocketDidDisconnect:(AsyncSocket *)sock;
{
	[selfWarmer release]; selfWarmer = nil;
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict;
{
	L0Log(@"Service %@ (named %@) failed to resolve for some reason. Boo!", sender, [sender name]);
	[servicesBeingResolved removeObject:sender];
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

- (MvrWiFiChannel*) channelForService:(NSNetService*) s;
{
	for (MvrWiFiChannel* aPeer in availableChannels) {
		if ([s.name isEqual:aPeer.service.name] && [s.type isEqual:aPeer.service.type])
			return aPeer;
	}
	
	return nil;
}

#pragma mark -
#pragma mark Socket delegate methods.

- (void) onSocket:(AsyncSocket*) sock didAcceptNewSocket:(AsyncSocket*) newSocket;
{
	MvrWiFiIncomingTransfer* transfer = [[MvrWiFiIncomingTransfer alloc] initWithSocket:newSocket scanner:self];
	[transfers addObject:transfer];
	[transfer release];
}

#pragma mark -
#pragma mark Jamming

@synthesize jammed;

- (void) setJammed:(BOOL) j;
{
	jammed = j;
	
	if (jammed && enabled)
		[self stop];
	else if (!jammed && enabled)
		[self start];
}

@end
