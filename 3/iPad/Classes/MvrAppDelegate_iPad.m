//
//  Mover3_iPadAppDelegate.m
//  Mover3-iPad
//
//  Created by ∞ on 14/04/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "MvrAppDelegate_iPad.h"

#import <AddressBook/AddressBook.h>

#warning Test
#import "MvrDraggableView.h"
#import "MvrItemController.h"

#import "MvrImageItem.h"
#import "MvrImageItemController.h"
#import "MvrContactItem.h"
#import "MvrContactItemController.h"

#import "MvrVideoItem.h"
#import "MvrVideoItemController.h"

#import "Network+Storage/MvrGenericItem.h"
#import "MvrGenericItemController.h"

@implementation MvrAppDelegate_iPad

@synthesize window;
@synthesize viewController;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {	
	
// ------------ SETUP: Network + Observer
	[MvrGenericItemController registerClass];
	
	[MvrImageItem registerClass];
	[MvrImageItemController registerClass];
	
	[MvrContactItem registerClass];
	[MvrContactItemController registerClass];
	
	[MvrVideoItem registerClass];
	[MvrVideoItemController registerClass];
	
	wifi = [[MvrModernWiFi alloc] initWithPlatformInfo:self serverPort:kMvrModernWiFiPort options:kMvrUseMobileService|kMvrAllowBrowsingForConduitService|kMvrAllowConnectionsFromConduitService];
	
	observer = [[MvrScannerObserver alloc] initWithScanner:wifi delegate:self];
	
	wifi.enabled = YES;
	
// ------------- SETUP: UI
	application.idleTimerDisabled = YES;
	
	[window addSubview:viewController.view];
	[window makeKeyAndVisible];

	[self performSelector:@selector(testByAddingImageAndContact) withObject:nil afterDelay:1.0];
	
	return YES;
}

- (void) testByAddingImageAndContact;
{
	//MvrImageItem* img = [[MvrImageItem alloc] initWithImage:[UIImage imageNamed:@"IMG_0439.jpg"] type:@"public.jpeg"];
//	[viewController addItem:img fromSource:nil ofType:kMvrItemSourceSelf];	
//	
//	ABRecordRef ref = ABPersonCreate();
//	ABRecordSetValue(ref, kABPersonFirstNameProperty, (CFTypeRef) @"Pinco", NULL);
//	ABRecordSetValue(ref, kABPersonLastNameProperty, (CFTypeRef) @"Pallo", NULL);
//
//	ABMultiValueRef email = ABMultiValueCreateMutable(kABMultiStringPropertyType);
//	ABMultiValueAddValueAndLabel(email, (CFTypeRef) @"pinco@pallo.net", kABWorkLabel, NULL);
//	ABRecordSetValue(ref, kABPersonEmailProperty, email, NULL);
//	
//	MvrContactItem* ci = [[[MvrContactItem alloc] initWithContentsOfAddressBookRecord:ref] autorelease];
//	[viewController addItem:ci fromSource:nil ofType:kMvrItemSourceSelf];
//	
//	CFRelease(email);
//	CFRelease(ref);
//	
//	[self.storage addStoredItemsObject:img];
//	[self.storage addStoredItemsObject:ci];
	
	for (MvrItem* i in self.storage.storedItems)
		[viewController addItem:i fromSource:nil ofType:kMvrItemSourceSelf];
}

- (void)dealloc {
	[wifi release];
	
	[viewController release];
	[window release];
	[super dealloc];
}

@synthesize wifi;

#pragma mark Platform info

- (NSString *) displayNameForSelf;
{
	return [UIDevice currentDevice].name;
}

- (L0UUID*) identifierForSelf;
{
	if (!selfIdentifier)
		selfIdentifier = [[L0UUID UUID] retain];
	
	return selfIdentifier;
}

- (MvrAppVariant) variant;
{
	return kMvrAppVariantMoverOpen;
}

- (NSString *) variantDisplayName;
{
	return @"Mover";
}

- (id) platform;
{
	return kMvrAppleiPhoneOSPlatform;
}

- (double) version;
{
	return [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] doubleValue];
}

- (NSString *) userVisibleVersion;
{
	return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

#pragma mark Receiving

- (void) incomingTransfer:(id <MvrIncoming>)incoming didEndReceivingItem:(MvrItem *)i;
{
	[viewController addItem:i fromSource:[incoming channel] ofType:kMvrItemSourceChannel];
}

#pragma mark Cleaning up

- (void) applicationWillTerminate:(UIApplication *)application;
{
	wifi.enabled = NO;
}

#pragma mark Storage

- (MvrStorage*) storage;
{
	if (!storage) {
		// TODO support Open /Mover Items subdirectory
		NSString* docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
		NSString* metaDir = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
		metaDir = [metaDir stringByAppendingPathComponent:@"Mover Metadata"];
		
		NSFileManager* fm = [NSFileManager defaultManager];
		
		[fm createDirectoryAtPath:docsDir withIntermediateDirectories:YES attributes:nil error:NULL];
		[fm createDirectoryAtPath:metaDir withIntermediateDirectories:YES attributes:nil error:NULL];
		
		storage = [[MvrStorage alloc] initWithItemsDirectory:docsDir metadataDirectory:metaDir];
	}
	
	return storage;
}

#pragma mark Modal VCs

- (void) presentModalViewController:(UIViewController*) vc;
{
	UIViewController* modalParent = viewController;
	while (modalParent.modalViewController)
		modalParent = modalParent.modalViewController;
	
	[modalParent presentModalViewController:vc animated:YES];
}

@end
