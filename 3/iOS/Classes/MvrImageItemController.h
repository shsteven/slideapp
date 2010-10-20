//
//  MvrImageItemController.h
//  Mover3-iPad
//
//  Created by ∞ on 23/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MvrItemController.h"
#import "MvrDraggableView.h"

@interface MvrImageItemController : MvrItemController {
	IBOutlet UIImageView* imageView;
	CGFloat imageViewMargin;
	
	IBOutlet UILabel* tooLargeLabel;
	IBOutlet UILabel* imageTitleLabel;
}

@end

@interface MvrImageItemBackdropView : MvrDraggableView {
	CALayer* backdrop;
}

@end
