//
//  MvrBookmarkItemController.h
//  Mover3
//
//  Created by ∞ on 26/06/10.
//  Copyright 2010 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MvrItemController.h"
#import "MvrBookmarkItem.h"

@interface MvrBookmarkItemController : MvrItemController {
	IBOutlet UIButton* addressButton;
	IBOutlet UIImageView* compassImageView;
}

- (IBAction) openInSafari;

@end
