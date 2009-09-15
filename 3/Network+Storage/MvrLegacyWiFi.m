//
//  MvrLegacyScanner.m
//  Network+Storage
//
//  Created by ∞ on 14/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrLegacyWiFi.h"

#import "BLIP.h"
#import "IPAddress.h"

#import <netinet/in.h>
#import <sys/types.h>
#import <sys/socket.h>
#import <ifaddrs.h>

#import <MuiKit/MuiKit.h>

#import "MvrProtocol.h"

#pragma mark -
#pragma mark IPAddress additions

@interface IPAddress (L0BonjourPeerFinder_NetServicesMatching)
- (BOOL) _l0_comesFromAddressOfService:(NSNetService*) s;
@end

@implementation IPAddress (L0BonjourPeerFinder_NetServicesMatching)

#define L0IPv6AddressIsEqual(a, b) (\
(a).__u6_addr.__u6_addr32[0] == (b).__u6_addr.__u6_addr32[0] && \
(a).__u6_addr.__u6_addr32[1] == (b).__u6_addr.__u6_addr32[1] && \
(a).__u6_addr.__u6_addr32[2] == (b).__u6_addr.__u6_addr32[2] && \
(a).__u6_addr.__u6_addr32[3] == (b).__u6_addr.__u6_addr32[3])

- (BOOL) _l0_comesFromAddressOfService:(NSNetService*) s;
{
	for (NSData* addressData in [s addresses]) {
		const struct sockaddr* s = [addressData bytes];
		if (s->sa_family == AF_INET) {
			const struct sockaddr_in* sIPv4 = (const struct sockaddr_in*) s;
			if (self.ipv4 == sIPv4->sin_addr.s_addr)
				return YES;
		} /* else if (s->sa_family == AF_INET6) {
		   const struct sockaddr_in6* sIPv6 = (const struct sockaddr_in6*) s;
		   if (L0IPv6AddressIsEqual(self.ipv6, sIPv6->sin6_addr))
		   return YES;
		   } */
	}
	
	return NO;
}

@end

#pragma mark -
#pragma mark Legacy Wi-Fi Scanner.


@implementation MvrLegacyWiFi

- (id) initWithPlatformInfo:(id <MvrPlatformInfo>) info;
{
	if (self = [super init]) {
		NSString* name = [info displayNameForSelf];
		
		NSDictionary* txtRecord = [NSDictionary dictionaryWithObjectsAndKeys:
								   [NSString stringWithFormat:@"%f", [info version]], kMvrLegacyWiFiApplicationVersionKey,
								   [info userVisibleVersion], kMvrLegacyWiFiUserVisibleApplicationVersionKey,
								   [[info identifierForSelf] stringValue], kMvrLegacyWiFiUniqueIdentifierKey,
								   nil];
		
		[self addServiceWithName:name type:kMvrLegacyWiFiServiceName_1_0 port:kMvrLegacyWiFiPort TXTRecord:txtRecord];
		[self addServiceWithName:name type:kMvrLegacyWiFiServiceName_2_0 port:kMvrLegacyWiFiPort TXTRecord:txtRecord];
		
		[self addBrowserForServicesWithType:kMvrLegacyWiFiServiceName_1_0];
		[self addBrowserForServicesWithType:kMvrLegacyWiFiServiceName_2_0];
	}
	
	return self;
}

- (void) start;
{
	[super start];
	
	listener = [[BLIPListener alloc] initWithPort:kMvrLegacyWiFiPort];
	listener.delegate = self;
	
	NSError* e;
	if (![listener open:&e])
		return; // TODO!!!
}

- (void) stop;
{
	[listener close];
	[listener release]; listener = nil;
	
	[super stop];
}

@end
