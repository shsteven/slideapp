//
//  L0BluetoothPeeringService.m
//  Mover
//
//  Created by ∞ on 05/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0BluetoothPeeringService.h"
#import "L0BluetoothPeer.h"

static const char kL0MoverBTDataHeader[4] = { 'M', 'O', 'V', 'R' };
#define kL0MoverBTDataHeaderLength (4)

#define kL0MoverBTTitleKey @"Title"
#define kL0MoverBTTypeKey @"Type"
#define kL0MoverBTDataKey @"Data"

static BOOL L0IsDictionaryWithRequiredKeysAndTypes(id plist, NSDictionary* typesByKey) {
	
	if (![plist isKindOfClass:[NSDictionary class]]) return NO;
	
	for (NSString* key in typesByKey) {
		id v = [plist objectForKey:key];
		if (!key) return NO;
		if (![v isKindOfClass:[typesByKey objectForKey:key]]) return NO;
	}
	
	return YES;
}


@interface L0BluetoothPeeringService ()

- (void) performSendingForPeerID:(NSString*) peerID;
- (void) endReceivingItem:(L0MoverItem*) i fromPeer:(L0BluetoothPeer*) peer;


@end


@implementation L0BluetoothPeeringService

@synthesize delegate;

+ sharedService;
{
	static id myself = nil; if (!myself)
		myself = [self new];
	
	return myself;
}

- (void) start;
{
	if (session) return;
	
	NSString* name = nil;
#if TARGET_IPHONE_SIMULATOR
	name = [NSString stringWithFormat:@"Mover Test Rig (%d)", getpid()];
#endif
	
	session = [[GKSession alloc] initWithSessionID:nil displayName:name sessionMode:GKSessionModePeer];
	session.delegate = self;
	[session setDataReceiveHandler:self withContext:NULL];
	session.available = YES;
	
	NSAssert(!currentPeers, @"No peers dictionary");
	currentPeers = [NSMutableDictionary new];
	
	NSAssert(!pendingItemsToSendByPeer, @"No pending item data dictionary");
	pendingItemsToSendByPeer = [NSMutableDictionary new];
	
	NSAssert(!pendingReceivedDataByPeer, @"No pending item data dictionary");
	pendingReceivedDataByPeer = [NSMutableDictionary new];
}

- (void) stop;
{
	if (!session) return;
	
	session.available = NO;
	[session release];
	session = nil;
	
	for (L0BluetoothPeer* peer in [currentPeers allValues])
		[self.delegate peerLeft:peer];
	
	[currentPeers release];
	currentPeers = nil;
	
	[pendingItemsToSendByPeer release];
	pendingItemsToSendByPeer = nil;
	
	[pendingReceivedDataByPeer release];
	pendingReceivedDataByPeer = nil;
}

- (void)session:(GKSession*) s connectionWithPeerFailed:(NSString*) peerID withError:(NSError*) error;
{
	L0Log(@"%@ (named '%@'): %@", peerID, [s displayNameForPeer:peerID], error);
}

- (void) session:(GKSession*) s didReceiveConnectionRequestFromPeer:(NSString*) peerID;
{
	if ([[s peersWithConnectionState:GKPeerStateConnected] count] == 0)
		[s acceptConnectionFromPeer:peerID error:NULL];
	else
		[s denyConnectionFromPeer:peerID];
}

- (void) session:(GKSession*) s didFailWithError:(NSError*) error;
{
	L0Log(@"%@", error);
}

- (void) session:(GKSession*) s peer:(NSString*) peerID didChangeState:(GKPeerConnectionState) state;
{
	if ([peerID isEqual:s.peerID]) {
		L0Log(@"Ignoring change on self.");
		return;
	}
	
	switch (state) {
		case GKPeerStateAvailable: {
			L0BluetoothPeer* peer = [[[L0BluetoothPeer alloc] initWithPeerID:peerID displayName:[s displayNameForPeer:peerID]] autorelease];
			[currentPeers setObject:peer forKey:peerID];
			[self.delegate peerFound:peer];
		}
			break;
			
		case GKPeerStateUnavailable: {
			L0BluetoothPeer* peer = [currentPeers objectForKey:peerID];
			if (peer) {
				[self.delegate peerLeft:peer];
				[currentPeers removeObjectForKey:peerID];
				[pendingItemsToSendByPeer removeObjectForKey:peerID];
			}
		}
			break;
			
		case GKPeerStateDisconnected: {
			[pendingReceivedDataByPeer removeObjectForKey:peerID];
		}
			break;
			
		case GKPeerStateConnected: {
			if ([pendingItemsToSendByPeer objectForKey:peerID])
				[self performSendingForPeerID:peerID];
		}
			break;
			
	}
}

