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

@interface MvrAppDelegate ()

- (void) setUpItemClassesAndUIs;
- (void) setUpStorageCentral;
- (void) setUpTableController;

@end

enum {
	kMvrAppDelegateAddSheetTag,
};

@implementation MvrAppDelegate

- (void) applicationDidFinishLaunching:(UIApplication*) application;
{	
	[self setUpItemClassesAndUIs];
	[self setUpStorageCentral];
	[self setUpTableController];
	
	[self.topViewController viewWillAppear:NO];
	self.topViewController.view.frame = self.window.bounds;
	[self.window addSubview:self.topViewController.view];
	[self.topViewController viewDidAppear:NO];
	
    [self.window makeKeyAndVisible];
}

@synthesize window, topViewController, tableController;

- (void) dealloc;
{
	[storageCentral release];
	[itemsDirectory release];
	[metadata release];
	
	[identifierForSelf release];
	
	[window release];
	[topViewController release];
	[tableController release];
	
    [super dealloc];
}

#pragma mark -
#pragma mark Item classes and UIs.

- (void) setUpItemClassesAndUIs;
{
	[MvrGenericItem registerClass];
	[MvrGenericItemUI registerClass];
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
	return [UIDevice currentDevice].name;
}

#pragma mark -
#pragma mark Adding

#define kMvrCancelButtonIdentifier @"Cancel"

- (IBAction) add;
{
	L0ActionSheet* sheet = [[L0ActionSheet new] autorelease];
	sheet.tag =	kMvrAppDelegateAddSheetTag;
	
	for (MvrItemSource* source in [MvrItemSource registeredItemSources])
		 [sheet addButtonWithTitle:source.displayName identifier:source];
	
	NSInteger index = [sheet addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel button on Add sheet") identifier:kMvrCancelButtonIdentifier];
	sheet.cancelButtonIndex = index;
	
	sheet.delegate = self;
	[sheet showInView:self.window];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex;
{
	if (buttonIndex == actionSheet.cancelButtonIndex)
		return;
	
	[[(L0ActionSheet*)actionSheet identifierForButtonAtIndex:buttonIndex] beginAddingItem];
}

#pragma mark -
#pragma mark Table controller

- (void) setUpTableController;
{
	[self.tableController setUp];
	
	for (MvrItem* i in self.storageCentral.storedItems)
		[self.tableController addItem:i];
}
@end
