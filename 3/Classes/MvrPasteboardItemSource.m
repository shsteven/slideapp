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
#import "MvrAppDelegate.h"

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
		
		if (i)
			[MvrApp() addItemFromSelf:i];
	}
}

- (BOOL) available;
{
	for (NSDictionary* d in [[UIPasteboard generalPasteboard] items]) {		
		for (NSString* type in d) {
			Class cls = [MvrItem classForType:type];
			if (cls)
				return YES;
		}
	}
	
	return NO;
}

@end
