//
//  MvrSyncController.m
//  Mover3
//
//  Created by ∞ on 14/11/10.
//  Copyright 2010 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrSyncController.h"

#import "Network+Storage/MvrItem.h"

@interface MvrSyncController ()

- (void) addObservedScannersObject:(id <MvrScanner>)scan;
- (void) removeObservedScannersObject:(id <MvrScanner>)scan;

@end


@implementation MvrSyncController

- (id) init
{
	self = [super init];
	if (self != nil) {
		internalObservedScanners = [NSMutableArray new];
		observers = [NSMutableArray new];
		services = [NSMutableSet new];
	}
	return self;
}

- (void) dealloc
{
	[observers makeObjectsPerformSelector:@selector(setDelegate:) withObject:nil];
	
	[internalObservedScanners release];
	[observers release];
	[services release];
	
	[super dealloc];
}


- (NSMutableSet *) mutableObservedScanners;
{
	return [self mutableSetValueForKey:@"observedScanners"];
}

- (NSSet*) observedScanners;
{
	return [NSSet setWithArray:internalObservedScanners];
}

- (void) addObservedScannersObject:(id <MvrScanner>) scan;
{
	if ([internalObservedScanners containsObject:scan])
		return;
	
	[internalObservedScanners addObject:scan];
	
	MvrScannerObserver* obs = [[[MvrScannerObserver alloc] initWithScanner:scan delegate:self] autorelease];
	[observers addObject:obs];
}

- (void) removeObservedScannersObject:(id <MvrScanner>) scan;
{
	NSInteger i = [internalObservedScanners indexOfObject:scan];
	if (i == NSNotFound)
		return;
	
	MvrScannerObserver* obs = [observers objectAtIndex:i];
	obs.delegate = nil;
	
	[observers removeObjectAtIndex:i];
	[internalObservedScanners removeObjectAtIndex:i];
}

@synthesize observedStorage;
- (void) setObservedStorage:(MvrStorage *) s;
{
	if (s != observedStorage) {
		for (MvrItem* i in [observedStorage storedItems])
			[services makeObjectsPerformSelector:@selector(removeAvailableItem:) withObject:i];
		
		if (observedStorage)
			[observedStorage removeObserver:self forKeyPath:@"storedItems"];
		
		[observedStorage release];
		observedStorage = [s retain];
		
		if (observedStorage)
			[observedStorage addObserver:self forKeyPath:@"storedItems" options:NSKeyValueObservingOptionOld context:NULL];
		
		for (MvrItem* i in [observedStorage storedItems])
			[services makeObjectsPerformSelector:@selector(addAvailableItem:) withObject:i];
	}
}

// ---------------------
#pragma mark Sync services management

- (void) addSyncService:(MvrSyncService*) service;
{
	[services addObject:service];
}

- (void) removeSyncService:(MvrSyncService*) service;
{
	[services removeObject:service];	
}

// ---------------------
#pragma mark Item handling

- (void) incomingTransfer:(id <MvrIncoming>)incoming didEndReceivingItem:(MvrItem *)i;
{
	if (i)
		[services makeObjectsPerformSelector:@selector(addAvailableItem:) withObject:i];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
{
	if (L0KVOChangeKind(change) == NSKeyValueChangeRemoval || L0KVOChangeKind(change) == NSKeyValueChangeReplacement) {
		for (MvrItem* i in [change objectForKey:NSKeyValueChangeOldKey])
			[services makeObjectsPerformSelector:@selector(removeAvailableItem:) withObject:i];
	}
}

@end
