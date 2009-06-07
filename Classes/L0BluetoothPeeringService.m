//
//  L0BluetoothPeeringService.m
//  Mover
//
//  Created by ∞ on 05/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0BluetoothPeeringService.h"
#import "L0BluetoothPeer.h"

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
	
	session = [[GKSession alloc] initWithSessionID:nil displayName:nil sessionMode:GKSessionModePeer];
	session.delegate = self;
	
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

- (void) session:(GKSession*) s peer:(NSString*) peerID didChangeState:(GKPeerConnectionState) state;
{
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
				NSData* dataToSend = [NSPropertyListSerialization dataFromPropertyList:d format:NSPropertyListBinaryFormat_v1_0 errorDescription:&errorString];
				
				if (errorString) {
					L0Log(@"%@", errorString);
					[errorString release];
				}
				
				if (d)
					[s sendData:dataToSend toPeers:[NSArray arrayWithObject:peerID] withDataMode:GKSendDataReliable error:NULL];
				
				[peer.delegate slidePeer:peer wasSentItem:itemToSend];
				[pendingItemsToSendByPeer removeObjectForKey:peerID];
			}
		}
			break;

	}
}

- (void) sendItem:(L0MoverItem*) i toPeer:(L0BluetoothPeer*) peer;
{
	if (!session) return;
	
	[peer.delegate slidePeer:peer willBeSentItem:i];
	[pendingItemsToSendByPeer setObject:i forKey:peer.peerID];
	[session connectToPeer:peer.peerID withTimeout:5.0];
}

@end
