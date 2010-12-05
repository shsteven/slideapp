//
//  MvrSyncController.h
//  Mover3
//
//  Created by ∞ on 14/11/10.
//  Copyright 2010 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Network+Storage/MvrScannerObserver.h"
#import "MvrStorage.h"

#import "MvrSyncService.h"

/* -------------------
 OK, this deserves a lengthy explanation because it's bizarre and obscure and such.
 
 Mover produces ITEMS. Since we now want to sync some of these items with external services, there is now a SYNC STACK inside Mover. This is the easy part.
 
 First of all, there exists a SYNC CONTROLLER. This is the class below. MvrServices() can return a reference to the shared sync ctl. This sync controller monitors ANY NUMBER OF SCANNERS (MvrScanner) and ONE STORAGE (MvrStorage -- NOT the old-style MvrStorageCentral) for items. It also coordinates a group of SYNC SERVICES (MvrSyncService instances).
 
 An item can be AVAILABLE to the sync services for sync. The sync controller enqueues new items via the sync services' addAvailableItem: method, which calls itemIsAvailable: if appropriate.
 Items that have just been received from the network immediately become AVAILABLE. Additionally, items already in the storage become AVAILABLE immediately as soon as possible. An available item may or may not have already been synchronized; it is up to the sync service to use the ITEM NOTES (see MvrItem's setObject:forItemNotesKey: and related) to see whether the item should be synchronized or not.
 
 An item can also STOP BEING AVAILABLE to a sync service (eg because the user has deleted it). The controller notifies the services via the removeAvailableItem: method, which in turn calls itemWillBecomeUnavailable:. The service itself can at any time remove an item from the available items queue by calling its own finishedSynchronizingAvailableItem: method.
 
 When an item becomes available and a sync service wants to sync it, the sync service produces a SYNC TASK (MvrSyncTask). A sync task is similar to a NSOperation except it sets up its own parallelization, if required. Sync tasks are then enqueued in the sync service's task queue. At any time, the sync service can elect to START a sync task. Sync tasks are one-use-only: they can only be started once, and cannot be later started again.
 
 Typically a sync task RUNS and then either FAILS, is CANCELLED (which is handled as a failure with the NSCocoaErrorDomain/NSUserCancelledError error) or COMPLETES. Sync tasks set their (KVO-able) @"finished" key to indicate they have finished; if they have, they're examined to see how they finished.
 If they have finished successfully, the item is DEQUEUED from the sync service's queue via finishedSynchronizingAvailableItem:. It is now synchronized.
 If they have finished with an error, the error is checked for its kMvrSyncErrorCannotReattemptSyncKey user info key. If present and YES, the item is DEQUEUED and no attempt will be made to resync it in the future. If absent or NO, the item is kept in the queue and is notified again as available (via itemIsAvailable:). This typically results in the construction of a NEW SYNC TASK to reattempt sync (potentially later).
 
 A sync service monitors the availability of the service it syncs with. It can at any time cancel its own sync tasks or refuse to start its own existing tasks, or enqueue new ones, if the service is unavailable; it can also ask to reevaluate items in the queue to produce new sync tasks for available, unsynchronized items in case the service later becomes available. (To reevaluate, it just calls -reevaluateEnqueuedItems on itself.)
 
 -- So the cycle is: ---
 
 App start ----> Sync controller init'd ----> Sync controller makes storage items available (A)
 
 Item arrives ----> Sync controller makes item available (A)
 
 (A) Item is available ----> itemIsAvailable:(item)
	(Is item OK for sync? no -> finishedSynchronizingAvailableItem:(item), end)
	----> Create new SYNC TASK
	----> [self.mutableOngoingSyncTasks addObject:task];
	----> (sometime later?) Start task.
 
 (B) Item becomes unavailable ----> 
	If sync task exists for item, cancel it without recovery (in itemWillBecomeUnavailable:). Then remove item from queue.
 
 A task finishes correctly, or incorrectly without recovery
	----> finishedSynchronizingAvailableItem:(item), end
 
 A task finishes incorrectly with possible recovery
	----> itemIsAvailable:(item) (see A)
 
*/

@interface MvrSyncController : NSObject <MvrScannerObserverDelegate> {
	NSMutableArray* internalObservedScanners, * observers;
	NSMutableSet* services;
	MvrStorage* observedStorage;
}

@property(readonly) NSSet* observedScanners;
@property(readonly) NSMutableSet* mutableObservedScanners;
@property(retain) MvrStorage* observedStorage;

- (void) addSyncService:(MvrSyncService*) service;
- (void) removeSyncService:(MvrSyncService*) service;

@end
