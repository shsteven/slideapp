//
//  MvrArrowView.h
//  Mover3
//
//  Created by ∞ on 22/09/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MvrArrowView : UIView {
	UIView* contentView;
	UIImageView* arrowView;
	UILabel* nameLabel;
	CGSize preferredSize;
	UIActivityIndicatorView* spinner;
	
	UIColor* busyColor, * normalColor;
	BOOL busy;
}

+ (CGAffineTransform) clockwiseHalfTurn;
+ (CGAffineTransform) counterclockwiseHalfTurn;

@property(copy) NSString* name;

@property(retain) IBOutlet UIView* contentView;
@property(retain) IBOutlet UIImageView* arrowView;
@property(retain) IBOutlet UILabel* nameLabel;
@property(retain) IBOutlet UIActivityIndicatorView* spinner;

@property(retain) UIColor* busyColor;
@property(retain) UIColor* normalColor;

@property BOOL busy;

@end
