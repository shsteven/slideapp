//
//  MvrMessageAction+ActingUpon.m
//  Mover3
//
//  Created by ∞ on 14/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrMessageAction+ActingUpon.h"

#import <MuiKit/MuiKit.h>
#import "MvrAppDelegate.h"

@interface MvrMessageActionWebPane : L0WebViewController {
	UIStatusBarStyle oldStatusBarStyle;
	BOOL switchesBarStyleOnShow;
}

@property BOOL switchesBarStyleOnShow;

- (IBAction) dismiss;

@end

@implementation MvrMessageActionWebPane

@synthesize switchesBarStyleOnShow;

- (BOOL) webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;
{
	BOOL isLink = (navigationType == UIWebViewNavigationTypeLinkClicked);
	
	if (isLink) {
		
		[UIApp beginIgnoringInteractionEvents];
		
		NSURL* u = [request URL];
		[u beginResolvingRedirectsWithDelegate:self selector:@selector(didResolveRedirectsWithURL:)];
		return NO;
		
	} else
		return YES;
}

- (void) didResolveRedirectsWithURL:(NSURL*) u;
{
	[UIApp endIgnoringInteractionEvents];
	
	if (u)
		[UIApp openURL:u];
	else
		[[UIAlertView alertNamed:@"MvrNoInternet_MessageAction"] show];
}

- (IBAction) dismiss;
{
	[self dismissModalViewControllerAnimated:YES];
}

- (void) viewWillAppear:(BOOL)animated;
{
	[super viewWillAppear:animated];
	
	if (self.switchesBarStyleOnShow) {
		oldStatusBarStyle = UIApp.statusBarStyle;
		UIStatusBarStyle style = self.wantsFullScreenLayout? UIStatusBarStyleBlackTranslucent : UIStatusBarStyleBlackOpaque;
		[UIApp setStatusBarStyle:style animated:animated];
	}
}

- (void) viewWillDisappear:(BOOL)animated;
{
	[super viewWillDisappear:animated];
	
	if (self.switchesBarStyleOnShow)
		[UIApp setStatusBarStyle:oldStatusBarStyle animated:animated];
}

@end


@implementation MvrMessageAction (MvrActingUpon)

#pragma mark -
#pragma mark Out-of-app URL opening

- (void) openURLAfterRedirects:(BOOL) reds;
{
	if (!reds)
		[UIApp openURL:self.URL]; // and that's it. otherwise...
	else  {
		[UIApp beginIgnoringInteractionEvents];
		[UIApp beginNetworkUse];
		[self.URL beginResolvingRedirectsWithDelegate:self selector:@selector(didResolveRedirectsWithURL:)];
	}
}

- (void) didResolveRedirectsWithURL:(NSURL*) u;
{
	[UIApp endNetworkUse];
	[UIApp endIgnoringInteractionEvents];
	
	if (u)
		[UIApp openURL:u];
	else
		[[UIAlertView alertNamed:@"MvrNoInternet_MessageAction"] show];
}

#pragma mark -
#pragma mark In-app URL display

- (UIViewController*) nonmodalViewController;
{
	MvrMessageActionWebPane* pane = [[MvrMessageActionWebPane new] autorelease];
	pane.initialURL = self.URL;
	return pane;
}

- (UIViewController*) modalViewController;
{
	MvrMessageActionWebPane* ctl = (MvrMessageActionWebPane*) [self nonmodalViewController];
	ctl.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:ctl action:@selector(dismiss)] autorelease];
	ctl.switchesBarStyleOnShow = YES;
	ctl.wantsFullScreenLayout = self.usesTranslucentTopBar;

	UINavigationController* nav = [[[UINavigationController alloc] initWithRootViewController:ctl] autorelease];
	nav.navigationBar.barStyle = self.usesTranslucentTopBar? UIBarStyleBlackTranslucent : UIBarStyleBlack;
	
	return nav;
}

#pragma mark -
#pragma mark Default acting-upon

- (void) perform;
{
	if (self.shouldDisplayInApp)
		[MvrApp() presentModalViewController:[self modalViewController]];
	else
		[self openURLAfterRedirects:YES];
}

@end
