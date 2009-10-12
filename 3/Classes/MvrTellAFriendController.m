//
//  MvrTellAFriendController.m
//  Mover3
//
//  Created by ∞ on 12/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrTellAFriendController.h"
#import "MvrAppDelegate.h"

#import <MuiKit/MuiKit.h>

@implementation MvrTellAFriendController

- (BOOL) canTellAFriend;
{
//	return [MFMailComposeViewController canSendMail];
	return NO;
}

- (void) start;
{
	if (!self.canTellAFriend) {
		UIAlertView* a = [UIAlertView alertNamed:@"MvrNoEmail"];
		[a show];
		return;
	}
	
	NSString* mailMessage = NSLocalizedString(@"Mover is an app that allows you to share files with other iPhones near you, with style. Download it at http://infinite-labs.net/mover/download or see it in action at http://infinite-labs.net/mover/",
											  @"Contents of 'Email a Friend' message");
	NSString* mailSubject = NSLocalizedString(@"Check out this iPhone app, Mover",
											  @"Subject of 'Email a Friend' message");
	
	MFMailComposeViewController* mail = [[MFMailComposeViewController new] autorelease];
	mail.mailComposeDelegate = self;
	[mail setSubject:mailSubject];
	[mail setMessageBody:mailMessage isHTML:NO];

	[MvrApp() presentModalViewController:mail];
}

- (void)mailComposeController:(MFMailComposeViewController *)mail didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error;
{
	[mail dismissModalViewControllerAnimated:YES];
}

@end
