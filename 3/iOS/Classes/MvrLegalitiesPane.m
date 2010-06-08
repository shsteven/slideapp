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

@end
