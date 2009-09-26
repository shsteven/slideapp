//
//  MvrGenericItemUI.m
//  Mover3
//
//  Created by ∞ on 20/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrGenericItemUI.h"
#import "Network+Storage/MvrGenericItem.h"

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
	// Does nothing.
}

@end
