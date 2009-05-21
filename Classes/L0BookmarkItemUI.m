//
//  L0BookmarkItemUI.m
//  Mover
//
//  Created by ∞ on 21/05/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0BookmarkItemUI.h"

@implementation L0BookmarkItemUI

+ (NSArray*) supportedItemClasses;
{
	return [NSArray arrayWithObject:[L0BookmarkItem class]];
}

- (id) init;
{
	if (self = [super init]) {
		[L0BookmarkItem setStorage:self];
	}
	
	return self;
}

- (void) storeBookmarkItem:(L0BookmarkItem*) item;
{
	L0Log(@"Will store bookmark item: %@", item);
	// TODO
}

- (BOOL) removingFromTableIsSafeForItem:(L0MoverItem*) i;
{
	return YES;
}

- (L0MoverItemAction*) mainActionForItem:(L0MoverItem*) i;
{
	return [self openAction];
}

- (void) showOrOpenItem:(L0MoverItem*) i forAction:(L0MoverItemAction*) a;
{
	L0BookmarkItem* item = (L0BookmarkItem*) i;
	[UIApp openURL:item.address];
}

@end
