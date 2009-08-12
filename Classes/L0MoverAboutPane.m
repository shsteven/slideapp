//
//  L0SlideAboutPane.m
//  Slide
//
//  Created by ∞ on 11/04/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0MoverAboutPane.h"
#import "L0MoverBookmarksAccountPane.h"
#import "L0MoverAppDelegate.h"

#import "L0MoverAdController.h"

@interface L0MoverAboutPane ()

- (void) clearOutlets;

@end


@implementation L0MoverAboutPane

- (void) viewWillAppear:(BOOL) ani;
{
	[super viewWillAppear:ani];
	[self.navigationController setNavigationBarHidden:YES animated:ani];

	CGPoint center = self.toolbar.center;
	center.y += self.toolbar.bounds.size.height + 20;
	self.toolbar.center = center;
	
	if ([L0MoverAdController isPaidVersion] || [L0MoverAdController isOpenSourceVersion]) {
		self.paidVersionButton.enabled = NO;
		
		if ([L0MoverAdController isPaidVersion]) {
			self.paidVersionButtonLabel.text = NSLocalizedString(@"Thanks for your support!", @"Paid version thank you banner");
			self.paidVersionButtonDetailLabel.text = NSLocalizedString(@"This is Mover+, the paid version without ads.", @"Paid version thank you subbanner");
		} else {
			self.paidVersionButtonLabel.text = NSLocalizedString(@"Thanks for using Mover!", @"FOSS version thank you banner");
			self.paidVersionButtonDetailLabel.text = NSLocalizedString(@"This is Mover Open, the open source version.", @"FOSS version thank you subbanner");
		}
		
		self.paidVersionButtonLabel.textAlignment = UITextAlignmentCenter;
		self.paidVersionButtonDetailLabel.textAlignment = UITextAlignmentCenter;
		
		self.paidVersionDisclosureIndicator.hidden = YES;
	}
}

- (void) viewDidAppear:(BOOL) ani;
{
	[super viewDidAppear:ani];
	[self performSelector:@selector(showToolbar) withObject:nil afterDelay:1.2];
}

- (void) showToolbar;
{	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.5];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
	
	CGPoint center = self.toolbar.center;
	center.y -= self.toolbar.bounds.size.height + 20;
	self.toolbar.center = center;
	
	[UIView commitAnimations];
}

- (void)viewDidLoad;
{
    [super viewDidLoad];

	NSString* version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	
	self.versionLabel.text = [NSString stringWithFormat:self.versionLabel.text, version];
}

- (void) viewDidUnload;
{
	[super viewDidUnload];
	[self clearOutlets];
}
 
- (void) clearOutlets;
{
	self.versionLabel = nil;
	self.copyrightPane = nil;
	self.toolbar = nil;
	self.paidVersionButton = nil;
	self.paidVersionButtonLabel = nil;
	self.paidVersionButtonDetailLabel = nil;
	self.paidVersionDisclosureIndicator = nil;
}

@synthesize versionLabel, copyrightPane, toolbar;
@synthesize paidVersionButton, paidVersionButtonLabel, paidVersionButtonDetailLabel, paidVersionDisclosureIndicator;

- (void) dealloc;
{
	[self clearOutlets];
	[super dealloc];
}

- (IBAction) showAboutCopyrightWebPane;
{
	[self.navigationController pushViewController:copyrightPane animated:YES];
}

- (IBAction) openInfiniteLabsDotNet;
{
	[UIApp openURL:[NSURL URLWithString:@"http://infinite-labs.net/"]];
}

- (IBAction) addSafariBookmarklet;
{
	[UIApp openURL:[NSURL URLWithString:@"http://infinite-labs.net/mover/safari-bookmarklet/"]];
}

- (IBAction) downloadPlus;
{
	[UIApp openURL:[NSURL URLWithString:@"http://infinite-labs.net/mover/download-plus/"]];
}

- (IBAction) emailAFriend;
{	
	[(L0MoverAppDelegate*)UIApp.delegate tellAFriend];
}

- (IBAction) showBookmarksAccountPane;
{
	L0MoverBookmarksAccountPane* pane = [[[L0MoverBookmarksAccountPane alloc] initWithDefaultNibName] autorelease];
	[self.navigationController pushViewController:pane animated:YES];
}

- (IBAction) dismiss;
{
	if (target && selector)
		[target performSelector:selector];
}

- (void) setDismissButtonTarget:(id) t selector:(SEL) s;
{
	target = t;
	selector = s;
}

@end

@implementation L0SlideAboutCopyrightWebPane

- (NSURL*) startingURL;
{
	NSString* path = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html" inDirectory:@"LicensesAndCopyrightPage"];
	return [NSURL fileURLWithPath:path];
}

@end
