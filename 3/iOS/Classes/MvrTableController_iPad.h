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

#import "MvrProgressReportPart.h"

enum {
	kMvrItemSourceUnknown, // source is ignored
	kMvrItemSourceSelf, // source is ignored
	kMvrItemSourceChannel, // source is a id <MvrChannel>
};
typedef NSInteger MvrItemSourceType;

@interface MvrTableController_iPad : ILViewController <MvrItemsTable, MvrScannerObserverDelegate, MvrAddPaneDelegate, MvrProgressReportPartDelegate, UIPopoverControllerDelegate> {
	BOOL inited;
	
	IBOutlet UIImageView* backdropImageView;
	IBOutlet UIView* bluetoothControlsView;
	
	IBOutlet UIView* draggableViewsLayer;
	IBOutlet UIView* arrowsLayer;
	
	NSMutableSet* itemControllersSet;
	
	L0Map* arrowViewsByChannel;
	NSMutableArray* orderedArrowViews;
	
	L0KVODispatcher* appObserver;
	MvrScannerObserver* currentObserver;
	
	UIPopoverController* addPopover, * aboutPopover, * networkPopover;
	IBOutlet UIBarButtonItem* networkBarItem;
	
	BOOL askDeleteIsShown;
	
	MvrProgressReportPart* progressReportPart;
	BOOL isHidingProgressReport;
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

- (IBAction) showNetworkPopover:(UIBarButtonItem*) sender;

- (IBAction) backToWiFi;
- (IBAction) reconnectBluetooth;

@end

