//
//  MvrImageItemController.h
//  Mover3-iPad
//
//  Created by ∞ on 23/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MvrItemViewController.h"
#import "MvrDraggableView.h"

@interface MvrImageItemController : MvrItemViewController {
	IBOutlet UIImageView* imageView;
	CGFloat imageViewMargin;
}

@end

@interface MvrImageItemBackdropView : MvrDraggableView {
	CALayer* backdrop;
}

@end
