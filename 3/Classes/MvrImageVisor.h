//
//  MvrImageVisor.h
//  Mover3
//
//  Created by ∞ on 03/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MvrVisor.h"

@interface MvrImageVisor : MvrVisor <UIScrollViewDelegate> {
	IBOutlet UIImageView* imageView;
	IBOutlet UIScrollView* scrollView;
}

@end
