//
//  Mover3AppDelegate.m
//  Mover3
//
//  Created by ∞ on 12/09/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
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

#import <MuiKit/MuiKit.h>
#import <QuartzCore/QuartzCore.h>

@interface MvrAppDelegate ()

- (void) setUpItemClassesAndUIs;
- (void) setUpStorageCentral;
- (void) setUpTableController;

@end

#define kMvrAppDelegateRemoveButtonIdentifier @"kMvrAppDelegateRemoveButtonIdentifier"
#define kMvrAppDelegateDeleteButtonIdentifier @"kMvrAppDelegateDeleteButtonIdentifier"

enum {
	kMvrAppDelegateAddSheetTag,
	kMvrAppDelegateItemActionSheetTag,
	kMvrAppDelegateDeleteConfirmationSheetTag,
};

@implementation MvrAppDelegate

- (void) applicationDidFinishLaunching:(UIApplication*) application;
{	
	[self setUpItemClassesAndUIs];
	[self setUpStorageCentral];
	[self setUpTableController];
	
	[self.tableController viewWillAppear:NO];
	CGRect bounds = [self.window convertRect:[UIScreen mainScreen].applicationFrame fromWindow:nil];
	self.tableController.view.frame = bounds;
	[self.window addSubview:self.tableController.view];
	[self.tableController viewDidAppear:NO];
	
	self.overlayWindow.hidden = YES;
    [self.window makeKeyAndVisible];
}

- (BOOL) application:(UIApplication *)application handleOpenURL:(NSURL *)url;  
{
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
	
	return NO;
}

@synthesize window, tableController, wifiMode, bluetoothMode;

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
			BOOL created = [[NSFileManager defaultManager] createDirectoryAtPath:docsDir attributes:nil];
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
	if (!metadata) {
		metadata = [[NSUserDefaults standardUserDefaults] objectForKey:kMvrItemsMetadataUserDefaultsKey];
		if (![metadata isKindOfClass:[NSDictionary class]])
			metadata = [NSDictionary dictionary];
		
		[metadata retain];
	}
	
	return metadata;
}

- (void) setMetadata:(NSDictionary*) m;
{
	if (m != metadata) {
		[metadata release];
		metadata = [m copy];
		
		NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
		[ud setObject:m forKey:kMvrItemsMetadataUserDefaultsKey];
		[ud synchronize];
	}
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

- (NSString*) variantDisplayName;
{
	return @"Experimental"; // TODO
}

- (MvrAppVariant) variant;
{
	return kMvrAppVariantMoverOpenSource; // TODO
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
	[self.tableController addItem:item animated:YES]; // TODO
	[self.storageCentral.mutableStoredItems addObject:item];
}

#pragma mark -
#pragma mark Displaying an action menu.

- (void) displayActionMenuForItem:(MvrItem*) i withRemove:(BOOL) remove withMainAction:(BOOL) mainAction;
{
	MvrItemUI* ui = [MvrItemUI UIForItem:i];
	
	L0ActionSheet* as = [[L0ActionSheet new] autorelease];
	as.tag = kMvrAppDelegateItemActionSheetTag;
	as.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
	[as setValue:i forKey:@"MvrItem"];
	
	if (mainAction) {
		MvrItemAction* main = [ui mainActionForItem:i];
		if (main)
			[as addButtonWithTitle:main.displayName identifier:main];
	}
	
	for (MvrItemAction* a in [ui additionalActionsForItem:i])
		[as addButtonWithTitle:a.displayName identifier:a];
	
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
			
			} else if (buttonIndex != actionSheet.cancelButtonIndex) {
				[[as identifierForButtonAtIndex:buttonIndex] performActionWithItem:item];
			}
			
			if (![identifier isEqual:kMvrAppDelegateDeleteButtonIdentifier])
				[self.tableController didEndDisplayingActionMenuForItem:item];
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
#pragma mark Blueototh

- (IBAction) moveToBluetoothMode;
{
	self.tableController.currentMode = self.bluetoothMode;
}

- (IBAction) moveToWiFiMode;
{
	self.tableController.currentMode = self.wifiMode;
}

@end
