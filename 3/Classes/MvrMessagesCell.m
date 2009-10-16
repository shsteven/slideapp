//
//  MvrMessagesCell.m
//  Mover3
//
//  Created by ∞ on 16/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrMessagesCell.h"
#import "MvrAppDelegate.h"

#import <QuartzCore/QuartzCore.h>

@interface MvrMessagesCell ()

- (void) showMessage:(MvrMessage*) message;
- (void) showOptIn:(BOOL) hasOptIn withChecker:(MvrMessageChecker*) checker;

- (void) optInChangedForChecker:(MvrMessageChecker*) checker change:(NSDictionary*) change;
- (void) didStartOrStopChecking:(MvrMessageChecker*) checker change:(NSDictionary*) change;

@end


@implementation MvrMessagesCell

- (id) init
{
	self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
	if (self != nil) {
		MvrMessageChecker* checker = MvrApp().messageChecker;
		
		self.textLabel.text = NSLocalizedString(@"News & Updates", @"News & Updates messages cell title");
		
		kvo = [[L0KVODispatcher alloc] initWithTarget:self];
		
		[kvo observe:@"userOptedInToMessages" ofObject:checker usingSelector:@selector(optInChangedForChecker:change:) options:0];
		// initial
		hadOptIn = [checker.userOptedInToMessages boolValue];
		[self showOptIn:hadOptIn withChecker:checker];
		
		[kvo observe:@"checking" ofObject:checker usingSelector:@selector(didStartOrStopChecking:change:) options:0];
		// again initial
		[self didStartOrStopChecking:checker change:nil];
		
		BOOL hasOptIn = [checker.userOptedInToMessages boolValue];
		if (hasOptIn && !checker.checking)
			[self showMessage:checker.lastMessage];
	}
	
	return self;
}

- (void) dealloc
{
	[kvo release];
	[super dealloc];
}

- (void) fade;
{
	CATransition* fade = [CATransition animation];
	fade.type = kCATransitionFade;
	[self.layer addAnimation:fade forKey:@"MvrFadeAnimation"];
}

- (void) optInChangedForChecker:(MvrMessageChecker*) checker change:(NSDictionary*) change;
{
	BOOL hasOptIn = [checker.userOptedInToMessages boolValue];
	L0Log(@"%d --> %d", hadOptIn, hasOptIn);
	
	if (hasOptIn != hadOptIn)
		[self showOptIn:hasOptIn withChecker:checker];
	
	hadOptIn = hasOptIn;
}

- (void) showOptIn:(BOOL) hasOptIn withChecker:(MvrMessageChecker*) checker;
{
	if (!hasOptIn) {
		[self fade];
		self.textLabel.textColor = [UIColor grayColor];
		self.detailTextLabel.text = NSLocalizedString(@"Off", @"Disabled detail text for News & Updates cell");
		self.accessoryType = UITableViewCellAccessoryNone;
		self.accessoryView = nil;
		self.selectionStyle = UITableViewCellSelectionStyleNone;
	} else {
		[self fade];
		self.textLabel.textColor = [UIColor blackColor];
		[self didStartOrStopChecking:checker change:nil];
		self.selectionStyle = UITableViewCellSelectionStyleBlue;
	}
}

- (void) showMessage:(MvrMessage*) message;
{
	L0Log(@"%@", message);
	
	if (message) {
		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		self.detailTextLabel.text = message.miniTitle;
	} else {
		self.accessoryType = UITableViewCellAccessoryNone;
		self.detailTextLabel.text = NSLocalizedString(@"Touch to check", @"No news detail text for News & Updates cell");
		self.detailTextLabel.highlighted = NO;
	}
}

- (void) didStartOrStopChecking:(MvrMessageChecker*) checker change:(NSDictionary*) change;
{
	L0Log(@"%d", checker.checking);
	
	BOOL hasOptIn = [checker.userOptedInToMessages boolValue];
	if (!hasOptIn)
		return;
	
	if (checker.checking) {
		self.detailTextLabel.text = @"";
		self.accessoryType = UITableViewCellAccessoryNone;
		
		UIActivityIndicatorView* spinner = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] autorelease];
		self.accessoryView = spinner;
		[spinner startAnimating];
	} else {
		self.accessoryView = nil;
		[self showMessage:checker.lastMessage];
	}
}

@end
