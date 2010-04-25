//
//  MvrInertia.m
//  Mover-iPad
//
//  Created by ∞ on 30/03/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MvrInertia.h"

#ifndef L0Log
#define L0Log NSLog
#endif

#define MvrILog(x, ...) L0Log(x, ## __VA_ARGS__)

static inline BOOL MvrAbsoluteWithinRange(CGPoint vector, CGFloat rangeAbs) {
	return
	ABS(vector.x) < rangeAbs && ABS(vector.y) < rangeAbs;
}

static inline NSString* MvrNSStringFromAnimationStep(MvrAnimationStep s) {
	if (s.shouldAnimate)
		return [NSString stringWithFormat:@"<Animation step: animation %f s long to %@", (double) s.duration, NSStringFromCGPoint(s.destination)];
	else
		return @"<Animation step: none>";
}

@interface MvrInertia ()

- (NSTimeInterval) timestamp;
- (MvrAnimationStep) endMotionWithLastMovementFromPoint:(CGPoint) checkpoint toPoint:(CGPoint) here;

@end

static MvrAnimationStep MvrMakeAnimationStep(BOOL shouldAnimate, CGPoint destination, NSTimeInterval duration) {
	MvrAnimationStep s;
	s.shouldAnimate = shouldAnimate;
	s.destination = destination;
	s.duration = duration;
	return s;
}



@implementation MvrInertia

- (id) init
{
	self = [super init];
	if (self != nil) {
		self.slowdownFactor = 0.5;
		self.minimumSpeedToTriggerSlide = 7.0;
	}
	return self;
}

- (void) dealloc
{
	[speedTrap invalidate];
	[speedTrap release];
	[motionStartTime release];
	[attractors release];
	[super dealloc];
}


@synthesize minimumSpeedToTriggerSlide, slowdownFactor;

- (void) addMotionToPoint:(CGPoint) p;
{
	if (!speedTrap) {
		MvrILog(@"Setting up the speed trap.");
		speedTrap = [[NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(recordSpeed:) userInfo:nil repeats:YES] retain];
		motionStartTime = [NSDate new];
		lastCheckpointLocation = p;
		lastCheckpointTime = 0.0;
	}
	
	MvrILog(@"Recorded motion to point: %@", NSStringFromCGPoint(p));
	lastMotion = p;
}

- (NSTimeInterval) timestamp;
{
	NSTimeInterval t = -[motionStartTime timeIntervalSinceNow];
	MvrILog(@"%f", t);
	return t;
}

- (void) recordSpeed:(NSTimer*) t;
{
	lastCheckpointLocation = lastMotion;
	lastCheckpointTime = [self timestamp];
	
	MvrILog(@"Checkpointed speed");
}

- (MvrAnimationStep) endMotionWithPoint:(CGPoint) here;
{
	return [self endMotionWithLastMovementFromPoint:lastCheckpointLocation toPoint:here];
}

- (MvrAnimationStep) endMotion;
{
	return [self endMotionWithLastMovementFromPoint:lastCheckpointLocation toPoint:lastMotion];
}

- (MvrAnimationStep) endMotionWithLastMovementFromPoint:(CGPoint) checkpoint toPoint:(CGPoint) here;
{
	MvrILog(@"Final point for movement is %@", NSStringFromCGPoint(here));
	
	NSTimeInterval movementTime = [self timestamp] - lastCheckpointTime;
	MvrILog(@"Last movement lasted: %f", movementTime);
	
	CGPoint movementVector;
	movementVector.x = here.x - lastCheckpointLocation.x;
	movementVector.y = here.y - lastCheckpointLocation.y;
	MvrILog(@"Movement delta vector is %@", NSStringFromCGPoint(movementVector));
	
	CGPoint speedPointsPer100MS;
	speedPointsPer100MS.x = (movementVector.x / movementTime) * 0.1;
	speedPointsPer100MS.y = (movementVector.y / movementTime) * 0.1;
	MvrILog(@"Speed vector is %@", NSStringFromCGPoint(speedPointsPer100MS));
	
	BOOL performInertialSlide = !MvrAbsoluteWithinRange(speedPointsPer100MS, self.minimumSpeedToTriggerSlide);
	MvrILog(@"Enough to slide? %d", performInertialSlide);
	
	MvrAnimationStep result;
	
	if (!performInertialSlide)
		result = MvrMakeAnimationStep(NO, CGPointZero, 0);
	else {
		CGFloat dampening = self.slowdownFactor;
		
		CGPoint delta = movementVector;
		int timeScale = 1;
		while (!MvrAbsoluteWithinRange(movementVector, 5.0)) {
			movementVector.x *= dampening;
			movementVector.y *= dampening;
			
			delta.x += movementVector.x;
			delta.y += movementVector.y;
			
			timeScale++;
		}
		
		here.x += delta.x;
		here.y += delta.y;
		
		NSTimeInterval duration = movementTime * timeScale;
		
		// Check for attraction points.
		
		CGFloat ar = self.attractionRange;
		if (ar > 0) {
			for (NSValue* v in self.attractors) {
				CGPoint a = [v CGPointValue];
				
				// If within the attraction range...
				CGFloat xDistance = ABS(a.x - here.x), yDistance = ABS(a.y - here.y);
				if (xDistance < ar && yDistance < ar) {
					
					// ATTRACT
					here = a;
					
					// TODO adjust speed.
//					duration = sqrt(pow(xDistance, 2) + pow(yDistance, 2)) / speedPointsPer100MS
					
					break;
					
				}
			}
		}
		
		result = MvrMakeAnimationStep(YES, here, duration);
	}
	
	[self clearAllMotions];
	
	MvrILog(@"Result: %@", MvrNSStringFromAnimationStep(result));
	return result;
}

- (void) clearAllMotions;
{
	[speedTrap invalidate];
	[speedTrap release]; speedTrap = nil;
}

@synthesize attractors, attractionRange;

@end
