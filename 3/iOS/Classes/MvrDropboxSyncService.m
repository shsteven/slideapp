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
#define kMvrDropboxPathItemNoteKey @"MvrDropboxPath"

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
	
	self.client = [[[DBRestClient alloc] initWithSession:[DBSession sharedSession] root:@"sandbox"] autorelease];
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
	self.error = error;
	[self end]; // bail.
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
	
	[self.item setObject:[kMvrDropboxSavePath stringByAppendingPathComponent:self.finalFilename] forItemNotesKey:kMvrDropboxPathItemNoteKey];
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

- (void) end;
{
	[self clear];
	self.finished = YES;
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

- (void) didEnqueueAvailableItem:(MvrItem *)i;
{
	if ([[DBSession sharedSession] isLinked])
		[self beginSynchronizingItem:i];
}

- (void) didRemoveAvailableItemFromQueue:(MvrItem *)i;
{
	id <MvrSyncTask> task = [self ongoingSyncTaskForItem:i];
	if (task) {
		[task cancel];
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
	NSString* path = i.storage.path;
	
	// Is it a hidden file (eg a contact)? We don't sync those (TODO).
	if ([[path lastPathComponent] hasPrefix:@"."]) {
		[self finishedSynchronizingAvailableItem:i];
		return;
	}
	
	MvrDropboxSyncTask* task = [[[MvrDropboxSyncTask alloc] initWithItem:i] autorelease];
	[self.mutableOngoingSyncTasks addObject:task];
	[task start];
}

- (MvrDropboxSyncTask*) ongoingSyncTaskForSourcePath:(NSString*) path;
{
	for (MvrDropboxSyncTask* t in self.ongoingSyncTasks) {
		if ([t.item.storage.path isEqual:path])
			return t;
	}
	
	return nil;
}

@end
