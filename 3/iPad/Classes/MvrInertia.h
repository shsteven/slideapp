//
//  MvrInertia.h
//  Mover3-iPad
//
//  Created by ∞ on 30/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

extern BOOL MvrInertiaShouldBeginAnimationAtStartPointAndVelocity(CGPoint startPoint, CGPoint velocity, CGFloat dampening, CGFloat attractionRange, NSArray* attractors, CGPoint* endPoint, NSTimeInterval* duration);
