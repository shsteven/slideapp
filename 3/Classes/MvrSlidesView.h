//
//  MvrSlidesView.h
//  Mover3
//
//  Created by ∞ on 18/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <MuiKit/MuiKit.h>

@protocol MvrSlidesViewDelegate;

enum {
	kMvrDirectionNone,
	kMvrDirectionNorth,
	kMvrDirectionEast,
	kMvrDirectionWest,
	kMvrDirectionSouth,
};
typedef NSUInteger MvrDirection;


@interface MvrSlidesView : UIView <L0DraggableViewDelegate> {
	id <MvrSlidesViewDelegate> delegate;
	
#if DEBUG
	UIView* shownArea;
#endif
}

- (id) initWithFrame:(CGRect) frame delegate:(id <MvrSlidesViewDelegate>) delegate;

- (void) addDraggableSubviewWithoutAnimation:(L0DraggableView*)view;
- (void) addDraggableSubview:(L0DraggableView *)view enteringFromDirection:(MvrDirection) d;

- (void) removeDraggableSubviewByFadingAway:(L0DraggableView *)view;

- (void) setEditing:(BOOL) editing animated:(BOOL) animated;

#if DEBUG
- (void) showArea:(CGRect) area;
#endif

- (MvrDirection) directionForCurrentPositionOfView:(L0DraggableView*) v;
- (void) bounceBack:(UIView*) v;

@end


@protocol MvrSlidesViewDelegate <NSObject>

- (void) slidesView:(MvrSlidesView*) v subviewDidMove:(L0DraggableView*) view inBounceBackAreaInDirection:(MvrDirection) d;

@end