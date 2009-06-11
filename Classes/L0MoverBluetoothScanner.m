//
//  L0MoverBluetoothScanner.m
//  Mover
//
//  Created by ∞ on 11/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0MoverBluetoothScanner.h"
#import "L0MoverBluetoothChannel.h"

@interface L0MoverBluetoothScanner ()

- (void) start;
- (void) stop;

- (void) makeChannelForPeer:(NSString*) peerID;
- (void) unmakeChannelForPeer:(NSString*) peerID;

@end


@implementation L0MoverBluetoothScanner

@synthesize service, jammed;
@synthesize bluetoothSession;

- (NSSet*) availableChannels;
{
	return [NSSet setWithArray:[channelsByPeerID allValues]];
}

- (void) addAvailableChannelsObject:(L0MoverBluetoothChannel*) c;
{
	[channelsByPeerID setObject:c forKey:c.peerID];
}

- (void) removeAvailableChannelsObject:(L0MoverBluetoothChannel*) c;
{
	if ([c isEqual:[channelsByPeerID objectForKey:c.peerID]])
		[channelsByPeerID removeObjectForKey:c.peerID];	
}

- (BOOL) enabled;
{
	return bluetoothSession != nil && !jammed;
}

- (void) setEnabled:(BOOL) enabled;
{
	if (enabled)
		[self start];
	else
		[self stop];
}

- (void) start;
{
	NSAssert(service, @"First add this scanner to a peering service via addAvailableScannerObject:.");
	if (bluetoothSession) return;
	
	NSString* name = [UIDevice currentDevice].name;
#if TARGET_IPHONE_SIMULATOR
	name = [name stringByAppendingFormat:@" (%d)", getpid()];
#endif
	
	name = [name stringByAppendingFormat:@"|%@", service.uniquePeerIdentifierForSelf];
	
	bluetoothSession = [[GKSession alloc] initWithSessionID:kL0MoverBTSessionIdentifier displayName:name sessionMode:GKSessionModePeer];
	bluetoothSession.delegate = self;
	[bluetoothSession setDataReceiveHandler:self withContext:NULL];
	
	bluetoothSession.available = YES;
	
	NSAssert(!channelsByPeerID, @"No channels-by-peer data must be present");
	channelsByPeerID = [NSMutableDictionary new];
}

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state;
{
	switch (state) {
		case GKPeerStateAvailable:
			[self makeChannelForPeer:peerID];
			break;
			
		case GKPeerStateUnavailable:
			[self unmakeChannelForPeer:peerID];
			break;
			
		case GKPeerStateConnected:
			[[channelsByPeerID objectForKey:peerID] communicateWithOtherEndpoint];
			break;
			
		case GKPeerStateDisconnected:
			[[channelsByPeerID objectForKey:peerID] endCommunicationWithOtherEndpoint];
	}
}

- (void) session:(GKSession*) session didReceiveConnectionRequestFromPeer:(NSString*)peerID;
{
	[session acceptConnectionFromPeer:peerID error:NULL];
}

- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error;
{
	[[channelsByPeerID objectForKey:peerID] endCommunicationWithOtherEndpoint];
}

- (void) session:(GKSession*) session didFailWithError:(NSError*) error;
{
	if ([error code] == GKSessionCannotEnableError) { // No BT on device.
		[[self retain] autorelease];
		[self stop];
		[self.service removeAvailableScannersObject:self];
		return;
	} else {
		[self stop];
		[self willChangeValueForKey:@"jammed"];
		
		if (retries <= 10) {
			jammed = YES;
			retries++;
			[self performSelector:@selector(start) withObject:nil afterDelay:10.0];
		} else {
			jammed = NO; // this makes us disabled.
		}
		
		[self didChangeValueForKey:@"jammed"];
	}
}

- (void) receiveData:(NSData*) data fromPeer:(NSString*) peerID inSession:(GKSession*) s context:(void*) nothing;
{
	[[channelsByPeerID objectForKey:peerID] receiveDataFromOtherEndpoint:data];
}

- (void) makeChannelForPeer:(NSString*) peerID;
{
	L0MoverBluetoothChannel* chan = [[L0MoverBluetoothChannel alloc] initWithScanner:self peerID:peerID];
	[self addAvailableChannelsObject:chan];
	[chan release];
}

- (void) unmakeChannelForPeer:(NSString*) peerID;
{
	L0MoverBluetoothChannel* chan = [channelsByPeerID objectForKey:peerID];
	if (chan)
		[self removeAvailableChannelsObject:chan];
}

- (void) stop;
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(start) object:nil];
	if (!bluetoothSession) return;
	
	bluetoothSession.delegate = nil;
	bluetoothSession.available = NO;
	[bluetoothSession release];
	bluetoothSession = nil;
	
	[channelsByPeerID release];
	channelsByPeerID = nil;
}

- (void) dealloc;
{
	[self stop];
	[super dealloc];
}

@end
