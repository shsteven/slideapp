//
//  MvrTableController.h
//  Mover3
//
//  Created by ∞ on 18/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MuiKit/MuiKit.h>

#import "MvrSlidesView.h"
#import "Network+Storage/MvrItem.h"

#import "MvrUIMode.h"

@interface MvrTableController : UIViewController <MvrSlidesViewDelegate, MvrUIModeDelegate> {
	UIView* hostView;
	MvrSlidesView* slidesStratum;
	UIToolbar* toolbar;
	MvrUIMode* currentMode;
	UIImageView* shadowView;
	
	L0Map* itemsToViews, * viewsToItems, * transfersToViews;
	
	L0KVODispatcher* kvo;
	
	UIView* currentDrawerView;
}

- (void) setUp;

@property(retain) IBOutlet MvrUIMode* currentMode;

@property(retain) IBOutlet UIView* hostView;
@property(retain) IBOutlet UIToolbar* toolbar;

@property(retain) MvrSlidesView* slidesStratum;

@property(retain) IBOutlet UIImageView* shadowView;

- (void) addItem:(MvrItem*) i animated:(BOOL) ani;
- (void) removeItem:(MvrItem*) item;

- (void) didEndDisplayingActionMenuForItem:(MvrItem*) i;

- (void) setEditing:(BOOL) editing animated:(BOOL) animated;

- (IBAction) testByRemovingDrawer;

@end
