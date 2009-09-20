//
//  MvrTableController.m
//  Mover3
//
//  Created by ∞ on 18/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrTableController.h"

#import "MvrSlidesView.h"
#import "MvrSlide.h"

#import "MvrAppDelegate.h"
#import "Network+Storage/MvrStorageCentral.h"
#import "Network+Storage/MvrItem.h"

static CGPoint MvrCenterOf(CGRect r) {
	return CGPointMake(r.size.width / 2, r.size.height / 2);
}

@implementation MvrTableController

- (void) setUp;
{
	CGRect r = [self.hostView convertRect:[UIScreen mainScreen].bounds fromView:nil];
	self.backdropStratum.frame = r;
	[self.hostView addSubview:self.backdropStratum];
	
	self.slidesStratum = [[MvrSlidesView alloc] initWithFrame:self.hostView.bounds delegate:self];
	[self.hostView addSubview:self.slidesStratum];
	
	kvo = [[L0KVODispatcher alloc] initWithTarget:self];
	[kvo observe:@"storedItems" ofObject:MvrApp().storageCentral usingSelector:@selector(storageCentral:didChangeStoredItemsKey:) options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld];
	
	// TODO remove me
	[self.slidesStratum testByAddingEmptySlide];
}

- (void) storageCentral:(MvrStorageCentral*) central didChangeStoredItemsKey:(NSDictionary*) change;
{
	[kvo forEachSetChange:change forObject:central invokeSelectorForInsertion:@selector(storageCentral:didAddStoredItem:) removal:@selector(storageCentral:didRemoveStoredItem:)];
}

- (void) storageCentral:(MvrStorageCentral*)central didAddStoredItem:(MvrItem*) i;
{

}

- (void) storageCentral:(MvrStorageCentral*)central didRemoveStoredItem:(MvrItem*) i;
{
	
}

@synthesize hostView, backdropStratum, slidesStratum;

- (void) dealloc;
{
	[hostView release];
	[backdropStratum release];
	[slidesStratum release];
	
	[super dealloc];
}

@end
