//
//  Mover3AppDelegate.h
//  Mover3
//
//  Created by ∞ on 12/09/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Network+Storage/MvrMetadataStorage.h"
#import "Network+Storage/MvrPlatformInfo.h"

#import "Network+Storage/MvrStorageCentral.h"
#import "Network+Storage/MvrItem.h"

#import "MvrTableController.h"

#import "MvrWiFiMode.h"
#import "MvrBluetoothMode.h"

#import "MvrTellAFriendController.h"
#import "MvrCrashReporting.h"

#import "MvrMessageChecker.h"

@interface MvrAppDelegate : NSObject <
	UIApplicationDelegate,
	UIActionSheetDelegate,
	MvrMetadataStorage, 
	MvrPlatformInfo>
{
    UIWindow *window;
	MvrTableController* tableController;
		
	NSString* itemsDirectory;
	MvrStorageCentral* storageCentral;
	NSDictionary* metadata;
	
	L0UUID* identifierForSelf;
	
	UIWindow* overlayWindow;
	UILabel* overlayLabel;
	UIActivityIndicatorView* overlaySpinner;
	
	MvrWiFiMode* wifiMode;
	MvrBluetoothMode* bluetoothMode;
	
	MvrTellAFriendController* tellAFriend;
	MvrCrashReporting* crashReporting;
	MvrMessageChecker* messageChecker;
}

@property(nonatomic, retain) IBOutlet UIWindow *window;
@property(nonatomic, retain) IBOutlet MvrTableController* tableController;

@property(readonly) NSString* itemsDirectory;
@property(readonly) MvrStorageCentral* storageCentral;

@property(nonatomic, retain) IBOutlet UIWindow* overlayWindow;
@property(nonatomic, retain) IBOutlet UILabel* overlayLabel;
@property(nonatomic, retain) IBOutlet UIActivityIndicatorView* overlaySpinner;

@property(nonatomic, retain) IBOutlet MvrWiFiMode* wifiMode;
@property(nonatomic, retain) IBOutlet MvrBluetoothMode* bluetoothMode;

@property(readonly) MvrTellAFriendController* tellAFriend;
@property(readonly) MvrMessageChecker* messageChecker;

- (IBAction) add;
- (void) addItemFromSelf:(MvrItem*) item;
- (void) displayActionMenuForItem:(MvrItem*) i withRemove:(BOOL) remove withSend:(BOOL) send withMainAction:(BOOL) mainAction;

- (void) presentModalViewController:(UIViewController*) ctl;

- (void) beginDisplayingOverlayViewWithLabel:(NSString*) label;
- (void) endDisplayingOverlayView;

- (IBAction) moveToBluetoothMode;
- (IBAction) moveToWiFiMode;

- (void) displaySendActionSheetForItem:(MvrItem*) i;

- (IBAction) showAboutPane;

@end

// -----

static inline MvrAppDelegate* MvrApp() {
	return (MvrAppDelegate*)([[UIApplication sharedApplication] delegate]);
}
