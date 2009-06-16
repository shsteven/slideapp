//
//  L0BookmarkItemUI.m
//  Mover
//
//  Created by ∞ on 21/05/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0MoverBookmarkItemUI.h"
#import <MessageUI/MessageUI.h>
#import "L0MoverAppDelegate.h"

@implementation L0MoverBookmarkItemUI

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
	return NO;
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

- (NSArray*) additionalActionsForItem:(L0MoverItem*) i;
{
	return [NSArray arrayWithObject:[self shareByEmailAction]];
}

- (void) shareItemByEmail:(L0MoverItem*) i forAction:(L0MoverItemAction*) a;
{
	MFMailComposeViewController* mailVC = [[MFMailComposeViewController new] autorelease];
	[mailVC setMessageBody:[((L0BookmarkItem*)i).address absoluteString] isHTML:NO];
	mailVC.mailComposeDelegate = self;
	
	L0MoverAppDelegate* delegate = (L0MoverAppDelegate*) UIApp.delegate;
	[delegate presentModalViewController:mailVC];
}

@end
