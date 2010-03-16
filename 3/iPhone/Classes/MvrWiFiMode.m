//
//  MvrWiFiMode.m
//  Mover3
//
//  Created by ∞ on 22/09/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#if !kMvrInstrumentForAds

#import "MvrWiFiMode.h"

#import <QuartzCore/QuartzCore.h>

#import "Network+Storage/MvrModernWiFi.h"
#import "Network+Storage/MvrLegacyWiFi.h"
#import "Network+Storage/MvrChannel.h"

#import "MvrAppDelegate.h"
#import "MvrAppDelegate+HelpAlerts.h"

#if kMvrIsLite
#import "MvrUpsellController.h"
#import "MvrImageItem.h"
#import "MvrContactItem.h"

static inline BOOL MvrWiFiModeShouldContinueSendingItemAfterLiteWarning(MvrItem* i) {
//	if (![i isKindOfClass:[MvrImageItem class]] && ![i isKindOfClass:[MvrContactItem class]]) {
//		[[MvrUpsellController upsellWithAlertNamed:@"MvrNoNewItemSendingInLite" cancelButton:0] show];
//		return NO;
//	} else
//		return YES;
	
	return YES;
}

#endif

@implementation MvrWiFiMode

@synthesize connectionStateInfo, connectionStateImage, connectionStateContainer, bluetoothButtonView;

- (Class) scannerClass;
{
	return [MvrWiFi class];
}

- (void) awakeFromNib;
{
	MvrModernWiFiOptions opts = kMvrUseMobileService;
	
#if !kMvrIsLite
	opts |= kMvrAllowBrowsingForConduitService;
#endif
	
	wifi = [[[self scannerClass] alloc] initWithPlatformInfo:MvrApp() modernPort:kMvrModernWiFiPort legacyPort:kMvrLegacyWiFiPort modernOptions:opts];
	observer = [[MvrScannerObserver alloc] initWithScanner:wifi delegate:self];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
	
	if (!MvrApp().bluetoothMode.available) {
		CGRect frame = connectionStateDrawerView.frame;
		frame.size.height -= bluetoothButtonView.frame.size.height;
		connectionStateDrawerView.frame = frame;
		[bluetoothButtonView removeFromSuperview];
		bluetoothButtonView = nil;
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyOfNetworkTrouble:) name:kMvrLegacyWiFiDifficultyStartingListenerNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyOfNetworkTrouble:) name:kMvrModernWiFiDifficultyStartingListenerNotification object:nil];
	
	if (self.delegate) // we're on!
		wifi.enabled = YES;
}

- (void) notifyOfNetworkTrouble:(NSNotification*) n;
{
	[MvrApp() showAlertIfNotShownThisSessionNamed:@"MvrNetworkTrouble"];
}

- (void) dealloc;
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[observer release];

	[wifi release];
	[super dealloc];
}

#pragma mark Jamming

- (void) scanner:(id <MvrScanner>)s didChangeJammedKey:(BOOL)jammed;
{
	if (!jammed) {
		
		self.connectionStateInfo.text = NSLocalizedString(@"Wi-Fi On", @"Wi-Fi unjammed text");
		self.connectionStateImage.image = [UIImage imageNamed:@"GreenDot.png"];
		
	} else {
		
		self.connectionStateInfo.text = NSLocalizedString(@"Wi-Fi Disconnected", @"Wi-Fi jammed text");
		self.connectionStateImage.image = [UIImage imageNamed:@"RedDot.png"];
		
	}
	
	[self.connectionStateContainer setAccessibilityValue:self.connectionStateInfo.text];
	self.delegate.shouldKeepConnectionDrawerVisible = jammed;
}

#pragma mark Channels

- (void) scanner:(id <MvrScanner>) s didAddChannel:(id <MvrChannel>) channel;
{
	[self.mutableDestinations addObject:channel];
}

- (void) scanner:(id <MvrScanner>) s didRemoveChannel:(id <MvrChannel>) channel;			
{
	[self.mutableDestinations removeObject:channel];
}

- (NSString*) displayNameForDestination:(id) dest;
{
	return [dest displayName];
}

- (void) channel:(id <MvrChannel>)c didChangeSupportsStreamsKey:(BOOL)supportsStreams;
{
	MvrArrowView* arrow = [self arrowViewForDestination:c];
	
	CATransition* fade = [CATransition animation];
	fade.type = kCATransitionFade;
	[arrow.nameLabel.layer addAnimation:fade forKey:@"MvrWiFiModeStreamSupportFade"];
	arrow.normalColor = supportsStreams? [UIColor blackColor] : [UIColor grayColor];
	arrow.nameLabel.textColor = arrow.normalColor;
}

#pragma mark Sending items

- (void) sendItem:(MvrItem*) i toDestinationAtDirection:(MvrDirection) dest;
{
#if kMvrIsLite
	if (!MvrWiFiModeShouldContinueSendingItemAfterLiteWarning(i))
		return;
#endif
	[[self destinationAtDirection:dest] beginSendingItem:i];
}

- (void) sendItem:(MvrItem*) i toDestination:(id) destination;
{
	if (![self.mutableDestinations containsObject:destination])
		return;
	
#if kMvrIsLite
	if (!MvrWiFiModeShouldContinueSendingItemAfterLiteWarning(i))
		return;
#endif

	[destination beginSendingItem:i];
}

- (void) channel:(id <MvrChannel>)c didBeginSendingWithOutgoingTransfer:(id <MvrOutgoing>)outgoing;
{
	MvrDirection dir = [self directionForDestination:c];
	if (dir == kMvrDirectionNone)
		return;
	
	[[self.arrowsView viewAtDirection:dir] setBusy:YES];
}

- (void) outgoingTransferDidEndSending:(id <MvrOutgoing>) outgoing;
{
	const MvrDirection directions[] = { kMvrDirectionNorth, kMvrDirectionEast, kMvrDirectionWest };
	const size_t directionsCount = 3;
	
	int i;
	for (i = 0; i < directionsCount; i++) {
		
		id dest = [self destinationAtDirection:directions[i]];
		if (!dest)
			continue;
		
		[[self.arrowsView viewAtDirection:directions[i]] setBusy:([[dest outgoingTransfers] count] > 0)];
	}
}

#pragma mark Receiving items

- (void) channel:(id <MvrChannel>) c didBeginReceivingWithIncomingTransfer:(id <MvrIncoming>) incoming;
{
	[self.delegate UIMode:self willBeginReceivingItemWithTransfer:incoming fromDirection:[self directionForDestination:c]];
}

#pragma mark Enabling/disabling

- (void) modeDidBecomeCurrent:(BOOL) ani;
{
	wifi.enabled = YES;
	delegate.shouldKeepConnectionDrawerVisible = wifi.jammed;
}

- (void) modeWillStopBeingCurrent:(BOOL)animated;
{
	wifi.enabled = NO;
}

- (void) willResignActive:(NSNotification*) n;
{
	wifi.enabled = NO;
}

- (void) didBecomeActive:(NSNotification*) n;
{
	if (self.delegate)
		wifi.enabled = YES;
}

@end

#endif // #if !kMvrInstrumentForAds