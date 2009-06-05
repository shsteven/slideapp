//
//  L0BluetoothPeeringService.m
//  Mover
//
//  Created by ∞ on 05/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0BluetoothPeeringService.h"
#import "L0BluetoothPeer.h"

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
	}
}

@end
