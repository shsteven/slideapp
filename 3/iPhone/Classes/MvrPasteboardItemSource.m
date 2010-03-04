//
//  MvrPasteboardItemSource.m
//  Mover3
//
//  Created by ∞ on 07/10/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrPasteboardItemSource.h"

#import "Network+Storage/MvrItemStorage.h"

#import "MvrBookmarkItem.h"
#import "MvrTextItem.h"
#import "Network+Storage/MvrGenericItem.h"
#import "MvrAppDelegate.h"
#import "MvrImageItem.h"

#if kMvrIsLite

#import "MvrContactItem.h"

static inline BOOL MvrPasteboardItemSourceLiteVersionCanPasteItemsOfClass(Class c) {
	return [c isEqual:[MvrImageItem class]] || [c isEqual:[MvrContactItem class]];
}

#endif


@interface MvrPasteboardItemSource ()

@end


@implementation MvrPasteboardItemSource

L0ObjCSingletonMethod(sharedSource)

- (id) init
{
	return [super initWithDisplayName:NSLocalizedString(@"Paste", @"'Paste' action menu item")];
}

- (void) beginAddingItem;
{
	UIPasteboard* pb = [UIPasteboard generalPasteboard];
	[self addAllItemsFromPasteboard:pb];
}

- (void) addAllItemsFromPasteboard:(UIPasteboard*) pb;
{
	int length = pb.numberOfItems;
	for (int i = 0; i < length; i++) {
		NSIndexSet* thisItem = [NSIndexSet indexSetWithIndex:i];
		NSArray* types = [[pb pasteboardTypesForItemSet:thisItem] objectAtIndex:0];
		
		Class currentClass = Nil;
		NSString* currentType = nil;
		for (NSString* type in types) {
			Class cls = [MvrItem classForType:type];
			if ([cls isEqual:[MvrGenericItem class]])
				continue;
			
			// If it's a link, we want MvrBookmarkItem to handle it.
			if ([currentClass isEqual:[MvrTextItem class]] || !currentClass) {
				currentClass = cls;
				currentType = type;
			}
		}
		
		if (!currentType)
			continue;
		
		NSData* data = [[pb dataForPasteboardType:currentType inItemSet:thisItem] objectAtIndex:0];
		
		MvrItemStorage* storage = [MvrItemStorage itemStorageWithData:data];
		id i = storage? [MvrItem itemWithStorage:storage type:currentType metadata:nil] : nil;
		
		if ([i isKindOfClass:[MvrTextItem class]]) {
			NSString* s = [i text];
			NSURL* u = s? [NSURL URLWithString:s] : nil;
			
			if (u) {
				// we make a new one to be sure.
				storage = [MvrItemStorage itemStorageWithData:data];
				id newItem = [MvrItem itemWithStorage:storage type:(id) kUTTypeURL metadata:nil];
				if (newItem)
					i = newItem;
			}
		}
		
		BOOL canAdd = i && ![i isKindOfClass:[MvrGenericItem class]];
#if kMvrIsLite
		canAdd = canAdd && MvrPasteboardItemSourceLiteVersionCanPasteItemsOfClass([i class]);
#endif
		if (canAdd)
			[MvrApp() addItemFromSelf:i];
	}
}

- (void) addAllItemsFromSwapKitRequest:(ILSwapRequest*) req;
{	
	for (ILSwapItem* i in req.items) {
		MvrItem* mi = nil;
		
		id v = i.value;
		NSData* d = i.dataValue;
		
		if ([v isKindOfClass:[NSString class]]) {
			NSURL* u = [NSURL URLWithString:v];
			if (u)
				mi = [[[MvrBookmarkItem alloc] initWithAddress:u] autorelease];
			else
				mi = [[[MvrTextItem alloc] initWithText:v] autorelease];
		} else if ([v isKindOfClass:[UIImage class]]) {
			mi = [[[MvrImageItem alloc] initWithImage:v type:(id) kUTTypePNG] autorelease];
		} else if (d)
			mi = [MvrItem itemWithStorage:[MvrItemStorage itemStorageWithData:d] type:i.type metadata:[NSDictionary dictionary]];
		
		if (mi)
			[MvrApp() addItemFromSelf:mi];
	}
}

- (BOOL) available;
{
	for (NSDictionary* d in [[UIPasteboard generalPasteboard] items]) {		
		for (NSString* type in d) {
			Class cls = [MvrItem classForType:type];
			if (cls && ![cls isEqual:[MvrGenericItem class]]) {
				BOOL canUse = YES;
#if kMvrIsLite
				canUse = MvrPasteboardItemSourceLiteVersionCanPasteItemsOfClass(cls);
#endif
				return canUse;
			}
		}
	}
	
	return NO;
}

@end
