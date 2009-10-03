//
//  MvrImageVisor.h
//  Mover3
//
//  Created by ∞ on 03/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MvrImageItem;

@interface MvrImageVisor : UIViewController <UIScrollViewDelegate> {
	IBOutlet UIImageView* imageView;
	IBOutlet UIScrollView* scrollView;
	
	MvrImageItem* item;
	
	BOOL changesStatusBarStyleOnAppearance;
	UIBarStyle previousStatusBarStyle;
}

+ visorWithImageItem:(MvrImageItem*) i;
+ modalVisorWithImageItem:(MvrImageItem*) i;

- (id) initWithImageItem:(MvrImageItem*) i;

@end
