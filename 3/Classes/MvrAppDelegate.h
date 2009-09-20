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

#import "MvrTableController.h"

@interface MvrAppDelegate : NSObject <
	UIApplicationDelegate,
	UIActionSheetDelegate,
	MvrMetadataStorage, 
	MvrPlatformInfo>
{
    UIWindow *window;
	UIViewController* topViewController;
	
	MvrTableController* tableController;
	
	NSString* itemsDirectory;
	MvrStorageCentral* storageCentral;
	NSDictionary* metadata;
	
	L0UUID* identifierForSelf;
}

@property(nonatomic, retain) IBOutlet UIWindow *window;
@property(nonatomic, retain) IBOutlet UIViewController* topViewController;
@property(nonatomic, retain) IBOutlet MvrTableController* tableController;

@property(readonly) NSString* itemsDirectory;
@property(readonly) MvrStorageCentral* storageCentral;

- (IBAction) add;

@end

// -----

static inline MvrAppDelegate* MvrApp() {
	return (MvrAppDelegate*)([[UIApplication sharedApplication] delegate]);
}
