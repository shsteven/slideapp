//
//  MvrTextItemUI.m
//  Mover3
//
//  Created by ∞ on 03/10/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrTextItemUI.h"
#import "MvrTextItem.h"
#import "MvrAppDelegate.h"
#import "MvrTextVisor.h"
#import "MvrSwapKitSendToAction.h"

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

#pragma mark -
#pragma mark Visor

- (MvrItemAction*) mainActionForItem:(id)i;
{
	return [self showAction];
}

- (void) performShowOrOpenAction:(MvrItemAction *)showOrOpen withItem:(id)i;
{
	[MvrApp() presentModalViewController:[MvrTextVisor modalVisorWithItem:i]];
}

#pragma mark -
#pragma mark Additional actions

- (NSArray*) additionalActionsForItem:(id)i;
{
	return [NSArray arrayWithObjects:
			[self clipboardAction],
			[self sendByEmailAction],
			[MvrSwapKitSendToAction sendToAction],
			nil];
}

- (void) fromItem:(MvrTextItem*)i getData:(NSData **)data mimeType:(NSString **)mimeType fileName:(NSString **)fileName messageBody:(NSString **)body isHTML:(BOOL *)html;
{
	*data = nil;
	*body = i.text;
	*html = NO;
}

@end
