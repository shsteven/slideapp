//
//  MvrUpsellController.h
//  Mover3
//
//  Created by ∞ on 23/10/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#if kMvrIsLite

#import <UIKit/UIKit.h>

#define kMvrUpsellURL ([NSURL URLWithString:@"http://infinite-labs.net/mover/download-plus"])

@interface MvrUpsellController : NSObject <UIAlertViewDelegate> {
	UIAlertView* alert;
}

- initWithAlertNamed:(NSString*) alertName cancelButton:(NSUInteger) index;
+ upsellWithAlertNamed:(NSString*) alertName cancelButton:(NSUInteger) index;

- (void) show;

@end

#endif