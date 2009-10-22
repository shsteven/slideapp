//
//  MvrMessage+Showing.m
//  Mover3
//
//  Created by ∞ on 14/10/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrMessage+Showing.h"


@implementation MvrMessage (MvrShowing)

- (void) show;
{
	[self retain];
	
	UIAlertView* alert = [[UIAlertView new] autorelease];
	
	alert.title = self.title;
	alert.message = self.blurb;
	
	for (MvrMessageAction* action in self.actions)
		[alert addButtonWithTitle:action.title];
		
	alert.cancelButtonIndex = [alert addButtonWithTitle:NSLocalizedString(@"Dismiss", @"Dismiss button in cloud message alerts")];

	alert.delegate = self;
	[alert show];
}

- (void)alertView:(UIAlertView *)alert clickedButtonAtIndex:(NSInteger)buttonIndex;
{
	[self autorelease];
	alert.delegate = nil;
	
	if (buttonIndex == alert.cancelButtonIndex)
		return;
	
	MvrMessageAction* action = [self.actions objectAtIndex:buttonIndex];
	[self.delegate message:self didEndShowingWithChosenAction:action];
}

@end
