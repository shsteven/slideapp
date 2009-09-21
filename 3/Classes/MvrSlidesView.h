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


@interface MvrSlidesView : UIView <L0DraggableViewDelegate> {
	id <MvrSlidesViewDelegate> delegate;
	
#if DEBUG
	UIView* shownArea;
#endif
}

- (id) initWithFrame:(CGRect) frame delegate:(id <MvrSlidesViewDelegate>) delegate;

- (void) addDraggableSubviewWithoutAnimation:(L0DraggableView*)view;
- (void) addDraggableSubviewFromSouth:(L0DraggableView *)view;

- (void) setEditing:(BOOL) editing animated:(BOOL) animated;

#if DEBUG
- (void) showArea:(CGRect) area;
#endif

@end


@protocol MvrSlidesViewDelegate <NSObject>
@optional

- (BOOL) slidesView:(MvrSlidesView*) v shouldBounceBackView:(UIView*) view;

@end