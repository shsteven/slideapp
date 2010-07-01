//
//  Mover3_iPadAppDelegate.m
//  Mover3-iPad
//
//  Created by ∞ on 14/04/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "MvrAppDelegate_iPad.h"

#import <AddressBook/AddressBook.h>

#import "MvrItemController.h"

#import "Network+Storage/MvrItem.h"
#import "MvrItem+UnidentifiedFileAdding.h"
#import "Network+Storage/MvrItemStorage.h"
#import "MvrStorage+iOSStandardInit.h"

#import "MvrImageItem.h"
#import "MvrImageItemController.h"
#import "MvrVideoItem.h"
#import "MvrVideoItemController.h"
#import "MvrContactItem.h"
#import "MvrContactItemController.h"
#import "MvrTextItem.h"
#import "MvrTextItemController.h"
#import "MvrBookmarkItem.h"
#import "MvrBookmarkItemController.h"

#import "Network+Storage/MvrGenericItem.h"
#import "MvrGenericItemController.h"

#import "MvrAppDelegate+HelpAlerts.h"

#define kMvrSoundsEffectsEnabledDefaultsKey @"MvrSoundEffectsEnabled"

@interface MvrAppDelegate_iPad ()

- (void) openFileAtPath:(NSString *)path;
- (void) addItemForUnidentifiedFileAtPath:(NSString *)path;
- (void) clearInbox;

- (void) beginMonitoringItemsDirectory;

- (void) setCurrentScanner:(id <MvrScanner>) s;

- (void) clearGameKitPicker;

- (void) performItemsDirectorySweep:(MvrDirectoryWatcher *)w;

@end


@implementation MvrAppDelegate_iPad

@synthesize window;
@synthesize viewController;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	
// ------------- BEFORE WE START: Monitor for crashes.
	crashReporting = [MvrCrashReporting new];
	[crashReporting enableReporting];
	
// ------------ SETUP: Network + Observer
	[MvrGenericItemController registerClass];
	
	[MvrImageItem registerClass];
	[MvrImageItemController registerClass];
	
	[MvrContactItem registerClass];
	[MvrContactItemController registerClass];
	
	[MvrVideoItem registerClass];
	[MvrVideoItemController registerClass];
	
	[MvrTextItem registerClass];
	[MvrTextItemController registerClass];
	
	[MvrBookmarkItem registerClass];
	[MvrBookmarkItemController registerClass];
	
	wifi = [[MvrModernWiFi alloc] initWithPlatformInfo:self serverPort:kMvrModernWiFiPort options:kMvrUseMobileService|kMvrAllowBrowsingForConduitService|kMvrAllowConnectionsFromConduitService];
	
	observer = [[MvrScannerObserver alloc] initWithScanner:wifi delegate:self];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyOfNetworkTrouble:) name:kMvrModernWiFiDifficultyStartingListenerNotification object:nil];
	
	wifi.enabled = YES;
	
// ------------- SETUP: Messages From The Cloud
	
	messageChecker = [MvrMessageChecker new];
	[messageChecker performSelector:@selector(checkIfNeeded) withObject:nil afterDelay:7.0];
	
// ------------- SETUP: UI
	application.idleTimerDisabled = YES;
	
	[window addSubview:viewController.view];
	[window makeKeyAndVisible];
	
	for (MvrItem* i in self.storage.storedItems)
		[viewController addItem:i fromSource:nil ofType:kMvrItemSourceSelf];
	
	soundEffects = [MvrSoundEffects new];
	id on = [[NSUserDefaults standardUserDefaults] objectForKey:kMvrSoundsEffectsEnabledDefaultsKey];
	soundEffects.enabled = on? [on boolValue] : YES;
	
// ------------- Handle file opening
	NSURL* u = [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];
	if ([u isFileURL])
		[self openFileAtPath:[u path]];
	
	[self clearInbox];
	
// ------------- Begin monitoring Documents for File Sharing
	[self beginMonitoringItemsDirectory];
	[self performItemsDirectorySweep:nil];

