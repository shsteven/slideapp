//
//  Mover3AppDelegate.m
//  Mover3
//
//  Created by ∞ on 12/09/09.
//  Copyright Infinite Labs (Emanuele Vulcano) 2009. All rights reserved.
//

#import "MvrAppDelegate.h"
#import "MvrItemUI.h"

#import "Network+Storage/MvrItemStorage.h"

#import "Network+Storage/MvrGenericItem.h"
#import "MvrGenericItemUI.h"

#import "MvrImageItem.h"
#import "MvrImageItemUI.h"
#import "MvrVideoItem.h"
#import "MvrVideoItemUI.h"
#import "MvrContactItem.h"
#import "MvrContactItemUI.h"
#import "MvrBookmarkItem.h"
#import "MvrBookmarkItemUI.h"
#import "MvrTextItem.h"
#import "MvrTextItemUI.h"

#import "MvrPasteboardItemSource.h"

#import "MvrAccessibility.h"

#import "MvrAboutPane.h"

#import "MvrAppDelegate+HelpAlerts.h"

#import "MvrAdActingController.h"

#import <MuiKit/MuiKit.h>
#import <QuartzCore/QuartzCore.h>

#import <SwapKit/SwapKit.h>

@interface MvrAppDelegate () <ILSwapServiceDelegate>

- (void) setUpItemClassesAndUIs;
- (void) setUpStorageCentral;
- (void) setUpTableController;

@end

#define kMvrAppDelegateRemoveButtonIdentifier @"kMvrAppDelegateRemoveButtonIdentifier"
#define kMvrAppDelegateDeleteButtonIdentifier @"kMvrAppDelegateDeleteButtonIdentifier"
#define kMvrAppDelegateSendButtonIdentifier @"kMvrAppDelegateSendButtonIdentifier"

enum {
	kMvrAppDelegateAddSheetTag,
	kMvrAppDelegateItemActionSheetTag,
	kMvrAppDelegateDeleteConfirmationSheetTag,
	kMvrAppDelegateSendActionSheetTag,
};

@implementation MvrAppDelegate

- (BOOL) application:(UIApplication*) application didFinishLaunchingWithOptions:(NSDictionary*) options;
{
	UIApp.idleTimerDisabled = YES;
	
	[self setUpItemClassesAndUIs];
	[self setUpStorageCentral];
#if kMvrInstrumentForAds
	self.storageCentral.itemSavingDisabled = YES;
#endif
	
	[self setUpTableController];
	
	tellAFriend = [MvrTellAFriendController new];
	crashReporting = [MvrCrashReporting new];
	[crashReporting checkForPendingReports];
	
	messageChecker = [MvrMessageChecker new];

	[self.tableController viewWillAppear:NO];
	CGRect bounds = [self.window convertRect:[UIScreen mainScreen].applicationFrame fromWindow:nil];
	self.tableController.view.frame = bounds;
	[self.window addSubview:self.tableController.view];
	[self.tableController viewDidAppear:NO];
	
	self.overlayWindow.hidden = YES;
	[self.window makeKeyAndVisible];
	
	[crashReporting enableReporting];
	
	[messageChecker performSelector:@selector(checkIfNeeded) withObject:nil afterDelay:7.0];
		
#if DEBUG
	if ([[[[NSProcessInfo processInfo] environment] objectForKey:@"MvrTestByPerformingAlertParade"] boolValue]) {
		[self performSelector:@selector(testByPerformingAlertParade) withObject:nil afterDelay:3.0];
	}
#endif
	
#if kMvrInstrumentForAds
	[[MvrAdActingController sharedAdController] start];
#endif
	
	[self showAlertIfNotShownBeforeNamed:@"MvrWelcome"];
	
	[ILSwapService didFinishLaunchingWithOptions:options];
	
	return YES;
}