- (void) receiveData:(NSData *)data fromPeer:(NSString *)peerID inSession: (GKSession *)session context:(void *)context;
{
	L0BluetoothPeer* peer = [currentPeers objectForKey:peerID];
	if (!peer) return;
	
	NSMutableData* d = [pendingReceivedDataByPeer objectForKey:peerID];
	if (!d) {
		d = [NSMutableData data];
		[pendingReceivedDataByPeer setObject:d forKey:peerID];
		[peer.delegate moverPeerWillSendUsItem:peer];
	}
	
	[d appendData:data];
	
	if ([d length] >= kL0MoverBTDataHeaderLength) {
		const char* c = (const char*) [d bytes];
		BOOL ok = YES;
		int i; for (i = 0; i < kL0MoverBTDataHeaderLength; i++) {
			if (kL0MoverBTDataHeader[i] != c[i]) {
				ok = NO; break;
			}
		}
		
		if (!ok) {
			[self endReceivingItem:nil fromPeer:peer];
			return;
		}
	}
	
	if ([d length] >= kL0MoverBTDataHeaderLength + sizeof(uint32_t)) {
		const void* lengthField = [d bytes] + kL0MoverBTDataHeaderLength;
		uint32_t networkLength = *((uint32_t*)lengthField);
		uint32_t length = ntohl(networkLength);
		
		if (length <= [d length] - kL0MoverBTDataHeaderLength - sizeof(uint32_t)) {
			NSData* plistData = [d subdataWithRange:NSMakeRange(kL0MoverBTDataHeaderLength + sizeof(uint32_t), [d length] - (kL0MoverBTDataHeaderLength + sizeof(uint32_t)))];
			
			NSString* errorString = nil;
			id plist = [NSPropertyListSerialization propertyListFromData:plistData mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:&errorString];
			
			if (errorString) {
				L0Log(@"plist error: %@", errorString);
				[errorString release];
				[self endReceivingItem:nil fromPeer:peer];
				return;
			}
			
			if (!L0IsDictionaryWithRequiredKeysAndTypes(plist, 
														[NSDictionary dictionaryWithObjectsAndKeys:
														 [NSString class], kL0MoverBTTypeKey,
														 [NSString class], kL0MoverBTTitleKey,
														 [NSData class], kL0MoverBTDataKey,
														 nil])) {
				[self endReceivingItem:nil fromPeer:peer];
				return;
			}
			
			Class c = [L0MoverItem classForType:[plist objectForKey:kL0MoverBTTypeKey]];
			L0MoverItem* item = [[[c alloc] initWithExternalRepresentation:[plist objectForKey:kL0MoverBTDataKey] type:[plist objectForKey:kL0MoverBTTypeKey] title:[plist objectForKey:kL0MoverBTTitleKey]] autorelease];
			
			[self endReceivingItem:item fromPeer:peer];
		}
	}
}

- (void) endReceivingItem:(L0MoverItem*) i fromPeer:(L0BluetoothPeer*) peer;
{
	[pendingReceivedDataByPeer removeObjectForKey:peer.peerID];
	if (i)
		[peer.delegate moverPeer:peer didSendUsItem:i];
	else {
		[peer.delegate moverPeerDidCancelSendingUsItem:peer];	
		[session disconnectPeerFromAllPeers:peer.peerID];
	}
}

- (void) performSendingForPeerID:(NSString*) peerID;
{
	L0BluetoothPeer* peer = [currentPeers objectForKey:peerID];
	L0MoverItem* itemToSend;
	if (peer && (itemToSend = [pendingItemsToSendByPeer objectForKey:peerID])) {
		NSMutableDictionary* d = [NSMutableDictionary dictionary];
		[d setObject:itemToSend.title forKey:kL0MoverBTTitleKey];
		[d setObject:itemToSend.type forKey:kL0MoverBTTypeKey];
		[d setObject:[itemToSend externalRepresentation] forKey:kL0MoverBTDataKey];
		
		NSString* errorString = nil;
		NSData* plistData = [NSPropertyListSerialization dataFromPropertyList:d format:NSPropertyListBinaryFormat_v1_0 errorDescription:&errorString];
		
		
		if (errorString) {
			L0Log(@"%@", errorString);
			[errorString release];
		}
		
		if (plistData) {
			NSMutableData* dataToSend = [NSMutableData data];
			[dataToSend appendBytes:&kL0MoverBTDataHeader length:kL0MoverBTDataHeaderLength];
			
			uint64_t payloadLength = [plistData length];
			if (payloadLength <= INT32_MAX) {
				uint32_t networkPayloadLength = htonl((uint32_t) payloadLength);
				[dataToSend appendBytes:&networkPayloadLength length:sizeof(uint32_t)];
				[dataToSend appendData:plistData];
				
				[session sendData:dataToSend toPeers:[NSArray arrayWithObject:peerID] withDataMode:GKSendDataReliable error:NULL];
			}
		}
		
		[peer.delegate moverPeer:peer wasSentItem:itemToSend];
		[pendingItemsToSendByPeer removeObjectForKey:peerID];
	}
}


- (void) sendItem:(L0MoverItem*) i toBluetoothPeer:(L0BluetoothPeer*) peer;
{
	[peer.delegate moverPeer:peer willBeSentItem:i];
	// TODO a better way to perform canceling on send.
	if (!session || [pendingItemsToSendByPeer objectForKey:peer.peerID]) {
		[peer.delegate moverPeer:peer wasSentItem:i];
		return;
	}
	
	[pendingItemsToSendByPeer setObject:i forKey:peer.peerID];
	[session connectToPeer:peer.peerID withTimeout:5.0];
}

@end
