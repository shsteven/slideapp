//
//  MvrPreviewVisor.m
//  Mover3
//
//  Created by ∞ on 17/03/10.
//  Copyright 2010 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrPreviewVisor.h"
#import "Network+Storage/MvrItem.h"
#import "Network+Storage/MvrItemStorage.h"

@implementation MvrPreviewVisor

- (id) initWithItem:(MvrItem*) i;
{
	self = [super initWithItem:i];
	if (self != nil) {
		self.title = i.title;
	}
	return self;
}

- (UIStatusBarStyle) preferredStatusBarStyle;
{
	return UIStatusBarStyleBlackOpaque;
}

- (void) modifyStyleForModalNavigationBar:(UINavigationBar*) nb;
{
	nb.barStyle = UIBarStyleBlack;
	nb.translucent = NO;
}

- (void) viewDidUnload;
{
	[super viewDidUnload];
	[webView release]; webView = nil;
}

- (void) dealloc
{
	[webView release];
	[super dealloc];
}

- (void) viewDidLoad;
{
	[super viewDidLoad];
	
	webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
	webView.scalesPageToFit = YES;
	[self.view addSubview:webView];
}

- (void) viewWillAppear:(BOOL) a;
{
	[super viewWillAppear:a];
	
	NSString* path = [self.item storage].path;
	NSURL* url = [NSURL fileURLWithPath:path];
	NSURLRequest* req = [NSURLRequest requestWithURL:url];
	
	[webView loadRequest:req];
}

- (void) webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error;
{
	L0Log(@"%@", error);
}

- (BOOL) webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;
{
	if (navigationType == UIWebViewNavigationTypeLinkClicked) {
		[UIApp openURL:[request URL]];
		return NO;
	}

	return YES;
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation;
{
	return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

@end