- (BOOL) application:(UIApplication *)application handleOpenURL:(NSURL *)url;  
{
#if !kMvrIsLite
	NSString* scheme = [url scheme];
	if ([scheme isEqual:@"x-infinitelabs-mover"]) {
		if (![[url resourceSpecifier] hasPrefix:@"add?"])
			return NO;
		
		NSDictionary* query = [url dictionaryByDecodingQueryString];
		NSString* urlString;
		if (!(urlString = [query objectForKey:@"url"]))
			return NO;
		
		NSURL* bookmarkedURL = [NSURL URLWithString:urlString];
		if (!bookmarkedURL)
			return NO;
		
		MvrBookmarkItem* item = [[[MvrBookmarkItem alloc] initWithAddress:bookmarkedURL] autorelease];
		if (item)
			[self performSelector:@selector(addItemFromSelf:) withObject:item afterDelay:0.7];
		return item != nil;
	}
#endif
	
	return [ILSwapService handleOpenURL:url];
}

- (void) swapServiceDidReceiveRequest:(ILSwapRequest*) request;
{
	[[MvrPasteboardItemSource sharedSource] addAllItemsFromSwapKitRequest:request];
}

@synthesize window, tableController, wifiMode, bluetoothMode, tellAFriend, messageChecker;

- (void) dealloc;
{
	[storageCentral release];
	[itemsDirectory release];
	[metadata release];
	
	[identifierForSelf release];
	
	[window release];
	[tableController release];
	
	[overlayWindow release];
	[overlayLabel release];
	[overlaySpinner release];
	
	[tellAFriend release];
	[crashReporting release];
	[messageChecker release];
	
    [super dealloc];
}

#pragma mark -
#pragma mark Item classes and UIs.

- (void) setUpItemClassesAndUIs;
{
	[MvrGenericItem registerClass];
	[MvrGenericItemUI registerClass];
	
	[MvrImageItem registerClass];
	[MvrImageItemUI registerClass];
	
	[MvrVideoItem registerClass];
	[MvrVideoItemUI registerClass];
	
	[MvrContactItem registerClass];
	[MvrContactItemUI registerClass];
	
	[MvrBookmarkItem registerClass];
	[MvrBookmarkItemUI registerClass];
	
	[MvrTextItem registerClass];
	[MvrTextItemUI registerClass];
	
	[[MvrPasteboardItemSource sharedSource] registerSource];
}

#pragma mark -
#pragma mark Storage central.

#define kMvrItemsMetadataUserDefaultsKey @"L0SlidePersistedItems"

@synthesize storageCentral;

- (NSString*) itemsDirectory;
{
	if (!itemsDirectory) {
		NSArray* docsDirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSAssert([docsDirs count] > 0, @"At least one documents directory is known");
		
		NSString* docsDir = [docsDirs objectAtIndex:0];
		
#if kMvrVariantSettings_UseSubdirectoryForItemStorage
		docsDir = [docsDir stringByAppendingPathComponent:@"Mover Items"];
		if (![[NSFileManager defaultManager] fileExistsAtPath:docsDir]) {
			NSError* e;
			BOOL created = [[NSFileManager defaultManager] createDirectoryAtPath:docsDir withIntermediateDirectories:YES attributes:nil error:&e];
			if (!created)
				L0LogAlways(@"Could not create the Mover Items subdirectory: %@", e);
			NSAssert(created, @"Could not create the Mover Items subdirectory!");
		}
#endif
		
		itemsDirectory = [docsDir copy];
	}
	
	return itemsDirectory;
}

- (void) setUpStorageCentral;
{
	storageCentral = [[MvrStorageCentral alloc] initWithPersistentDirectory:self.itemsDirectory metadataStorage:self];
	MvrStorageSetTemporaryDirectory(NSTemporaryDirectory());
}

- (NSDictionary*) metadata;
{
	NSDictionary* m = L0As(NSDictionary, [[NSUserDefaults standardUserDefaults] objectForKey:kMvrItemsMetadataUserDefaultsKey]);
	
	if (!m)
		m = [NSDictionary dictionary];
	
	return m;
}

- (void) setMetadata:(NSDictionary*) m;
{		
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setObject:m forKey:kMvrItemsMetadataUserDefaultsKey];
	[ud synchronize];
}

