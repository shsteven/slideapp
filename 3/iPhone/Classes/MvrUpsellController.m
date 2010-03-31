//
//  MvrUpsellController.m
//  Mover3
//
//  Created by ∞ on 23/10/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#if kMvrIsLite

#import "MvrUpsellController.h"
#import "MvrStorePane.h"
#import "MvrAppDelegate.h"

#import <MuiKit/MuiKit.h>

@interface MvrUpsellController () <MvrStorePaneDelegate>
@end


@implementation MvrUpsellController

- initWithAlertNamed:(NSString*) alertName cancelButton:(NSUInteger) index action:(MvrUpsellAction) a;
{
	if (self = [super init]) {
		alert = [[UIAlertView alertNamed:alertName] retain];
		alert.delegate = self;
		alert.cancelButtonIndex = index;
		
		action = a;
	}
	
	return self;
}

- (void) dealloc
{
	storePane.delegate = nil;
	[storePane release];
	[modalController release];
	[alert release];
	[super dealloc];
}


+ upsellWithAlertNamed:(NSString*) alertName cancelButton:(NSUInteger) index action:(MvrUpsellAction) a;
{
	return [[[self alloc] initWithAlertNamed:alertName cancelButton:index action:a] autorelease];
}

- (void) show;
{
	[self retain]; // balanced in -...clickedButtonAtIndex:...
	[alert show];
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
{
	if (buttonIndex != alertView.cancelButtonIndex) {
		
		switch (action) {
			case kMvrUpsellOpenMoverPlusPageInAppStore:
			{
				[self retain]; // balanced in -openAppStoreURL:
				[kMvrUpsellURL beginResolvingRedirectsWithDelegate:self selector:@selector(openAppStoreURL:)];
			}
				break;
				
			case kMvrUpsellDisplayStorePane:
			{
				[self retain]; // balanced in -dismissStorePane:
				MvrStorePane* pane;
				modalController = [[MvrStorePane modalControllerForPane:&pane] retain];
				pane.delegate = self;
				storePane = [pane retain];
				
				[MvrApp() presentModalViewController:modalController];
			}
				break;
		}
	
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

- (void) dismissStorePane:(MvrStorePane*) pane;
{
	[self autorelease];
	pane.delegate = nil;
	[pane dismissModalViewControllerAnimated:YES];
}

@end

#endif
