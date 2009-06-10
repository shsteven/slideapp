//
//  L0MoverDummyScanner.m
//  Mover
//
//  Created by ∞ on 10/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0MoverWiFiScanner.h"

#import "BLIP.h"
#import "IPAddress.h"
#import <netinet/in.h>
#import <sys/types.h>
#import <sys/socket.h>
#import <ifaddrs.h>

#define kL0BonjourPeerApplicationVersionKey @"L0AppVersion"
#define kL0BonjourPeerUserVisibleApplicationVersionKey @"L0UserAppVersion"
#define kL0BonjourPeerUniqueIdentifier @"L0PeerID"

#define kL0BonjourPeeringServiceName @"_x-infinitelabs-slides._tcp."

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

@implementation L0MoverWiFiScanner

L0ObjCSingletonMethod(sharedScanner)

- (id) init;
{
	if (self = [super init]) {
		browser = [[NSNetServiceBrowser alloc] init];
		[browser setDelegate:self];
		[browser searchForServicesOfType:kL0BonjourPeeringServiceName inDomain:@""];
		
		listener = [[BLIPListener alloc] initWithPort:52525];
		listener.delegate = self;
		listener.pickAvailablePort = YES;
		listener.bonjourServiceType = kL0BonjourPeeringServiceName;
		listener.bonjourServiceName = [UIDevice currentDevice].name;
		listener.bonjourTXTRecord = [NSDictionary dictionaryWithObjectsAndKeys:
									 [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"], kL0BonjourPeerApplicationVersionKey,
									 [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"], kL0BonjourPeerUserVisibleApplicationVersionKey,
									 [[L0MoverPeering sharedService] uniquePeerIdentifierForSelf], 
									 nil];
		NSError* e = nil;
		[listener open:&e];
	}
	
	return self;
}

@end
