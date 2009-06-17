//
//  ShardAppDelegate.m
//  Shard
//
//  Created by ∞ on 21/03/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#define L0MoverAppDelegateAllowFriendMethods 1
#import "L0MoverAppDelegate.h"

#import "L0MoverAdController.h"

#import "L0MoverAppDelegate+L0HelpAlerts.h"

#import "L0MoverPeering.h"
#import "L0MoverWiFiScanner.h"
#import "L0MoverBluetoothScanner.h"

#import "L0MoverAppDelegate+L0ItemPersistance.h"
#import "L0BookmarkItem.h"
#import "L0ImageItem.h"
#import "L0TextItem.h"
#import "L0AddressBookPersonItem.h"

#import "L0MoverItemUI.h"
#import "L0MoverImageItemUI.h"
#import "L0MoverAddressBookItemUI.h"
#import "L0MoverTextItemUI.h"
#import "L0MoverBookmarkItemUI.h"
#import "L0MoverItemAction.h"

#import <netinet/in.h>

// Alert/Action sheet tags
enum {
	kL0MoverNewVersionAlertTag = 1000,
	kL0MoverAddSheetTag,
	kL0MoverItemMenuSheetTag,
	kL0MoverTellAFriendAlertTag,
	kL0MoverDeleteConfirmationSheetTag,
};

#define kL0MoverLastSeenVersionKey @"L0MoverLastSeenVersion"
#define kL0MoverTellAFriendWasShownKey @"L0MoverTellAFriendWasShown"

@interface L0MoverAppDelegate ()

- (void) returnFromImagePicker;
@property(copy, setter=privateSetDocumentsDirectory:) NSString* documentsDirectory;

- (BOOL) isCameraAvailable;
- (void) paste;

@end


@implementation L0MoverAppDelegate

- (void) applicationDidFinishLaunching:(UIApplication *) application;
{
	self.tableHostController.cacheViewsDuringFlip = YES;
	
	// Registering item subclasses.
	[L0ImageItem registerClass];
	[L0AddressBookPersonItem registerClass];
	[L0BookmarkItem registerClass];
	[L0TextItem registerClass];
	
	// Registering UIs.
	[L0MoverImageItemUI registerClass];
	[L0MoverAddressBookItemUI registerClass];
	[L0MoverBookmarkItemUI registerClass];
	[L0MoverTextItemUI registerClass];
	
	// Starting up peering services.
	L0MoverPeering* peering = [L0MoverPeering sharedService];
	peering.delegate = self;
	
	L0MoverWiFiScanner* scanner = [L0MoverWiFiScanner sharedScanner];
	[peering addAvailableScannersObject:scanner];
	scanner.enabled = YES;

#if DEBUG && !kL0MoverTestByDisablingBluetooth
	L0MoverBluetoothScanner* btScanner = [L0MoverBluetoothScanner sharedScanner];
	[peering addAvailableScannersObject:btScanner];
	btScanner.enabled = YES;
#endif
	
#if !DEBUG && kL0MoverTestByDisablingBluetooth
#error Disable kL0MoverTestByDisablingBluetooth in your local settings to build.
#endif
	
	// Setting up the UI.
	self.tableController = [[[L0MoverItemsTableController alloc] initWithDefaultNibName] autorelease];
	
	NSMutableArray* itemsArray = [self.toolbar.items mutableCopy];

	// edit button
	[itemsArray insertObject:self.tableController.editButtonItem atIndex:2];
	
	// info button
	UIButton* infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
	[infoButton addTarget:self.tableHostController action:@selector(showBack) forControlEvents:UIControlEventTouchUpInside];
	UIBarButtonItem* infoButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:infoButton] autorelease];
	[itemsArray addObject:infoButtonItem];

	self.toolbar.items = itemsArray;
	[itemsArray release];
    
	[tableHostView addSubview:self.tableController.view];
	[window addSubview:self.tableHostController.view];
	
	// Loading persisted items from disk. (Later, so we avoid the AB constant bug.)
	[self performSelector:@selector(addPersistedItemsToTable) withObject:nil afterDelay:0.05];
	
	// Go!
	[window makeKeyAndVisible];
	
	// Be helpful if this is the first time (ahem).
	[self showAlertIfNotShownBeforeNamed:@"L0MoverWelcome"];
	
	networkUnavailableViewStartingPosition = self.networkUnavailableView.center;
	self.networkUnavailableView.hidden = YES;
	networkAvailable = YES;
	//[self beginWatchingNetwork];
	
	self.networkCalloutController.anchorView = self.toolbar;
	[self.networkCalloutController startWatchingForJams];
	
	// Make sure Tell a Friend is shown if needed.
	if (![[NSUserDefaults standardUserDefaults] boolForKey:kL0MoverTellAFriendWasShownKey]) {
		[self performSelector:@selector(proposeTellingAFriend) withObject:nil afterDelay:15.0];
	}
	
	// Make sure we show the network callout if there are one or more jams.
	[self performSelector:@selector(showNetworkCalloutIfJammed) withObject:nil afterDelay:2.0];
}

