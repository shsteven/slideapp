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

#import <MessageUI/MessageUI.h>

@interface MvrContactItemController : MvrItemController <UIPopoverControllerDelegate, UIAlertViewDelegate, MFMailComposeViewControllerDelegate> {
	IBOutlet UIImageView* contactImageView;
	IBOutlet UILabel* contactNameLabel;
	IBOutlet UIButton* contactEmailButton;
	IBOutlet UILabel* contactPhoneLabel;
	
	UIPopoverController* personPopover;
}

- (IBAction) showMailComposerForContact;

@end
