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
#import "MvrAppDelegate+HelpAlerts.h"
#import "MvrUpsellController.h"

BOOL MvrBluetoothIsAvailable() {
	NSString* model = [UIDevice currentDevice].internalModelName;
	return ![model isEqual:@"iPod1,1"] && ![model isEqual:@"iPhone1,1"];
}

#if !kMvrInstrumentForAds

@interface MvrBluetoothMode ()

- (void) sendOrConfirmItem:(MvrItem*) i toDestination:(id) destination;
- (void) startPeerPicker;

@end

enum {
	kBTAlertNoLiteToLiteReminder = 1000,
	kBTAlertVeryLarge,
};

@implementation MvrBluetoothMode

- (id) init
{
	self = [super init];
	if (self != nil) {
		scanner = [MvrBTScanner new];
		observer = [[MvrScannerObserver alloc] initWithScanner:scanner delegate:self];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(outgoingUnavailableInLite:) name:kMvrBTOutgoingUnavailableInLiteVersionNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cannotConnectToLite:) name:kMvrBTConnectionToLiteVersionBeingDroppedNotification object:nil];
	}
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[self stopPickingPeer];
	[nextDestination release];
	[nextItem release];
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

#if kMvrIsLite
	UIAlertView* alert = [MvrApp() alertIfNotShownBeforeNamed:@"MvrNoLiteToLiteBTReminder"];
	if (alert) {
		alert.tag = kBTAlertNoLiteToLiteReminder;
		alert.delegate = self;
		[alert show];
		return;
	}
#endif
		
	[self startPeerPicker];
}

- (void) startPeerPicker;
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
#if kMvrIsLite
	self.arrowsView.northView.arrowView.hidden = YES;
#endif
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
	
	[self sendOrConfirmItem:i toDestination:self.northDestination];
}

- (void) sendItem:(MvrItem*) i toDestination:(id) destination;
{
	if (self.northDestination != destination)
		return;
	
	[self sendOrConfirmItem:i toDestination:destination];
}

- (void) sendOrConfirmItem:(MvrItem*) i toDestination:(id) destination;
{	
	if (i.storage.contentLength >= 1024 * 1024) {
		if (nextDestination || nextItem)
			return;
		
		nextDestination = [destination retain];
		nextItem = [i retain];
		
		UIAlertView* alert = [UIAlertView alertNamed:@"MvrLargeItemOverBT"];
		alert.tag = kBTAlertVeryLarge;
		alert.cancelButtonIndex = 1;
		alert.delegate = self;
		[alert show];
	} else
		[destination beginSendingItem:i];
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
{
	switch (alertView.tag) {
		case kBTAlertNoLiteToLiteReminder:
			[self startPeerPicker];
			return;
			
		case kBTAlertVeryLarge: {
			if (buttonIndex != alertView.cancelButtonIndex)
				[nextDestination beginSendingItem:nextItem];
			
			[nextDestination release]; nextDestination = nil;
			[nextItem release]; nextItem = nil;
		}
			
			return;
	}
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
	return MvrBluetoothIsAvailable();
}

#pragma mark Lite version limitations

- (void) outgoingUnavailableInLite:(NSNotification*) n;
{
#if kMvrIsLite
	[[MvrUpsellController upsellWithAlertNamed:@"MvrNoBTOutgoingInLite" cancelButton:0] show];
#endif
}

- (void) cannotConnectToLite:(NSNotification*) n;
{
#if kMvrIsLite
	[[MvrUpsellController upsellWithAlertNamed:@"MvrNoLiteToLiteBT" cancelButton:0] show];
#endif
}

@end

#endif // #if !kMvrInstrumentForAds