// ------------- Fix up pending crash reports
	[crashReporting checkForPendingReports];
	
	
// ------------- Aaaaand, welcome!
	[MvrAlertIfNotShownBeforeNamed(@"MvrWelcome") show];
	
	return YES;
}

- (BOOL) application:(UIApplication *)application handleOpenURL:(NSURL *)u;
{
	if ([u isFileURL])
		[self openFileAtPath:[u path]];
	
	[self clearInbox];
	
	return YES;	
}

- (void) notifyOfNetworkTrouble:(NSNotification*) n;
{
	if (!didShowNetworkTroubleAlert) {
		[[UIAlertView alertNamed:@"MvrNetworkTrouble"] show];
		didShowNetworkTroubleAlert = YES;
	}
	
	if (wifi.enabled) {
		wifi.enabled = NO;
		[self performSelector:@selector(reenableWiFi) withObject:nil afterDelay:2.0];
	}
}

- (void) reenableWiFi;
{
	if (self.currentScanner == wifi)
		wifi.enabled = YES;
}

- (void) openFileAtPath:(NSString*) path;
{
	[self addItemForUnidentifiedFileAtPath:path];	
}

- (void) clearInbox;
{
	// Delete the inbox
	NSString* inboxDir = [self.storage.itemsDirectory stringByAppendingPathComponent:@"Inbox"];
	NSFileManager* fm = [NSFileManager defaultManager];
	NSArray* content = [fm contentsOfDirectoryAtPath:inboxDir error:NULL];
	if (content)
		[fm removeItemAtPath:inboxDir error:NULL];
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
	if (i)
		[viewController addItem:i fromSource:[incoming channel] ofType:kMvrItemSourceChannel];
	
	[soundEffects endPlayingTransferSoundSucceding:(i != nil)];
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
		storage = [[MvrStorage iOSStorage] retain];
		[storage migrateFrom30StorageInUserDefaultsIfNeeded];
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

#pragma mark Services

- (BOOL) helpAlertsSuppressed;
{
	return NO;
}

@synthesize messageChecker;

- (MvrTellAFriendController *) tellAFriend;
{
	if (!tellAFriend)
		tellAFriend = [MvrTellAFriendController new];
	
	return tellAFriend;
}

#pragma mark Adding unidentified files

- (void) addItemForUnidentifiedFileAtPath:(NSString*) path;
{
	BOOL shouldMakePersistent = ([[[path stringByDeletingLastPathComponent] stringByStandardizingPath] isEqual:[storage.itemsDirectory stringByStandardizingPath]]);
	
	MvrItem* i = [MvrItem itemForUnidentifiedFileAtPath:path options:shouldMakePersistent? kMvrItemStorageIsPersistent : kMvrItemStorageCanMoveOrDeleteFile];
	if (i) {
		if (i.storage.persistent)
			[self.storage adoptPersistentItem:i];
		else
			[self.storage addStoredItemsObject:i];
	}
	
	[viewController addItem:i fromSource:nil ofType:kMvrItemSourceSelf];
}

#pragma mark Monitoring the Documents directory

- (void) beginMonitoringItemsDirectory;
{
	if (!itemsDirectoryWatcher)
		itemsDirectoryWatcher = [[MvrDirectoryWatcher alloc] initForDirectoryAtPath:[[self.storage.itemsDirectory copy] autorelease] target:self selector:@selector(scheduleItemsDirectorySweep:)];
	
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
	
	NSString* idir = self.storage.itemsDirectory;
	
	for (NSString* item in [fm contentsOfDirectoryAtPath:self.storage.itemsDirectory error:NULL]) {
		if ([item hasPrefix:@"."])
			continue; // no hidden files.
		
		NSString* fullPath = [idir stringByAppendingPathComponent:item];
		
		if (MvrIsDirectory(fullPath))
			L0Log(@"Skipping %@ -- is a directory", fullPath);
		else if ([self.storage hasItemForFileAtPath:fullPath])
			L0Log(@"Skipping %@ -- is already known", fullPath);
		else { // if (!MvrIsDirectory(fullPath) && ![self.storage hasItemForFileAtPath:fullPath])
			L0Log(@"Adding new file %@", fullPath);
			[self addItemForUnidentifiedFileAtPath:fullPath];
		}
	}
	
	for (MvrItem* i in [[self.storage.storedItems copy] autorelease]) {
		if (i.storage.hasPath && ![fm fileExistsAtPath:i.storage.path]) {
			[self.viewController removeItem:i];
			[self.storage removeStoredItemsObject:i];
		}
	}
}

#pragma mark Current scanner & Bluetooth operation

- (id <MvrScanner>) currentScanner;
{
	if (!currentScanner)
		currentScanner = self.wifi;
	
	return currentScanner;
}

- (void) setCurrentScanner:(id <MvrScanner>) n;
{
	if (n != currentScanner) {
		[currentScanner release];
		currentScanner = [n retain];
		
		[observer release];
		observer = [[MvrScannerObserver alloc] initWithScanner:n delegate:self];
	}
}

- (void) switchToBluetooth;
{
	if ((bluetooth && self.currentScanner == bluetooth) || picker)
		return;
	
	if (!bluetooth)
		bluetooth = [[MvrBTScanner alloc] init];
	
	self.currentScanner = bluetooth;
	
	wifi.enabled = NO;
	didPickBluetoothChannel = NO;
	[self beginPickingBluetoothChannel];
}

- (IBAction) beginPickingBluetoothChannel;
{
	if (!bluetooth || self.currentScanner != bluetooth)
		return;
	
	if (!picker) {
		picker = [[GKPeerPickerController alloc] init];
		picker.connectionTypesMask = GKPeerPickerConnectionTypeNearby;
		picker.delegate = self;
	}
	
	if (!picker.visible)
		[picker show];
}

- (void) peerPickerControllerDidCancel:(GKPeerPickerController *)picker;
{
	[self clearGameKitPicker];
	
	if (!didPickBluetoothChannel)
		[self switchToWiFi];
}

- (void) clearGameKitPicker;
{
	picker.delegate = nil;
	[picker release]; picker = nil;	
}

- (void) peerPickerController:(GKPeerPickerController *)p didConnectPeer:(NSString *)peerID toSession:(GKSession *)session;
{
	bluetooth.session = session;
	[bluetooth acceptPeerWithIdentifier:peerID];
	
	[picker dismiss];
	[self clearGameKitPicker];
	
	didPickBluetoothChannel = YES;
}

- (GKSession *) peerPickerController:(GKPeerPickerController *)picker sessionForConnectionType:(GKPeerPickerConnectionType)type;
{
	if (type == GKPeerPickerConnectionTypeNearby)
		return [bluetooth configuredSession];
	else
		return nil;
}

- (void) switchToWiFi;
{
	if (self.currentScanner == wifi)
		return;
	
	wifi.enabled = YES;
	self.currentScanner = wifi;
	
	[picker dismiss];
	[self clearGameKitPicker];
	
	bluetooth.enabled = NO;
	[bluetooth release]; bluetooth = nil;
}

#pragma mark Sound effects

- (void) scanner:(id <MvrScanner>)s didAddChannel:(id <MvrChannel>)channel;
{
	[soundEffects playChannelNowAvailable];
}

- (void) scanner:(id <MvrScanner>)s didRemoveChannel:(id <MvrChannel>)channel;
{
	[soundEffects playChannelDisconnected];
}

- (void) channel:(id <MvrChannel>)c didBeginReceivingWithIncomingTransfer:(id <MvrIncoming>)incoming;
{
	[soundEffects beginPlayingTransferSound];
}

- (BOOL) soundsAvailable;
{
	return YES;
}

- (BOOL) soundsEnabled;
{
	return soundEffects.enabled;
}

- (void) setSoundsEnabled:(BOOL) e;
{
	soundEffects.enabled = e;
	[[NSUserDefaults standardUserDefaults] setBool:e forKey:kMvrSoundsEffectsEnabledDefaultsKey];
}

@end
