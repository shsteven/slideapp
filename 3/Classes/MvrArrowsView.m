//
//  MvrArrowsView.m
//  Mover3
//
//  Created by ∞ on 22/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrArrowsView.h"

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

@end


@implementation MvrArrowsView


- (id) initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.opaque = NO;
		self.backgroundColor = [UIColor clearColor];
		self.autoresizesSubviews = NO;
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

- (void) setNorthViewLabel:(NSString*) label;
{
	[self setLabel:label forViewOfKey:@"northView"];
}

- (void) setLabel:(NSString*) label forViewOfKey:(NSString*) key;
{
	MvrArrowView* view = [self valueForKey:key];
	
	if (!label) {
		[view removeFromSuperview]; // TODO
		[self setValue:nil forKey:key];
	} else if (!view) {
		view = [[[MvrArrowView alloc] initWithFrame:CGRectZero] autorelease];
		[self setValue:view forKey:key];
		
		[self layoutSubviews];
		
		view.nameLabel.text = label;

		[self addSubview:view];
	} else
		view.nameLabel.text = label;
}

- (void) setWestViewLabel:(NSString*) label;
{
	[self setLabel:label forViewOfKey:@"eastView"];
}

- (void) setEastViewLabel:(NSString*) label;
{
	[self setLabel:label forViewOfKey:@"westView"];	
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

@end
