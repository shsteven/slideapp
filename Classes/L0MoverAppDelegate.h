//
//  ShardAppDelegate.h
//  Shard
//
//  Created by ∞ on 21/03/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <MessageUI/MessageUI.h>

#import "L0MoverItemsTableController.h"
#import "L0PeerDiscovery.h"
#import "MvrNetworkExchange.h"
#import "L0MoverPeer.h"

#import "L0MoverAboutPane.h"

#import "L0MoverNetworkCalloutController.h"

#define L0Mover ((L0MoverAppDelegate*) UIApp.delegate)

@interface L0MoverAppDelegate : NSObject <UIApplicationDelegate, L0PeerDiscoveryDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, ABPeoplePickerNavigationControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate, MFMailComposeViewControllerDelegate> {
    UIWindow *window;
	
	L0MoverItemsTableController* tableController;
	UIView* tableHostView;
	L0FlipViewController* tableHostController;
	L0MoverAboutPane* aboutPane;
	
	NSString* documentsDirectory;
	
	UIToolbar* toolbar;
	UIView* networkUnavailableView;
	CGPoint networkUnavailableViewStartingPosition;
	
	double lastSeenVersion;
	L0MoverNetworkCalloutController* networkCalloutController;
	
	UIView* shieldView;
	UIActivityIndicatorView* shieldViewSpinner;
	UILabel* shieldViewLabel;
	
	UIBarStyle barStyleBeforeShowingShieldView;
	
	L0KVODispatcher* dispatcher;
}

@property(retain) IBOutlet UIWindow* window;
@property(retain) IBOutlet UIView* tableHostView;
@property(retain) IBOutlet UIToolbar* toolbar;

@property(retain) IBOutlet L0FlipViewController* tableHostController;
@property(retain) L0MoverItemsTableController* tableController;

@property(assign) IBOutlet L0MoverAboutPane* aboutPane;

@property(retain) IBOutlet L0MoverNetworkCalloutController* networkCalloutController;
- (IBAction) showNetworkCallout;
- (void) showNetworkSettingsPane;

@property(retain) IBOutlet UIView* shieldView;
@property(assign) IBOutlet UIActivityIndicatorView* shieldViewSpinner;
@property(assign) IBOutlet UILabel* shieldViewLabel;
- (void) beginShowingShieldViewWithText:(NSString*) text;
- (void) endShowingShieldView;

- (IBAction) addItem;
- (void) addImageItem;
- (void) takeAPhotoAndAddImageItem;
- (void) addAddressBookItem;

- (IBAction) testBySendingItemToAnyPeer;

@property(readonly, copy) NSString* documentsDirectory;

- (void) tellAFriend;

- (void) beginShowingActionMenuForItem:(L0MoverItem*) i includeRemove:(BOOL) r;
- (BOOL) performMainActionForItem:(L0MoverItem*) i;

- (void) finishPerformingMainAction;

- (void) startAdvertisementsInView:(UIView*) view;
- (void) stopAdvertisements;

- (void) presentModalViewController:(UIViewController*) vc;

- (void) setEnabledDefault:(BOOL) e forScanner:(id <L0MoverPeerScanner>) s;
- (BOOL) isScannerEnabled:(id <L0MoverPeerScanner>) s;
- (NSString*) defaultsKeyForDisablingScanner:(id <L0MoverPeerScanner>) s;

- (void) showNetworkHelpPane;
- (void) showNetworkSettingsPane;

- (void) askWhetherToClearTable;
- (void) clearTable;

@end

#if L0MoverAppDelegateAllowFriendMethods
@interface L0MoverAppDelegate (L0FriendMethods)

- (void) displayNewVersionAlertWithVersion:(NSString*) version;

@end
#endif
