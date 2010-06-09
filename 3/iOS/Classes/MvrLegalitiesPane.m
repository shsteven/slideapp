//
//  MvrLegalitiesPane.m
//  Mover3
//
//  Created by ∞ on 13/10/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrLegalitiesPane.h"


@implementation MvrLegalitiesPane

- (id) init
{
	self = [super init];
	if (self != nil) {
		self.wantsFullScreenLayout = YES;
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
			self.title = NSLocalizedString(@"Licenses & Copyrights", @"Title for legalities pane.");
	}
	return self;
}

- (void) viewDidLoad;
{
	[super viewDidLoad];	
	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"DrawerBackdrop.png"]];
}

- (void) viewWillAppear:(BOOL) a;
{
	[super viewWillAppear:a];
	
	if (self.navigationController.navigationBarHidden)
		[self.navigationController setNavigationBarHidden:NO animated:a];
	
	self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
}

- (CGSize) contentSizeForViewInPopover;
{
	return CGSizeMake(320, 430);
}

- (NSURL*) initialURL;
{
	NSString* path = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html" inDirectory:@"Legalities"];
	return [NSURL fileURLWithPath:path];
}

- (BOOL) webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;
{
	if (navigationType != UIWebViewNavigationTypeLinkClicked)
		return YES;
	
	[UIApp openURL:[request URL]];
	return NO;
}

- (void) webViewDidFinishLoad:(UIWebView *)webView;
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
		(void) [self.webView stringByEvaluatingJavaScriptFromString:@"document.body.className += ' is-overlaid-with-translucent-44px-bar';"];	
}

@end
