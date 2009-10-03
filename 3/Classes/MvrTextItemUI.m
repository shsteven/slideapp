//
//  MvrTextItemUI.m
//  Mover3
//
//  Created by ∞ on 03/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrTextItemUI.h"
#import "MvrTextItem.h"

@implementation MvrTextItemUI

+ supportedItemClasses;
{
	return [NSArray arrayWithObject:[MvrTextItem class]];
}

- (UIImage*) representingImageWithSize:(CGSize) size forItem:(id) i;
{
	return [UIImage imageNamed:@"TextIcon.png"];
}

- (NSString*) accessibilityLabelForItem:(id)i;
{
	return [NSString stringWithFormat:NSLocalizedString(@"Text clipping titled '%@'", @"Template for text item accessibiity label"), [i title]];
}

@end