#pragma mark -
#pragma mark Ad support

- (void) startAdvertisementsInView:(UIView*) view;
{
	L0MoverAdController* ads = [L0MoverAdController sharedController];
	ads.superview = view;
	
	CGPoint origin = toolbar.frame.origin;
	origin.y -= kL0MoverAdSize.height;
	ads.origin = origin;
	
	[ads start];
}

- (void) stopAdvertisements;
{
	[[L0MoverAdController sharedController] stop];
}

#pragma mark -
#pragma mark Tell a Friend

- (void) proposeTellingAFriend;
{
	BOOL hasPeers = self.tableController.northPeer || self.tableController.eastPeer || self.tableController.westPeer;
	if (self.networkAvailable && !hasPeers) {
		UIAlertView* a = [UIAlertView alertNamed:@"L0MoverTellAFriend"];
		a.delegate = self;
		a.tag = kL0MoverTellAFriendAlertTag;
		[a show];
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:kL0MoverTellAFriendWasShownKey];
	}
}

- (void) tellAFriend;
{
	if (![MFMailComposeViewController canSendMail]) {
		UIAlertView* a = [UIAlertView alertNamed:@"L0MoverNoEmailSetUp"];
		[a show];
		return;
	}
	
	NSString* mailMessage = NSLocalizedString(@"Mover is an app that allows you to share files with other iPhones near you, with style. Download it at http://infinite-labs.net/mover/download or see it in action at http://infinite-labs.net/mover/",
											  @"Contents of 'Email a Friend' message");
	NSString* mailSubject = NSLocalizedString(@"Check out this iPhone app, Mover",
											  @"Subject of 'Email a Friend' message");
	
	MFMailComposeViewController* mailVC = [[MFMailComposeViewController new] autorelease];
	mailVC.mailComposeDelegate = self;
	[mailVC setSubject:mailSubject];
	[mailVC setMessageBody:mailMessage isHTML:NO];
	[self presentModalViewController:mailVC];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error;
{
	[controller dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark Bookmark items

- (BOOL) application:(UIApplication*) application handleOpenURL:(NSURL*) url;
{
	NSString* scheme = [url scheme];
	if (![scheme isEqual:@"x-infinitelabs-mover"])
		return NO;
	
	if (![[url resourceSpecifier] hasPrefix:@"add?"])
		return NO;
	
	NSDictionary* query = [url dictionaryByDecodingQueryString];
	NSString* urlString, * title;
	if (!(urlString = [query objectForKey:@"url"]))
		return NO;
	if (!(title = [query objectForKey:@"title"]))
		title = urlString;
	
	if (![urlString hasPrefix:@"http://"] && ![urlString hasPrefix:@"https://"])
		return NO;
	
	NSURL* bookmarkedURL = [NSURL URLWithString:urlString];
	if (!bookmarkedURL)
		return NO;
	L0BookmarkItem* item = [[[L0BookmarkItem alloc] initWithAddress:bookmarkedURL title:title] autorelease];
	[self performSelector:@selector(addItemToTableAndSave:) withObject:item afterDelay:0.7];
	return YES;
}

- (void) addItemToTableAndSave:(L0MoverItem*) item;
{
	[item storeToAppropriateApplication];
	[self.tableController addItem:item animation:kL0SlideItemsTableAddByDropping];
}

#pragma mark -
#pragma mark Reachability

static SCNetworkReachabilityRef reach = NULL;

static void L0MoverAppDelegateNetworkStateChanged(SCNetworkReachabilityRef reach, SCNetworkReachabilityFlags flags, void* nothing) {
	L0MoverAppDelegate* myself = (L0MoverAppDelegate*) UIApp.delegate;
	[NSObject cancelPreviousPerformRequestsWithTarget:myself selector:@selector(checkNetwork) object:nil];
	[myself updateNetworkWithFlags:flags];
}

@synthesize networkUnavailableView, networkAvailable;

- (void) beginWatchingNetwork;
{
	if (reach) return;
	
	// What follows comes from Reachability.m.
	// Basically, we look for reachability for the link-local address --
	// and filter for WWAN or connection-required responses in -updateNetworkWithFlags:.
	
	// Build a sockaddr_in that we can pass to the address reachability query.
	struct sockaddr_in sin;
	bzero(&sin, sizeof(sin));
	sin.sin_len = sizeof(sin);
	sin.sin_family = AF_INET;
	
	// IN_LINKLOCALNETNUM is defined in <netinet/in.h> as 169.254.0.0
	sin.sin_addr.s_addr = htonl(IN_LINKLOCALNETNUM);
	
	reach = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr*) &sin);
	
	SCNetworkReachabilityContext emptyContext = {0, self, NULL, NULL, NULL};
	SCNetworkReachabilitySetCallback(reach, &L0MoverAppDelegateNetworkStateChanged, &emptyContext);
	SCNetworkReachabilityScheduleWithRunLoop(reach, [[NSRunLoop currentRunLoop] getCFRunLoop], kCFRunLoopDefaultMode);
	
	SCNetworkReachabilityFlags flags;
	if (!SCNetworkReachabilityGetFlags(reach, &flags))
		[self performSelector:@selector(checkNetwork) withObject:nil afterDelay:0.5];
	else
		[self updateNetworkWithFlags:flags];
}

#if DEBUG
- (void) stopWatchingNetwork;
{
	if (!reach) return;
	
	SCNetworkReachabilityUnscheduleFromRunLoop(reach, [[NSRunLoop currentRunLoop] getCFRunLoop], kCFRunLoopDefaultMode);
	CFRelease(reach); reach = NULL;
}
#endif

- (void) checkNetwork;
{
	SCNetworkReachabilityFlags flags;
	if (SCNetworkReachabilityGetFlags(reach, &flags))
		[self updateNetworkWithFlags:flags];
}

- (void) updateNetworkWithFlags:(SCNetworkReachabilityFlags) flags;
{
	BOOL habemusNetwork = 
		(flags & kSCNetworkReachabilityFlagsReachable) &&
		!(flags & kSCNetworkReachabilityFlagsConnectionRequired);
	// note that unlike Reachability.m we don't care about WWANs.
	
	self.networkAvailable = habemusNetwork;
}

- (void) setNetworkAvailable:(BOOL) habemusNetwork;
{
	BOOL wasUp = networkAvailable;
	networkAvailable = habemusNetwork;
	L0Log(@"Available = %d", habemusNetwork);
	
	if (habemusNetwork && !wasUp) {
		// update UI for network. Huzzah!
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
		[UIView setAnimationDuration:1.0];
		
		self.networkUnavailableView.alpha = 0.0;
		CGPoint position = self.networkUnavailableView.center;
		position.y =
		self.networkUnavailableView.superview.frame.size.height +
		self.networkUnavailableView.superview.frame.size.height;
		self.networkUnavailableView.center = position;
		
		[UIView commitAnimations];

		self.networkUnavailableView.hidden = NO;
	} else if (!habemusNetwork && wasUp) {
		// disable UI for no network. Boo, user, boo!
		CGPoint position = self.networkUnavailableView.center;
		position.y =
		self.networkUnavailableView.superview.frame.size.height +
		self.networkUnavailableView.superview.frame.size.height;
		self.networkUnavailableView.center = position;
		
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
		[UIView setAnimationDuration:1.0];
		
		self.networkUnavailableView.alpha = 1.0;
		self.networkUnavailableView.center = networkUnavailableViewStartingPosition;
		
		[UIView commitAnimations];
		
		// clear all peers off the table. TODO: only Bonjour peers!
		self.tableController.northPeer = nil;
		self.tableController.eastPeer = nil;
		self.tableController.westPeer = nil;
		
		self.networkUnavailableView.hidden = NO;
	}

	[self.networkUnavailableView.superview bringSubviewToFront:self.networkUnavailableView];
}

#pragma mark -
#pragma mark Other methods

- (void) addPersistedItemsToTable;
{
	for (L0MoverItem* i in [self loadItemsFromMassStorage])
		[self.tableController addItem:i animation:kL0SlideItemsTableNoAddAnimation];
}

- (void) applicationWillTerminate:(UIApplication*) app;
{
	[self persistItemsToMassStorage:[self.tableController items]];
}

- (void) moverPeer:(L0MoverPeer*) peer willBeSentItem:(L0MoverItem*) item;
{
	L0Log(@"About to send item %@", item);
}

- (void) moverPeer:(L0MoverPeer*) peer wasSentItem:(L0MoverItem*) item;
{
	L0Log(@"Sent %@", item);
	[self.tableController returnItemToTableAfterSend:item toPeer:peer];
}

- (void) moverPeerWillSendUsItem:(L0MoverPeer*) peer;
{
	L0Log(@"Receiving from %@", peer);
	[self.tableController beginWaitingForItemComingFromPeer:peer];
}
- (void) moverPeer:(L0MoverPeer*) peer didSendUsItem:(L0MoverItem*) item;
{
	L0Log(@"Received %@", item);
	[item storeToAppropriateApplication];
	[self.tableController addItem:item comingFromPeer:peer];
	
	if ([item isKindOfClass:[L0ImageItem class]])
		[self showAlertIfNotShownBeforeNamedForiPhone:@"L0ImageReceived_iPhone" foriPodTouch:@"L0ImageReceived_iPodTouch"];
	else if ([item isKindOfClass:[L0AddressBookPersonItem class]])
		[self showAlertIfNotShownBeforeNamed:@"L0ContactReceived"];
}
- (void) moverPeerDidCancelSendingUsItem:(L0MoverPeer*) peer;
{
	[self.tableController stopWaitingForItemFromPeer:peer];
}

- (void) peerFound:(L0MoverPeer*) peer;
{
	peer.delegate = self;
	[self.tableController addPeerIfSpaceAllows:peer];
	
	if (lastSeenVersion == 0.0) {
		double seen = [[NSUserDefaults standardUserDefaults] doubleForKey:kL0MoverLastSeenVersionKey];
		double mine = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] doubleValue];
		
		lastSeenVersion = MAX(seen, mine);
	}
	
	if (peer.applicationVersion > lastSeenVersion) {
		lastSeenVersion = peer.applicationVersion;
		[[NSUserDefaults standardUserDefaults] setDouble:peer.applicationVersion forKey:kL0MoverLastSeenVersionKey];

		NSString* version = peer.userVisibleApplicationVersion?: @"(no version number)";
		[self displayNewVersionAlertWithVersion:version];
	}
}

