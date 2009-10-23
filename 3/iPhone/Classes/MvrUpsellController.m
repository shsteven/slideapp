//
//  MvrUpsellController.m
//  Mover3
//
//  Created by ∞ on 23/10/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#if kMvrIsLite

#import "MvrUpsellController.h"

#import <MuiKit/MuiKit.h>

@implementation MvrUpsellController

- initWithAlertNamed:(NSString*) alertName cancelButton:(NSUInteger) index;
{
	if (self = [super init]) {
		alert = [[UIAlertView alertNamed:alertName] retain];
		alert.delegate = self;
		alert.cancelButtonIndex = index;
	}
	
	return self;
}

- (void) dealloc
{
	[alert release];
	[super dealloc];
}


+ upsellWithAlertNamed:(NSString*) alertName cancelButton:(NSUInteger) index;
{
	return [[[self alloc] initWithAlertNamed:alertName cancelButton:index] autorelease];
}

- (void) show;
{
	[self retain]; // balanced in -...clickedButtonAtIndex:...
	[alert show];
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
{
	if (buttonIndex != alertView.cancelButtonIndex) {
		[self retain]; // balanced in -openAppStoreURL:
		[kMvrUpsellURL beginResolvingRedirectsWithDelegate:self selector:@selector(openAppStoreURL:)];
	}
	
	[self autorelease];
}

- (void) openAppStoreURL:(NSURL*) url;
{
	[self autorelease]; // balances the -retain in -...didSelectRow....
	if (!url)
		url = kMvrUpsellURL;
	[UIApp openURL:url];
}

@end

#endif
