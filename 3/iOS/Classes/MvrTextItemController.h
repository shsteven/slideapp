//
//  MvrTextItemController.h
//  Mover3
//
//  Created by ∞ on 25/06/10.
//  Copyright 2010 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MvrItemController.h"
#import "MvrTextItem.h"

@interface MvrTextItemController : MvrItemController {
	IBOutlet UIView* stickyNoteView;
	IBOutlet UILabel* titleView;
	
	IBOutlet UITextView* contentView;
}

@end
