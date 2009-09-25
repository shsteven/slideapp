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
	
	UIColor* busyColor, * normalColor;
	BOOL busy;
}

+ (CGAffineTransform) clockwiseHalfTurn;
+ (CGAffineTransform) counterclockwiseHalfTurn;

@property(retain) IBOutlet UIView* contentView;
@property(retain) IBOutlet UIImageView* arrowView;
@property(retain) IBOutlet UILabel* nameLabel;

@property(retain) UIColor* busyColor;
@property(retain) UIColor* normalColor;

@property BOOL busy;

@end
