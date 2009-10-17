//
//  MvrLegacyScanner.m
//  Network+Storage
//
//  Created by ∞ on 14/09/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
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
#import "MvrItem.h"
#import "MvrItemStorage.h"

#import "MvrLegacyWiFiChannel.h"

#pragma mark -
#pragma mark IPAddress additions

@interface IPAddress (MvrLegacyWiFiAdditions)
- (BOOL) _l0_comesFromAnyAddressIn:(NSArray*) s;
@end

@implementation IPAddress (MvrLegacyWiFiAdditions)

#define L0IPv6AddressIsEqual(a, b) (\
(a).__u6_addr.__u6_addr32[0] == (b).__u6_addr.__u6_addr32[0] && \
(a).__u6_addr.__u6_addr32[1] == (b).__u6_addr.__u6_addr32[1] && \
(a).__u6_addr.__u6_addr32[2] == (b).__u6_addr.__u6_addr32[2] && \
(a).__u6_addr.__u6_addr32[3] == (b).__u6_addr.__u6_addr32[3])

- (BOOL) _l0_comesFromAnyAddressIn:(NSArray*) s;
{
	for (NSData* addressData in s) {
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

- (id) initWithPlatformInfo:(id <MvrPlatformInfo>) info serverPort:(int) port;
{
	if (self = [super init]) {
		NSString* name = [info displayNameForSelf];
		
		NSDictionary* txtRecord = [NSDictionary dictionaryWithObjectsAndKeys:
								   [NSString stringWithFormat:@"%f", [info version]], kMvrLegacyWiFiApplicationVersionKey,
								   [info userVisibleVersion], kMvrLegacyWiFiUserVisibleApplicationVersionKey,
								   [[info identifierForSelf] stringValue], kMvrLegacyWiFiUniqueIdentifierKey,
								   nil];
		
		[self addServiceWithName:name type:kMvrLegacyWiFiServiceName_1_0 port:port TXTRecord:txtRecord];
		[self addServiceWithName:name type:kMvrLegacyWiFiServiceName_2_0 port:port TXTRecord:txtRecord];
		
		[self addBrowserForServicesWithType:kMvrLegacyWiFiServiceName_1_0];
		[self addBrowserForServicesWithType:kMvrLegacyWiFiServiceName_2_0];
		
		serverPort = port;
	}
	
	return self;
}

- (void) start;
{
	[super start];
	
	listener = [[BLIPListener alloc] initWithPort:serverPort];
	listener.delegate = self;
	
	NSError* e;
	BOOL started = [listener open:&e];
	if (!started)
		[NSException raise:@"MvrLegacyWiFiCouldNotStartError" format:@"An error occurred when starting the legacy listener: %@", e];
}

- (void) stop;
{
	[listener close];
	[listener release]; listener = nil;
	
	[super stop];
}

#pragma mark -
#pragma mark Peer management.

- (MvrLegacyWiFiChannel*) channelForIPAddress:(IPAddress*) addr;
{
	for (MvrLegacyWiFiChannel* channel in self.channels) {
		if ([addr _l0_comesFromAnyAddressIn:channel.netService.addresses])
			return channel;
	}
	
	return nil;
}

- (MvrLegacyWiFiChannel*) channelForService:(NSNetService*) s;
{
	for (MvrLegacyWiFiChannel* channel in self.channels) {
		if ([channel hasSameServiceAs:s])
			return channel;
	}
	
	return nil;
}

- (void) foundService:(NSNetService *)s;
{
	NSDictionary* idents = [self stringsForKeys:[NSSet setWithObject:kMvrLegacyWiFiUniqueIdentifierKey] inTXTRecordData:[s TXTRecordData] encoding:NSASCIIStringEncoding];
	NSString* ident = [idents objectForKey:kMvrLegacyWiFiUniqueIdentifierKey];
	
	if (!ident) {
		L0Log(@"Service %@ has its UUID missing, generating one for this session.", s);
		ident = [[L0UUID UUID] stringValue];
	}
	
	MvrLegacyWiFiChannel* chan = [[MvrLegacyWiFiChannel alloc] initWithNetService:s identifier:ident];
	[self.mutableChannels addObject:chan];
	[chan release];
}

- (void) lostService:(NSNetService *)s;
{
	MvrLegacyWiFiChannel* chan = [self channelForService:s];
	if (chan)
		[self.mutableChannels removeObject:chan];
}

#pragma mark -
#pragma mark Incoming transfers.

- (void) listener: (TCPListener*)listener didAcceptConnection: (TCPConnection*)connection;
{
	[[self channelForIPAddress:connection.address] addIncomingTransferWithConnection:(BLIPConnection*)connection];
}

@end

#pragma mark -
#pragma mark BLIP additions to MvrItem.

@implementation MvrItem (MvrLegacyWiFi)

- (BLIPRequest*) contentsAsBLIPRequest;
{
	NSDictionary* properties = [NSDictionary dictionaryWithObjectsAndKeys:
								self.title, @"L0SlideItemTitle",
								self.type, @"L0SlideItemType",
								@"1", @"L0SlideItemWireProtocolVersion",
								nil];
	
	
	return [BLIPRequest requestWithBody:self.storage.data
							 properties:properties];
}

+ (id) itemWithContentsOfBLIPRequest:(BLIPRequest*) req;
{
	NSString* version = [req valueOfProperty:@"L0SlideItemWireProtocolVersion"];
	if (![version isEqualToString:@"1"])
		return nil;
	
	NSString* type = [req valueOfProperty:@"L0SlideItemType"];
	if (!type)
		return nil;
	
	
	NSString* title = [req valueOfProperty:@"L0SlideItemTitle"];
	if (!title)
		return nil;
	
	Class c = [self classForType:type];
	if (!c)
		return nil;
	
	MvrItemStorage* storage = [MvrItemStorage itemStorageWithData:req.body];
	NSDictionary* metadata = [NSDictionary dictionaryWithObject:title forKey:kMvrItemTitleMetadataKey];
	
	return [[[c alloc] initWithStorage:storage type:type metadata:metadata] autorelease];
}

@end
