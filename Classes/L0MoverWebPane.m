//
//  L0MoverWebPane.m
//  Mover
//
//  Created by ∞ on 24/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0MoverWebPane.h"

@interface L0MoverWebPane ()

@property(copy, setter=privateSetStartingURL:) NSURL* startingURL;
@property(retain, setter=privateSetWebView:) UIWebView* webView;

@end


@implementation L0MoverWebPane

- (id) init;
{
	return [self initWithStartingURL:nil];
}

- (id) initWithStartingURL:(NSURL*) url;
{
	if (self = [super initWithNibName:nil bundle:nil])
		self.startingURL = url;
		
	return self;
}

@synthesize webView, startingURL;

- (void) loadView;
{
	UIView* v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
	self.view = v;
	[v release];
	
	[self viewDidLoad];
}

- (void) dealloc;
{
	[startingURL release];
	[webView release];
	[super dealloc];
}

- (void) viewDidAppear:(BOOL) ani;
{
	[super viewDidAppear:ani];
}

- (void) viewWillAppear:(BOOL) ani;
{
	[super viewWillAppear:ani];
	[self.navigationController setNavigationBarHidden:NO animated:ani];
	
	UIWebView* wv;
	if (self.webView)
		wv = self.webView;
	else {
		wv = [[UIWebView alloc] initWithFrame:self.view.bounds];
		wv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		wv.backgroundColor = self.view.backgroundColor;
		wv.delegate = self;
		self.webView = wv;
		[wv release];
	}
	
	if (!wv.superview)
		[self.view addSubview:wv];
	
	[wv loadRequest:[NSURLRequest requestWithURL:self.startingURL]];	
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

@end
