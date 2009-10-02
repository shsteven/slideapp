//
//  MvrSlidesView.m
//  Mover3
//
//  Created by ∞ on 18/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrSlidesView.h"
#import "MvrSlide.h"

typedef CGPoint (*MvrCGRectInspector)(CGRect rect);


#define MvrClampValueBetween(value, min, max) \
	(MAX((min), MIN((max), (value))))

#define kMvrMaximumAngleRange (30)
static CGAffineTransform MvrConcatenateRandomRotationToTransform(CGAffineTransform transform)
{
	srandomdev();
	CGFloat angle = ((random() % kMvrMaximumAngleRange) - kMvrMaximumAngleRange / 2.0) * M_PI/180.0;
	return CGAffineTransformRotate(transform, angle);
}

@interface MvrSlidesView ()

@property(readonly) CGRect safeArea;
@property(readonly) CGRect bouncebackArrivalArea;
@property(readonly) CGRect additionArrivalArea;

- (void) didComeToRest:(UIView *)v;
- (void) bounceBack:(UIView*) v;

- (CGPoint) entrancePointForView:(UIView*) view fromDirection:(MvrDirection) d;

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
		self.clipsToBounds = YES;
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
static BOOL MvrSlidesViewAllowsShowingAreas = NO;

+ (void) allowShowingAreas;
{
	MvrSlidesViewAllowsShowingAreas = YES;
}

- (void) showArea:(CGRect)area;
{
	if (!MvrSlidesViewAllowsShowingAreas) return;
	
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
- (void) addDraggableSubview:(L0DraggableView *)view enteringFromDirection:(MvrDirection) d;
{
	view.center = [self entrancePointForView:view fromDirection:d];
	[self addDraggableSubview:view];
	[self enterView:view inArea:self.additionArrivalArea randomness:kMvrAdditionRandomnessLimit];
}

- (void) addDraggableSubviewWithoutAnimation:(L0DraggableView*)view;
{
	// simulate an entrance without actually animating anything.
	CGPoint cen = [self entrancePointForView:view fromDirection:kMvrDirectionSouth];
	cen = [self arrivalPointStartingFromPoint:cen inArea:self.additionArrivalArea randomness:kMvrAdditionRandomnessLimit];
	view.center = cen;
	[self addDraggableSubview:view];	
}

#define kMvrEntrancePointForViewMargin (10.0)
- (CGPoint) entrancePointForView:(UIView*) v fromDirection:(MvrDirection) d;
{
	CGRect r = self.bounds;
	CGRect viewBounds = v.bounds;
	CGFloat diagonal = sqrt(pow(viewBounds.size.width, 2) + pow(viewBounds.size.height, 2));

	switch (d) {
		case kMvrDirectionNone:
			return CGPointMake(CGRectGetMidX(r), CGRectGetMidY(r));
		
		case kMvrDirectionNorth:
			return CGPointMake(CGRectGetMidX(r), -(diagonal + kMvrEntrancePointForViewMargin));
		
		case kMvrDirectionWest:
			return CGPointMake(-(diagonal + kMvrEntrancePointForViewMargin), CGRectGetMidY(r));
			
		case kMvrDirectionSouth:
			return CGPointMake(CGRectGetMidX(r), r.size.height + (diagonal + kMvrEntrancePointForViewMargin));

		case kMvrDirectionEast:
			return CGPointMake(r.size.width + (diagonal + kMvrEntrancePointForViewMargin), CGRectGetMidY(r));
			
		default:
			NSAssert(NO, @"Unhandled direction while trying to determine an entrance point!");
			return CGPointZero;
	}
}

- (CGRect) additionArrivalArea;
{
	CGRect selfBounds = self.bounds;
	CGFloat
		horizontalDelta = selfBounds.size.width * 1.0/3.0,
		verticalDelta = selfBounds.size.height * 1.0/3.0;
	
	return CGRectInset(selfBounds, horizontalDelta, verticalDelta);
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
	
	UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
}

- (void) draggableView:(L0DraggableView *)view didEndInertialSlideByFinishing:(BOOL)finished;
{
	[self didComeToRest:view];
	UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
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

- (void) didComeToRest:(L0DraggableView*) v;
{	
	// for now we just bounce back if needed.
	if (!CGRectContainsPoint(self.bounds, v.center)) {
		[delegate slidesView:self subviewDidMove:v inBounceBackAreaInDirection:[self directionForCurrentPositionOfView:v]];
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
	[self performSelector:@selector(postAccessibilityNotificationForAddition) withObject:nil afterDelay:0.7];
}

- (void) postAccessibilityNotificationForAddition;
{
	UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
}

- (void) bounceBackAll;
{
	for (L0DraggableView* v in self.subviews) {
		if ([v isKindOfClass:[L0DraggableView class]] && [self directionForCurrentPositionOfView:v] != kMvrDirectionNone)
			[self bounceBack:v];
	}
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
	view.transform = MvrConcatenateRandomRotationToTransform(view.transform);
	[self addSubview:view];
}

- (MvrDirection) directionForCurrentPositionOfView:(L0DraggableView*) v;
{
	if (v.superview != self)
		return kMvrDirectionNone;
	
	CGPoint c = v.center;
	CGRect me = self.bounds;
	if (c.y < CGRectGetMinY(me))
		return kMvrDirectionNorth;
	else if (c.y > CGRectGetMaxY(me))
		return kMvrDirectionSouth;
	else if (c.x < CGRectGetMinX(me))
		return kMvrDirectionWest;
	else if (c.x > CGRectGetMaxX(me))
		return kMvrDirectionEast;
	else
		return kMvrDirectionNone;
}

- (void) removeDraggableSubviewByFadingAway:(L0DraggableView *)view;
{
	if (view.superview != self)
		return;
	
	CFRetain(view); // in case the iPhone ever goes GC in the future (please please please). balanced in removeAnimation:didEndByFinishing:context:.
	[UIView beginAnimations:nil context:(void*) view];
	[UIView setAnimationDuration:0.5];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(removeAnimation:didEndByFinishing:context:)];
	
	view.alpha = 0.0;
	
	[UIView commitAnimations];
}

- (void) removeAnimation:(NSString*) ani didEndByFinishing:(BOOL) finished context:(void*) context;
{
	L0DraggableView* view = (id) context; 
	[view removeFromSuperview];
	CFRelease(view); // balances the one in removeDraggableSubviewByFadingAway:.
}

- (void) draggableView:(L0DraggableView *)view didTapMultipleTimesWithTouch:(UITouch *)t;
{
	if ([t tapCount] == 2)
		[delegate slidesView:self didDoubleTapSubview:view];
}

- (void) draggableView:(L0DraggableView*) view didTouch:(UITouch*) t;
{
	[delegate slidesView:self didStartHolding:view];
}

- (BOOL) draggableViewShouldBeginDraggingAfterPressAndHold:(L0DraggableView *)view;
{
	return [delegate slidesView:self shouldAllowDraggingAfterHold:view];
}

- (void) draggableViewDidBeginDragging:(L0DraggableView *)view;
{
	[delegate slidesView:self didCancelHolding:view];
	UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
}

- (void) draggableViewDidPress:(L0DraggableView*) view;
{
	[delegate slidesView:self didCancelHolding:view];	
}

@end
