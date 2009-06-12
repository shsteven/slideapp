//
//  L0MoverPeering.m
//  Mover
//
//  Created by ∞ on 10/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0MoverPeering.h"
#import "L0MoverPeer.h"
#import "L0MoverWiFiScanner.h"
#import <MuiKit/MuiKit.h>

// Our private L0MoverPeer subclass.
// "Synthesized" from one or more channels.
@interface L0MoverSynthesizedPeer : L0MoverPeer
{
	NSString* name;
	double applicationVersion;
	NSString* userVisibleApplicationVersion;
	
	NSMutableSet* channels;
	NSString* uniquePeerIdentifier;
}

@property(readonly) NSMutableSet* channels;
@property(readonly) NSString* uniquePeerIdentifier;

@end

@implementation L0MoverSynthesizedPeer

@synthesize channels, uniquePeerIdentifier;
@synthesize name, applicationVersion, userVisibleApplicationVersion;

- (id) initWithFirstChannel:(id <L0MoverPeerChannel>) chan;
{
	NSAssert(chan, @"Chan must be nonnil");
	
	if (self = [super init]) {
		channels = [[NSMutableSet setWithObject:chan] retain];
		uniquePeerIdentifier = [chan.uniquePeerIdentifier copy];
		name = [chan.name copy];
		userVisibleApplicationVersion = [chan.userVisibleApplicationVersion copy];
		applicationVersion = chan.applicationVersion;
	}
	
	return self;
}

- (void) dealloc;
{
	[channels release];
	[uniquePeerIdentifier release];
	[userVisibleApplicationVersion release];
	[name release];
	[super dealloc];
}

- (BOOL) receiveItem:(L0MoverItem*) item;
{
	return [[self.channels anyObject] sendItemToOtherEndpoint:item];
}

@end

// ----------------------

@interface L0MoverPeering ()
+ allScanners;
- (L0MoverSynthesizedPeer*) peerWithChannel:(id <L0MoverPeerChannel>) channel;

- (void) makeChannelAvailable:(id <L0MoverPeerChannel>) channel;
- (void) makeChannelUnavailable:(id <L0MoverPeerChannel>) channel;
@end

L0UniquePointerConstant(kL0MoverPeeringObservationContext);

@implementation L0MoverPeering

L0ObjCSingletonMethod(sharedService);
@synthesize availableScanners, delegate, uniquePeerIdentifierForSelf;

- (NSSet*) peers;
{
	return peers;
}

- (id) init;
{
	if (self = [super init]) {
		availableScanners = [[NSMutableSet setWithSet:[[self class] allScanners]] retain];
		peers = [NSMutableSet new];
		uniquePeerIdentifierForSelf = [[[[L0UUID UUID] stringValue] substringWithRange:NSMakeRange(0, 2)] copy];
		
		// set up KVO
		for (id scanner in availableScanners)
			[scanner addObserver:self forKeyPath:@"availableChannels" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionInitial context:(void*) kL0MoverPeeringObservationContext];
	}
	
	return self;
}

- (void) dealloc;
{
	[availableScanners release];
	[peers release];
	[uniquePeerIdentifierForSelf release];
	[super dealloc];
}

+ allScanners;
{
	return [NSSet setWithObject:[L0MoverWiFiScanner sharedScanner]]; // TODO
}

#pragma mark Peers and channels

- (L0MoverSynthesizedPeer*) peerWithChannel:(id <L0MoverPeerChannel>) channel;
{
	for (L0MoverSynthesizedPeer* peer in peers) {
		if ([peer.uniquePeerIdentifier isEqual:channel.uniquePeerIdentifier]) {
			return peer;
		}
	}
	
	return nil;
}

- (void) channelWillBeginReceiving:(id <L0MoverPeerChannel>) channel;
{
	L0MoverSynthesizedPeer* peer = [self peerWithChannel:channel];
	[peer.delegate moverPeerWillSendUsItem:peer];
}

- (void) channel:(id <L0MoverPeerChannel>) channel didReceiveItem:(L0MoverItem*) i;
{
	L0MoverSynthesizedPeer* peer = [self peerWithChannel:channel];
	[peer.delegate moverPeer:peer didSendUsItem:i];
}

- (void) channelDidCancelReceivingItem:(id <L0MoverPeerChannel>) channel;
{
	L0MoverSynthesizedPeer* peer = [self peerWithChannel:channel];
	[peer.delegate moverPeerDidCancelSendingUsItem:peer];
}

- (void) channel:(id <L0MoverPeerChannel>) channel willSendItemToOtherEndpoint:(L0MoverItem*) i;
{
	L0MoverSynthesizedPeer* peer = [self peerWithChannel:channel];
	[peer.delegate moverPeer:peer willBeSentItem:i];
}

- (void) channel:(id <L0MoverPeerChannel>) channel didSendItemToOtherEndpoint:(L0MoverItem*) i;
{
	L0MoverSynthesizedPeer* peer = [self peerWithChannel:channel];
	[peer.delegate moverPeer:peer wasSentItem:i];
}

- (void) observeValueForKeyPath:(NSString*) keyPath ofObject:(id) object change:(NSDictionary*) change context:(void*) context;
{
	if (context != kL0MoverPeeringObservationContext) return;
	
	NSArray* inserted = nil, * removed = nil;
	// TODO
	if ([change l0_changeKind] == NSKeyValueChangeInsertion || [change l0_changeKind] == NSKeyValueChangeReplacement)
		inserted = [change l0_changedValue];
	if ([change l0_changeKind] == NSKeyValueChangeRemoval || [change l0_changeKind] == NSKeyValueChangeReplacement)
		removed = [change l0_previousValue];
	
	// inserting new channels...
	for (id <L0MoverPeerChannel> channel in inserted)
		[self makeChannelAvailable:channel];

	// removing invalid channels...
	for (id <L0MoverPeerChannel> channel in removed)
		[self makeChannelUnavailable:channel];
}

- (void) makeChannelAvailable:(id <L0MoverPeerChannel>) channel;
{
	L0Log(@"Found channel: %@", channel);
	L0MoverSynthesizedPeer* peer = [self peerWithChannel:channel];
	if (peer) {
		[peer.channels addObject:channel];
		L0Log(@"Channel: %@ added to peer: %@", channel, peer);
	} else {
		L0Log(@"Creating new peer from channel: %@", channel);
		L0MoverSynthesizedPeer* peer = [[L0MoverSynthesizedPeer alloc] initWithFirstChannel:channel];
		[peers addObject:peer];
		[self.delegate peerFound:peer];
		[peer release];
	}
}

- (void) makeChannelUnavailable:(id <L0MoverPeerChannel>) channel;
{
	L0Log(@"Lost channel: %@", channel);
	L0MoverSynthesizedPeer* peer = [self peerWithChannel:channel];
	
	if (peer) {
		[peer.channels removeObject:channel];
		L0Log(@"Channel: %@ removed from peer: %@", channel, peer);
		if ([peer.channels count] == 0) {
			L0Log(@"Channel-less peer now being removed.");
			[self.delegate peerLeft:peer];
			[peers removeObject:peer];
		}
	}
}

#pragma mark Scanners and availability

- (void) addAvailableScannersObject:(id <L0MoverPeerScanner>) scanner;
{
	scanner.service = self;
	[availableScanners addObject:scanner];
}

- (void) removeAvailableScannersObject:(id <L0MoverPeerScanner>) scanner;
{
	for (id channel in scanner.availableChannels)
		[self makeChannelUnavailable:channel];
	
	scanner.service = nil;
	[availableScanners removeObject:scanner];
}

@end