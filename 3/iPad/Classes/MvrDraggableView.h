//
//  MvrDraggableView.h
//  Mover3-iPad
//
//  Created by ∞ on 21/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MvrInertia_Old.h"

@protocol MvrDraggableViewDelegate;

@interface MvrDraggableView : UIView {
	CGPoint startingCenter;
	CGAffineTransform startingTransform;
	
	MvrInertia_Old* inertia;
	
	id <MvrDraggableViewDelegate> delegate;
}

@property(assign) id <MvrDraggableViewDelegate> delegate;

@end



@protocol MvrDraggableViewDelegate <NSObject>

// Sent whenever a touch begins on the view.
- (void) draggableViewDidBeginTouching:(MvrDraggableView*) view;

// Sent as often as possible during a drag.
- (void) draggableViewCenterDidMove:(MvrDraggableView*) view;

// Sent when the view stops moving.
- (void) draggableViewCenterDidStopMoving:(MvrDraggableView*) view velocity:(CGPoint) velocity;


@end
