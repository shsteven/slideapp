//
//  MvrArrowsView.m
//  Mover3
//
//  Created by ∞ on 22/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrArrowsView.h"
#import <QuartzCore/QuartzCore.h>

#import "MvrAccessibility.h"

typedef enum {
	kMvrSlideDown,
	kMvrSlideRight,
	kMvrSlideLeft,
} MvrSlideDirection;

@interface MvrArrowsView ()

- (void) setLabel:(NSString*) label forViewOfKey:(NSString*) key;

@property(retain) MvrArrowView* northView;
@property(retain) MvrArrowView* eastView;
@property(retain) MvrArrowView* westView;

- (void) fadeAway:(UIView *)v;

@end


@implementation MvrArrowsView


- (id) initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.opaque = NO;
		self.backgroundColor = [UIColor clearColor];
		self.autoresizesSubviews = NO;
		self.contentMode = UIViewContentModeCenter;
    }
	
    return self;
}

@synthesize northView, eastView, westView;

- (void)dealloc {
	[northView release];
	[eastView release];
	[westView release];
    [super dealloc];
}

#pragma mark -
#pragma mark Adding and removing arrowed labels.

- (void) setLabel:(NSString*) label forViewOfKey:(NSString*) key;
{
	MvrArrowView* view = [self valueForKey:key];
	
	if (!label) {
		[self fadeAway:view];
		[self setValue:nil forKey:key];
	} else if (!view) {
		view = [[[MvrArrowView alloc] initWithFrame:CGRectZero] autorelease];
		[self setValue:view forKey:key];
		
		[self layoutSubviews];
		
		view.name = label;
		
		view.alpha = 0.0;
		[self addSubview:view];
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
		
		view.alpha = 1.0;
		
		[UIView commitAnimations];
	} else {
		CATransition* fade = [CATransition animation];
		fade.type = kCATransitionFade;
		[view.nameLabel.layer addAnimation:fade forKey:@"MvrFadeTransitionKey"];
		view.name = label;
	}
	
	MvrAccessibilityDidChangeLayout();
}

- (void) fadeAway:(UIView*) v;
{	
	CFRetain(v); // balanced in the did stop selector
	[UIView beginAnimations:nil context:(void*) v];
	
	[UIView setAnimationDuration:1.0];
	[UIView setAnimationDelay:0.3];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
	
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(fadeAway:didEndByFinishing:context:)];
	
	v.alpha = 0.0;
	
	[UIView commitAnimations];
}

- (void) fadeAway:(NSString*) fade didEndByFinishing:(BOOL) finished context:(void*) context;
{
	UIView* v = (id) context;
	[v removeFromSuperview];
	CFRelease(v); // balances the one in -fadeAway:
}

- (void) setNorthViewLabel:(NSString*) label;
{
	[self setLabel:label forViewOfKey:@"northView"];
}

- (void) setWestViewLabel:(NSString*) label;
{
	[self setLabel:label forViewOfKey:@"westView"];
}

- (void) setEastViewLabel:(NSString*) label;
{
	[self setLabel:label forViewOfKey:@"eastView"];	
}

#define kMvrArrowsViewMargin (10)
- (void) layoutSubviews;
{
	CGRect bounds;
	
	if (self.northView) {
		bounds = self.northView.bounds;
		bounds.size.width = self.bounds.size.width;
		self.northView.bounds = bounds;
		self.northView.center = CGPointMake(self.bounds.size.width / 2, bounds.size.height / 2.0 + kMvrArrowsViewMargin);
		
		if (!CGAffineTransformEqualToTransform(self.northView.transform, CGAffineTransformIdentity))
			self.northView.transform = CGAffineTransformIdentity;
	}
	
	if (self.eastView) {
		bounds = self.eastView.bounds;
		bounds.size.width = self.bounds.size.height;
		self.eastView.bounds = bounds;
		self.eastView.center = CGPointMake(self.bounds.size.width - (bounds.size.height / 2.0) - kMvrArrowsViewMargin, (self.bounds.size.height / 2));
		
		if (!CGAffineTransformEqualToTransform(self.eastView.transform, [MvrArrowView clockwiseHalfTurn]))
			self.eastView.transform = [MvrArrowView clockwiseHalfTurn];
	}
	
	if (self.westView) {
		bounds = self.westView.bounds;
		bounds.size.width = self.bounds.size.height;
		self.westView.bounds = bounds;
		self.westView.center = CGPointMake((bounds.size.height / 2.0) + kMvrArrowsViewMargin, (self.bounds.size.height / 2));
		
		if (!CGAffineTransformEqualToTransform(self.westView.transform, [MvrArrowView counterclockwiseHalfTurn]))
			self.westView.transform = [MvrArrowView counterclockwiseHalfTurn];
	}
}

- (MvrArrowView*) viewAtDirection:(MvrDirection) d;
{
	if (d == kMvrDirectionNorth)
		return self.northView;
	else if (d == kMvrDirectionEast)
		return self.eastView;
	else if (d == kMvrDirectionWest)
		return self.westView;
	else
		return nil;
}

- (void) setFrame:(CGRect) r;
{
	[super setFrame:r];
	[self layoutSubviews];
}

@end
