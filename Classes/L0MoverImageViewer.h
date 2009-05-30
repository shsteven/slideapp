//
//  L0MoverImageViewer.h
//  Mover
//
//  Created by ∞ on 16/05/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface L0MoverImageViewer : UIViewController <UIScrollViewDelegate> {
	UIScrollView* scrollView;
	UIImageView* imageView;
	UIImage* image;
	
	BOOL hasBarStyle;
	UIBarStyle lastBarStyle;
	
	id delegate;
	SEL selector;
}

- (id) initWithImage:(UIImage*) i dismissDelegate:(id) d selector:(SEL) s;

@property(assign) IBOutlet UIImageView* imageView;
@property(assign) IBOutlet UIScrollView* scrollView;
@property(retain) UIImage* image;

@end
