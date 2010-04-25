//
//  MvrDraggableView.h
//  Mover3-iPad
//
//  Created by ∞ on 21/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MvrInertia.h"

@protocol MvrDraggableViewDelegate;

@interface MvrDraggableView : UIView {
	CGPoint startingCenter;
	CGAffineTransform startingTransform;
	
	MvrInertia* inertia;
	
	id <MvrDraggableViewDelegate> delegate;
}

@property(assign) id <MvrDraggableViewDelegate> delegate;

@end



@protocol MvrDraggableViewDelegate <NSObject>

// Sent as often as possible during a drag.
- (void) draggableViewCenterDidMove:(MvrDraggableView*) view;

// Sent when the view stops moving.
- (void) draggableViewCenterDidStopMoving:(MvrDraggableView*) view;

@end
