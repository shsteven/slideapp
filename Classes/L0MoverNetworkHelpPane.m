//
//  L0MoverNetworkHelpPane.m
//  Mover
//
//  Created by ∞ on 24/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0MoverNetworkHelpPane.h"
#import "L0MoverAppDelegate.h"
#import "L0MoverNetworkSettingsPane.h"

@implementation L0MoverNetworkHelpPane

- (NSURL*) startingURL;
{
	NSString* path = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html" inDirectory:@"NetworkHelpPage"];
	return [NSURL fileURLWithPath:path];
}

- (void) viewWillAppear:(BOOL) ani;
{
	self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
	[super viewWillAppear:ani];
}

- (BOOL)webView:(UIWebView *)w shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;
{
	// x-internal:mover-network-pane opens the network pane.
	NSURL* u = [request URL];
	if ([[u scheme] isEqual:@"x-internal"] && [[u resourceSpecifier] isEqual:@"mover-network-pane"]) {
		
		if (self.navigationController) {
			L0MoverNetworkSettingsPane* pane = [L0MoverNetworkSettingsPane networkSettingsPane];
			[self.navigationController pushViewController:pane animated:YES];
		} else {
			UIViewController* ctl = [L0MoverNetworkSettingsPane modalNetworkSettingsPane];
			[self presentModalViewController:ctl animated:YES];
		}
		
		return NO;
	} else
		return [super webView:w shouldStartLoadWithRequest:request navigationType:navigationType];
}

#pragma mark -
#pragma mark Construction

+ modalNetworkHelpPane;
{
	L0MoverNetworkHelpPane* myself = [[L0MoverNetworkHelpPane alloc] init];
	UINavigationController* nav = [[UINavigationController alloc] initWithRootViewController:myself];
	
	myself.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:myself action:@selector(dismiss)] autorelease];
	myself.title = @"Network Help";
	
	[myself release];
	
	nav.navigationBar.barStyle = UIBarStyleBlackTranslucent;
	return [nav autorelease];
}

- (IBAction) dismiss;
{
	[self dismissModalViewControllerAnimated:YES];
}

@end