//
//  MvrDocumentOpenAction.m
//  Mover3
//
//  Created by ∞ on 27/06/10.
//  Copyright 2010 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrDocumentOpenAction.h"
#import "Network+Storage/MvrItem.h"
#import "Network+Storage/MvrItemStorage.h"

#import <MuiKit/MuiKit.h>

@implementation MvrDocumentOpenAction

- init;
{
	if (self = [super initWithDisplayName:NSLocalizedString(@"Open\u2026", @"Open label for doc interaction controller action")]) {
		
	}
	
	return self;
}

- (void) dealloc
{
	documentInteractionController.delegate = nil;
	[documentInteractionController release];
	[super dealloc];
}


- (BOOL) isAvailableForItem:(MvrItem *)i;
{
	return (NSClassFromString(@"UIDocumentInteractionController") != nil);
}

- (void) performActionWithItem:(MvrItem *)i;
{
	if (documentInteractionController)
		return;
	
	[self retain]; // balanced on dismiss.
	
	documentInteractionController = [UIDocumentInteractionController new];
	
	documentInteractionController.URL = [NSURL fileURLWithPath:[i storage].path];
	documentInteractionController.UTI = [i type];
	if ([i title] && ![[i title] isEqual:@""])
		documentInteractionController.name = [i title];
	else
		documentInteractionController.name = @"Preview"; // TODO
	
	documentInteractionController.delegate = self;

	if (![documentInteractionController presentOpenInMenuFromRect:[[UIApp keyWindow] bounds] inView:[UIApp keyWindow] animated:YES]) {
		UIAlertView* alert = [UIAlertView alertNamed:@"MvrNoOpeningOptions"];
		[alert setTitleFormat:nil, [UIDevice currentDevice].localizedModel];
		[alert show];
	}	
}

- (void) documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller;
{
	controller.delegate = nil;
	[self autorelease];
}

+ openAction;
{
	return [[[self alloc] init] autorelease];
}

@end
