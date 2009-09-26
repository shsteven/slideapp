//
//  MvrUIMode.h
//  Mover3
//
//  Created by ∞ on 22/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MvrArrowsView.h"
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
}

@property(assign) id <MvrUIModeDelegate> delegate;

@property(retain) IBOutlet UIView* backdropStratum;
@property(retain) IBOutlet UIView* arrowsStratum;
@property(readonly) MvrArrowsView* arrowsView;

@property(readonly) NSMutableArray* mutableDestinations;
- (NSString*) displayNameForDestination:(id) destination;

@property(retain) id northDestination;
@property(retain) id eastDestination;
@property(retain) id westDestination;

- (void) sendItem:(MvrItem*) i toDestinationAtDirection:(MvrDirection) dest;
- (id) destinationAtDirection:(MvrDirection) d;
- (MvrDirection) directionForDestination:(id) d;

@end


@protocol MvrUIModeDelegate <NSObject>

- (void) UIMode:(MvrUIMode*) mode didFinishSendingItem:(MvrItem*) i;
- (void) UIMode:(MvrUIMode*) mode willBeginReceivingItemWithTransfer:(id <MvrIncoming>) i fromDirection:(MvrDirection) d;

@end
