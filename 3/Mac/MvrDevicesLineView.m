//
//  MvrDevicesLineView.m
//  MoverWaypoint
//
//  Created by ∞ on 03/03/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MvrDevicesLineView.h"

#import "MvrDevice.h"
#import "Network+Storage/MvrChannel.h"

@interface MvrDevicesLineView ()

- (void) layoutSubviews;

@end



@implementation MvrDevicesLineView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        contentViewControllers = [NSMutableArray new];
		content = [NSMutableArray new];
    }
    return self;
}

- (void) setFrame:(NSRect) frame;
{
	[super setFrame:frame];
	[self layoutSubviews];
}

- (NSArray *) contentViewControllers;
{
	return [contentViewControllers copy];
}

- (void) layoutSubviews;
{
	NSMutableSet* okViews = [NSMutableSet set];
	
	CGFloat x = 0, selfHeight = [self frame].size.height;
	for (NSViewController* vc in contentViewControllers) {
		NSView* v = [vc view];
		
		CGFloat y = selfHeight - [v frame].size.height;
		[v setFrameOrigin:NSMakePoint(x, y)];
		
		if ([v superview] != self) {
			if ([v superview]) [v removeFromSuperview];
			[self addSubview:v];
		}
		
		[okViews addObject:v];
		x += [v frame].size.width;
	}
	
	for (NSView* v in [[self subviews] copy]) {
		if (![okViews containsObject:v])
			[v removeFromSuperview];
	}
	
	NSRect r = [self frame];
	r.size.width = x;
	[super setFrame:r];
}

// KVO support

- (NSMutableArray*) content;
{
	return [self mutableArrayValueForKey:@"mutableContent"];
}

- (NSViewController*) viewControllerForContentObject:(id) o;
{
	return [[[MvrDeviceItem alloc] initWithChannel:(id <MvrChannel>) o] autorelease];
}

- (NSMutableArray*) mutableContent;
{
	return content;
}

- (void) insertObject:(id) o inMutableContentAtIndex:(NSInteger) idx;
{
	[content insertObject:o atIndex:idx];
	
	NSViewController* vc = [self viewControllerForContentObject:o];
	[vc setRepresentedObject:o];
	[contentViewControllers insertObject:vc atIndex:idx];
	
	[self layoutSubviews];
}

- (void) removeObjectFromMutableContentAtIndex:(NSInteger) idx;
{
	[content removeObjectAtIndex:idx];
	[contentViewControllers removeObjectAtIndex:idx];
	
	[self layoutSubviews];
}

@end
