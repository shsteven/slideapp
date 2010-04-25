//
//  Mover3_iPadAppDelegate.m
//  Mover3-iPad
//
//  Created by ∞ on 14/04/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "MvrAppDelegate_iPad.h"
#import "MvrTableController_iPad.h"

#warning Test
#import "MvrDraggableView.h"
#import "MvrItemViewController.h"
#import "MvrImageItem.h"
#import "MvrImageItemController.h"

@implementation MvrAppDelegate_iPad

@synthesize window;
@synthesize viewController;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {	
	
	[MvrItemViewController setViewControllerClass:[MvrImageItemController class] forItemClass:[MvrImageItem class]];
	
	MvrImageItem* item = [[[MvrImageItem alloc] initWithImage:[UIImage imageNamed:@"IMG_0439.jpg"] type:@"public.png"] autorelease];
	MvrImageItemController* ctl = [[[MvrItemViewController viewControllerClassForItem:item] new] autorelease];
	ctl.item = item;
	
	[viewController addItemController:ctl];
	
	
	// Override point for customization after app launch	
	[window addSubview:viewController.view];
	[window makeKeyAndVisible];
	
	return YES;
}


- (void)dealloc {
	[viewController release];
	[window release];
	[super dealloc];
}


@end
