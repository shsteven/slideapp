//
//  MvrMessage+Showing.h
//  Mover3
//
//  Created by ∞ on 14/10/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MvrMessage.h"

@interface MvrMessage (MvrShowing) <UIAlertViewDelegate>

- (void) show;

@end
