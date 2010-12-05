//
//  MvrSyncService.m
//  Mover3
//
//  Created by ∞ on 02/11/10.
//  Copyright 2010 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrSyncService.h"

@interface MvrSyncService ()

@property(retain) NSMutableArray* mutableAvailableItems;

@end


@implementation MvrSyncService

- (id) init
{
	self = [super init];
	if (self != nil) {
		self.mutableAvailableItems = [NSMutableArray array];
		ongoingSyncTasksArray = [NSMutableArray new]; // WANT IVARS IN CLASS CONTINUATIONS NOWWWWW
	}
	
	return self;
}

- (void) dealloc
{
	self.mutableAvailableItems = nil;

	for (id x in ongoingSyncTasksArray)
		[x removeObserver:self forKeyPath:@"finished"];
	
	[ongoingSyncTasksArray release];
	[super dealloc];
}


@synthesize mutableAvailableItems, platformInfo;

- (NSArray *) availableItems;
{
	return self.mutableAvailableItems;
}

- (void) addAvailableItem:(MvrItem *)i;
{
	if ([self.mutableAvailableItems containsObject:i])
		return;
	
	[self.mutableAvailableItems addObject:i];
	[self itemIsAvailable:i];
}

- (void) removeAvailableItem:(MvrItem *)i;
{
	if (![self.mutableAvailableItems containsObject:i])
		return;
	
	[self.mutableAvailableItems removeObject:i];
	[self itemWillBecomeUnavailable:i];
}

- (void) itemIsAvailable:(MvrItem *)i;
{
	L0AbstractMethod();
}

- (void) itemWillBecomeUnavailable:(MvrItem *)i;
{
	L0AbstractMethod();
}

- (void) finishedSynchronizingAvailableItem:(MvrItem *)i;
{
	[self.mutableAvailableItems removeObject:i];
}

- (NSArray *) ongoingSyncTasks;
{
	return ongoingSyncTasksArray;
}

- (void) insertObject:(id <MvrSyncTask>) o inOngoingSyncTasksAtIndex:(NSUInteger) i;
{
	[ongoingSyncTasksArray insertObject:o atIndex:i];
	[o addObserver:self forKeyPath:@"finished" options:0 context:NULL];
}

- (void) removeObjectFromOngoingSyncTasksAtIndex:(NSUInteger) i;
{
	id x = [ongoingSyncTasksArray objectAtIndex:i];
	[x removeObserver:self forKeyPath:@"finished"];
	[ongoingSyncTasksArray removeObjectAtIndex:i];
}

- (NSMutableArray*) mutableOngoingSyncTasks;
{
	return [self mutableArrayValueForKey:@"ongoingSyncTasks"];
}

- (id <MvrSyncTask>) ongoingSyncTaskForItem:(MvrItem*) i;
{
	for (id <MvrSyncTask> t in self.ongoingSyncTasks) {
		if ([t.item isEqual:i])
			return t;
	}
	
	return nil;
}

- (void) ongoingSyncTaskDidFinish:(id <MvrSyncTask>) syncTask;
{
	[[syncTask retain] autorelease];
	
	MvrItem* item = [[syncTask.item retain] autorelease];
	BOOL reenqueue = NO;
	
	if (syncTask.error) {
		id x = [[syncTask.error userInfo] objectForKey:kMvrSyncErrorCannotReattemptSyncKey];
		reenqueue = !(x && [x boolValue]);
	}
	
	[self.mutableOngoingSyncTasks removeObject:syncTask];
	
	if (reenqueue)
		[self itemIsAvailable:item];
	else
		[self finishedSynchronizingAvailableItem:item];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
{
	if ([object conformsToProtocol:@protocol(MvrSyncTask)] && [keyPath isEqual:@"finished"]) {
		if ([object isFinished])
			[self ongoingSyncTaskDidFinish:object];
	}
}

- (void) reevaluateEnqueuedItems;
{
	for (MvrItem* i in self.availableItems)
		[self itemIsAvailable:i];
}

@end

