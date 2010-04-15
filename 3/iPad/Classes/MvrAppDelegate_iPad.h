//
//  Mover3_iPadAppDelegate.h
//  Mover3-iPad
//
//  Created by ∞ on 14/04/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MvrTableController_iPad;

@interface MvrAppDelegate_iPad : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    MvrTableController_iPad *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet MvrTableController_iPad *viewController;

@end

