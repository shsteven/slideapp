//
//  MvrSlidesView.m
//  Mover3
//
//  Created by ∞ on 18/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrSlidesView.h"
#import "MvrSlide.h"


#define MvrClampValueBetween(value, min, max) \
	(MAX((min), MIN((max), (value))))

@interface MvrSlidesView ()

- (void) didComeToRest:(UIView *)v;
- (void) bounceBack:(UIView*) v;

@end



@implementation MvrSlidesView

- (id) initWithFrame:(CGRect) frame delegate:(id <MvrSlidesViewDelegate>) d;
{
    if (self = [super initWithFrame:frame]) {
        srandomdev();
		delegate = d;
    }
	
    return self;
}

- (void) dealloc;
{
    [super dealloc];
}


#define kMvrSafeRectDistanceDelta 40
- (CGRect) safeArea;
{
	return CGRectInset(self.bounds, kMvrSafeRectDistanceDelta, kMvrSafeRectDistanceDelta);
}


- (void) testByAddingEmptySlide;
{	
	MvrSlide* slide = [[MvrSlide alloc] initWithFrame:CGRectZero];
	[slide sizeToFit];
	slide.center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
	slide.delegate = self;
	[self addSubview:slide];
}

- (void) draggableViewDidEndDragging:(L0DraggableView *)view continuesWithSlide:(BOOL)slide;
{
	if (!slide)
		[self didComeToRest:view];
}

- (void) draggableView:(L0DraggableView *)view didEndInertialSlideByFinishing:(BOOL)finished;
{
	[self didComeToRest:view];
}

#define kMvrSafeRectBouncebackDelta 20
#define kMvrBouncebackCenterRandomnessLimit (20)
- (CGPoint) centerForBouncebackFromPoint:(CGPoint) point;
{
	CGRect safe = CGRectInset(self.safeArea, kMvrSafeRectBouncebackDelta, kMvrSafeRectBouncebackDelta);
	
	// TODO a little randomness?
	
	point.x = MvrClampValueBetween(point.x, CGRectGetMinX(safe), CGRectGetMaxX(safe));
	
	point.x += (random() & 1? 1 : -1) * (random() % kMvrBouncebackCenterRandomnessLimit);
	
	point.y = MvrClampValueBetween(point.y, CGRectGetMinY(safe), CGRectGetMaxY(safe));

	point.y += (random() & 1? 1 : -1) * (random() % kMvrBouncebackCenterRandomnessLimit);
	
	return point;
}

#define kMvrBoundsStartOfBouncebackArea (-20)
- (void) didComeToRest:(UIView*) v;
{
	CGRect bounceback = CGRectInset(self.bounds, kMvrBoundsStartOfBouncebackArea, kMvrBoundsStartOfBouncebackArea);
	
	// for now we just bounce back if needed.
	if (!CGRectContainsPoint(bounceback, v.center)) {
		if (![delegate respondsToSelector:@selector(slidesView:shouldBounceBackView:)] || [delegate slidesView:self shouldBounceBackView:v])
			[self bounceBack:v];
	}
	
}

- (void) bounceBack:(UIView*) v;
{
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
	[UIView setAnimationDuration:0.7];
	
	v.center = [self centerForBouncebackFromPoint:v.center];
	
	[UIView commitAnimations];
}

@end
