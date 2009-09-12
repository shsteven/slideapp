//
//  MvrWiFiScanner.m
//  Network
//
//  Created by ∞ on 12/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrWiFiScanner.h"

#import <sys/socket.h>
#import <sys/types.h>
#import <netinet/in.h>
#import <ifaddrs.h>

@implementation MvrWiFiScanner

- (id) init;
{
	if (self = [super init]) {
		netServices = [NSMutableSet new];
		soughtServices = [NSMutableSet new];
		
		browsers = [L0Map new];
		servicesBeingResolved = [NSMutableSet new];
	}
	
	return self;
}

- (void) addServiceWithName:(NSString*) name type:(NSString*) type port:(int) port;
{
	NSAssert(!enabled, @"Can't change published services without disabling");
	
	NSNetService* service = [[[NSNetService alloc] initWithDomain:@"" type:type name:name port:port] autorelease];
	
	service.delegate = self;
	[netServices addObject:service];
}

- (void) addBrowserForServicesWithType:(NSString*) type;
{
	[soughtServices addObject:type];
}

@synthesize enabled;
- (void) setEnabled:(BOOL) e;
{
	BOOL wasEnabled = enabled;
	
	if (!wasEnabled && e)
		[self start];
	else if (wasEnabled && !e)
		[self stop];
	
	enabled = e;
}

- (void) start;
{
	if (enabled)
		return;
	
	for (NSNetService* n in netServices)
		[n publish];
	
	for (NSString* type in soughtServices) {
		NSNetServiceBrowser* browser = [[NSNetServiceBrowser new] autorelease];
		browser.delegate = self;
		[browser searchForServicesOfType:type inDomain:@""];
		[browsers setObject:type forKey:browser];
	}
}

- (void) stop;
{
	if (!enabled)
		return;
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	
	for (NSNetService* n in netServices)
		[n stop];
	
	for (NSNetService* s in servicesBeingResolved)
		[s stop];
	
	[servicesBeingResolved release];
	
	for (NSNetServiceBrowser* browser in [browsers allKeys])
		[browser stop];
	[browsers removeAllObjects];
}

- (void) dealloc;
{
	[self stop];
	
	[soughtServices release];
	
	for (NSNetService* s in netServices)
		s.delegate = nil;
	
	[netServices release];
	
	for (NSNetServiceBrowser* s in [browsers allKeys])
		s.delegate = nil;

	[browsers release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Searching

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing;
{
	[servicesBeingResolved addObject:aNetService];
	aNetService.delegate = self;
	[aNetService resolve];
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender;
{
	L0Log(@"For service %@:", sender);
	for (NSData* d in [sender addresses])
		L0Log(@"Found address: %@", [d socketAddressStringValue]);
	
	BOOL isSelf = NO;
	
	struct ifaddrs* interface;
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
					break;
				}
			}
			
			if (isSelf) break;
			interface = interface->ifa_next;
		}
		
		freeifaddrs(allInterfaces);
	}

	if (!isSelf)
		[self foundService:sender];

	[servicesBeingResolved removeObject:sender];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing;
{
	[self lostService:aNetService];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didNotSearch:(NSDictionary *)errorDict;
{
	L0Log(@"An error happened while trying to search, will auto-retry: %@", errorDict);
	[self performSelector:@selector(restartBrowser:) withObject:aNetServiceBrowser afterDelay:2.0];
}

- (void) restartBrowser:(NSNetServiceBrowser*) browser;
{
	NSString* type = [browsers objectForKey:browser];
	if (type)
		[browser searchForServicesOfType:type inDomain:@""];
}

- (void) foundService:(NSNetService*) s;
{
	L0AbstractMethod();
}

- (void) lostService:(NSNetService*) s;
{
	L0AbstractMethod();
}


#pragma mark -
#pragma mark Publishing



@end