- (void) displayNewVersionAlertWithVersion:(NSString*) version;
{
	UIAlertView* alert = [UIAlertView alertNamed:@"L0MoverNewVersion"];
	alert.tag = kL0MoverNewVersionAlertTag;
	[alert setTitleFormat:nil, version];
	alert.delegate = self;
	[alert show];
}

- (void) alertView:(UIAlertView*) alertView clickedButtonAtIndex:(NSInteger) buttonIndex;
{
	switch (alertView.tag) {
		case kL0MoverNewVersionAlertTag: {
			if (buttonIndex != 1) return;
			
			NSString* appStoreURLString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"L0MoverAppStoreURL"];
			if (!appStoreURLString)
				appStoreURLString = @"http://infinite-labs.net/mover/download";
			[UIApp openURL:[NSURL URLWithString:appStoreURLString]];
			return;
		}
			
		case kL0MoverTellAFriendAlertTag: {
			if (buttonIndex == 0)
				[self tellAFriend];
			return;
		}
	}
}

- (IBAction) testBySendingItemToAnyPeer;
{
}

- (void) peerLeft:(L0MoverPeer*) peer;
{
	[self.tableController removePeer:peer];
}

@synthesize window, toolbar;
@synthesize tableController, tableHostView, tableHostController;

@synthesize networkCalloutController;

