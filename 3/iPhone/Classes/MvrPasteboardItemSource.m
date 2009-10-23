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

#if kMvrIsLite

#import "MvrImageItem.h"
#import "MvrContactItem.h"

@interface MvrPasteboardItemSource ()
- (BOOL) liteVersionCanPasteItemOfClass:(Class) c;
@end

#endif


@implementation MvrPasteboardItemSource

L0ObjCSingletonMethod(sharedSource)

- (id) init
{
	return [super initWithDisplayName:NSLocalizedString(@"Paste", @"'Paste' action menu item")];
}

- (void) beginAddingItem;
{
	UIPasteboard* pb = [UIPasteboard generalPasteboard];
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
		canAdd = canAdd && [self liteVersionCanPasteItemOfClass:[i class]];
#endif
		if (canAdd)
			[MvrApp() addItemFromSelf:i];
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
				canUse = [self liteVersionCanPasteItemOfClass:cls];
#endif
				return canUse;
			}
		}
	}
	
	return NO;
}

#if kMvrIsLite
- (BOOL) liteVersionCanPasteItemOfClass:(Class) c;
{
	return [c isEqual:[MvrImageItem class]] || [c isEqual:[MvrContactItem class]];
}
#endif

@end
