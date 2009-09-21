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

@interface MvrTableController : UIViewController <MvrSlidesViewDelegate> {
	UIView* hostView;
	UIView* backdropStratum;
	MvrSlidesView* slidesStratum;
	UIToolbar* toolbar;
	
	L0Map* itemsToViews, * viewsToItems;
}

- (void) setUp;

@property(retain) IBOutlet UIView* backdropStratum;
@property(retain) IBOutlet UIView* hostView;
@property(retain) IBOutlet UIToolbar* toolbar;

@property(retain) MvrSlidesView* slidesStratum;

- (void) addItem:(MvrItem*) i animated:(BOOL) ani;

- (void) setEditing:(BOOL) editing animated:(BOOL) animated;

@end
