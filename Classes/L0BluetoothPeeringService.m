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
	name = [NSString stringWithFormat:@"Mover Test Rig (%d)", getpid()]
#endif
	
	session = [[GKSession alloc] initWithSessionID:nil displayName:name sessionMode:GKSessionModePeer];
	session.delegate = self;
	session.available = YES;
	
	NSAssert(!currentPeers, @"No peers dictionary");
	currentPeers = [NSMutableDictionary new];
	
	NSAssert(!pendingItemsToSendByPeer, @"No pending item data dictionary");
	pendingItemsToSendByPeer = [NSMutableDictionary new];
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
}

- (void)session:(GKSession*) s connectionWithPeerFailed:(NSString*) peerID withError:(NSError*) error;
{
	L0Log(@"%@ (named '%@'): %@", peerID, [s displayNameForPeer:peerID], error);
}

- (void) session:(GKSession*) s didFailWithError:(NSError*) error;
{
	L0Log(@"%@", error);
}

- (void) session:(GKSession*) s peer:(NSString*) peerID didChangeState:(GKPeerConnectionState) state;
{
	L0Log(@"%@ (%@) is now in state %@", peerID, [s displayNameForPeer:peerID], state);
	
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
			}
		}
			break;
			
		case GKPeerStateConnected: {
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
					[dataToSend appendBytes:&payloadLength length:sizeof(uint64_t)];
					[dataToSend appendData:plistData];
					
					[s sendData:dataToSend toPeers:[NSArray arrayWithObject:peerID] withDataMode:GKSendDataReliable error:NULL];
				}
				
				[peer.delegate slidePeer:peer wasSentItem:itemToSend];
				[pendingItemsToSendByPeer removeObjectForKey:peerID];
			}
		}
			break;

	}
}

- (void) sendItem:(L0MoverItem*) i toBluetoothPeer:(L0BluetoothPeer*) peer;
{
	if (!session) return;
	
	[peer.delegate slidePeer:peer willBeSentItem:i];
	[pendingItemsToSendByPeer setObject:i forKey:peer.peerID];
	[session connectToPeer:peer.peerID withTimeout:5.0];
}

@end
