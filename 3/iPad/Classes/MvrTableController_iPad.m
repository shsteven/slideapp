//
//  Mover3_iPadViewController.m
//  Mover3-iPad
//
//  Created by ∞ on 14/04/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "MvrTableController_iPad.h"
#import <QuartzCore/QuartzCore.h>

#import "MvrInertia.h"

#define kMvrMaximumAngleRange (30)
static CGAffineTransform MvrConcatenateRandomRotationToTransform(CGAffineTransform transform)
{
	srandomdev();
	CGFloat angle = ((random() % kMvrMaximumAngleRange) - kMvrMaximumAngleRange / 2.0) * M_PI/180.0;
	return CGAffineTransformRotate(transform, angle);
}

enum {
	kMvrNorthEdge,
	kMvrSouthEdge,
	kMvrWestEdge,
	kMvrEastEdge,
};

// This function computes start and end points for a sliding entrance for a draggable view.
// - view is the aforementioned view. It must already be correctly transformed and all.
// - edge is the edge the view should be coming in (n, s, w, e).
// - coord is a coordinate along that edge the view will pass near when entering. N and S edge take X coordinates (left-to-right), W and E take Y coordinates (top-to-bottom).
// on return, *start is the starting center for the view, while *end is the ending position.
// start and end CANNOT be NULL.
@interface MvrTableController_iPad ()

- (void) getStartingPoint:(CGPoint*) start endingPoint:(CGPoint*) end toAnimateSlidingEntranceOfView:(MvrDraggableView*) view alongEdge:(NSInteger) edge atCoordinate:(CGFloat) coord;

@end


@implementation MvrTableController_iPad

- (ILRotationStyle) rotationStyle;
{
	return kILRotateAny;
}


- (void) getStartingPoint:(CGPoint*) start endingPoint:(CGPoint*) end toAnimateSlidingEntranceOfView:(MvrDraggableView*) view alongEdge:(NSInteger) edge atCoordinate:(CGFloat) coord;
{
	CGRect bounds = view.bounds, selfBounds = draggableViewsLayer.bounds;
	// excess approximation
	CGFloat safeDistanceForHidingView = MAX(bounds.size.width, bounds.size.height) * 1.41;
	
	switch (edge) {
		case kMvrNorthEdge: {
			*start = CGPointMake(coord, -safeDistanceForHidingView);
			*end = CGPointMake(coord, selfBounds.size.height * 0.2);
		}
			break;

		case kMvrSouthEdge: {
			*start = CGPointMake(coord, selfBounds.size.height + safeDistanceForHidingView);
			*end = CGPointMake(coord, selfBounds.size.height * 0.8);
		}
			break;
			
#warning TODO not correct below this point
			
		case kMvrEastEdge: {
			*start = CGPointMake(0, 0);
			*end = CGPointMake(CGRectGetMidX(selfBounds), CGRectGetMidY(selfBounds));
		}
			break;
		case kMvrWestEdge: {
			*start = CGPointMake(0, 0);
			*end = CGPointMake(CGRectGetMidX(selfBounds), CGRectGetMidY(selfBounds));
		}
			break;
		default:
			break;
	}
}

- (void) awakeFromNib;
{
	itemControllers = [NSMutableSet new];
}

