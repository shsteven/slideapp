//
//  MvrArrowView_iPad.h
//  Mover3-iPad
//
//  Created by ∞ on 21/05/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface MvrArrowView_iPad : UIView {
	IBOutlet UIView* contentView;
	
	IBOutlet UILabel* mainLabel;
	IBOutlet UIActivityIndicatorView* spinner;
}

@property(readonly) UILabel* mainLabel;

@end
