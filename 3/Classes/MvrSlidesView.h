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
}

- (id) initWithFrame:(CGRect) frame delegate:(id <MvrSlidesViewDelegate>) delegate;

- (void) testByAddingEmptySlide;

@property(readonly) CGRect safeArea;

@end


@protocol MvrSlidesViewDelegate <NSObject>
@optional

- (BOOL) slidesView:(MvrSlidesView*) v shouldBounceBackView:(UIView*) view;

@end