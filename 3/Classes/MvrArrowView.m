//
//  MvrArrowView.m
//  Mover3
//
//  Created by ∞ on 22/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrArrowView.h"


@implementation MvrArrowView

+ (CGAffineTransform) clockwiseHalfTurn;
{
	return CGAffineTransformMakeRotation(M_PI/2.0);
}

+ (CGAffineTransform) counterclockwiseHalfTurn;
{
	return CGAffineTransformMakeRotation(-M_PI/2.0);
}

- (id)initWithFrame:(CGRect) frame {
	if (self = [super initWithFrame:frame]) {
		self.contentMode = UIViewContentModeCenter;
		
        [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil];
		preferredSize = contentView.frame.size;
		
		self.nameLabel.contentMode = UIViewContentModeCenter;
		self.arrowView.contentMode = UIViewContentModeCenter;
		
		if (CGRectIsEmpty(frame)) {
			if (CGRectIsNull(frame))
				frame.origin = CGPointZero;
			
			frame.size = preferredSize;
			self.frame = frame;
		}
		
		self.contentView.frame = self.bounds;
		[self addSubview:self.contentView];
		
		self.normalColor = self.nameLabel.textColor;
		self.busyColor = [UIColor colorWithRed:33.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0];
    }

    return self;
}

@synthesize nameLabel, contentView, arrowView, busyColor, normalColor, spinner;

- (void)dealloc {
	[contentView release];
	[arrowView release];
	[nameLabel release];
	[normalColor release];
	[busyColor release];
	[spinner release];
    [super dealloc];
}

- (void) sizeToFit;
{
	CGRect frame;
	frame.origin = self.frame.origin;
	frame.size = preferredSize;
	self.frame = frame;
}

@synthesize busy;
- (void) setBusy:(BOOL) nowBusy;
{
	BOOL wasBusy = busy;
	busy = nowBusy;
	
	if (!wasBusy && nowBusy) {		
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:1.0];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
		[UIView setAnimationRepeatCount:1e100f];
		[UIView setAnimationRepeatAutoreverses:YES];
		
		self.nameLabel.alpha = 0.3;
		self.nameLabel.textColor = self.busyColor;

		[UIView commitAnimations];
		
		[self.spinner startAnimating];
	} else if (wasBusy && !nowBusy) {
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:1.0];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
		[UIView setAnimationBeginsFromCurrentState:YES];
		[UIView setAnimationRepeatCount:1];
		[UIView setAnimationRepeatAutoreverses:NO];
		
		self.nameLabel.alpha = 1;
		self.nameLabel.textColor = self.normalColor;
		
		[UIView commitAnimations];
		
		[self.spinner stopAnimating];
	}
}

@end
