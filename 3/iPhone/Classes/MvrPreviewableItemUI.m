//
//  MvrPreviewableItemUI.m
//  Mover3
//
//  Created by ∞ on 17/03/10.
//  Copyright 2010 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrPreviewableItemUI.h"
#import "MvrPreviewVisor.h"
#import "MvrAppDelegate.h"

#import "Network+Storage/MvrItem.h"
#import "Network+Storage/MvrItemStorage.h"

@implementation MvrPreviewableItemUI

+ (NSSet*) supportedItemClasses;
{
	return [NSSet setWithObject:[MvrPreviewableItem class]];
}

- (UIImage*) representingImageWithSize:(CGSize) size forItem:(id) i;
{
	return [UIImage imageNamed:@"DocIcon.png"];
}

- (NSString*) accessibilityLabelForItem:(id)i;
{
	if ([i title])
		return [i title];
	else
		return NSLocalizedString(@"Untitled item", @"The accessibility label of a generic item without a title");
}


- (MvrItemAction*) mainActionForItem:(id) i;
{
	NSString* ext = [[i storage].path pathExtension];
	return ((ext && ![ext isEqual:@""])? [self showAction] : nil);
}

- (void) performShowOrOpenAction:(MvrItemAction*) showOrOpen withItem:(id) i;
{
	[MvrApp() presentModalViewController:[MvrPreviewVisor modalVisorWithItem:i]];
}

@end
