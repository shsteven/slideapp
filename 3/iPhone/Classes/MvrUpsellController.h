//
//  MvrUpsellController.h
//  Mover3
//
//  Created by ∞ on 23/10/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#if kMvrIsLite

enum {
	kMvrUpsellOpenMoverPlusPageInAppStore,
	kMvrUpsellDisplayStorePane,
};
typedef NSInteger MvrUpsellAction;

@class MvrStorePane;

#import <UIKit/UIKit.h>

#define kMvrUpsellURL ([NSURL URLWithString:@"http://infinite-labs.net/mover/download-plus"])

@interface MvrUpsellController : NSObject <UIAlertViewDelegate> {
	UIAlertView* alert;
	MvrUpsellAction action;
	UIViewController* modalController;
	MvrStorePane* storePane;
}

- initWithAlertNamed:(NSString*) alertName cancelButton:(NSUInteger) index action:(MvrUpsellAction) a;
+ upsellWithAlertNamed:(NSString*) alertName cancelButton:(NSUInteger) index action:(MvrUpsellAction) a;

- (void) show;

@end

#endif