//
//  L0MoverPeering.h
//  Mover
//
//  Created by ∞ on 10/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "L0PeerDiscovery.h"

@protocol L0MoverPeerChannel, L0MoverPeerScanner;

@interface L0MoverPeering : NSObject {
	id <L0PeerDiscoveryDelegate> delegate;
	NSMutableSet* peers, * availableScanners;
	NSString* uniquePeerIdentifierForSelf;
}

+ sharedService;

// Scanners find channels to other peers. Peering bundles channels to
// the same peer together to make a single L0MoverPeer object
// that the rest of the app understands.
// When a channel to a new peer appears, a new peer is constructed and made visible
// via peerFound:.
// When the last channel to a peer disappears, the peer has left the building (er) and
// peerLeft: is called.

// The scanners that are available. Unavailable = can't ever
// be used on this device.
// Some scanners (eg Bluetooth) may start tentatively available
// but become unavailable later. (For now, no KVO supported
// on this key.)
@property(readonly) NSSet* availableScanners;

// The peers we care about. Contains L0MoverPeers.
@property(readonly) NSSet* peers;

// Hook the rest of the app here.
@property(assign) id <L0PeerDiscoveryDelegate> delegate;

// Our current peer identifier.
@property(readonly) NSString* uniquePeerIdentifierForSelf;

// Channels can call this to notify of new items.
- (void) channelWillBeginReceiving:(id <L0MoverPeerChannel>) channel;
- (void) channel:(id <L0MoverPeerChannel>) channel didReceiveItem:(L0MoverItem*) i;
- (void) channelDidCancelReceivingItem:(id <L0MoverPeerChannel>) channel;
- (void) channel:(id <L0MoverPeerChannel>) channel willSendItemToOtherEndpoint:(L0MoverItem*) i;
- (void) channel:(id <L0MoverPeerChannel>) channel didSendItemToOtherEndpoint:(L0MoverItem*) i;

// Makes a scanner unavailable.
// This makes any peers it found gone too.
- (void) makeScannerUnavailable:(id <L0MoverPeerScanner>) scanner;

@end

// Scanners and channels -------

@protocol L0MoverPeerScanner <NSObject>

// Note: UI should prevent all scanners to be off at once, or otherwise
// manage them so that the user isn't confused. No scanners = no peers ever
// found = useless app.
// New scanners start enabled, and should recuse themselves ASAP if they
// detect unavailability.
// PLEASE NOTE: enabled = NO should make all channels unavailable at once.
@property BOOL enabled;

// A jammed scanner is available but external trouble prevents
// it from working. For example, Wi-Fi may be available, enabled,
// but disconnected from a network. If all scanners are jammed,
// UI should display a warning to the user.
// Will be KVO'd.
@property(readonly) BOOL jammed;

// Will be KVO'd. Contains id <L0MoverPeerChannel>s.
@property(readonly) NSSet* availableChannels;

@end

// Someday, maybe.
/* enum {
	// Channel speed: on average, this channel...
	// (pick the one that applies the most)
	kL0MoverPeerChannelLowSpeed = 1 << 0; // high latency, or less than 10 kbps throughput
	kL0MoverPeerChannelMediumSpeed = 1 << 1; // low latency, or tp in tens of kbps
	kL0MoverPeerChannelHighSpeed = 1 << 2; // always unnoticeable latency, or tp of hundreds of kbps or more
	
	// Hops-to-destination distance
	kL0MoverDirectNetworking = 1 << 3; // point-to-point connection
	kL0MoverLinkLocalNetworking = 1 << 4; // needs an intermediary, but fast
	kL0MoverWideAreaNetworking = 1 << 5; // Internet-style hopping, basically
	
	
}; */


@protocol L0MoverPeerChannel <NSObject>

// This is pretty much what we need to make a L0MoverPeer.

// Never changes.
@property(readonly) NSString* name;

// Must be the same for different channels to the same peer.
// Never changes unless the peer fully disconnects (ie retracts
// all channels) and then reappears later with a different id.
@property(readonly, copy) NSString* uniquePeerIdentifier;

// May change. Should be set on first appaerance, but may
// be KVO'd in the future.
@property(readonly) double applicationVersion;
@property(readonly, copy) NSString* userVisibleApplicationVersion;

- (BOOL) sendItemToOtherEndpoint:(L0MoverItem*) i;

@end

