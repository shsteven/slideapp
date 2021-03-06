//
//  L0BeamingPeer.h
//  Shard
//
//  Created by ∞ on 24/03/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "L0MoverItem.h"

#define kL0UnknownApplicationVersion (0.0)

@protocol L0MoverPeerDelegate;

@interface L0MoverPeer : NSObject {
	id <L0MoverPeerDelegate> delegate;
}

@property(readonly) NSString* name;
@property(assign) id <L0MoverPeerDelegate> delegate;
@property(readonly) double applicationVersion;
@property(readonly, copy) NSString* userVisibleApplicationVersion;

- (BOOL) receiveItem:(L0MoverItem*) item;

@end

@protocol MvrIncoming <NSObject>

// All properties MUST provide KVO notifications.
// An incoming transfer is complete whenever its .item property is set to the received item; or whenever the .canceled property is set to YES, whichever comes first.
@property(readonly) L0MoverItem* item;
@property(readonly, getter=isCancelled) BOOL cancelled;

// Reports on progress. 0.0-1.0 inclusive or kMvrPacketIndeterminateProgress to indicate progress is unknown.
@property(readonly) CGFloat progress;

@optional

// Manually cancels the arrival. Canceling must be signaled by setting .canceled to YES (and notified via KVO).
- (void) cancel;

@end

@protocol L0MoverPeerDelegate <NSObject>

- (void) moverPeer:(L0MoverPeer*) peer willBeSentItem:(L0MoverItem*) item;
- (void) moverPeer:(L0MoverPeer*) peer wasSentItem:(L0MoverItem*) item;

- (void) moverPeer:(L0MoverPeer*) peer didStartReceiving:(id <MvrIncoming>) incomingTransfer;
@end
