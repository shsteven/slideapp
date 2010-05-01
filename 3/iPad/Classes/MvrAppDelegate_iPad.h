//
//  Mover3_iPadAppDelegate.h
//  Mover3-iPad
//
//  Created by ∞ on 14/04/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Network+Storage/MvrModernWiFi.h"
#import "Network+Storage/MvrPlatformInfo.h"

#import "Network+Storage/MvrScannerObserver.h"

@class MvrTableController_iPad;

@interface MvrAppDelegate_iPad : NSObject <UIApplicationDelegate, MvrPlatformInfo, MvrScannerObserverDelegate> {
    UIWindow *window;
    MvrTableController_iPad *viewController;
	
	MvrModernWiFi* wifi;
	L0UUID* selfIdentifier;
	
	MvrScannerObserver* observer;
}

@property(nonatomic, retain) IBOutlet UIWindow* window;
@property(nonatomic, retain) IBOutlet MvrTableController_iPad* viewController;

@property(nonatomic, readonly) MvrModernWiFi* wifi;

@end


static inline MvrAppDelegate_iPad* MvrApp() {
	return (MvrAppDelegate_iPad*) [UIApp delegate];
}
