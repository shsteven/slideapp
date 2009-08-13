//
//  MvrAppleAdItem.h
//  Mover
//
//  Created by ∞ on 20/07/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "L0MoverItem.h"

@interface MvrAppleAdItem : L0MoverItem {
	int number;
	UIImage* image;
}

+ adItemWithNumber:(int) n;
+ adItemForReceiving;

- (id) initWithNumber:(int) number;

@end