- (void) dealloc;
{
	[toolbar release];
	[tableHostView release];
	[tableHostController release];
	[tableController release];
	[networkCalloutController release];
    [window release];
    [super dealloc];
}

#define kL0MoverAddImageButton @"kL0MoverAddImageButton"
#define kL0MoverAddContactButton @"kL0MoverAddContactButton"
#define kL0MoverPasteButton @"kL0MoverPasteButton"
#define kL0MoverTakeAPhotoButton @"kL0MoverTakeAPhotoButton"
#define kL0MoverCancelButton @"kL0MoverCancelButton"

- (BOOL) isCameraAvailable;
{
#if defined(TARGET_IPHONE_SIMULATOR) && kL0iPhoneSimulatorPretendIsiPodTouch
	return NO;
#else
	return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
#endif
}

- (IBAction) addItem;
{
	[self.tableController setEditing:NO animated:YES];
	
	L0ActionSheet* sheet = [[L0ActionSheet new] autorelease];
	sheet.tag = kL0MoverAddSheetTag;
	sheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
	sheet.delegate = self;
	[sheet addButtonWithTitle:NSLocalizedString(@"Add Image", @"Add item - image button") identifier:kL0MoverAddImageButton];
	
	if ([self isCameraAvailable])
		[sheet addButtonWithTitle:NSLocalizedString(@"Take a Photo", @"Add item - take a photo button") identifier:kL0MoverTakeAPhotoButton];
	
	[sheet addButtonWithTitle:NSLocalizedString(@"Add Contact", @"Add item - contact button")  identifier:kL0MoverAddContactButton];
	
	UIPasteboard* pb = [UIPasteboard generalPasteboard];
	if ([pb.strings count] > 0)
		[sheet addButtonWithTitle:NSLocalizedString(@"Paste", @"Add item - paste button") identifier:kL0MoverPasteButton];
	
	NSInteger i = [sheet addButtonWithTitle:NSLocalizedString(@"Cancel", @"Add item - cancel button") identifier:kL0MoverCancelButton];
	sheet.cancelButtonIndex = i;

	[sheet showInView:self.window];
}

