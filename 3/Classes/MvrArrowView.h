//
//  MvrArrowView.h
//  Mover3
//
//  Created by ∞ on 22/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MvrArrowView : UIView {
	UIView* contentView;
	UIImageView* arrowView;
	UILabel* nameLabel;
	CGSize preferredSize;
}

+ (CGAffineTransform) clockwiseHalfTurn;
+ (CGAffineTransform) counterclockwiseHalfTurn;

@property(retain) IBOutlet UIView* contentView;
@property(retain) IBOutlet UIImageView* arrowView;
@property(retain) IBOutlet UILabel* nameLabel;

@end
