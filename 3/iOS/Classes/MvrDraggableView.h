//
//  MvrDraggableView.h
//  Mover3-iPad
//
//  Created by ∞ on 21/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MvrDraggableViewDelegate;

@interface MvrDraggableView : UIView {
	CGPoint startingCenter;
	CGAffineTransform startingTransform;
	
	id <MvrDraggableViewDelegate> delegate;
	
	BOOL draggingDisabledOnScrollViews;
}

@property(assign) id <MvrDraggableViewDelegate> delegate;

// If YES, panning gestures on scroll views that have scroll enabled will not cause the view to be dragged. By default NO to prevent performance trouble.
@property(assign) BOOL draggingDisabledOnScrollViews;

@end



@protocol MvrDraggableViewDelegate <NSObject>

// Sent whenever a touch begins on the view.
- (void) draggableViewDidBeginTouching:(MvrDraggableView*) view;

// Sent as often as possible during a drag.
- (void) draggableViewCenterDidMove:(MvrDraggableView*) view;

// Sent when the view stops moving.
- (void) draggableViewCenterDidStopMoving:(MvrDraggableView*) view velocity:(CGPoint) velocity;


@end
