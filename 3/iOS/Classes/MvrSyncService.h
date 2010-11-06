//
//  MvrSyncService.h
//  Mover3
//
//  Created by ∞ on 02/11/10.
//  Copyright 2010 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Network+Storage/MvrItem.h"
#import "Network+Storage/MvrPlatformInfo.h"

#define kMvrSyncItemPersistentIDNoteKey @"MvrSyncID"

@protocol MvrSyncTask;

@interface MvrSyncService : NSObject {
	NSMutableArray* ongoingSyncTasks;
}

// set by the MvrServices thingy when we add the sync service to it.
@property(assign) id <MvrPlatformInfo> platformInfo;

- (void) addAvailableItem:(MvrItem*) i;
- (void) removeAvailableItem:(MvrItem*) i;

@property(readonly) NSArray* availableItems;

// Can be KVO'd.
@property(readonly) NSArray* ongoingSyncTasks;

// --- for subclasses ----------------------------------
- (void) didEnqueueAvailableItem:(MvrItem*) i;
- (void) didRemoveAvailableItemFromQueue:(MvrItem*) i;
- (void) finishedSynchronizingAvailableItem:(MvrItem*) i; // call to remove from available items without a didRemove... call.

- (id <MvrSyncTask>) ongoingSyncTaskForItem:(MvrItem*) i;

// automatically generates KVO notifications for the ongoingSyncTasks key.
@property(readonly) NSMutableArray* mutableOngoingSyncTasks;

@end


@protocol MvrSyncTask <NSObject>

- (void) cancel;
- (MvrItem*) item;

// All KVOable beyond this point.

- (BOOL) isFinished;
- (float) progress;

@end
