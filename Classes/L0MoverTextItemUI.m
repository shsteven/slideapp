//
//  L0MoverTextItemUI.m
//  Mover
//
//  Created by ∞ on 15/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0MoverTextItemUI.h"
#import "L0TextItem.h"
#import "L0MoverTextViewer.h"
#import "L0MoverAppDelegate.h"

@implementation L0MoverTextItemUI

+ (NSArray*) supportedItemClasses;
{
	return [NSArray arrayWithObject:[L0TextItem class]];
}

- (BOOL) removingFromTableIsSafeForItem:(L0MoverItem*) i;
{
	return NO;
}

- (L0MoverItemAction*) mainActionForItem:(L0MoverItem*) i;
{
	return [self showAction];
}

- (NSArray*) additionalActionsForItem:(L0MoverItem*) i;
{
	L0MoverItemAction* copyAction = [L0MoverItemAction actionWithTarget:self selector:@selector(copyItem:forAction:) localizedLabel:NSLocalizedString(@"Copy", @"As in 'Cut, Copy and Paste'.")];
	return [NSArray arrayWithObject:copyAction];
}

- (void) showOrOpenItem:(L0MoverItem*) i forAction:(L0MoverItemAction*) a;
{
	L0TextItem* item = (L0TextItem*) i;
	UINavigationController* c = [L0MoverTextViewer navigationControllerWithViewerForItem:item delegate:UIApp.delegate didDismissSelector:@selector(finishPerformingMainAction)];
	
	L0MoverAppDelegate* delegate = (L0MoverAppDelegate*) UIApp.delegate;
	[delegate presentModalViewController:c];
}

- (void) copyItem:(L0MoverItem*) i forAction:(L0MoverItemAction*) a;
{
	UIPasteboard* pb = [UIPasteboard generalPasteboard];
	pb.string = ((L0TextItem*)i).text;
}

@end