#pragma mark -
#pragma mark Platform info.

- (NSString*) userVisibleVersion;
{
	return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

- (double) version;
{
	id ver = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
	return ver? [ver doubleValue] : kMvrUnknownVersion;
}

- (id) platform;
{
	return kMvrAppleiPhoneOSPlatform;
}

#ifndef kMvrCurrentAppVariantDisplayName
#error kMvrCurrentAppVariantDisplayName is undefined! It should have been defined in the variant's Variant.xcconfig (or overridden by Mover-Baseline-Debug.xcconfig).
#endif

- (NSString*) variantDisplayName;
{
	return kMvrCurrentAppVariantDisplayName;
}

#ifndef kMvrCurrentAppVariant
#error kMvrCurrentAppVariant is undefined! It should have been defined in the variant's Variant.xcconfig (or overridden by Mover-Baseline-Debug.xcconfig).
#endif

- (MvrAppVariant) variant;
{
	return kMvrCurrentAppVariant;
}

- (L0UUID*) identifierForSelf;
{
	if (!identifierForSelf)
		identifierForSelf = [L0UUID new];
	
	return identifierForSelf;
}

- (NSString*) displayNameForSelf;
{
#if TARGET_IPHONE_SIMULATOR
	return [[NSProcessInfo processInfo] hostName];
#else
	return [UIDevice currentDevice].name;
#endif
}

#pragma mark -
#pragma mark Adding

#define kMvrAppDelegateCancelButtonIdentifier @"Cancel"

- (IBAction) add;
{
	L0ActionSheet* sheet = [[L0ActionSheet new] autorelease];
	sheet.tag =	kMvrAppDelegateAddSheetTag;
	sheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
	
	for (MvrItemSource* source in [MvrItemSource registeredItemSources]) {
		if (source.available)
			[sheet addButtonWithTitle:source.displayName identifier:source];
	}
	
	NSInteger index = [sheet addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel button on action sheet") identifier:kMvrAppDelegateCancelButtonIdentifier];
	sheet.cancelButtonIndex = index;
	
	sheet.delegate = self;
	[sheet showInView:self.window];
}


- (void) addItemFromSelf:(MvrItem*) item;
{
	[self.tableController addItem:item animated:YES];
	[self.storageCentral.mutableStoredItems addObject:item];
}

#pragma mark -
#pragma mark Displaying an action menu.

- (void) displayActionMenuForItem:(MvrItem*) i withRemove:(BOOL) remove withSend:(BOOL) send withMainAction:(BOOL) mainAction;
{
	MvrItemUI* ui = [MvrItemUI UIForItem:i];
	
	L0ActionSheet* as = [[L0ActionSheet new] autorelease];
	as.tag = kMvrAppDelegateItemActionSheetTag;
	as.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
	[as setValue:i forKey:@"MvrItem"];
	
#if kMvrIsLite
	if (![i isKindOfClass:[MvrImageItem class]] && ![i isKindOfClass:[MvrContactItem class]])
		send = NO;
#endif
	
	if (mainAction) {
		MvrItemAction* main = [ui mainActionForItem:i];
		if (main)
			[as addButtonWithTitle:main.displayName identifier:main];
	}
	
	if (send && [self.tableController.currentMode.mutableDestinations count] > 0)
		[as addButtonWithTitle:NSLocalizedString(@"Send", @"Send button in action menu") identifier:kMvrAppDelegateSendButtonIdentifier];
	
	for (MvrItemAction* a in [ui additionalActionsForItem:i]) {
		if ([a isAvailableForItem:i])
			[as addButtonWithTitle:a.displayName identifier:a];
	}
	
	if (remove && [ui isItemRemovable:i]) {
		
		if ([ui isItemSavedElsewhere:i])
			[as addButtonWithTitle:NSLocalizedString(@"Remove from Table", @"Remove button in item actions menu") identifier:kMvrAppDelegateRemoveButtonIdentifier];
		else 
			as.destructiveButtonIndex = [as addButtonWithTitle:NSLocalizedString(@"Delete", @"Delete button in item actions menu") identifier:kMvrAppDelegateDeleteButtonIdentifier];
		
	}
	
	as.cancelButtonIndex = [as addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel button on action sheet") identifier:kMvrAppDelegateCancelButtonIdentifier];

	as.delegate = self;
	[as showInView:self.window];
}

- (void) displaySendActionSheetForItem:(MvrItem*) i;
{
	L0ActionSheet* as = [[L0ActionSheet new] autorelease];
	as.tag = kMvrAppDelegateSendActionSheetTag;
	as.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
	[as setValue:i forKey:@"MvrItem"];
	
	as.title = NSLocalizedString(@"Send this item to:", @"Prompt for send action menu");
	
	MvrUIMode* mode = self.tableController.currentMode;
	
	for (id destination in mode.mutableDestinations) {
		[as addButtonWithTitle:[mode displayNameForDestination:destination] identifier:destination];
	}
	
	as.cancelButtonIndex = [as addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel button on action sheet") identifier:kMvrAppDelegateCancelButtonIdentifier];
	
	as.delegate = self;
	[as showInView:self.window];
}

#pragma mark -
#pragma mark Managing action sheets.

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex;
{
	L0ActionSheet* as = (L0ActionSheet*) actionSheet;
	switch (as.tag) {
		case kMvrAppDelegateAddSheetTag:
			if (buttonIndex != actionSheet.cancelButtonIndex)
				[[as identifierForButtonAtIndex:buttonIndex] beginAddingItem];
			break;
			
		case kMvrAppDelegateItemActionSheetTag: {
			id identifier = [as identifierForButtonAtIndex:buttonIndex];
			MvrItem* item = [as valueForKey:@"MvrItem"];
			
			if ([identifier isEqual:kMvrAppDelegateRemoveButtonIdentifier])
				[self.tableController removeItem:item];
			else if ([identifier isEqual:kMvrAppDelegateDeleteButtonIdentifier]) {

				L0ActionSheet* deleteConfirm = [[L0ActionSheet new] autorelease];
				deleteConfirm.tag = kMvrAppDelegateDeleteConfirmationSheetTag;
				deleteConfirm.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
				[deleteConfirm setValue:item forKey:@"MvrItem"];
				
				deleteConfirm.title = NSLocalizedString(@"This item is only saved on Mover's table. If you delete it, there will be no way to recover it.", @"Prompt on unsafe delete confirmation sheet");
				
				deleteConfirm.destructiveButtonIndex = [deleteConfirm addButtonWithTitle:NSLocalizedString(@"Delete", @"Delete button in the unsafe delete confirmation sheet") identifier:kMvrAppDelegateDeleteButtonIdentifier];
				
				deleteConfirm.cancelButtonIndex = [deleteConfirm addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel button on action sheet") identifier:kMvrAppDelegateCancelButtonIdentifier];
				
				deleteConfirm.delegate = self;
				[deleteConfirm showInView:self.window];
			
			} else if ([identifier isEqual:kMvrAppDelegateSendButtonIdentifier])
				[self displaySendActionSheetForItem:item];
			else if (buttonIndex != actionSheet.cancelButtonIndex)
				[identifier performActionWithItem:item];
			
			if (![identifier isEqual:kMvrAppDelegateDeleteButtonIdentifier])
				[self.tableController didEndDisplayingActionMenuForItem:item];
		}
			break;
			
		case kMvrAppDelegateSendActionSheetTag: {
			MvrItem* item = [as valueForKey:@"MvrItem"];
			
			if (buttonIndex != as.cancelButtonIndex) {
				id identifier = [as identifierForButtonAtIndex:buttonIndex];
				[self.tableController.currentMode sendItem:item toDestination:identifier];
			}
		}
			break;
			
		case kMvrAppDelegateDeleteConfirmationSheetTag: {
			MvrItem* item = [as valueForKey:@"MvrItem"];
			
			if ([[as identifierForButtonAtIndex:buttonIndex] isEqual:kMvrAppDelegateDeleteButtonIdentifier])
				[self.tableController removeItem:item];
			else
				[self.tableController didEndDisplayingActionMenuForItem:item];
		}
			break;
	}
}

#pragma mark -
#pragma mark Table controller

- (void) setUpTableController;
{
	[self.tableController setUp];
	
	for (MvrItem* i in self.storageCentral.storedItems)
		[self.tableController addItem:i animated:NO];
}

#pragma mark -
#pragma mark Utility methods

- (void) presentModalViewController:(UIViewController*) ctl;
{
	ctl.view.frame = self.window.bounds;
	UIViewController* vc = self.tableController;
	while (vc.modalViewController != nil)
		vc = vc.modalViewController;
	
	[vc presentModalViewController:ctl animated:YES];
}

#pragma mark -
#pragma mark Termination

- (void) applicationWillTerminate:(UIApplication *)application;
{
	[self.tableController tearDown];
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:4.0]];
}

#pragma mark -
#pragma mark Overlay view

@synthesize overlayWindow, overlayLabel, overlaySpinner;

- (void) beginDisplayingOverlayViewWithLabel:(NSString*) label;
{
	if (!overlayWindow.hidden) {
		CATransition* fade = [CATransition animation]; fade.type = kCATransitionFade;
		[overlayLabel.layer addAnimation:fade forKey:@"MvrAppDelegateFadeAnimation"];
	}
	
	overlayLabel.text = label;
	
	if (!overlayWindow.hidden) return;
	
	overlayWindow.windowLevel = UIWindowLevelStatusBar + 1;
	overlayWindow.frame = CGRectInset([UIScreen mainScreen].bounds, -100, -100);
	overlayWindow.alpha = 0.0;
	overlayWindow.transform = CGAffineTransformMakeScale(1.2, 1.2);
	[overlaySpinner startAnimating];
	[overlayWindow makeKeyAndVisible];
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
	[UIView setAnimationDuration:0.5];
	
	overlayWindow.alpha = 1.0;
	overlayWindow.transform = CGAffineTransformIdentity;
	
	[UIView commitAnimations];
	
	MvrAccessibilityDidChangeScreen();
}

- (void) endDisplayingOverlayView;
{
	if (overlayWindow.hidden) return;
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDuration:0.3];
	[UIView setAnimationDidStopSelector:@selector(endDisplayingOverlayViewAnimation:didEnd:context:)];
	
	overlayWindow.transform = CGAffineTransformMakeScale(0.9, 0.9);
	overlayWindow.alpha = 0.0;
	
	[UIView commitAnimations];
}

- (void) endDisplayingOverlayViewAnimation:(NSString*) ani didEnd:(BOOL) finished context:(void*) context;
{
	[overlaySpinner stopAnimating];
	overlayWindow.hidden = YES;
}	

#pragma mark -
#pragma mark Mode availability & switches

- (IBAction) moveToBluetoothMode;
{
	if (self.bluetoothMode.available)
		self.tableController.currentMode = self.bluetoothMode;
}

- (IBAction) moveToWiFiMode;
{
	self.tableController.currentMode = self.wifiMode;
}

#pragma mark -
#pragma mark About pane

- (IBAction) showAboutPane;
{
	MvrAboutPane* about = [MvrAboutPane modalPane];
	[self presentModalViewController:about];
}

#if DEBUG

- (void) testByPerformingAlertParade;
{
	NSArray* allResources = [[NSFileManager defaultManager] directoryContentsAtPath:[[NSBundle mainBundle] resourcePath]];
	
	for (NSString* resource in allResources) {
		if ([[resource pathExtension] isEqual:@"alert"]) {
			UIAlertView* a = [UIAlertView alertNamed:[resource stringByDeletingPathExtension]];
			[a show];
		}
	}
}

#endif

- (UIView*) actionSheetOriginView;
{
	return self.tableController.toolbar;
}

@end
