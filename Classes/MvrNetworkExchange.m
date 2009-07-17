//
//  L0MoverPeering.m
//  Mover
//
//  Created by ∞ on 10/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrNetworkExchange.h"
#import "L0MoverPeer.h"

#import "L0MoverWiFiScanner.h"
#import "L0MoverWiFiChannel.h"

#import "L0MoverBluetoothScanner.h"

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
	// return [[self.channels anyObject] sendItemToOtherEndpoint:item];
	id <L0MoverPeerChannel> selectedChan;
	for (id <L0MoverPeerChannel> chan in self.channels) {
		selectedChan = chan;
		if ([chan isKindOfClass:[L0MoverWiFiChannel class]])
			break;
	}
	
	return [selectedChan sendItemToOtherEndpoint:item];
}

- (void) addChannel:(id <L0MoverPeerChannel>) channel;
{
	NSMutableSet* oldChans = [NSMutableSet set];
	for (id chan in self.channels) {
		if ([chan isKindOfClass:[channel class]])
			[oldChans addObject:chan];
	}
	
	[self.channels minusSet:oldChans];
	[self.channels addObject:channel];
}

- (NSString*) description;
{
	return [NSString stringWithFormat:@"%@ uid = %@, with channels = %@",
			[super description], self.uniquePeerIdentifier, self.channels];
}

@end

// ----------------------

@interface MvrNetworkExchange ()
+ allScanners;
- (L0MoverSynthesizedPeer*) peerWithChannel:(id <L0MoverPeerChannel>) channel;

- (void) makeChannelAvailable:(id <L0MoverPeerChannel>) channel;
- (void) makeChannelUnavailable:(id <L0MoverPeerChannel>) channel;
@end

// L0UniquePointerConstant(kL0MoverPeeringObservationContext);

@implementation MvrNetworkExchange

L0ObjCSingletonMethod(sharedExchange);
@synthesize delegate, uniquePeerIdentifierForSelf;

- (NSSet*) availableScanners;
{
	return scanners;
}

- (NSSet*) peers;
{
	return peers;
}

#define kL0MoverSelfUniqueIDKey @"L0MoverSelfUniqueID"

- (id) init;
{
	if (self = [super init]) {
		dispatcher = [[L0KVODispatcher alloc] initWithTarget:self];
		scanners = [NSMutableSet new];
		peers = [NSMutableSet new];
		
		NSString* selfId = [[NSUserDefaults standardUserDefaults] stringForKey:kL0MoverSelfUniqueIDKey];
		if (!selfId) {
			selfId = [[[L0UUID UUID] stringValue] substringWithRange:NSMakeRange(0, 5)];
			[[NSUserDefaults standardUserDefaults] setObject:selfId forKey:kL0MoverSelfUniqueIDKey];
		}
		
		uniquePeerIdentifierForSelf = [selfId copy];
	}
	
	return self;
}

- (void) dealloc;
{
	[dispatcher release];
	[scanners release];
	[peers release];
	[uniquePeerIdentifierForSelf release];
	[super dealloc];
}

+ allScanners;
{
	return [NSSet setWithObjects:[L0MoverWiFiScanner sharedScanner], [L0MoverBluetoothScanner sharedScanner], nil];
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
	L0Log(@"%@", channel);
	L0MoverSynthesizedPeer* peer = [self peerWithChannel:channel];
	[peer.delegate moverPeerWillSendUsItem:peer];
}

- (void) channel:(id <L0MoverPeerChannel>) channel didReceiveItem:(L0MoverItem*) i;
{
	L0Log(@"%@ --> %@ --> us", channel, i);
	L0MoverSynthesizedPeer* peer = [self peerWithChannel:channel];
	[peer.delegate moverPeer:peer didSendUsItem:i];
}

- (void) channelDidCancelReceivingItem:(id <L0MoverPeerChannel>) channel;
{
	L0Log(@"%@ --X--> us", channel);
	L0MoverSynthesizedPeer* peer = [self peerWithChannel:channel];
	[peer.delegate moverPeerDidCancelSendingUsItem:peer];
}

- (void) channel:(id <L0MoverPeerChannel>) channel willSendItemToOtherEndpoint:(L0MoverItem*) i;
{
	L0Log(@"us -- %@ --> %@", i, channel);
	L0MoverSynthesizedPeer* peer = [self peerWithChannel:channel];
	[peer.delegate moverPeer:peer willBeSentItem:i];
}

- (void) channel:(id <L0MoverPeerChannel>) channel didSendItemToOtherEndpoint:(L0MoverItem*) i;
{
	L0Log(@"us -- done --> (%@) %@", i, channel);
	L0MoverSynthesizedPeer* peer = [self peerWithChannel:channel];
	[peer.delegate moverPeer:peer wasSentItem:i];
}

- (void) availableChannelsOfObject:(id <L0MoverPeerScanner>) s changed:(NSDictionary*) change;
{
	NSArray* inserted = nil, * removed = nil;
	// TODO
	if (L0KVOChangeKind(change) == NSKeyValueChangeInsertion || L0KVOChangeKind(change) == NSKeyValueChangeReplacement)
		inserted = L0KVOChangedValue(change);
	if (L0KVOChangeKind(change) == NSKeyValueChangeRemoval || L0KVOChangeKind(change) == NSKeyValueChangeReplacement)
		removed = L0KVOPreviousValue(change);
	
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
		[peer addChannel:channel];
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
	// set up KVO
	const NSKeyValueObservingOptions options = NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld|NSKeyValueObservingOptionInitial;

	[dispatcher observe:@"availableChannels" ofObject:scanner usingSelector:@selector(availableChannelsOfObject:changed:) options:options];
	[dispatcher observe:@"enabled" ofObject:scanner usingSelector:@selector(enabledOrJammedOfObject:changed:) options:options];
	[dispatcher observe:@"jammed" ofObject:scanner usingSelector:@selector(enabledOrJammedOfObject:changed:) options:options];
	
	scanner.service = self;
	[scanners addObject:scanner];
}

- (void) removeAvailableScannersObject:(id <L0MoverPeerScanner>) scanner;
{
	for (id channel in scanner.availableChannels)
		[self makeChannelUnavailable:channel];
	
	scanner.enabled = NO;
	scanner.service = nil;
	[scanners removeObject:scanner];
	
	[dispatcher endObserving:@"availableChannels" ofObject:scanner];
	[dispatcher endObserving:@"enabled" ofObject:scanner];
	[dispatcher endObserving:@"jammed" ofObject:scanner];
}

- (BOOL) disconnected;
{
	for (id <L0MoverPeerScanner> s in scanners) {
		if (s.enabled && !s.jammed)
			return NO;
	}
	
	return YES;
}

- (void) enabledOrJammedOfObject:(id) o changed:(NSDictionary*) change;
{
	if (L0KVOIsPrior(change))
		[self willChangeValueForKey:@"disconnected"];
	else
		[self didChangeValueForKey:@"disconnected"];	
}

@end