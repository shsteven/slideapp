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
		ongoingSyncTasks = [NSMutableArray array]; // WANT IVARS IN CLASS CONTINUATIONS NOWWWWW
	}
	
	return self;
}

- (void) dealloc
{
	self.mutableAvailableItems = nil;
	[ongoingSyncTasks release];
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
	[self didEnqueueAvailableItem:i];
}

- (void) removeAvailableItem:(MvrItem *)i;
{
	if (![self.mutableAvailableItems containsObject:i])
		return;
	
	[self.mutableAvailableItems removeObject:i];
	[self didRemoveAvailableItemFromQueue:i];
}

- (void) didEnqueueAvailableItem:(MvrItem *)i;
{
	L0AbstractMethod();
}

- (void) didRemoveAvailableItemFromQueue:(MvrItem *)i;
{
	L0AbstractMethod();
}

- (void) finishedSynchronizingAvailableItem:(MvrItem *)i;
{
	[self.mutableAvailableItems removeObject:i];
}

- (NSArray *) ongoingSyncTasks;
{
	return ongoingSyncTasks;
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

@end

