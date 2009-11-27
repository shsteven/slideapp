//
//  MvrBluetoothMode-AppleAd.m
//  Mover3
//
//  Created by ∞ on 27/11/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#if kMvrInstrumentForAds

#import "MvrBluetoothMode.h"
#import "MvrAdActingController.h"
#import "Network+Storage/MvrIncoming.h"
#import "Network+Storage/MvrProtocol.h"
#import "MvrTableController.h"
#import "MvrAppDelegate.h"

@interface MvrBluetoothMode_AdIncoming : NSObject <MvrIncoming> {}
@end

@implementation MvrBluetoothMode_AdIncoming

- (float) progress;
{
	return kMvrIndeterminateProgress; // TODO animation
}

- (MvrItem*) item;
{
	return [MvrAdActingController sharedAdController].itemForReceiving; // TODO animation
}

- (BOOL) cancelled;
{
	return NO;
}

@end



#define kMvrBluetoothAdSessionID @"net.infinite-labs.Mover3.AppleAd"

static GKSession* adSession = nil;
static GKPeerPickerController* adPicker = nil;

@interface MvrBluetoothMode () <GKSessionDelegate>
@end


@implementation MvrBluetoothMode

- (void) beginPickingPeer;
{	
}

- (void) stopPickingPeer;
{	
}

- (void) modeDidBecomeCurrent:(BOOL)animated;
{
	if (adPicker)
		return;
	
	adPicker = [[GKPeerPickerController alloc] init];
	adPicker.delegate = self;
	adPicker.connectionTypesMask = GKPeerPickerConnectionTypeNearby;
	[adPicker show];
}

- (GKSession *)peerPickerController:(GKPeerPickerController *)picker sessionForConnectionType:(GKPeerPickerConnectionType)type;
{
	GKSession* s = [[[GKSession alloc] initWithSessionID:kMvrBluetoothAdSessionID displayName:[UIDevice currentDevice].name sessionMode:GKSessionModePeer] autorelease];
	return s;
}

- (void)peerPickerControllerDidCancel:(GKPeerPickerController *)picker;
{
	exit(0);
}

- (void) peerPickerController:(GKPeerPickerController *)picker didConnectPeer:(NSString *)peerID toSession:(GKSession *)session;
{
	adSession = [session retain];
	adSession.delegate = self;
	[adSession setDataReceiveHandler:self withContext:NULL];
	
	adPicker.delegate = nil;
	[adPicker dismiss];
	[adPicker release]; adPicker = nil;
	
	MvrAdActingController* ad = [MvrAdActingController sharedAdController];
	if ([ad.receiver boolValue])
		self.eastDestination = peerID;
	else
		self.westDestination = peerID;
}

- (BOOL) isAvailable;
{
	return MvrBluetoothIsAvailable();
}

#pragma mark Sending

- (void) sendItem:(MvrItem *)i toDestination:(id)destination;
{
	MvrAdActingController* ad = [MvrAdActingController sharedAdController];
	if ([ad.receiver boolValue])
		return;
	
	[adSession sendData:[@"x" dataUsingEncoding:NSASCIIStringEncoding] toPeers:[NSArray arrayWithObject:destination] withDataMode:GKSendDataReliable error:NULL];

	[self.delegate UIMode:self didFinishSendingItem:i]; // TODO delay?
}

#pragma mark Receiving

- (void) receiveData:(NSData*) d fromPeer:(NSString*) peer inSession:(GKSession*) s context:(void*) nothing;
{
	MvrBluetoothMode_AdIncoming* inco = [[MvrBluetoothMode_AdIncoming new] autorelease];
	[self.delegate UIMode:self willBeginReceivingItemWithTransfer:inco fromDirection:kMvrDirectionWest];
}

@end

#endif // #if kMvrInstrumentForAds
