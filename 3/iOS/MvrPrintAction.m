//
//  MvrPrintAction.m
//  Mover3
//
//  Created by ∞ on 30/09/10.
//  Copyright 2010 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrPrintAction.h"
#import "Network+Storage/MvrItemStorage.h"


@implementation MvrPrintAction

- (id) init;
{
	return [super initWithDisplayName:NSLocalizedString(@"Print\u2026", @"Print action button")];
}

- (id) initWithItemController:(MvrItemController*) ic;
{
	if ((self = [self init]))
		itemController = ic;
	
	return self;
}

- (BOOL) isAvailableForItem:(MvrItem *)i;
{
	Class c = NSClassFromString(@"UIPrintInteractionController");
	return c && [c isPrintingAvailable] && [c canPrintURL:[NSURL fileURLWithPath:[[i storage] path]]];
}

- (BOOL) continuesInteractionOnTable;
{
	return YES;
}

- (void) performActionWithItem:(MvrItem *)i;
{
	Class picClass = NSClassFromString(@"UIPrintInteractionController");
	if (!picClass) {
		[itemController didFinishAction];
		return;
	}
	
	UIPrintInteractionController* pic = [picClass sharedPrintController];
	if (!pic) {
		[itemController didFinishAction];
		return;
	}
	
	[self retain];
	pic.delegate = self;
	pic.printingItem = [NSURL fileURLWithPath:[[i storage] path]];
		
	UIPrintInteractionCompletionHandler h = ^(UIPrintInteractionController *printInteractionController, BOOL completed, NSError *error) {};
	
	if (itemController)
		[pic presentFromRect:itemController.boundsOfSourceViewForActionUI inView:itemController.sourceViewForActionUI animated:YES completionHandler:h];
	else
		[pic presentAnimated:YES completionHandler:h];
}

- (void) printInteractionControllerDidDismissPrinterOptions:(UIPrintInteractionController *)pic;
{
	[itemController didFinishAction];
	pic.delegate = nil;
	[self autorelease];
}

@end
