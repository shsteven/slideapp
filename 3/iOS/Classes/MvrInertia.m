//
//  MvrInertia.m
//  Mover3-iPad
//
//  Created by ∞ on 30/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MvrInertia.h"
static inline BOOL MvrAbsoluteWithinRange(CGPoint vector, CGFloat rangeAbs) {
	return
	ABS(vector.x) < rangeAbs && ABS(vector.y) < rangeAbs;
}

#define kMvrInertiaMinimumMovementPerStep (5.0)
#define kMvrInertiaMinimumSpeedToTriggerSlide (50) // points per second

BOOL MvrInertiaShouldBeginAnimationAtStartPointAndVelocity(CGPoint startPoint, CGPoint velocity, CGFloat dampening, CGFloat attractionRange, NSArray* attractors, CGPoint* endPoint, NSTimeInterval* duration) {
	BOOL performInertialSlide = !MvrAbsoluteWithinRange(velocity, kMvrInertiaMinimumSpeedToTriggerSlide);
	L0CLog(@"Enough to slide? %d", performInertialSlide);
	
	if (!performInertialSlide)
		return NO;
	else {
		CGPoint delta = CGPointZero;
		CGPoint movementVector = velocity;
		
		const CGFloat timeDelta = 0.1;
		CGFloat time = 0.0;
		
		while (!MvrAbsoluteWithinRange(movementVector, kMvrInertiaMinimumMovementPerStep)) {
			delta.x += movementVector.x * timeDelta;
			delta.y += movementVector.y * timeDelta;
			
			time += timeDelta;
			
			movementVector.x *= dampening;
			movementVector.y *= dampening;
		}
		
		CGPoint endCandidate;
		
		endCandidate.x = startPoint.x + delta.x;
		endCandidate.y = startPoint.y + delta.y;
		
		// Check for attraction points.		
		CGFloat ar = attractionRange;
		if (ar > 0) {
			for (NSValue* v in attractors) {
				CGPoint a = [v CGPointValue];
				
				// If within the attraction range...
				CGFloat xDistance = ABS(a.x - endCandidate.x), yDistance = ABS(a.y - endCandidate.y);
				if (xDistance < ar && yDistance < ar) {
					
					// ATTRACT
					endCandidate = a;
					// TODO adjust duration
					break;
					
				}
			}
		}
		
		*endPoint = endCandidate;
		*duration = time;
		
		return YES;
	}
}
