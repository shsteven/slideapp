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
#import "MvrItemController.h"
#import "MvrImageItem.h"
#import "MvrImageItemController.h"

@implementation MvrAppDelegate_iPad

@synthesize window;
@synthesize viewController;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {	
	
	[MvrImageItem registerClass];
	[MvrImageItemController registerClass];
	
	wifi = [[MvrModernWiFi alloc] initWithPlatformInfo:self serverPort:kMvrModernWiFiPort options:kMvrUseMobileService|kMvrAllowBrowsingForConduitService|kMvrAllowConnectionsFromConduitService];
	
	wifi.enabled = YES;
	
	[window addSubview:viewController.view];
	[window makeKeyAndVisible];
		

	[self performSelector:@selector(testByAddingImage) withObject:nil afterDelay:1.0];
	
	return YES;
}

- (void) testByAddingImage;
{
	MvrImageItem* img = [[MvrImageItem alloc] initWithImage:[UIImage imageNamed:@"IMG_0439.jpg"] type:@"public.jpeg"];
	[viewController addItem:img fromSource:nil ofType:kMvrItemSourceSelf];	
}

- (void)dealloc {
	[wifi release];
	
	[viewController release];
	[window release];
	[super dealloc];
}

@synthesize wifi;

#pragma mark Platform info

- (NSString *) displayNameForSelf;
{
	return [UIDevice currentDevice].name;
}

- (L0UUID*) identifierForSelf;
{
	if (!selfIdentifier)
		selfIdentifier = [[L0UUID UUID] retain];
	
	return selfIdentifier;
}

- (MvrAppVariant) variant;
{
	return kMvrAppVariantMoverOpen;
}

- (NSString *) variantDisplayName;
{
	return @"Mover";
}

- (id) platform;
{
	return kMvrAppleiPhoneOSPlatform;
}

- (double) version;
{
	return [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] doubleValue];
}

- (NSString *) userVisibleVersion;
{
	return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

@end
