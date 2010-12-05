//
//  MvrDropboxSyncService.m
//  Mover3
//
//  Created by ∞ on 04/11/10.
//  Copyright 2010 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrDropboxSyncService.h"

#import "Network+Storage/MvrProtocol.h"

#import "Network+Storage/MvrItemStorage.h"
#import "DropboxSDK.h"

// TODO ew tying
#import "MvrStorage.h"

#define kMvrDropboxSavePath @"/Mover"

@interface MvrDropboxSyncTask : NSObject <MvrSyncTask, DBRestClientDelegate> {}

@property(retain) MvrItem* item;
@property(retain) DBRestClient* client;

@property(retain) NSString* finalFilename;

@property float progress;
@property(getter=isFinished) BOOL finished;
@property(copy) NSError* error;

- (void) beginPickingFinalFilename;

- (void) clear;
- (void) end;

@end

@implementation MvrDropboxSyncTask

- (id) initWithItem:(MvrItem*) i;
{
	if ((self = [super init])) {
		self.item = i;
		self.progress = kMvrIndeterminateProgress;
	}
	
	return self;
}

- (void) dealloc
{
	[self clear];
	self.error = nil;
	
	[super dealloc];
}


- (void) start;
{
	if (self.client || self.finished)
		return;
	
	self.client = [[[DBRestClient alloc] initWithSession:[DBSession sharedSession]] autorelease];
	self.client.delegate = self;
	
	// FOLLOW THE NUMBERS! --> [0]
	// First of all, we create the /Mover directory.
	[self.client createFolder:kMvrDropboxSavePath];
}

- (void) restClient:(DBRestClient *)client createdFolder:(DBMetadata *)folder;
{
	// [1] OK, let's proceed to making a filename that does not conflict with the stuff we have.
	[self beginPickingFinalFilename];
}

- (void) restClient:(DBRestClient *)client createFolderFailedWithError:(NSError *)error;
{
	if ([error code] == 403) { // folder already there
		[self beginPickingFinalFilename];
	} else {
		self.error = error;
		[self end]; // bail.
	}
}

- (void) beginPickingFinalFilename;
{
	// [2] check out the contents of that directory
	[self.client loadMetadata:kMvrDropboxSavePath];
}

- (void) restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata;
{
	// [3] actually pick a filename and start uploading the file
	NSMutableSet* unacceptableFilenames = [NSMutableSet set];

	for (DBMetadata* fileMD in metadata.contents)
		[unacceptableFilenames addObject:[fileMD.path lastPathComponent]];
	
	self.finalFilename = [MvrStorage userVisibleFilenameForItem:self.item unacceptableFilenames:unacceptableFilenames];
	
	[self.item setObject:[kMvrDropboxSavePath stringByAppendingPathComponent:self.finalFilename] forItemNotesKey:kMvrDropboxSyncPathKey];
	[self.client uploadFile:self.finalFilename toPath:kMvrDropboxSavePath fromPath:self.item.storage.path];
}

- (void) restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error;
{
	self.error = error;
	[self end];
}

- (void) restClient:(DBRestClient *)client uploadProgress:(CGFloat)progress forFile:(NSString *)destPath from:(NSString *)srcPath;
{
	self.progress = progress;
}

- (void) restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath from:(NSString *)srcPath;
{
	// [4] done!
	self.finalFilename = nil;
	[self end];
}

- (void) restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error;
{
	self.error = error;
	[self end];
}

- (void) cancel;
{
	self.error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];
	[self end];
}

- (void) cancelAndDoNotAttemptNewSync;
{
	self.error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:kMvrSyncErrorCannotReattemptSyncKey]];
	[self end];
}

- (void) end;
{
	self.finished = YES;
	[self clear];
}

- (void) clear;
{
	self.client.delegate = nil;
	
	if (self.finalFilename)
		[self.client cancelFileLoad:self.item.storage.path];
	
	self.client = nil;
	self.item = nil;
}

@synthesize item, client, finalFilename, progress, finished, error;

