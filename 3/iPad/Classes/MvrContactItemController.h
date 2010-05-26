//
//  MvrContactItemController.h
//  Mover3-iPad
//
//  Created by ∞ on 01/05/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MvrContactItem.h"
#import "MvrItemController.h"

@interface MvrContactItemController : MvrItemController <UIPopoverControllerDelegate, UIAlertViewDelegate> {
	IBOutlet UIImageView* contactImageView;
	IBOutlet UILabel* contactNameLabel;
	IBOutlet UILabel* contactEmailLabel;
	IBOutlet UILabel* contactPhoneLabel;
	
	UIPopoverController* personPopover;
}

@end
