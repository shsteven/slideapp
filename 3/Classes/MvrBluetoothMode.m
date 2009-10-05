//
//  MvrBluetoothMode.m
//  Mover3
//
//  Created by ∞ on 05/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrBluetoothMode.h"


@implementation MvrBluetoothMode

- (id) init
{
	self = [super init];
	if (self != nil) {
		scanner = [MvrBluetoothScanner new];
		observer = [[MvrScannerObserver alloc] initWithScanner:scanner delegate:self];
	}
	return self;
}

- (void) dealloc
{
	[self stopPickingPeer];
	[scanner release];
	[super dealloc];
}


- (void) beginPickingPeer;
{
	if (peerPicker)
		return;
	
	peerPicker = [GKPeerPickerController new];
	peerPicker.delegate = self;
	peerPicker.connectionTypesMask = GKPeerPickerConnectionTypeNearby;
	[peerPicker show];
}

- (void) stopPickingPeer;
{
	if (!peerPicker)
		return;
	
	[peerPicker dismiss];
	[peerPicker autorelease]; peerPicker = nil;
}

- (GKSession*) peerPickerController:(GKPeerPickerController*) picker sessionForConnectionType:(GKPeerPickerConnectionType) type;
{
	return scanner.session;
}

- (void) peerPickerController:(GKPeerPickerController*) picker didConnectPeer:(NSString*) peerID toSession:(GKSession*) session;
{
	[self stopPickingPeer];
}

- (void) peerPickerControllerDidCancel:(GKPeerPickerController*) picker;
{
	[self stopPickingPeer];	
}

- (NSString*) displayNameForDestination:(id) destination;
{
	return [scanner.session displayNameForPeer:[destination peerIdentifier]];
}

- (void) scanner:(id <MvrScanner>) s didAddChannel:(id <MvrChannel>) channel;
{
	if (!self.northDestination)
		self.northDestination = channel;
}

@end
