//
//  MvrItemUI.m
//  Mover3
//
//  Created by ∞ on 17/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrItemUI.h"

#pragma mark -
#pragma mark Item sources.

static NSMutableArray* MvrItemSources = nil;

@interface MvrItemSource ()

- (id) initWithDisplayName:(NSString*) name correspondingUI:(MvrItemUI*) ui;

@property(setter=private_setDisplayName:, copy) NSString* displayName;
@property(setter=private_setCorrespondingUI:, retain) MvrItemUI* correspondingUI;

@end


@implementation MvrItemSource

+ registeredItemSources;
{
	if (MvrItemSources)
		return MvrItemSources;
	
	return [NSArray array];
}

+ itemSourceWithDisplayName:(NSString*) name;
{
	return [[[self alloc] initWithDisplayName:name correspondingUI:nil] autorelease];
}

+ itemSourceWithDisplayName:(NSString*) name correspondingUI:(MvrItemUI*) ui;
{
	return [[[self alloc] initWithDisplayName:name correspondingUI:ui] autorelease];
}

- (id) initWithDisplayName:(NSString*) name correspondingUI:(MvrItemUI*) ui;
{
	if (self = [super init]) {
		self.displayName = name;
		self.correspondingUI = ui;
	}
	
	return self;
}

@synthesize displayName, correspondingUI;

- (void) dealloc;
{
	[displayName release];
	[correspondingUI release];
	[super dealloc];
}

- (void) beginAddingItem;
{
	NSAssert(self.correspondingUI, @"Override -beginAddingItem in MvrItemSource if you don't want to delegate item addition to an item UI controller.");
	[self.correspondingUI beginAddingItemForSource:self];
}

@end

#pragma mark -
#pragma mark Item UI controllers

@implementation MvrItemUI

static NSMutableDictionary* MvrItemClassesToUIs = nil;

+ (void) registerUI:(MvrItemUI*) ui forItemClass:(Class) c;
{
	if (!MvrItemClassesToUIs)
		MvrItemClassesToUIs = [NSMutableDictionary new];
	
	[MvrItemClassesToUIs setObject:ui forKey:NSStringFromClass(c)];
}

+ (void) registerClass;
{
	id myself = [[self new] autorelease];
	
	for (Class c in [self supportedItemClasses])
		[self registerUI:myself forItemClass:c];
	
	if (!MvrItemSources)
		MvrItemSources = [NSMutableArray new];
	
	// [MvrItemSources addObjectsFromArray:[self supportedItemSources]];
	// we don't do the above because we may have item sources shared between different item UIs. For example, the camera item source can produce either videos or photos, so both item ui controllers claim it as their own and we display it only once.
	for (id source in [self supportedItemSources]) {
		if (![MvrItemSources containsObject:source])
			[MvrItemSources addObject:source];
	}
}

+ (MvrItemUI*) UIForItemClass:(Class) i;
{
	Class current = i; id ui;
	do {
		if (!current || [current isEqual:[MvrItem class]])
			return nil;
		
		ui = [MvrItemClassesToUIs objectForKey:NSStringFromClass(current)];
		current = [current superclass];
	} while (ui == nil);
	
	return ui;
}

+ (MvrItemUI*) UIForItem:(MvrItem*) i;
{
	return [self UIForItemClass:[i class]];
}

+ (NSArray*) supportedItemSources;
{
	return [NSArray array];
}

+ (NSArray*) supportedItemClasses;
{
	L0AbstractMethod();
	return nil;
}

- (void) beginAddingItemForSource:(MvrItemSource*) s;
{
	L0AbstractMethod();
}

@end
