//
//  Mover3_iPadAppDelegate.m
//  Mover3-iPad
//
//  Created by ∞ on 14/04/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "MvrAppDelegate_iPad.h"
#import "MvrTableController_iPad.h"

#warning Test
#import "MvrDraggableView.h"
#import "MvrItemController.h"

#import "MvrImageItem.h"
#import "MvrImageItemController.h"
#import "MvrContactItem.h"
#import "MvrContactItemController.h"

#import <AddressBook/AddressBook.h>

@implementation MvrAppDelegate_iPad

@synthesize window;
@synthesize viewController;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {	
	
// ------------ SETUP: Network + Observer
	[MvrImageItem registerClass];
	[MvrImageItemController registerClass];
	
	[MvrContactItem registerClass];
	[MvrContactItemController registerClass];
	
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
	MvrImageItem* img = [[MvrImageItem alloc] initWithImage:[UIImage imageNamed:@"IMG_0439.jpg"] type:@"public.jpeg"];
	[viewController addItem:img fromSource:nil ofType:kMvrItemSourceSelf];	
	
	ABRecordRef ref = ABPersonCreate();
	ABRecordSetValue(ref, kABPersonFirstNameProperty, (CFTypeRef) @"Pinco", NULL);
	ABRecordSetValue(ref, kABPersonLastNameProperty, (CFTypeRef) @"Pallo", NULL);

	ABMultiValueRef email = ABMultiValueCreateMutable(kABMultiStringPropertyType);
	ABMultiValueAddValueAndLabel(email, (CFTypeRef) @"pinco@pallo.net", kABWorkLabel, NULL);
	ABRecordSetValue(ref, kABPersonEmailProperty, email, NULL);
	
	MvrContactItem* ci = [[[MvrContactItem alloc] initWithContentsOfAddressBookRecord:ref] autorelease];
	[viewController addItem:ci fromSource:nil ofType:kMvrItemSourceSelf];
	
	CFRelease(email);
	CFRelease(ref);
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

@end
