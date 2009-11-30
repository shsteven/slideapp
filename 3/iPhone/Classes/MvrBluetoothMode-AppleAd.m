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

@interface MvrBluetoothMode_AdIncoming : NSObject <MvrIncoming> {
	CGFloat progress;
	BOOL done;
}

- (void) start;

- (void) showSomeProgress;
- (void) beDone;

@end

@implementation MvrBluetoothMode_AdIncoming

- (float) progress;
{
	return done? 1.0 : progress; // TODO animation
}

- (MvrItem*) item;
{
	return !done? nil: [MvrAdActingController sharedAdController].itemForReceiving; // TODO animation
}

- (void) start;
{
	[self willChangeValueForKey:@"progress"];
	progress = 0.2;
	[self didChangeValueForKey:@"progress"];
	
	[self performSelector:@selector(showSomeProgress) withObject:nil afterDelay:0.45];
}

- (void) showSomeProgress;
{
	[self willChangeValueForKey:@"progress"];
	progress = 0.7;
	[self didChangeValueForKey:@"progress"];
	
	[self performSelector:@selector(beDone) withObject:nil afterDelay:0.25];
}

- (void) beDone;
{
	[self willChangeValueForKey:@"progress"];
	[self willChangeValueForKey:@"item"];
	
	done = YES;
	
	[self didChangeValueForKey:@"item"];
	[self didChangeValueForKey:@"progress"];
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
	
#if DEBUG
	if ([[[[NSProcessInfo processInfo] environment] objectForKey:@"MvrAppleAdDoNotConnectBT"] boolValue])
		return;
#endif
	
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
	[adSession sendData:[@"hi" dataUsingEncoding:NSASCIIStringEncoding] toPeers:[NSArray arrayWithObject:peerID] withDataMode:GKSendDataReliable error:NULL];
	
	adPicker.delegate = nil;
	[adPicker dismiss];
	[adPicker release]; adPicker = nil;
	
	MvrAdActingController* ad = [MvrAdActingController sharedAdController];
	MvrArrowView* arrowView;
	if ([ad.receiver boolValue]) {
		self.westDestination = peerID;
		arrowView = self.arrowsView.westView;
	} else {
		self.eastDestination = peerID;
		arrowView = self.arrowsView.eastView;
	}
	
	arrowView.normalColor = [UIColor whiteColor];
	arrowView.nameLabel.textColor = [UIColor whiteColor];
	arrowView.busyColor = [UIColor colorWithRed:1.0 green:1.0 blue:0.820 alpha:1.000];
}

- (BOOL) isAvailable;
{
	return MvrBluetoothIsAvailable();
}

- (NSString*) displayNameForDestination:(id) destination;
{
	return [adSession displayNameForPeer:destination];
}

#pragma mark Sending

- (void) sendItem:(MvrItem *)i toDestination:(id)destination;
{
	MvrAdActingController* ad = [MvrAdActingController sharedAdController];
	if ([ad.receiver boolValue])
		return;
	
	[adSession sendData:[@"g" dataUsingEncoding:NSASCIIStringEncoding] toPeers:[NSArray arrayWithObject:destination] withDataMode:GKSendDataReliable error:NULL];

	[self.delegate UIMode:self didFinishSendingItem:i]; // TODO delay?
}

#pragma mark Receiving

- (void) receiveData:(NSData*) d fromPeer:(NSString*) peer inSession:(GKSession*) s context:(void*) nothing;
{
	if ([d length] != 1)
		return;
	
	const char* data = [d bytes];
	
	if (*data != 'g')
		return;
	
	MvrBluetoothMode_AdIncoming* inco = [[MvrBluetoothMode_AdIncoming new] autorelease];
	[self.delegate UIMode:self willBeginReceivingItemWithTransfer:inco fromDirection:kMvrDirectionWest];
	[inco start];
}

@end

#endif // #if kMvrInstrumentForAds
