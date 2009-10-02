//
//  MvrItemUI.m
//  Mover3
//
//  Created by ∞ on 17/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrItemUI.h"
#import "Network+Storage/MvrItemStorage.h"

#pragma mark -
#pragma mark Item actions.

@interface MvrItemAction ()

- (id) initWithDisplayName:(NSString *)string target:(id) target selector:(SEL) selector;

@property(copy, setter=private_setDisplayName:) NSString* displayName;

@end


@implementation MvrItemAction

- (id) initWithDisplayName:(NSString*) string;
{
	if (self = [super init])
		self.displayName = string;
	
	return self;
}

- (id) initWithDisplayName:(NSString *)string target:(id) t selector:(SEL) s;
{
	if (self = [self initWithDisplayName:string]) {
		target = t; selector = s;
	}
	
	return self;
}

@synthesize displayName;

- (void) dealloc
{
	self.displayName = nil;
	[super dealloc];
}

+ actionWithDisplayName:(NSString*) name target:(id) target selector:(SEL) selector;
{
	return [[[self alloc] initWithDisplayName:name target:target selector:selector] autorelease];
}

- (void) performActionWithItem:(id) i;
{
	if (!target || !selector)
		L0AbstractMethod();
	
	// -performAction:self withItem:i
	[target performSelector:selector withObject:self withObject:i];
}

@end

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
	return [[[self alloc] initWithDisplayName:name] autorelease];
}

- (id) initWithDisplayName:(NSString *)name;
{
	return [self initWithDisplayName:name correspondingUI:nil];
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

- (BOOL) available;
{
	return YES;
}

@end

#pragma mark -
#pragma mark Item UI controllers

@implementation MvrItemUI

static NSMutableDictionary* MvrItemClassesToUIs = nil;

#pragma mark Registering and retrieving

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
	for (id source in [myself supportedItemSources]) {
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

#pragma mark Funnels

- (NSArray*) supportedItemSources;
{
	return [NSArray array];
}

+ (NSSet*) supportedItemClasses;
{
	L0AbstractMethod();
	return nil;
}

#pragma mark Working with items

- (void) beginAddingItemForSource:(MvrItemSource*) s;
{
	L0AbstractMethod();
}

- (UIImage*) representingImageWithSize:(CGSize) size forItem:(id) i;
{
	L0AbstractMethod();
	return nil;
}

- (void) didReceiveItem:(id) i;
{
}

- (void) didStoreItem:(id) i;
{	
}

#pragma mark Actions

- (MvrItemAction*) mainActionForItem:(id) i;
{
	return nil;
}

// Additional actions, which are shown on the action menu.
- (NSArray*) additionalActionsForItem:(id) i;
{
	return [NSArray array];
}

- (MvrItemAction*) showAction;
{
	return [MvrItemAction actionWithDisplayName:NSLocalizedString(@"Show", @"Title for the 'Show' action") target:self selector:@selector(performShowOrOpenAction:withItem:)];
}
- (MvrItemAction*) openAction;
{
	return [MvrItemAction actionWithDisplayName:NSLocalizedString(@"Open", @"Title for the 'Open' action") target:self selector:@selector(performShowOrOpenAction:withItem:)];
}

// Copies the item to the clipboard.
- (MvrItemAction*) clipboardAction;
{
	return [MvrItemAction actionWithDisplayName:NSLocalizedString(@"Copy", @"Title for the 'Copy' action") target:self selector:@selector(performCopyAction:withItem:)];
}

// Send the item via e-mail.
- (MvrItemAction*) sendByEmailAction;
{
	return [MvrItemAction actionWithDisplayName:NSLocalizedString(@"Send by E-mail", @"Title for the 'Send by E-mail' action") target:self selector:@selector(performShowOrOpenAction:withItem:)];
}

- (void) performShowOrOpenAction:(MvrItemAction*) showOrOpen withItem:(id) i;
{
	L0AbstractMethod();
}

- (void) performCopyAction:(MvrItemAction*) copy withItem:(id) i;
{
	[[UIPasteboard generalPasteboard] setData:((MvrItem*)i).storage.data forPasteboardType:((MvrItem*)i).type];
}

- (void) performSendByEmail:(MvrItemAction*) send withItem:(id) i;
{
	// TODO
	L0AbstractMethod();
}

- (BOOL) isItemRemovable:(id) i;
{
	return YES;
}

- (BOOL) isItemSavedElsewhere:(id) i;
{
	return NO;
}

@end