- (BOOL) performMainActionForItem:(L0MoverItem*) i;
{
	L0MoverItemAction* mainAction = [[L0MoverItemUI UIForItem:i] mainActionForItem:i];
	[mainAction performOnItem:i];
	return mainAction != nil;
}

- (void) finishPerformingMainAction;
{
	[self.tableController unhighlightAllItems];
}

#define kL0MoverItemMenuSheetRemoveIdentifier @"kL0MoverItemMenuSheetRemoveIdentifier"
#define kL0MoverItemMenuSheetDeleteIdentifier @"kL0MoverItemMenuSheetDeleteIdentifier"
#define kL0MoverItemMenuSheetCancelIdentifier @"kL0MoverItemMenuSheetCancelIdentifier"
#define kL0MoverItemKey @"L0MoverItem"

- (void) beginShowingActionMenuForItem:(L0MoverItem*) i includeRemove:(BOOL) r;
{
	L0MoverItemUI* ui = [L0MoverItemUI UIForItem:i];
	if (!ui) return;
	
	L0ActionSheet* actionMenu = [[L0ActionSheet new] autorelease];
	actionMenu.tag = kL0MoverItemMenuSheetTag;
	actionMenu.delegate = self;
	actionMenu.actionSheetStyle = UIActionSheetStyleBlackOpaque;
	[actionMenu setValue:i forKey:kL0MoverItemKey];
	
	L0MoverItemAction* mainAction;
	if ((mainAction = [ui mainActionForItem:i]) && !mainAction.hidden)
		[actionMenu addButtonWithTitle:mainAction.localizedLabel identifier:mainAction];
	
	NSArray* a = [ui additionalActionsForItem:i];
	for (L0MoverItemAction* otherAction in a) {
		if (!otherAction.hidden)
			[actionMenu addButtonWithTitle:otherAction.localizedLabel identifier:otherAction];
	}
	
	if (r) {
		if ([ui removingFromTableIsSafeForItem:i])
			[actionMenu addButtonWithTitle:NSLocalizedString(@"Remove from Table", @"Remove button in action menu") identifier:kL0MoverItemMenuSheetRemoveIdentifier];
		else {
			NSInteger i = [actionMenu addButtonWithTitle:NSLocalizedString(@"Delete", @"Delete button in action menu") identifier:kL0MoverItemMenuSheetDeleteIdentifier];
			actionMenu.destructiveButtonIndex = i;
		}
	}
		
	
	NSInteger cancelIndex = [actionMenu addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel button in action menu") identifier:kL0MoverItemMenuSheetCancelIdentifier];
	actionMenu.cancelButtonIndex = cancelIndex;
	
	[actionMenu showInView:self.window];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex;
{
	switch (actionSheet.tag) {
		case kL0MoverAddSheetTag: {
			id identifier = [(L0ActionSheet*)actionSheet identifierForButtonAtIndex:buttonIndex];
			
			if ([identifier isEqual:kL0MoverAddImageButton])
				[self addImageItem];
			else if ([identifier isEqual:kL0MoverTakeAPhotoButton])
				[self takeAPhotoAndAddImageItem];
			else if ([identifier isEqual:kL0MoverAddContactButton])
				[self addAddressBookItem];
			else if ([identifier isEqual:kL0MoverPasteButton])
				[self paste];
		}
			break;
			
		case kL0MoverItemMenuSheetTag: {
			
			id identifier = [(L0ActionSheet*)actionSheet identifierForButtonAtIndex:buttonIndex];
			L0MoverItem* item = [actionSheet valueForKey:kL0MoverItemKey];
			
			if ([identifier isEqual:kL0MoverItemMenuSheetRemoveIdentifier]) {
				// TODO make a version w/o ani param
				[self.tableController removeItem:item animation:kL0SlideItemsTableRemoveByFadingAway];
			} else if ([identifier isEqual:kL0MoverItemMenuSheetDeleteIdentifier]) {
				
				L0ActionSheet* sheet = [L0ActionSheet new];
				sheet.tag = kL0MoverDeleteConfirmationSheetTag;
				
				sheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
				sheet.title = NSLocalizedString(@"This item is only saved on Mover's table. If you delete it, there will be no way to recover it.", @"Prompt on unsafe delete confirmation sheet");
				
				NSInteger i = [sheet addButtonWithTitle:NSLocalizedString(@"Delete", @"Delete button in the unsafe delete confirmation sheet") identifier:kL0MoverItemMenuSheetDeleteIdentifier];
				sheet.destructiveButtonIndex = i;
				
				i = [sheet addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel button in the unsafe delete confirmation sheet") identifier:kL0MoverItemMenuSheetCancelIdentifier];
				sheet.cancelButtonIndex = i;
				sheet.delegate = self;
				[sheet setValue:item forKey:kL0MoverItemKey];
				
				[sheet showInView:self.window];
				
			} else if ([identifier isKindOfClass:[L0MoverItemAction class]])
				[identifier performOnItem:item];
			
			[self.tableController finishedShowingActionMenuForItem:item];
			
		}
			break;
			
		case kL0MoverDeleteConfirmationSheetTag: {
			if (buttonIndex == actionSheet.destructiveButtonIndex) {
				L0MoverItem* item = [actionSheet valueForKey:kL0MoverItemKey];
				[self.tableController removeItem:item animation:kL0SlideItemsTableRemoveByFadingAway];
			}
		}
			break;
	}
}

- (void) addAddressBookItem;
{
	ABPeoplePickerNavigationController* picker = [[[ABPeoplePickerNavigationController alloc] init] autorelease];
	picker.peoplePickerDelegate = self;
	[self.tableHostController presentModalViewController:picker animated:YES];
}

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker;
{
	[peoplePicker dismissModalViewControllerAnimated:YES];
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person;
{
	L0AddressBookPersonItem* item = [[L0AddressBookPersonItem alloc] initWithAddressBookRecord:person];
	[self.tableController addItem:item animation:kL0SlideItemsTableAddFromSouth];
	[item release];
	
	[peoplePicker dismissModalViewControllerAnimated:YES];
	return NO;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier;
{
	return [self peoplePickerNavigationController:peoplePicker shouldContinueAfterSelectingPerson:person];
}

- (void) takeAPhotoAndAddImageItem;
{
	if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
		return;
	
	UIImagePickerController* imagePicker = [[[UIImagePickerController alloc] init] autorelease];
	imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
	imagePicker.delegate = self;
	[self.tableHostController presentModalViewController:imagePicker animated:YES];
}	

- (void) addImageItem;
{
	if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
		return;
	
	UIImagePickerController* imagePicker = [[[UIImagePickerController alloc] init] autorelease];
	imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
	imagePicker.delegate = self;
	[self.tableHostController presentModalViewController:imagePicker animated:YES];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info;
{
	L0Log(@"%@", info);
	UIImage* image = [info objectForKey:UIImagePickerControllerEditedImage];
	if (!image)
		image = [info objectForKey:UIImagePickerControllerOriginalImage];
	
	L0ImageItem* item = [[L0ImageItem alloc] initWithTitle:@"" image:image];
	if (picker.sourceType == UIImagePickerControllerSourceTypeCamera)
		[item storeToAppropriateApplication];
	
	[self.tableController addItem:item animation:kL0SlideItemsTableAddFromSouth];
	[item release];
	
	[picker dismissModalViewControllerAnimated:YES];
	[self returnFromImagePicker];
}

@synthesize documentsDirectory;
- (NSString*) documentsDirectory;
{
	if (!documentsDirectory) {
		NSArray* docsDirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSAssert([docsDirs count] > 0, @"At least one documents directory is known");
		self.documentsDirectory = [docsDirs objectAtIndex:0];
	}
	
	return documentsDirectory;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker;
{
	[picker dismissModalViewControllerAnimated:YES];
	[self returnFromImagePicker];
}

- (void) returnFromImagePicker;
{
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];	
}

- (void) paste;
{
	UIPasteboard* pb = [UIPasteboard generalPasteboard];
	for (NSString* s in pb.strings) {
		L0TextItem* item = [[L0TextItem alloc] initWithText:s];
		[self.tableController addItem:item animation:kL0SlideItemsTableAddFromSouth];
		[item release];
	}
}

- (IBAction) showNetworkCallout;
{
	[self.networkCalloutController toggleCallout];
}

- (IBAction) showNetworkCalloutIfJammed;
{
	BOOL wiFiOff = [[L0MoverWiFiScanner sharedScanner] enabled] && [[L0MoverWiFiScanner sharedScanner] jammed];
	BOOL bluetoothOff = [[L0MoverBluetoothScanner sharedScanner] enabled] && [[L0MoverBluetoothScanner sharedScanner] jammed];
	if (wiFiOff || bluetoothOff)
		[self.networkCalloutController showCallout];
}

- (void) presentModalViewController:(UIViewController*) vc;
{
	[self.tableHostController presentModalViewController:vc animated:YES];
}

@end
