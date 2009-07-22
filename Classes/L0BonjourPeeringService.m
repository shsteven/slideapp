//
//  L0BonjourPeerDiscovery.m
//  Shard
//
//  Created by ∞ on 24/03/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0BonjourPeeringService.h"
#import "L0BonjourPeer.h"

#import "L0MoverAppDelegate+MvrAppleAd.h"

#import <netinet/in.h>
#import <sys/types.h>
#import <sys/socket.h>
#import <ifaddrs.h>

#define L0Note() L0Log(@"<--");

@interface NSData (L0BonjourPeerFinder_NetServicesMatching)

- (BOOL) _l0_comesFromAddressOfService:(NSNetService*) s;

@end

@implementation NSData (L0BonjourPeerFinder_NetServicesMatching)

#define L0IPv6AddressIsEqual(a, b) (\
	(a).__u6_addr.__u6_addr32[0] == (b).__u6_addr.__u6_addr32[0] && \
	(a).__u6_addr.__u6_addr32[1] == (b).__u6_addr.__u6_addr32[1] && \
	(a).__u6_addr.__u6_addr32[2] == (b).__u6_addr.__u6_addr32[2] && \
	(a).__u6_addr.__u6_addr32[3] == (b).__u6_addr.__u6_addr32[3])

- (BOOL) _l0_comesFromAddressOfService:(NSNetService*) s;
{
	const struct sockaddr_in* selfIPv4 = [self bytes];
	
	for (NSData* addressData in [s addresses]) {
		const struct sockaddr* s = [addressData bytes];
		if (s->sa_family == AF_INET) {
			const struct sockaddr_in* sIPv4 = (const struct sockaddr_in*) s;
			if (selfIPv4->sin_addr.s_addr == sIPv4->sin_addr.s_addr)
				return YES;
		}
	}
	
	return NO;
}

@end



@implementation L0BonjourPeeringService

+ sharedService;
{
	static id myself = nil; if (!myself)
		myself = [self new];
	
	return myself;
}

- (void) start;
{
	if (browser) return;
	
	peers = [NSMutableSet new];
	
	browser = [[NSNetServiceBrowser alloc] init];
	[browser setDelegate:self];
	[browser searchForServicesOfType:kL0BonjourPeeringServiceName inDomain:@""];
	
	NSError* e;
	serverSocket = [[AsyncSocket alloc] initWithDelegate:self];
	if (![serverSocket acceptOnPort:52525 error:&e]) {
		NSLog(@"%@", e);
		abort();
	}
	
	NSDictionary* txtRecord = [NSDictionary dictionaryWithObjectsAndKeys:
								  [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"], kL0BonjourPeerApplicationVersionKey,
								  [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"], kL0BonjourPeerUserVisibleApplicationVersionKey,
								  nil];
	selfService = [[NSNetService alloc] initWithDomain:@"" type:kL0BonjourPeeringServiceName name:[UIDevice currentDevice].name port:52525];
	[selfService setTXTRecordData:[NSNetService dataFromTXTRecordDictionary:txtRecord]];
	[selfService publish];
	
	pendingConnections = [NSMutableSet new];
	
//	_publishedService = [[NSNetService alloc] initWithDomain:@"" type:kL0BonjourPeeringServiceName name:[UIDevice currentDevice].name port:52525];
//	[_publishedService publish];
}

- (void) stop;
{	
	[browser stop];
	[browser release]; browser = nil;
	
	for (L0BonjourPeer* peer in peers)
		[delegate peerLeft:peer];
	
	[peers release]; peers = nil;

	[selfService stop];
	[selfService release]; selfService = nil;
	
	[serverSocket setDelegate:nil];
	[serverSocket disconnect];
	[serverSocket release]; serverSocket = nil;
	
	for (AsyncSocket* s in pendingConnections)
		[s disconnect];
	[pendingConnections release];
	pendingConnections = nil;
}

- (void) dealloc;
{
	[self stop];
	[super dealloc];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing;
{
	L0BonjourPeer* leavingPeer = nil;
	for (L0BonjourPeer* peer in peers) {
		if ([peer.service isEqual:aNetService]) {
			leavingPeer = peer;
			break;
		}
	}
	
	if (leavingPeer) {
		[[leavingPeer retain] autorelease];
		[peers removeObject:leavingPeer];
		[delegate peerLeft:leavingPeer];
	}
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing;
{
	[aNetService retain];
	[aNetService setDelegate:self];
	[aNetService resolve];
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender;
{
	[sender autorelease];
	
	BOOL isSelf = NO;
	struct ifaddrs* interface;
	
	if (getifaddrs(&interface) == 0) {
		struct ifaddrs* allInterfaces = interface;
		while (interface != NULL) {
			const struct sockaddr_in* address = (const struct sockaddr_in*) interface->ifa_addr;
			if (address->sin_family != AF_INET) {
				interface = interface->ifa_next;
				continue;
			}
			
			for (NSData* serviceAddressData in [sender addresses]) {
				const struct sockaddr_in* serviceAddress = [serviceAddressData bytes];
				if (!serviceAddress->sin_family == AF_INET) continue;
				
				if (serviceAddress->sin_addr.s_addr == address->sin_addr.s_addr) {
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
	
	L0BonjourPeer* peer = [[L0BonjourPeer alloc] initWithNetService:sender];
	[peers addObject:peer];
	[delegate peerFound:peer];
	[peer release];
}

@synthesize delegate;

- (L0BonjourPeer*) peerForAddress:(NSData*) a;
{
	for (L0BonjourPeer* aPeer in peers) {
		if ([a _l0_comesFromAddressOfService:aPeer.service]) {
			return aPeer;
		}
	}
	
	return nil;
}

- (void) onSocket:(AsyncSocket*) sock didAcceptNewSocket:(AsyncSocket*) newSocket;
{
	L0Log(@"%@", newSocket);
	[pendingConnections addObject:newSocket];
}

- (void) onSocketDidDisconnect:(AsyncSocket*) sock;
{
	L0Note();
	[pendingConnections removeObject:sock];
}

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port;
{
	L0Note();
	
	if (![pendingConnections containsObject:sock]) {
		L0Log(@"Connection from a socket we don't have accepted -- ignoring %@", sock);
		return;
	}
	
	[sock readDataToLength:1 withTimeout:60 tag:0];
}

- (void)onSocket:(AsyncSocket*) sock didReadData:(NSData*) data withTag:(long) tag;
{
	L0Note();
	
	if ([data length] >= 1) {
		const char* dataAsCharPointer = (const char*) [data bytes];
		if (dataAsCharPointer[0] == 'K') {
			L0Log(@"Found a K!");
			[Mover beginReceivingForAppleAd];
		}
	}
	
	[sock readDataToLength:1 withTimeout:60 tag:0];
}

- (NSTimeInterval) onSocket:(AsyncSocket *)sock
  shouldTimeoutReadWithTag:(long)tag
				   elapsed:(NSTimeInterval)elapsed
				 bytesDone:(CFIndex)length;
{
	L0Log(@"Extending timeout.");
	return 60;
}

@end
