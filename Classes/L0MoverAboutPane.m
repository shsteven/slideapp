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
}

@synthesize versionLabel, copyrightPane, toolbar;

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

- (void) viewDidAppear:(BOOL) ani;
{
	[super viewDidAppear:ani];
}

- (void) viewWillAppear:(BOOL) ani;
{
	[super viewWillAppear:ani];
	[self.navigationController setNavigationBarHidden:NO animated:ani];
	
	UIWebView* wv = [[UIWebView alloc] initWithFrame:self.view.bounds];
	wv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	wv.backgroundColor = self.view.backgroundColor;
	wv.delegate = self;
	
	[self.view addSubview:wv];
	
	NSString* index = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html" inDirectory:@"LicensesAndCopyrightPage"];
	NSURL* url = [NSURL fileURLWithPath:index];
	[wv loadRequest:[NSURLRequest requestWithURL:url]];

	self.webView = wv;
	[wv release];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;
{
	if (navigationType == UIWebViewNavigationTypeBackForward || navigationType == UIWebViewNavigationTypeReload || navigationType == UIWebViewNavigationTypeFormSubmitted || navigationType == UIWebViewNavigationTypeFormResubmitted || navigationType == UIWebViewNavigationTypeOther)
		return YES; // either they're benign, we have requested them, or we need a whole browser to handle 'em.
	
	// everything else, off we go.
	[UIApp openURL:[request URL]];
	return NO;
}

- (void) viewDidDisappear:(BOOL) ani;
{
	[self.webView removeFromSuperview];
	self.webView = nil;
}

@synthesize webView;

- (void) dealloc;
{
	[webView release];
	[super dealloc];
}

@end
