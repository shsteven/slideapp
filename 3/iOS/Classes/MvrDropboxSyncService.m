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

@property(retain) NSString* temporaryFilename, * finalFilename;

@property(assign) id <MvrPlatformInfo> platformInfo;

@property float progress;
@property(getter=isFinished) BOOL finished;

@property int numberOfFinalFilenameAttempts;

@property(copy) NSString* lastMoverFolderHash;

- (void) buildFinalFilename;
- (void) buildTemporaryFilename;

@end

@implementation MvrDropboxSyncTask

- (id) initWithItem:(MvrItem*) i platformInfo:(id <MvrPlatformInfo>) info lastMoverFolderHash:(NSString*) hash;
{
	if ((self = [super init])) {
		self.item = i;
		self.progress = kMvrIndeterminateProgress;
		self.platformInfo = info;	
		self.lastMoverFolderHash = hash;
	}
	
	return self;
}

- (void) dealloc
{
	[self cancel];
	[super dealloc];
}


- (void) buildTemporaryFilename;
{
	self.temporaryFilename = [NSString stringWithFormat:@".%@-%@", self.platformInfo.displayNameForSelf, [[L0UUID UUID] stringValue]];
}

- (void) buildFinalFilename;
{
	self.finalFilename = [MvrStorage userVisibleFilenameForItem:self.item attempt:self.numberOfFinalFilenameAttempts];
	self.numberOfFinalFilenameAttempts = self.numberOfFinalFilenameAttempts + 1;
}

- (void) start;
{	
	self.client = [[[DBRestClient alloc] initWithSession:[DBSession sharedSession] root:@"sandbox"] autorelease];
	self.client.delegate = self;
	
	// FOLLOW THE NUMBERS! --> [0]
	// First of all, we create the /Mover directory. If it's already there, we simply don't care. (We get 403 in that case.)
	[self.client loadMetadata:kMvrDropboxSavePath withHash:self.lastMoverFolderHash];
}

- (void) restClient:(DBRestClient *)client createdFolder:(DBMetadata *)folder;
{
	// [1]a OK, let's proceed to making a filename that does not conflict with the stuff we have.
	[self beginPickingFinalFilename];
}

- (void) restClient:(DBRestClient *)client createFolderFailedWithError:(NSError *)error;
{
	if ([[error domain] isEqual:DBErrorDomain] && [error code] == 403) {
		// already exists!
		// [1]b OK, let's proceed etc!
		[self beginPickingFinalFilename];
	} else
		[self cancel]; // bail.
}

- (void) beginPickingFinalFilename;
{
	// <#TODO#>
}

- (void) cancel;
{
	// TODO cancel ongoing stuff
	
	self.client.delegate = nil;
	self.client = nil;
	self.item = nil;
	self.finished = YES;
}

@synthesize item, client, temporaryFilename, finalFilename, progress, finished, numberOfFinalFilenameAttempts;

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
