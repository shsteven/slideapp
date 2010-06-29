//
//  MvrGenericItemUI.m
//  Mover3
//
//  Created by ∞ on 20/09/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrGenericItemUI.h"
#import "Network+Storage/MvrGenericItem.h"

#import "MvrAppDelegate+HelpAlerts.h"

#import "MvrDocumentOpenAction.h"

@implementation MvrGenericItemUI

+ supportedItemClasses {
	return [NSSet setWithObject:[MvrGenericItem class]];
}

- (UIImage*) representingImageWithSize:(CGSize) size forItem:(id) i;
{
	return [UIImage imageNamed:@"GenericItemIcon.png"];
}

- (void) didReceiveItem:(MvrItem*) i;
{
	if ([[MvrDocumentOpenAction openAction] isAvailableForItem:i])
		[MvrApp() showAlertIfNotShownBeforeNamed:@"MvrGenericItemReceived_CanOpen"];
	else
		[MvrApp() showAlertIfNotShownBeforeNamed:@"MvrGenericItemReceived"];
}

- (NSString*) accessibilityLabelForItem:(id)i;
{
	if ([i title] && ![[i title] isEqual:@""])
		return [i title];
	else
		return NSLocalizedString(@"Untitled item", @"The accessibility label of a generic item without a title");
}

- (MvrItemAction *) mainActionForItem:(id)i;
{
	return [MvrDocumentOpenAction openAction];
}

@end
