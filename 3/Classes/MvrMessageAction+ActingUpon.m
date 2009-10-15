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

@interface MvrMessageActionWebPane : L0WebViewController {}
- (IBAction) dismiss;
@end

@implementation MvrMessageActionWebPane

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

- (void) didResoveRedirectsWithURL:(NSURL*) u;
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

// TODO styling stuff

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
		[self.URL beginResolvingRedirectsWithDelegate:self selector:@selector(didResolveRedirectsWithURL:)];
	}
}

- (void) didResoveRedirectsWithURL:(NSURL*) u;
{
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
	MvrMessageActionWebPane* pane = [MvrMessageActionWebPane new];
	pane.initialURL = self.URL;
	return pane;
}

- (UIViewController*) modalViewController;
{
	UIViewController* ctl = [self nonmodalViewController];
	ctl.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:ctl action:@selector(dismiss)] autorelease];
	
	UINavigationController* nav = [[[UINavigationController alloc] initWithRootViewController:ctl] autorelease];
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
