//
//  L0MoverBluetoothScanner.m
//  Mover
//
//  Created by ∞ on 11/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0MoverBluetoothScanner.h"
#import "L0MoverBluetoothChannel.h"

#import <sys/types.h>
#import <sys/sysctl.h>

@interface L0MoverBluetoothScanner ()

- (void) start;
- (void) stop;

- (void) makeChannelForPeer:(NSString*) peerID;
- (void) unmakeChannelForPeer:(NSString*) peerID;

@end


static NSString* L0MoverCurrentModelName() {
	size_t length;
	if (sysctlbyname("hw.machine", NULL, &length, NULL, 0) == -1)
		return nil;
	
	char* hardwareModelC = malloc(sizeof(char) * length);
	NSString* hardwareModel = nil;
	if (sysctlbyname("hw.machine", hardwareModelC, &length, NULL, 0) != -1) {
		hardwareModel = [[[NSString alloc] initWithBytes:hardwareModelC length:length - 1 encoding:NSASCIIStringEncoding] autorelease];
	}
	
	free(hardwareModelC);
	return hardwareModel;
}


@implementation L0MoverBluetoothScanner

L0ObjCSingletonMethod(sharedScanner)

@synthesize service, jammed;
@synthesize bluetoothSession;
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

+ (BOOL) modelAssumedToSupportBluetooth;
{
#if DEBUG && kL0MoverTestByAssumingModelDoesNotSupportBluetooth
#warning Testing: Will assume no model supports Bluetooth.
	return NO;
#endif
	
#if !DEBUG && kL0MoverTestByAssumingModelDoesNotSupportBluetooth
#error Disable kL0MoverTestByAssumingModelDoesNotSupportBluetooth in your local settings to build.
#endif

	NSString* model = L0MoverCurrentModelName();
	return ![model isEqual:@"iPhone1,1"] && ![model isEqual:@"iPod1,1"];
}

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
	return bluetoothSession != nil;
}

- (void) setEnabled:(BOOL) enabled;
{
	if (enabled)
		[self start];
	else {
		[self stop];
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(restart) object:nil];
	}
}

- (void) restart;
{
	[self stop];
	[self start];
}

- (void) start;
{
	NSAssert(service, @"First add this scanner to a peering service via addAvailableScannerObject:.");
	if (bluetoothSession) return;
	
	L0Log(@"Model: %@ should support BT: %d", L0MoverCurrentModelName(), [[self class] modelAssumedToSupportBluetooth]);
	
	NSString* name = [UIDevice currentDevice].name;
#if TARGET_IPHONE_SIMULATOR
	name = [name stringByAppendingFormat:@" (%d)", getpid()];
#endif
	
	name = [name stringByAppendingFormat:@"|%@", service.uniquePeerIdentifierForSelf];
	
	bluetoothSession = [[GKSession alloc] initWithSessionID:kL0MoverBTSessionIdentifier displayName:name sessionMode:GKSessionModePeer];
	[bluetoothSession setDataReceiveHandler:self withContext:NULL];
	bluetoothSession.delegate = self;
	bluetoothSession.disconnectTimeout = 5.0;
	
	bluetoothSession.available = YES;
	
	NSAssert(!channelsByPeerID, @"No channels-by-peer data must be present");
	channelsByPeerID = [NSMutableDictionary new];
}

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state;
{
	L0Log(@"%@ has peer %@ in state %d", session, peerID, state);
	
	NSMutableArray* peers = [NSMutableArray array];
	[peers addObjectsFromArray:[session peersWithConnectionState:GKPeerStateAvailable]];
	[peers addObjectsFromArray:[session peersWithConnectionState:GKPeerStateConnected]];
	[peers addObjectsFromArray:[session peersWithConnectionState:GKPeerStateConnecting]];

	NSArray* currentPeers = [[[channelsByPeerID allKeys] copy] autorelease];

	L0Log(@"new peer collection = %@, previous peer collection = %@", peers, currentPeers);

	for (NSString* peer in peers) {
		if (![currentPeers containsObject:peer])
			[self makeChannelForPeer:peer];
	}
	
	for (NSString* peer in currentPeers) {
		if (![peers containsObject:peer])
			[self unmakeChannelForPeer:peer];
	}
	
	switch (state) {
		case GKPeerStateConnected:
			[[channelsByPeerID objectForKey:peerID] communicateWithOtherEndpoint];
			break;
			
		case GKPeerStateDisconnected:
			[[channelsByPeerID objectForKey:peerID] endCommunicationWithOtherEndpoint];
			break;
	}
}

- (void) session:(GKSession*) session didReceiveConnectionRequestFromPeer:(NSString*)peerID;
{
	[session acceptConnectionFromPeer:peerID error:NULL];
}

- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error;
{
	[self unmakeChannelForPeer:peerID];
}

- (void) session:(GKSession*) session didFailWithError:(NSError*) error;
{
	if ([error code] == GKSessionCannotEnableError && ![[self class] modelAssumedToSupportBluetooth]) { // No BT on device.
		[[self retain] autorelease];
		[self stop];
		[self.service removeAvailableScannersObject:self];
		return;
	} else {
		[self willChangeValueForKey:@"jammed"];
		
		if (retries <= 10) {
			jammed = YES;
			retries++;
			[self performSelector:@selector(restart) withObject:nil afterDelay:10.0];
		} else {
			jammed = NO;
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
	L0MoverBluetoothChannel* chan = [[[L0MoverBluetoothChannel alloc] initWithScanner:self peerID:peerID] autorelease];
	if ([chan.uniquePeerIdentifier isEqual:[[MvrNetworkExchange sharedExchange] uniquePeerIdentifierForSelf]])
		return;
	
	[[self mutableSetValueForKey:@"availableChannels"] addObject:chan];
}

- (void) unmakeChannelForPeer:(NSString*) peerID;
{
	L0MoverBluetoothChannel* chan = [channelsByPeerID objectForKey:peerID];
	[chan endCommunicationWithOtherEndpoint];
	if (chan)
		[[self mutableSetValueForKey:@"availableChannels"] removeObject:chan];
}

- (void) stop;
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(restart) object:nil];
	if (!bluetoothSession) return;
	
	bluetoothSession.delegate = nil;
	bluetoothSession.available = NO;
	[bluetoothSession disconnectFromAllPeers];
	[bluetoothSession release];
	bluetoothSession = nil;
	
	for (NSString* peerID in [NSArray arrayWithArray:[channelsByPeerID allKeys]])
		[self unmakeChannelForPeer:peerID];
	
	[channelsByPeerID release];
	channelsByPeerID = nil;
}

- (void) dealloc;
{
	[self stop];
	[super dealloc];
}

@end
