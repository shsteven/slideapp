//
//  Mover3AppDelegate.h
//  Mover3
//
//  Created by ∞ on 12/09/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Network+Storage/MvrMetadataStorage.h"
#import "Network+Storage/MvrPlatformInfo.h"

#import "Network+Storage/MvrStorageCentral.h"

@interface MvrAppDelegate : NSObject <UIApplicationDelegate,
	MvrMetadataStorage, MvrPlatformInfo>
{
    UIWindow *window;
	
	NSString* itemsDirectory;
	MvrStorageCentral* storageCentral;
	NSDictionary* metadata;
	
	L0UUID* identifierForSelf;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property(readonly) NSString* itemsDirectory;
@property(readonly) MvrStorageCentral* storageCentral;

@end

// -----

static inline MvrAppDelegate* MvrApp() {
	return (MvrAppDelegate*)([[UIApplication sharedApplication] delegate]);
}
