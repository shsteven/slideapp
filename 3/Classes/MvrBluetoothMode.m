//
//  MvrBluetoothMode.m
//  Mover3
//
//  Created by ∞ on 05/10/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrBluetoothMode.h"

#import <MuiKit/MuiKit.h>

#import "MvrAppDelegate.h"

@implementation MvrBluetoothMode

- (id) init
{
	self = [super init];
	if (self != nil) {
		scanner = [MvrBTScanner new];
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


- (void) modeDidBecomeCurrent:(BOOL)animated;
{
	scanner.enabled = YES;
	didPickAfterSwitch = NO;
	
	[self performSelector:@selector(setDrawerAsSticky) withObject:nil afterDelay:0.7];
	
	if (!scanner.channel)
		[self beginPickingPeer];
}

- (void) modeWillStopBeingCurrent:(BOOL)animated;
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(setDrawerAsSticky) object:nil];
	
	[self stopPickingPeer];
	scanner.enabled = NO;
	scanner.session = nil;
}

- (void) setDrawerAsSticky;
{
	delegate.shouldKeepConnectionDrawerVisible = YES;
}

- (void) beginPickingPeer;
{
	if (peerPicker)
		return;
	
	scanner.session = nil;
	
	peerPicker = [GKPeerPickerController new];
	peerPicker.delegate = self;
	peerPicker.connectionTypesMask = GKPeerPickerConnectionTypeNearby;
	[peerPicker show];
}

- (void) stopPickingPeer;
{
	if (!peerPicker)
		return;
	
	peerPicker.delegate = nil;
	[peerPicker autorelease]; peerPicker = nil;
}

- (GKSession*) peerPickerController:(GKPeerPickerController*) picker sessionForConnectionType:(GKPeerPickerConnectionType) type;
{
	return [scanner configuredSession];
}

- (void) peerPickerController:(GKPeerPickerController*) picker didConnectPeer:(NSString*) peerID toSession:(GKSession*) session;
{
	scanner.session = session;
	[scanner acceptPeerWithIdentifier:peerID];
	didPickAfterSwitch = YES;
	
	[picker dismiss];
	[self stopPickingPeer];
}

- (void) peerPickerControllerDidCancel:(GKPeerPickerController*) picker;
{
	[self stopPickingPeer];
	
	if (!didPickAfterSwitch)
		[MvrApp() moveToWiFiMode];
}

- (NSString*) displayNameForDestination:(MvrBTChannel*) destination;
{
	return [scanner.session displayNameForPeer:destination.peerID];
}

- (void) scanner:(id <MvrScanner>) s didAddChannel:(id <MvrChannel>) channel;
{
	if (!self.northDestination)
		self.northDestination = channel;
	self.arrowsView.northView.normalColor = [UIColor whiteColor];
	self.arrowsView.northView.nameLabel.textColor = [UIColor whiteColor];
	self.arrowsView.northView.busyColor = [UIColor colorWithRed:1.0 green:1.0 blue:0.820 alpha:1.000];
}

- (void) scanner:(id <MvrScanner>) s didRemoveChannel:(id <MvrChannel>) channel;
{
	if (self.northDestination == channel)
		self.northDestination = nil;
}

- (void) sendItem:(MvrItem*) i toDestinationAtDirection:(MvrDirection) d;
{
	if (!self.northDestination || d != kMvrDirectionNorth)
		return;
	
	[self.northDestination beginSendingItem:i];
}

- (void) sendItem:(MvrItem*) i toDestination:(id) destination;
{
	if (self.northDestination != destination)
		return;
	
	[destination beginSendingItem:i];
}


#pragma mark Receiving items


- (void) channel:(id <MvrChannel>)c didBeginSendingWithOutgoingTransfer:(id <MvrOutgoing>)outgoing;
{	
	[self.arrowsView.northView setBusy:YES];
}

- (void) outgoingTransferDidEndSending:(id <MvrOutgoing>) outgoing;
{
	[self.arrowsView.northView setBusy:NO];
}

- (void) channel:(id <MvrChannel>) c didBeginReceivingWithIncomingTransfer:(id <MvrIncoming>) incoming;
{
	[self.delegate UIMode:self willBeginReceivingItemWithTransfer:incoming fromDirection:kMvrDirectionNorth];
}

#pragma mark Availability

- (BOOL) isAvailable;
{
	NSString* model = [UIDevice currentDevice].internalModelName;
	return ![model isEqual:@"iPod1,1"] && ![model isEqual:@"iPhone1,1"];
}

@end