@end


// ------------------------------------------------

@interface MvrDropboxSyncService ()

- (void) beginSynchronizingItem:(MvrItem *)i;

@end


@implementation MvrDropboxSyncService

- (void) dealloc;
{
#if TARGET_OS_IPHONE
	loginController.delegate = nil;
	[loginController release];
	
	[modalLoginController release];
#endif
	
	[super dealloc];
}


+ sharedDropboxSyncService;
{
	static id me = nil; if (!me)
		me = [self new];
	
	return me;
}

+ (void) setUpSharedSessionWithKey:(NSString*) key secret:(NSString*) secret;
{
	NSAssert(![DBSession sharedSession], @"Can only set up the shared session once per app launch");
	
	DBSession* session = [[[DBSession alloc] initWithConsumerKey:key consumerSecret:secret] autorelease];
	session.delegate = [self sharedDropboxSyncService];
	[DBSession setSharedSession:session];
}

- (void) itemIsAvailable:(MvrItem *)i;
{
	// Do we have a sync task for it? Don't make a new one.
	if ([self ongoingSyncTaskForItem:i])
		return;
	
	// Is it a hidden file (eg a contact)? We don't sync those (TODO).
	if (![MvrStorage hasUserVisibleFileRepresentation:i]) {
		[self finishedSynchronizingAvailableItem:i];
		return;
	}
	
	// Have we already synchronized this item?
	if ([i objectForItemNotesKey:kMvrDropboxSyncPathKey]) {
		[self finishedSynchronizingAvailableItem:i];
		return;
	}
	
	if (!self.linked)
		return;
		
	MvrDropboxSyncTask* task = [[[MvrDropboxSyncTask alloc] initWithItem:i] autorelease];
	[self.mutableOngoingSyncTasks addObject:task];
	[task start];
}

- (void) itemWillBecomeUnavailable:(MvrItem *)i;
{
	MvrDropboxSyncTask* task = (MvrDropboxSyncTask*) [self ongoingSyncTaskForItem:i];
	if (task) {
		[task cancelAndDoNotAttemptNewSync];
		[self.mutableOngoingSyncTasks removeObject:task];
	}
}

- (void) didChangeDropboxAccountLinkState;
{
	if ([[DBSession sharedSession] isLinked]) {

		for (MvrItem* i in self.availableItems)
			[self beginSynchronizingItem:i];

	} else {
		
		[self.mutableOngoingSyncTasks makeObjectsPerformSelector:@selector(cancel)];
		[self.mutableOngoingSyncTasks removeAllObjects];
		
	}
}

- (void) beginSynchronizingItem:(MvrItem*) i;
{
}

- (MvrDropboxSyncTask*) ongoingSyncTaskForSourcePath:(NSString*) path;
{
	for (MvrDropboxSyncTask* t in self.ongoingSyncTasks) {
		if ([t.item.storage.path isEqual:path])
			return t;
	}
	
	return nil;
}

- (BOOL) isLinked;
{
	return [[DBSession sharedSession] isLinked];
}

- (void) unlink;
{
	[[DBSession sharedSession] unlink];
	[self didChangeDropboxAccountLinkState];
}

#if TARGET_OS_IPHONE

- (UIViewController *) loginController;
{
	if (!loginController) {
		loginController = [DBLoginController new];
		loginController.delegate = self;
	}
	
	if (!modalLoginController) {
		modalLoginController = [[UINavigationController alloc] initWithRootViewController:loginController];
		modalLoginController.navigationBar.barStyle = UIBarStyleBlackOpaque;
	}
	
	return modalLoginController;
}

- (void) loginControllerDidLogin:(DBLoginController *)controller;
{
	[self didChangeDropboxAccountLinkState];
}

- (void) loginControllerDidCancel:(DBLoginController *)controller;
{
	[self didChangeDropboxAccountLinkState];
}

#endif

- (void) sessionDidReceiveAuthorizationFailure:(DBSession *)session;
{
	// ??? TODO
}

@end
