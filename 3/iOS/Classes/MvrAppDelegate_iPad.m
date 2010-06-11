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

#import "Network+Storage/MvrItem.h"
#import "Network+Storage/MvrItemStorage.h"

#import "MvrImageItem.h"
#import "MvrImageItemController.h"
#import "MvrContactItem.h"
#import "MvrContactItemController.h"

#import "MvrVideoItem.h"
#import "MvrVideoItemController.h"

#import "Network+Storage/MvrGenericItem.h"
#import "MvrGenericItemController.h"

#import <fcntl.h>
#import <sys/types.h>
#import <sys/event.h>
#import <sys/time.h>

#define ILAssertNoNSError(errVarName, call) \
{ \
	NSError* errVarName; \
	if (!(call)) \
		[NSException raise:@"ILUnexpectedNSErrorException" format:@"Operation " #call " failed with error %@", errVarName]; \
}

static inline BOOL MvrIsDirectory(NSString* path) {
	BOOL exists, isDir;
	exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
	return exists && isDir;
}
		
@interface MvrAppDelegate_iPad ()

- (void) openFileAtPath:(NSString *)path;
- (MvrItem *) itemForUnidentifiedFileAtPath:(NSString *)path;
- (void) addItemForUnidentifiedFileAtPath:(NSString *)path;
- (void) clearInbox;

- (void) beginMonitoringItemsDirectory;
- (void) cancelMonitoringItemsDirectory;
- (void) scheduleItemsDirectorySweep;
- (void) performItemsDirectorySweep;

@end


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
	
// ------------- SETUP: Messages From The Cloud
	
	messageChecker = [MvrMessageChecker new];
	[messageChecker performSelector:@selector(checkIfNeeded) withObject:nil afterDelay:7.0];
	
// ------------- SETUP: UI
	application.idleTimerDisabled = YES;
	
	[window addSubview:viewController.view];
	[window makeKeyAndVisible];

	for (MvrItem* i in self.storage.storedItems)
		[viewController addItem:i fromSource:nil ofType:kMvrItemSourceSelf];
	
// ------------- Handle file opening
	NSURL* u = [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];
	if ([u isFileURL])
		[self openFileAtPath:[u path]];
	
	[self clearInbox];
	
// ------------- Begin monitoring Documents for File Sharing
	[self beginMonitoringItemsDirectory];
	[self performItemsDirectorySweep];
	
	return YES;
}

- (BOOL) application:(UIApplication *)application handleOpenURL:(NSURL *)u;
{
	if ([u isFileURL])
		[self openFileAtPath:[u path]];
	
	[self clearInbox];
	
	return YES;	
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

- (void)dealloc {
	[wifi release];
	
	[messageChecker release];
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
		
		// [fm createDirectoryAtPath:docsDir withIntermediateDirectories:YES attributes:nil error:NULL];
		if (![fm fileExistsAtPath:docsDir])
			ILAssertNoNSError(e, [fm createDirectoryAtPath:docsDir withIntermediateDirectories:YES attributes:nil error:&e]);
							  
		// [fm createDirectoryAtPath:metaDir withIntermediateDirectories:YES attributes:nil error:NULL];
		if (![fm fileExistsAtPath:metaDir])
			ILAssertNoNSError(e, [fm createDirectoryAtPath:metaDir withIntermediateDirectories:YES attributes:nil error:&e]);
		
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

#pragma mark Services

- (BOOL) helpAlertsSuppressed;
{
#warning TODO
	return NO;
}

@synthesize messageChecker;

- (MvrTellAFriendController *) tellAFriend;
{
	return nil;
}

#pragma mark Adding unidentified files

- (MvrItem*) itemForUnidentifiedFileAtPath:(NSString*) path;
{
	id type = [NSMakeCollectable(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef) [path pathExtension], NULL)) autorelease];
		
	if (!type)
		type = [[MvrItem typesForFallbackPathExtension:[path pathExtension]] anyObject];
	
	if (!type)
		type = (id) kUTTypeData;
	
	BOOL shouldMakePersistent = ([[[path stringByDeletingLastPathComponent] stringByStandardizingPath] isEqual:[storage.itemsDirectory stringByStandardizingPath]]);
	
	NSError* e;
	MvrItemStorage* s = [MvrItemStorage itemStorageFromFileAtPath:path options:shouldMakePersistent? kMvrItemStorageIsPersistent : kMvrItemStorageCanMoveOrDeleteFile error:&e];
	if (!s) {
		L0LogAlways(@"Could not create item storage (persistent? %d) for file at path %@: error %@", shouldMakePersistent, path, e);
		return nil;
	}
	
	NSDictionary* m = [NSDictionary dictionaryWithObjectsAndKeys:
					   [path lastPathComponent], kMvrItemOriginalFilenameMetadataKey,
					   [[NSFileManager defaultManager] displayNameAtPath:path], kMvrItemTitleMetadataKey,
					   nil];
	
	return [MvrItem itemWithStorage:s type:type metadata:m];
}

- (void) addItemForUnidentifiedFileAtPath:(NSString*) path;
{
	MvrItem* i = [self itemForUnidentifiedFileAtPath:path];
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
	@synchronized(self) {
		shouldMonitorDirectory = YES;
	}
	
	[NSThread detachNewThreadSelector:@selector(runKQueueToMonitorDirectory:) toTarget:self withObject:[[self.storage.itemsDirectory copy] autorelease]];
}

- (BOOL) shouldMonitorDirectory;
{
	@synchronized(self) {
		return shouldMonitorDirectory;
	}
}

- (void) cancelMonitoringItemsDirectory;
{
	@synchronized(self) {
		shouldMonitorDirectory = NO;
	}
}

- (void) runKQueueToMonitorDirectory:(NSString*) dir;
{
	NSAutoreleasePool* pool = [NSAutoreleasePool new];
	
	int fdes = open([dir fileSystemRepresentation], O_RDONLY);
	if (fdes == -1)
		goto cleanup;
	
	int kq = kqueue();
	if (kq == -1)
		goto cleanup;
	
	struct kevent toMonitor;
	EV_SET(&toMonitor, fdes, EVFILT_VNODE, EV_ADD | EV_ENABLE | EV_ONESHOT,
		   NOTE_WRITE | NOTE_EXTEND | NOTE_DELETE,
		   0, 0);
	
	while ([self shouldMonitorDirectory]) {
		NSAutoreleasePool* innerPool = [NSAutoreleasePool new];
		
		const struct timespec time = { 1, 0 };
		struct kevent event;

		int result = kevent(kq, &toMonitor, 1, &event, 1, &time);
		
		if (result > 0)
			[self performSelectorOnMainThread:@selector(scheduleItemsDirectorySweep) withObject:nil waitUntilDone:NO];
		
		[innerPool release];
		
		if (result == -1)
			break;
	}
	
cleanup:
	if (kq != -1)
		close(kq);
	
	if (fdes != -1)
		close(fdes);
	
	[pool release];
}

- (void) scheduleItemsDirectorySweep;
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(performItemsDirectorySweep) object:nil];
	[self performSelector:@selector(performItemsDirectorySweep) withObject:nil afterDelay:2.0];
}

- (void) performItemsDirectorySweep;
{
	L0Note();
	
	NSFileManager* fm = [NSFileManager defaultManager];
	
	NSString* idir = self.storage.itemsDirectory;
	
	for (NSString* item in [fm contentsOfDirectoryAtPath:self.storage.itemsDirectory error:NULL]) {
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

@end
