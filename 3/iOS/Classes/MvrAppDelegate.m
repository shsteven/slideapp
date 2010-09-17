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
#import "MvrStorage+iOSStandardInit.h"

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
#import "MvrPreviewableItem.h"
#import "MvrPreviewableItemUI.h"

#import "MvrPasteboardItemSource.h"

#import "MvrAccessibility.h"

#import "MvrAboutPane.h"

#import "MvrAppDelegate+HelpAlerts.h"

#import "MvrAdActingController.h"

#import <MuiKit/MuiKit.h>
#import <QuartzCore/QuartzCore.h>

#import <SwapKit/SwapKit.h>

#import "MvrItem+UnidentifiedFileAdding.h"

#if kMvrIsLite
#import "MvrStore.h"
#endif

@interface MvrAppDelegate () <ILSwapServiceDelegate>

- (void) setUpItemClassesAndUIs;
- (void) setUpStorageCentral;
- (void) setUpTableController;

- (BOOL) performActionsForURL:(NSURL*) url;
- (void) addByOpeningFileAtPath:(NSString *)path;

- (void) setUpDirectoryWatching;
- (void) addItemForUnidentifiedFileAtPath:(NSString *)path;
- (void) performItemsDirectorySweep:(MvrDirectoryWatcher *)w;
- (void) scheduleItemsDirectorySweep:(MvrDirectoryWatcher *)w;

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

	if ([UIDevice instancesRespondToSelector:@selector(isMultitaskingSupported)] && [[UIDevice currentDevice] isMultitaskingSupported]) {
		// if we're multitasking, we schedule a second check after a few hours, so that it can still trigger if we're kept alive for a long-ish time.
		// checks are triggered every three hours. this doesn't mean they're DONE -- the call below still obeys our self-imposed limits (once per day/week on WWAN).
		[self performSelector:@selector(performPeriodicMessagesCheck) withObject:nil afterDelay:(3 * 60 * 60)];
	}
		
#if DEBUG
	if ([[[[NSProcessInfo processInfo] environment] objectForKey:@"MvrTestByPerformingAlertParade"] boolValue]) {
		[self performSelector:@selector(testByPerformingAlertParade) withObject:nil afterDelay:3.0];
	}
#endif
	
#if kMvrInstrumentForAds
	[[MvrAdActingController sharedAdController] start];
#endif
	
	[self showAlertIfNotShownBeforeNamed:@"MvrWelcome"];
	
#if kMvrIsLite
	[MvrStore setStoreUIBundleFromResource:@"StoreUI" ofType:@"bundle" inBundle:[NSBundle mainBundle]];
	
#if DEBUG
	if ([[[[NSProcessInfo processInfo] environment] objectForKey:@"MvrTestByRelockingAllProducts"] boolValue]) {
		[[MvrStore store] relockAllProducts];
	}
#endif
	
	[[MvrStore store] beginObservingTransactions];
#endif
	
	BOOL ok = [ILSwapService didFinishLaunchingWithOptions:options];
	
	NSURL* url = [options objectForKey:UIApplicationLaunchOptionsURLKey];
	if (!ok && url && ![url isFileURL])
		ok = [self performActionsForURL:url];
	
	[self setUpDirectoryWatching];
	
	return !url || [url isFileURL] || ok;
}

- (void) performPeriodicMessagesCheck;
{
	[messageChecker checkIfNeeded];
	[self performSelector:@selector(performPeriodicMessagesCheck) withObject:nil afterDelay:3 * 60 * 60];	
}

- (void) applicationWillResignActive:(UIApplication *)application;
{
	if (![self.tableController.currentMode isKindOfClass:[MvrWiFi class]])
		[self moveToWiFiMode];
}

- (BOOL) performActionsForURL:(NSURL*) url;
{
#if !kMvrIsLite
	if ([url isFileURL]) {
		[self addByOpeningFileAtPath:[url path]];
		return YES;
	}
	
	NSString* scheme = [url scheme];
	if ([scheme isEqual:kMvrLegacyAPIURLScheme]) {
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
	} else
		return NO;
#else
	return NO;
#endif
}
	

- (BOOL) application:(UIApplication *)application handleOpenURL:(NSURL *)url;  
{
	return [self performActionsForURL:url] || [ILSwapService handleOpenURL:url];
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
	
	[MvrPreviewableItem registerClass];
	[MvrPreviewableItemUI registerClass];
	
	[[MvrPasteboardItemSource sharedSource] registerSource];
}

#pragma mark -
#pragma mark Storage central.

#define kMvrItemsMetadataUserDefaultsKey @"L0SlidePersistedItems"

@synthesize storageCentral;

- (void) setUpStorageCentral;
{
	MvrStorageSetTemporaryDirectory(NSTemporaryDirectory());
	storageCentral = [[MvrStorage iOSStorage] retain];
	[storageCentral migrateFrom30StorageInUserDefaultsIfNeeded];
}

- (NSString *) itemsDirectory;
{
	return storageCentral.itemsDirectory;
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
	[self.storageCentral addStoredItemsObject:item];
}

- (void) addByOpeningFileAtPath:(NSString*) path;
{
	MvrItem* i = [MvrItem itemForUnidentifiedFileAtPath:path options:0];
	if (i)
		[self addItemFromSelf:i];
}

#pragma mark -
#pragma mark Directory watching.

