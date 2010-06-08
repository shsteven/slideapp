//
//  MvrShadowBackdropDraggableView.h
//  Mover3-iPad
//
//  Created by ∞ on 01/05/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MvrDraggableView.h"

@interface MvrShadowBackdropDraggableView : MvrDraggableView {
	UIColor* contentAreaBackgroundColor;
}

@property(retain) UIColor* contentAreaBackgroundColor;
@property(readonly) CGFloat margin;
@property(readonly) CGRect contentBounds;

@end

