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

#import "L0MoverWiFiChannel.h"

#import <netinet/in.h>
#import <sys/types.h>
#import <sys/socket.h>
#import <ifaddrs.h>

#import <MuiKit/MuiKit.h>

#import "MvrProtocol.h"

#pragma mark -
#pragma mark Transfer marker.

@interface MvrLegacyWiFiIncomingTransfer : NSObject <MvrIncoming>
{
	L0MoverItem* item;
	BOOL cancelled;
}

- (void) setItem:(L0MoverItem*) i;
- (void) setCancelled:(BOOL) cancelled;

@end

@implementation MvrLegacyWiFiIncomingTransfer

@synthesize item;
- (void) setItem:(L0MoverItem*) i;
{
	if (i != item) {
		[item release];
		item = [i retain];
	}
}

@synthesize cancelled;
- (void) setCancelled:(BOOL) c;
{
	cancelled = c;
}

- (CGFloat) progress { return kMvrPacketIndeterminateProgress; }

- (void) dealloc;
{
	[item release];
	[super dealloc];
}

@end

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

// --------------------------
#pragma mark -
#pragma mark Wi-Fi Scanner

@interface L0MoverWiFiScanner ()

- (void) addAvailableChannelsObject:(L0MoverWiFiChannel*) chan;
- (void) removeAvailableChannelsObject:(L0MoverWiFiChannel*) chan;

- (BOOL) start;
- (void) stop;

- (void) beginMonitoringReachability;
- (void) stopMonitoringReachability;
- (void) updateNetworkWithFlags:(SCNetworkReachabilityFlags) flags;

- (void) publishServices;
- (void) publishServicesWithName:(NSString*) serviceName;
- (void) stopPublishingServices;
- (void) startBrowsing;
- (void) stopBrowsing;

@end


@implementation L0MoverWiFiScanner

L0ObjCSingletonMethod(sharedScanner)

- (id) init;
{
	if (self = [super init]) {
		availableChannels = [NSMutableSet new];
		
		dispatcher = [[L0KVODispatcher alloc] initWithTarget:self];
		[dispatcher observe:@"jammed" ofObject:self usingSelector:@selector(jammedChangedForSelf:change:) options:0];
		
		servicesBeingDisabled = [NSMutableSet new];
	}
	
	return self;
}

- (BOOL) start;
{
	if (listener) return YES;
	
	[self willChangeValueForKey:@"enabled"];
	
	listener = [[BLIPListener alloc] initWithPort:52525];
	listener.delegate = self;
	listener.pickAvailablePort = YES;

	NSError* e = nil;
	[listener open:&e];
	if (e) {
		L0LogAlways(@"Disabling Wi-Fi peering -- got an error while opening a socket on port 52525: %@", e);
		
		[self stop];
		[self didChangeValueForKey:@"enabled"];
		return NO;
	}
	
	[self startBrowsing];
	[self publishServices];
	
	[self beginMonitoringReachability];
	
	// Set up browser resetting
//	NSAssert(!browserResetTimer, @"A browser reset timer is already present");
//	browserResetTimer = [[NSTimer scheduledTimerWithTimeInterval:120.0 target:self selector:@selector(resetBrowsing:) userInfo:nil repeats:YES] retain];

	connectionsToTransfers = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	
	[self didChangeValueForKey:@"enabled"];
	return YES;
}

- (void) startBrowsing;
{
	L0Note();
	[self stopBrowsing];
	
	legacyBrowser = [[NSNetServiceBrowser alloc] init];
	[legacyBrowser setDelegate:self];
	[legacyBrowser searchForServicesOfType:kL0BonjourPeeringServiceName inDomain:@"local."];

	modernBrowser = [[NSNetServiceBrowser alloc] init];
	[modernBrowser setDelegate:self];
	[modernBrowser searchForServicesOfType:kMvrStandardServiceName inDomain:@"local."];	
}

- (void) stopBrowsing;
{
	L0Note();
	legacyBrowser.delegate = nil;
	[legacyBrowser stop];
	[legacyBrowser autorelease]; legacyBrowser = nil;

	modernBrowser.delegate = nil;
	[modernBrowser stop];
	[modernBrowser autorelease]; modernBrowser = nil;
}

