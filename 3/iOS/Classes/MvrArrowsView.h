//
//  MvrArrowsView.h
//  Mover3
//
//  Created by ∞ on 22/09/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MvrArrowView.h"
#import "MvrSlidesView.h" // for MvrDirection

@interface MvrArrowsView : UIView {
	MvrArrowView* northView;
	MvrArrowView* eastView;
	MvrArrowView* westView;
}

// setting when the corresponding view is nil creates the view and adds it to its proper position.
// setting to nil hides the corresponding view.
// both are animated.
- (void) setNorthViewLabel:(NSString*) label;
- (void) setEastViewLabel:(NSString*) label;
- (void) setWestViewLabel:(NSString*) label;

@property(readonly, retain) MvrArrowView* northView;
@property(readonly, retain) MvrArrowView* eastView;
@property(readonly, retain) MvrArrowView* westView;

- (MvrArrowView*) viewAtDirection:(MvrDirection) d;

@end
