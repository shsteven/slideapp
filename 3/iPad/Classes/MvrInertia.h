//
//  MvrInertia.h
//  Mover-iPad
//
//  Created by ∞ on 30/03/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MvrAnimationStep;

typedef struct {
	BOOL shouldAnimate;
	CGPoint destination;
	NSTimeInterval duration;
} MvrAnimationStep;


@interface MvrInertia : NSObject {
	NSDate* motionStartTime;
	
	NSTimer* speedTrap;
	CGPoint lastMotion;
	
	CGPoint lastCheckpointLocation;
	NSTimeInterval lastCheckpointTime;
	
	CGFloat minimumSpeedToTriggerSlide, slowdownFactor;
	
	CGFloat attractionRange; NSArray* attractors;
}

// Informs that a motion just happened at point p. You call this method once with the starting point to begin, then keep calling it as motions are detected (except for the last).
- (void) addMotionToPoint:(CGPoint) p;
// Ends motions with the given last known point. This method returns an animation step producing an inertia (slide) animation if there was enough speed, or one not advising animation otherwise.
- (MvrAnimationStep) endMotionWithPoint:(CGPoint) p;

// Cancels the current motion and resets this object, so that the next call to -addMotionToPoint: will be the first of a new series. Not needed after an -endMotionWithPoint: call.
- (void) clearAllMotions;

// measured in point units per 100 ms.
// Defaults to 7 units per 100 ms.
@property CGFloat minimumSpeedToTriggerSlide;

// this is a slowdown factor -- how much speed the slide loses for each unit of "travel"
// a factor of 0.5 means that the inertial slide will cause the point to travel X, then 0.5*X,
// then 0.5*0.5*X and so on until it converges to a value.
// Defaults to 0.5. MUST be a reasonable value (in range 0.0-1.0, but not too near 1.0 nor too near 0.0).
@property CGFloat slowdownFactor;

// If the final point of a slide comes at least attractionRange units away from one of the points in attractors, the attractor point will be used instead as the destination.
// attractors is a NSArray of NSValue objects, each wrapping a CGPoint.
@property CGFloat attractionRange; // If 0, attraction is disabled. Defaults to 0.
@property(copy) NSArray* attractors;

@end