- (void) stopPublishingServices;
{
	L0Note();
	if (legacyService)
		[servicesBeingDisabled addObject:legacyService];
	[legacyService stop];
	[legacyService release]; legacyService = nil;
	
	if (modernService)
		[servicesBeingDisabled addObject:modernService];
	[modernService stop];
	[modernService release]; modernService = nil;
	
	L0Log(@"Services being disabled now = %@", servicesBeingDisabled);
}

- (void) publishServices;
{
	[self publishServicesWithName:[UIDevice currentDevice].name];
}

- (void) publishServicesWithName:(NSString*) serviceName;
{
	L0Log(@"%@", serviceName);
	
	[self stopPublishingServices];
	NSDictionary* txtDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								   [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"], kL0BonjourPeerApplicationVersionKey,
								   [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"], kL0BonjourPeerUserVisibleApplicationVersionKey,
								   [service uniquePeerIdentifierForSelf], kL0BonjourPeerUniqueIdentifierKey,
								   nil];
	NSData* txtData = [NSNetService dataFromTXTRecordDictionary:txtDictionary];
	
	legacyService = [[NSNetService alloc] initWithDomain:@"local." type:kL0BonjourPeeringServiceName name:serviceName port:listener.port];
	[legacyService setTXTRecordData:txtData];
	legacyService.delegate = self;
	[legacyService publish];
	
	modernService = [[NSNetService alloc] initWithDomain:@"local." type:kMvrStandardServiceName name:serviceName port:listener.port];
	[modernService setTXTRecordData:txtData];
	modernService.delegate = self;
	[modernService publish];
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
{
	L0Log(@"%@ -> %@", service, errorDict);
	
	NSInteger i = [[errorDict objectForKey:NSNetServicesErrorCode] integerValue];
	if (i == NSNetServicesCollisionError) {
		uniquenessNameSuffix++;
		
		[self publishServicesWithName:[NSString stringWithFormat:@"%@ (%d)", [UIDevice currentDevice].name, uniquenessNameSuffix]];
	}
	
	[[UIAlertView alertNamed:@"MvrDidNotPublish"] show];
}

- (void) resetBrowsing:(NSTimer*) t;
{
	L0Note();
	
	[self stop];
	[self start];
}

- (void) stop;
{
	[self willChangeValueForKey:@"enabled"];
	
	[browserResetTimer invalidate];
	[browserResetTimer release]; browserResetTimer = nil;
	
	[self stopBrowsing];
	[self stopPublishingServices];
	
	[[self mutableSetValueForKey:@"availableChannels"] removeAllObjects];
	
	[listener close];
	[listener release]; listener = nil;	
	
	if (connectionsToTransfers) {
		CFRelease(connectionsToTransfers); connectionsToTransfers = NULL;
	}
	
	[self didChangeValueForKey:@"enabled"];
	
	[self stopMonitoringReachability];
}

- (BOOL) enabled;
{
	return listener != nil;
}

- (void) setEnabled:(BOOL) e;
{
	if (e) {
		NSAssert(service, @"You must first add this scanner to a peering service.");
		if (![self start]) {
			[[self retain] autorelease];
			[service removeAvailableScannersObject:self];
		}
	} else
		[self stop];
}

- (void) dealloc;
{
	[self stop];
	[availableChannels release];
	[dispatcher release];
	[servicesBeingDisabled release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark KVC accessors

@synthesize availableChannels, service;

- (void) addAvailableChannelsObject:(L0MoverWiFiChannel*) chan;
{
	[availableChannels addObject:chan];
}

- (void) removeAvailableChannelsObject:(L0MoverWiFiChannel*) chan;
{
	[availableChannels removeObject:chan];	
}

#pragma mark -
#pragma mark Bonjour browsing.

- (void) netServiceBrowserDidStopSearch:(NSNetServiceBrowser*) browser;
{
	L0Log(@"legacy? = %d, modern? = %d", browser == legacyBrowser, browser == modernBrowser);
	if (browser == legacyBrowser)
		[legacyBrowser searchForServicesOfType:kL0BonjourPeeringServiceName inDomain:@""];
	else if (browser == modernBrowser)
		[modernBrowser searchForServicesOfType:kMvrStandardServiceName inDomain:@""];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing;
{
	for (L0MoverWiFiChannel* chan in [[availableChannels copy] autorelease]) {
		if ([chan.service.name isEqual:aNetService.name] && [chan.service.type isEqual:aNetService.type])
			[self removeAvailableChannelsObject:chan];
	}
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing;
{
	[aNetService retain];
	[aNetService setDelegate:self];
	[aNetService resolve];
}

- (void) netServiceDidStop:(NSNetService*) sender;
{
	L0Log(@"%@", sender);
	if ([servicesBeingDisabled containsObject:sender]) {
		[[sender retain] autorelease];
		sender.delegate = nil;
		[servicesBeingDisabled removeObject:sender];
		
		L0Log(@"After removal, services being disabled are: %@", servicesBeingDisabled);
	}
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
			if (address->sin_family != AF_INET) {
				interface = interface->ifa_next;
				continue;
			}
			
			for (NSData* serviceAddressData in [sender addresses]) {
				const struct sockaddr_in* serviceAddress = [serviceAddressData bytes];
				if (serviceAddress->sin_family != AF_INET) continue;
				
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
	
	L0MoverWiFiChannel* channel = [[L0MoverWiFiChannel alloc] initWithScanner:self netService:sender];
	[self addAvailableChannelsObject:channel];
	[channel release];
}

#pragma mark -
#pragma mark Item reception

- (L0MoverWiFiChannel*) channelForAddress:(IPAddress*) a;
{
	for (L0MoverWiFiChannel* aPeer in availableChannels) {
		if ([a _l0_comesFromAddressOfService:aPeer.service]) {
			return aPeer;
		}
	}
	
	return nil;
}

- (void) listener:(TCPListener*) listener didAcceptConnection:(TCPConnection*) connection;
{
	L0MoverWiFiChannel* chan = [self channelForAddress:connection.address];
	
	if (!chan) {
		L0Log(@"No peer associated with this connection; throwing away.");
		[connection close];
		return;
	}
	
	MvrLegacyWiFiIncomingTransfer* transfer = [[MvrLegacyWiFiIncomingTransfer new] autorelease];
	CFDictionarySetValue(connectionsToTransfers, (const void*) connection, (const void*) transfer);
	[service channel:chan didStartReceiving:transfer];
 	
	[connection setDelegate:self];
	[pendingConnections addObject:connection];
}

- (void) connection: (BLIPConnection*)connection receivedRequest: (BLIPRequest*)request;
{
	L0MoverWiFiChannel* chan = [self channelForAddress:connection.address];
	
	if (!chan) {
		L0Log(@"No peer associated with this connection; throwing away.");
		goto returnAfterRemovingConnection;
	}
	
	MvrLegacyWiFiIncomingTransfer* transfer = (MvrLegacyWiFiIncomingTransfer*) CFDictionaryGetValue(connectionsToTransfers, (const void*) connection);
	if (!transfer) {
		L0Log(@"No transfer associated with this connection; throwing away");
		goto returnAfterRemovingConnection;
	}
	
	L0MoverItem* item = [L0MoverItem itemWithContentsOfBLIPRequest:request];
	if (!item) {
		L0Log(@"No item could be created.");
		[transfer setCancelled:YES];
		goto returnAfterRemovingConnection;
	} else
		[transfer setItem:item];
	
	[request respondWithString:@"OK"];
	
returnAfterRemovingConnection:
	CFDictionaryRemoveValue(connectionsToTransfers, (const void*) connection);
	[pendingConnections removeObject:connection];
	[connection close];
}

#pragma mark -
#pragma mark Network reachability (jamming)

@synthesize jammed;

#if DEBUG
- (BOOL) jammed;
{
	if (isJammingSimulated)
		return simulatedJammedValue;
	
	return jammed;
}

- (void) testBySimulatingJamming:(BOOL) simulatedJam;
{
	[self willChangeValueForKey:@"jammed"];
	isJammingSimulated = YES;
	simulatedJammedValue = simulatedJam;
	[self didChangeValueForKey:@"jammed"];
}

- (void) testByStoppingJamSimulation;
{
	[self willChangeValueForKey:@"jammed"];
	isJammingSimulated = NO;
	[self didChangeValueForKey:@"jammed"];
}
#endif

static void L0MoverWiFiNetworkStateChanged(SCNetworkReachabilityRef reach, SCNetworkReachabilityFlags flags, void* meAsPointer) {
	L0MoverWiFiScanner* myself = (L0MoverWiFiScanner*) meAsPointer;
	[NSObject cancelPreviousPerformRequestsWithTarget:myself selector:@selector(checkReachability) object:nil];
	[myself updateNetworkWithFlags:flags];
}

- (void) beginMonitoringReachability;
{
	if (reach) return;
	
	// What follows comes from Reachability.m.
	// Basically, we look for reachability for the link-local address --
	// and filter for WWAN or connection-required responses in -updateNetworkWithFlags:.
	
	// Build a sockaddr_in that we can pass to the address reachability query.
	struct sockaddr_in sin;
	bzero(&sin, sizeof(sin));
	sin.sin_len = sizeof(sin);
	sin.sin_family = AF_INET;
	
	// IN_LINKLOCALNETNUM is defined in <netinet/in.h> as 169.254.0.0
	sin.sin_addr.s_addr = htonl(IN_LINKLOCALNETNUM);
	
	reach = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr*) &sin);
	
	SCNetworkReachabilityContext selfContext = {0, self, NULL, NULL, &CFCopyDescription};
	SCNetworkReachabilitySetCallback(reach, &L0MoverWiFiNetworkStateChanged, &selfContext);
	SCNetworkReachabilityScheduleWithRunLoop(reach, [[NSRunLoop currentRunLoop] getCFRunLoop], kCFRunLoopDefaultMode);
	
	SCNetworkReachabilityFlags flags;
	if (!SCNetworkReachabilityGetFlags(reach, &flags))
		[self performSelector:@selector(checkReachability) withObject:nil afterDelay:0.5];
	else
		[self updateNetworkWithFlags:flags];
}

- (void) stopMonitoringReachability;
{
	if (!reach) return;
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkReachability) object:nil];
	
	SCNetworkReachabilityUnscheduleFromRunLoop(reach, [[NSRunLoop currentRunLoop] getCFRunLoop], kCFRunLoopDefaultMode);
	CFRelease(reach); reach = NULL;
}

- (void) checkReachability;
{
	if (!reach) return;
	
	SCNetworkReachabilityFlags flags;
	if (SCNetworkReachabilityGetFlags(reach, &flags))
		[self updateNetworkWithFlags:flags];
}

- (void) updateNetworkWithFlags:(SCNetworkReachabilityFlags) flags;
{
	BOOL habemusNetwork = 
		(flags & kSCNetworkReachabilityFlagsReachable) &&
		!(flags & kSCNetworkReachabilityFlagsConnectionRequired) &&
		!(flags & kSCNetworkReachabilityFlagsIsWWAN);
	// note that unlike Reachability.m we don't care about WWANs.
	
	[self willChangeValueForKey:@"jammed"];
	jammed = !habemusNetwork;
	[self didChangeValueForKey:@"jammed"];
	
	if (jammed) {
		[[self mutableSetValueForKey:@"availableChannels"] removeAllObjects];
	}
}

- (void) jammedChangedForSelf:(id) me change:(NSDictionary*) change;
{
	if (self.jammed) {
		[self stopBrowsing];
		[self stopPublishingServices];
	} else if (self.enabled) {
		[self stopBrowsing];
		[self performSelector:@selector(startBrowsing) withObject:nil afterDelay:0.3];
		[self performSelector:@selector(publishServices) withObject:nil afterDelay:0.31];
	}

}

@end
