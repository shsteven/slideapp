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
#import "L0MoverPeer.h"

#import "L0MoverNetworkCalloutController.h"

@interface L0MoverAppDelegate : NSObject <UIApplicationDelegate, L0PeerDiscoveryDelegate, L0MoverPeerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, ABPeoplePickerNavigationControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate, MFMailComposeViewControllerDelegate> {
    UIWindow *window;
	
	L0MoverItemsTableController* tableController;
	UIView* tableHostView;
	L0FlipViewController* tableHostController;
	
	NSString* documentsDirectory;
	
	UIToolbar* toolbar;
	UIView* networkUnavailableView;
	CGPoint networkUnavailableViewStartingPosition;
	
	double lastSeenVersion;
	BOOL networkAvailable;
	L0MoverNetworkCalloutController* networkCalloutController;
}

@property(retain) IBOutlet UIWindow* window;
@property(retain) IBOutlet UIView* tableHostView;
@property(retain) IBOutlet UIToolbar* toolbar;

@property(retain) IBOutlet L0FlipViewController* tableHostController;
@property(retain) L0MoverItemsTableController* tableController;

@property(retain) IBOutlet L0MoverNetworkCalloutController* networkCalloutController;
- (IBAction) showNetworkCallout;

- (IBAction) addItem;
- (void) addImageItem;
- (void) takeAPhotoAndAddImageItem;
- (void) addAddressBookItem;

- (IBAction) testBySendingItemToAnyPeer;

@property(readonly, copy) NSString* documentsDirectory;

- (void) beginWatchingNetwork;
- (void) checkNetwork;
- (void) updateNetworkWithFlags:(SCNetworkReachabilityFlags) flags;

- (void) tellAFriend;

@property(retain) IBOutlet UIView* networkUnavailableView;
@property(readonly, getter=isNetworkAvailable) BOOL networkAvailable;

- (void) beginShowingActionMenuForItem:(L0MoverItem*) i includeRemove:(BOOL) r;
- (BOOL) performMainActionForItem:(L0MoverItem*) i;

- (void) finishPerformingMainAction;

- (void) startAdvertisementsInView:(UIView*) view;
- (void) stopAdvertisements;

- (void) presentModalViewController:(UIViewController*) vc;

@end

#if L0MoverAppDelegateAllowFriendMethods
@interface L0MoverAppDelegate (L0FriendMethods)

@property(readwrite) BOOL networkAvailable;
#if DEBUG
- (void) stopWatchingNetwork;
#endif

- (void) displayNewVersionAlertWithVersion:(NSString*) version;

@end
#endif