- (void) setUpDirectoryWatching;
{
	if (!itemsDirectoryWatcher)
		itemsDirectoryWatcher = [[MvrDirectoryWatcher alloc] initForDirectoryAtPath:self.itemsDirectory target:self selector:@selector(scheduleItemsDirectorySweep:)];
	
	[itemsDirectoryWatcher start];
}

- (void) scheduleItemsDirectorySweep:(MvrDirectoryWatcher*) w;
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(performItemsDirectorySweep:) object:nil];
	[self performSelector:@selector(performItemsDirectorySweep:) withObject:w afterDelay:2.0];
}

- (void) performItemsDirectorySweep:(MvrDirectoryWatcher*) w;
{
	L0Note();
	
	NSFileManager* fm = [NSFileManager defaultManager];
	
	NSString* idir = self.itemsDirectory;
	
	for (NSString* item in [fm contentsOfDirectoryAtPath:self.itemsDirectory error:NULL]) {
		if ([item hasPrefix:@"."])
			continue; // no hidden files.
		
		NSString* fullPath = [idir stringByAppendingPathComponent:item];
		
		if (MvrIsDirectory(fullPath))
			L0Log(@"Skipping %@ -- is a directory", fullPath);
		else if ([self.storageCentral hasItemForFileAtPath:fullPath])
			L0Log(@"Skipping %@ -- is already known", fullPath);
		else { // if (!MvrIsDirectory(fullPath) && ![self.storage hasItemForFileAtPath:fullPath])
			L0Log(@"Adding new file %@", fullPath);
			[self addItemForUnidentifiedFileAtPath:fullPath];
		}
	}
	
	for (MvrItem* i in [[self.storageCentral.storedItems copy] autorelease]) {
		if (i.storage.hasPath && ![fm fileExistsAtPath:i.storage.path]) {
			[self.tableController removeItem:i];
			[self.storageCentral removeStoredItemsObject:i];
		}
	}
}

- (void) addItemForUnidentifiedFileAtPath:(NSString*) path;
{
	BOOL shouldMakePersistent = ([[[path stringByDeletingLastPathComponent] stringByStandardizingPath] isEqual:[self.storageCentral.itemsDirectory stringByStandardizingPath]]);
	
	MvrItem* i = [MvrItem itemForUnidentifiedFileAtPath:path options:shouldMakePersistent? kMvrItemStorageIsPersistent : kMvrItemStorageCanMoveOrDeleteFile];
	if (i) {
		if (i.storage.persistent)
			[self.storageCentral adoptPersistentItem:i];
		else
			[self.storageCentral addStoredItemsObject:i];
	}
	
	[self.tableController addItem:i animated:YES];
}

#pragma mark -
#pragma mark Displaying an action menu.

- (void) displayActionMenuForItem:(MvrItem*) i withRemove:(BOOL) remove withSend:(BOOL) send withMainAction:(BOOL) mainAction;
{
	MvrItemUI* ui = [MvrItemUI UIForItem:i];
	
	
	L0ActionSheet* as = [[L0ActionSheet new] autorelease];
	NSString* title = [ui actionMenuTitleForItem:i];
	if (title)
		as.title = title;

	
	as.tag = kMvrAppDelegateItemActionSheetTag;
	as.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
	[as setValue:i forKey:@"MvrItem"];
	
	if (![i isKindOfClass:[MvrImageItem class]] && ![i isKindOfClass:[MvrContactItem class]])
		send = NO;
	
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
	[as showInView:[self viewControllerForPresentingModalViewControllers].view];
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
				[deleteConfirm performSelector:@selector(showInView:) withObject:self.window afterDelay:0.01];
			
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

- (UIViewController*) viewControllerForPresentingModalViewControllers;
{
	UIViewController* vc = self.tableController;
	while (vc.modalViewController != nil)
		vc = vc.modalViewController;
	return vc;
}

- (void) presentModalViewController:(UIViewController*) ctl;
{
	ctl.view.frame = self.window.bounds;	
	[[self viewControllerForPresentingModalViewControllers] presentModalViewController:ctl animated:YES];
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
//	NSArray* allResources = [[NSFileManager defaultManager] directoryContentsAtPath:[[NSBundle mainBundle] resourcePath]];
	
	NSArray* allResources = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[[NSBundle mainBundle] resourcePath] error:NULL];
	
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

#pragma mark -
#pragma mark Feature availability

- (BOOL) isFeatureAvailable:(MvrStoreFeature) f;
{
#if !kMvrIsLite
	return YES;
#else
	return [[MvrStore store] featureIsAvailable:f];
#endif
}

#pragma mark Compiler warning silencing

@dynamic helpAlertsSuppressed; // defined in MvrAppDelegate+HelpAlerts.[hm]

- (BOOL) soundsEnabled;
{
	return NO;
}

- (void) setSoundsEnabled:(BOOL) e;
{}

- (BOOL) soundsAvailable;
{
	return NO;
}

- (BOOL) highQualityVideoEnabled;
{
	NSNumber* n = L0As(NSNumber, [[NSUserDefaults standardUserDefaults] objectForKey:kMvrHighQualityVideoEnabledKey]);
	return n? [n boolValue] : YES;
}

- (void) setHighQualityVideoEnabled:(BOOL) h;
{
	[[NSUserDefaults standardUserDefaults] setBool:h forKey:kMvrHighQualityVideoEnabledKey];
}

@end
