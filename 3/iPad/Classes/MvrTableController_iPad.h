//
//  Mover3_iPadViewController.h
//  Mover3-iPad
//
//  Created by ∞ on 14/04/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ILViewController.h"
#import "MvrDraggableView.h"
#import "MvrItemViewController.h"

@interface MvrTableController_iPad : ILViewController <MvrDraggableViewDelegate> {
	IBOutlet UIView* draggableViewsLayer;
	
	NSMutableSet* itemControllers;
}

// TODO private?
- (void) addDraggableView:(MvrDraggableView*) v;

@property(readonly) NSSet* itemControllers;
- (void) addItemController:(MvrItemViewController*) ic;
- (void) removeItemController:(MvrItemViewController*) ic;

@end

