//
//  L0MoverImageItemUI.m
//  Mover
//
//  Created by ∞ on 16/05/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0MoverImageItemUI.h"
#import "L0MoverImageViewer.h"
#import "L0ImageItem.h"
#import "L0MoverAppDelegate.h"

@implementation L0MoverImageItemUI

+ (NSArray*) supportedItemClasses;
{
	return [NSArray arrayWithObject:[L0ImageItem class]];
}

- (BOOL) removingFromTableIsSafeForItem:(L0MoverItem*) i;
{
	return YES;
}

- (L0MoverItemAction*) mainActionForItem:(L0MoverItem*) i;
{
	return [self showAction];
}

- (NSArray*) additionalActionsForItem:(L0MoverItem*) i;
{
	return [NSArray arrayWithObject:[self shareByEmailAction]];
}

- (BOOL) fromItem:(L0MoverItem*) i getMailAttachmentData:(NSData**) d mimeType:(NSString**) t fileName:(NSString**) f;
{
	L0ImageItem* item = (L0ImageItem*) i;
	
	if (d)
		*d = UIImageJPEGRepresentation([item.image imageByRenderingRotation], 0.7);
	
	if (t)
		*t = @"image/jpeg";
	
	if (f)
		*f = NSLocalizedString(@"Image.jpeg", @"Default filename for images shared via mail.");
	
	BOOL doneWithD = !d || *d != nil;
	return doneWithD;
}

- (BOOL) preparesEmailAsynchronously;
{
	return YES;
}

- (void) showOrOpenItem:(L0MoverItem*) i forAction:(L0MoverItemAction*) a;
{
	L0ImageItem* item = (L0ImageItem*) i;
	L0MoverImageViewer* viewer = [[[L0MoverImageViewer alloc] initWithImage:item.image dismissDelegate:UIApp.delegate selector:@selector(finishPerformingMainAction)] autorelease];
	UINavigationController* controller = [[[UINavigationController alloc] initWithRootViewController:viewer] autorelease];	
	controller.navigationBar.barStyle = UIBarStyleBlackTranslucent;

	L0MoverAppDelegate* delegate = (L0MoverAppDelegate*) UIApp.delegate;
	[delegate.tableHostController presentModalViewController:controller animated:YES];
}

@end
