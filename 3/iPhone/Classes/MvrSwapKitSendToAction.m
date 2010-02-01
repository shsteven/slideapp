//
//  MvrSwapKitSendToAction.m
//  Mover3
//
//  Created by ∞ on 11/01/10.
//  Copyright 2010 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrSwapKitSendToAction.h"
#import "MvrAppDelegate.h"

@implementation MvrSwapKitSendToAction

- init;
{
	if (self = [super initWithDisplayName:NSLocalizedString(@"Send to App", @"Name for the 'Send to App' (SwapKit) action")]) {
		
	}
	
	return self;
}

- (BOOL) isAvailableForItem:(MvrItem *)i;
{
	NSData* d = i.storage.data;
	return [[ILSwapService sharedService] canSendItems:[NSArray arrayWithObject:d] ofType:i.type forAction:nil];
}

- (void) performActionWithItem:(MvrItem *)i;
{
	NSData* d = i.storage.data;
	[[ILSwapSendController controllerForSendingItems:[NSArray arrayWithObject:d] ofType:i.type forAction:nil] send:MvrApp().actionSheetOriginView];
}

+ sendToAction;
{
	return [[[self alloc] init] autorelease];
}

@end