- (void) addItem:(MvrItem*) item fromSource:(id) source ofType:(MvrItemSourceType) type;
{
	MvrItemController* ic = [MvrItemController itemControllerWithItem:item];
	if (!ic)
		return;
	
	ic.draggableView.hidden = YES;
	
	[self addItemController:ic];
	
#warning TODO real channel management.
	
	switch (type) {
		case kMvrItemSourceChannel: // TODO
		case kMvrItemSourceSelf: {
			NSInteger edge = (type == kMvrItemSourceSelf)? kMvrSouthEdge : kMvrNorthEdge;
			
			CGPoint start, end;
			[self getStartingPoint:&start endingPoint:&end toAnimateSlidingEntranceOfView:ic.draggableView alongEdge:edge atCoordinate:CGRectGetMidX(draggableViewsLayer.bounds)];
			
			ic.draggableView.center = start;
			ic.draggableView.hidden = NO;
			
			[UIView beginAnimations:nil context:NULL];
			{
				[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
				[UIView setAnimationDuration:1.25];
				ic.draggableView.center = end;
			}
			[UIView commitAnimations];
			
		}
			break;
			
		case kMvrItemSourceUnknown: {
			
			ic.draggableView.alpha = 0.0;
			ic.draggableView.center = CGPointMake(CGRectGetMidX(draggableViewsLayer.bounds), CGRectGetMidY(draggableViewsLayer.bounds));
			ic.draggableView.hidden = NO;
			
			CGAffineTransform finished = MvrConcatenateRandomRotationToTransform(CGAffineTransformIdentity);
			ic.draggableView.transform = CGAffineTransformScale(finished, 1.1, 1.1);
			
			[UIView beginAnimations:nil context:NULL];
			{
				[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
				[UIView setAnimationDelay:0.5];
				[UIView setAnimationDuration:0.5];
				ic.draggableView.alpha = 1.0;
				ic.draggableView.transform = finished;
			}
			[UIView commitAnimations];
		}
			break;
	}
}

- (NSSet*) itemControllers;
{	
	return [[itemControllers copy] autorelease];
}

- (void) addItemController:(MvrItemController*) ic;
{
	[itemControllers addObject:ic];
	ic.itemsTable = self;
	[self addDraggableView:ic.draggableView];
}

- (void) removeItemController:(MvrItemController*) ic;
{
	if (ic.draggableView.superview == draggableViewsLayer)
		[ic.draggableView removeFromSuperview];
	
	if (ic.itemsTable == self)
		ic.itemsTable = nil;
	
	[itemControllers removeObject:ic];
}



- (void) addDraggableView:(MvrDraggableView*) v;
{
	v.autoresizingMask = UIViewAutoresizingNone;
	[draggableViewsLayer addSubview:v];
}


- (void) bounceBackViewIfNeeded:(MvrDraggableView*) dv;
{
	if (dv.superview != draggableViewsLayer)
		return;
	
	// defect approxim.
	const CGFloat distance = MIN(200, 0.3 * MAX(dv.bounds.size.width, dv.bounds.size.height));
	
	CGRect bounds = draggableViewsLayer.bounds;
	CGPoint center = dv.center;
	
	if (center.x < 0)
		center.x = distance;
	else if (center.x > bounds.size.width)
		center.x = bounds.size.width - distance;
	
	if (center.y < 0)
		center.y = distance;
	else if (center.y > bounds.size.height)
		center.y = bounds.size.height - distance;
	
	[UIView beginAnimations:nil context:NULL];
	{
		[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
		[UIView setAnimationDuration:0.5];
		[UIView setAnimationDelay:0.1];
	
		dv.center = center;
	}
	[UIView commitAnimations];
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation;
{
	for (MvrItemController* ic in itemControllers)
		[self bounceBackViewIfNeeded:ic.draggableView];
}

- (void) itemControllerViewDidFinishMoving:(MvrItemController *)ic velocity:(CGPoint) v;
{
	CGPoint end;
	NSTimeInterval time;
	
	if (MvrInertiaShouldBeginAnimationAtStartPointAndVelocity(ic.draggableView.center, v, 0.1, 0, nil, &end, &time)) {
		
		[ic retain]; // released in the did stop selector.
		[UIView beginAnimations:nil context:(void*) ic];
		{
			[UIView setAnimationDuration:time];
			[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
			
			[UIView setAnimationDelegate:self];
			[UIView setAnimationDidStopSelector:@selector(inertiaAnimation:didEnd:context:)];
			
			ic.draggableView.center = end;
		}
		[UIView commitAnimations];
		
		// TODO begin transfer if needed.
		
	} else
		[self bounceBackViewIfNeeded:ic.draggableView];
}

- (void) inertiaAnimation:(NSString*) ani didEnd:(BOOL) finished context:(MvrItemController*) retainedItemController;
{
	[self bounceBackViewIfNeeded:retainedItemController.draggableView];
	[retainedItemController release]; // balances the retain above.
}

@end
