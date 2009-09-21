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

@property(readonly) CGRect safeArea;
@property(readonly) CGRect bouncebackArrivalArea;
@property(readonly) CGRect additionArrivalArea;

- (void) didComeToRest:(UIView *)v;
- (void) bounceBack:(UIView*) v;

- (CGPoint) southEntrancePointForView:(UIView*) v;

- (void) enterView:(UIView*) v inArea:(CGRect) area randomness:(CGSize) randomness;
- (CGPoint) arrivalPointStartingFromPoint:(CGPoint) point inArea:(CGRect) area randomness:(CGSize) randomness;

- (void) addDraggableSubview:(L0DraggableView*) view;

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
#if DEBUG
	[shownArea release];
#endif
	
    [super dealloc];
}

#if DEBUG
- (void) showArea:(CGRect)area;
{
	if (!shownArea) {
		shownArea = [[UIView alloc] initWithFrame:area];
		[self insertSubview:shownArea atIndex:0];
	}
	
	shownArea.backgroundColor = [UIColor redColor];
}
#endif

#pragma mark -
#pragma mark Adding items

#define kMvrAdditionRandomnessLimit CGSizeMake(50, 0)
- (void) addDraggableSubviewFromSouth:(L0DraggableView *)view;
{
	view.center = [self southEntrancePointForView:view];
	[self addDraggableSubview:view];
	[self enterView:view inArea:self.additionArrivalArea randomness:kMvrAdditionRandomnessLimit];
}

- (void) addDraggableSubviewWithoutAnimation:(L0DraggableView*)view;
{
	// simulate an entrance without actually animating anything.
	CGPoint cen = [self southEntrancePointForView:view];
	cen = [self arrivalPointStartingFromPoint:cen inArea:self.additionArrivalArea randomness:kMvrAdditionRandomnessLimit];
	view.center = cen;
	[self addDraggableSubview:view];	
}

- (CGPoint) southEntrancePointForView:(UIView*) v;
{
	CGRect r = self.bounds;
	CGPoint point;
	point.x = CGRectGetMidX(r);
	
	// Hi Pythagoras!
	CGRect viewBounds = v.bounds;
	CGFloat diagonal = sqrt(pow(viewBounds.size.width, 2) + pow(viewBounds.size.height, 2));
	point.y = CGRectGetMaxY(r) + diagonal + 10;
	
	return point;
}

- (CGRect) additionArrivalArea;
{
	CGRect safe = self.safeArea;
	safe.size.height = self.bounds.size.height * (2.0/3.0);
	return safe;
}

#pragma mark -
#pragma mark Bounceback

#define kMvrSafeRectDistanceDelta 40
- (CGRect) safeArea;
{
	return CGRectInset(self.bounds, kMvrSafeRectDistanceDelta, kMvrSafeRectDistanceDelta);
}

#define kMvrSafeRectBouncebackDelta 20
- (CGRect) bouncebackArrivalArea;
{
	return CGRectInset(self.safeArea, kMvrSafeRectBouncebackDelta, kMvrSafeRectBouncebackDelta);
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

- (CGPoint) arrivalPointStartingFromPoint:(CGPoint) point inArea:(CGRect) safe randomness:(CGSize) randomness;
{	
	point.x = MvrClampValueBetween(point.x, CGRectGetMinX(safe), CGRectGetMaxX(safe));
	
	if (randomness.width != 0)
		point.x += (random() & 1? 1 : -1) * (random() % (long) randomness.width);
	
	point.y = MvrClampValueBetween(point.y, CGRectGetMinY(safe), CGRectGetMaxY(safe));

	if (randomness.height != 0)
		point.y += (random() & 1? 1 : -1) * (random() % (long) randomness.height);
	
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

#define kMvrBouncebackCenterRandomnessLimit (50)
- (void) bounceBack:(UIView*) v;
{
	[self enterView:v inArea:self.bouncebackArrivalArea randomness:CGSizeMake(kMvrBouncebackCenterRandomnessLimit, kMvrBouncebackCenterRandomnessLimit)];
}

- (void) enterView:(UIView*) v inArea:(CGRect) area randomness:(CGSize) randomness;
{
#if DEBUG
	[self showArea:area];
#endif
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
	[UIView setAnimationDuration:0.7];
	
	v.center = [self arrivalPointStartingFromPoint:v.center inArea:area randomness:randomness];
	
	[UIView commitAnimations];
}

#pragma mark -
#pragma mark Subview management

- (void) setEditing:(BOOL) editing animated:(BOOL) animated;
{
	for (id v in self.subviews) {
		if ([v respondsToSelector:@selector(setEditing:animated:)])
			[v setEditing:editing animated:animated];
	}
}

- (void) addDraggableSubview:(L0DraggableView*) view;
{
	view.delegate = self;
	[self addSubview:view];
}

@end
