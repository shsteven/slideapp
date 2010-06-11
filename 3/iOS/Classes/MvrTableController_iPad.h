//
//  Mover3_iPadViewController.h
//  Mover3-iPad
//
//  Created by ∞ on 14/04/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MuiKit/MuiKit.h>

#import "ILViewController.h"
#import "MvrDraggableView.h"
#import "MvrItemController.h"
#import "Network+Storage/MvrItem.h"

#import "MvrAddPane.h"

#import "Network+Storage/MvrScannerObserver.h"

enum {
	kMvrItemSourceUnknown, // source is ignored
	kMvrItemSourceSelf, // source is ignored
	kMvrItemSourceChannel, // source is a id <MvrChannel>
};
typedef NSInteger MvrItemSourceType;

@interface MvrTableController_iPad : ILViewController <MvrItemsTable, MvrScannerObserverDelegate, MvrAddPaneDelegate> {
	IBOutlet UIView* draggableViewsLayer;
	IBOutlet UIView* arrowsLayer;
	
	NSMutableSet* itemControllers;
	
	L0Map* arrowViewsByChannel;
	NSMutableArray* orderedArrowViews;
	
	MvrScannerObserver* obs;
	
	UIPopoverController* addPopover, * aboutPopover;
	
	BOOL askDeleteIsShown;
}

- (void) addItem:(MvrItem*) item fromSource:(id) source ofType:(MvrItemSourceType) type;
- (void) removeItem:(MvrItem*) item;

// TODO private?
- (void) addDraggableView:(MvrDraggableView*) v;

@property(readonly) NSSet* itemControllers;
- (void) addItemController:(MvrItemController*) ic;
- (void) removeItemController:(MvrItemController*) ic;

- (IBAction) showAddPopover:(UIBarButtonItem*) sender;
- (IBAction) askForDeleteAll:(UIBarButtonItem*) sender;

- (IBAction) showAboutPane:(UIButton*) infoButton;

@end

