//
//  MvrUIMode.h
//  Mover3
//
//  Created by ∞ on 22/09/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MvrArrowsView.h"
#import "MvrArrowView.h"
#import "MvrSlidesView.h" // for MvrDirection

#import "Network+Storage/MvrIncoming.h"
#import "Network+Storage/MvrItem.h"

@class MvrItem;
@protocol MvrUIModeDelegate;


@interface MvrUIMode : NSObject {
	UIView* backdropStratum;
	UIView* arrowsStratum;
	
	NSMutableArray* destinations;
	id northDestination, eastDestination, westDestination;
	id <MvrUIModeDelegate> delegate;
  UIView * connectionStateDrawerView;
}

@property(assign) id <MvrUIModeDelegate> delegate;

@property(retain) IBOutlet UIView* backdropStratum;
@property(retain) IBOutlet UIView* arrowsStratum;
@property(readonly) MvrArrowsView* arrowsView;

@property(retain) IBOutlet UIView* connectionStateDrawerView;

@property(readonly) NSMutableArray* mutableDestinations;
- (NSString*) displayNameForDestination:(id) destination;

@property(retain) id northDestination;
@property(retain) id eastDestination;
@property(retain) id westDestination;

- (void) sendItem:(MvrItem*) i toDestinationAtDirection:(MvrDirection) dest;
- (void) sendItem:(MvrItem*) i toDestination:(id) destination;
- (id) destinationAtDirection:(MvrDirection) d;
- (MvrDirection) directionForDestination:(id) d;
- (MvrArrowView*) arrowViewForDestination:(id) d;

- (void) modeWillBecomeCurrent:(BOOL) animated;
- (void) modeDidBecomeCurrent:(BOOL) animated;

- (void) modeWillStopBeingCurrent:(BOOL) animated;
- (void) modeDidStopBeingCurrent:(BOOL) animated;

@end


@protocol MvrUIModeDelegate <NSObject>

- (void) UIMode:(MvrUIMode*) mode didFinishSendingItem:(MvrItem*) i;
- (void) UIMode:(MvrUIMode*) mode willBeginReceivingItemWithTransfer:(id <MvrIncoming>) i fromDirection:(MvrDirection) d;

@property BOOL shouldKeepConnectionDrawerVisible;

- (void) UIMode:(MvrUIMode*) mode didAddDestination:(id) destination atDirection:(MvrDirection) d;
- (void) UIMode:(MvrUIMode*) mode didRemoveDestination:(id) destination atDirection:(MvrDirection) d;

@end
