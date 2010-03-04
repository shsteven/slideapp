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

@interface L0LineOfViewsView ()

- (void) layoutSubviews;

@end



@implementation L0LineOfViewsView

- (id) initWithFrame:(NSRect) frame;
{
    self = [super initWithFrame:frame];
    if (self) {
        contentViewControllers = [NSMutableArray new];
		content = [NSMutableArray new];
		[self layoutSubviews];
    }
    return self;
}

- (void) setFrame:(NSRect) frame;
{
	[super setFrame:frame];
	[self layoutSubviews];
	[self setNeedsDisplay:YES];
}

- (NSArray *) contentViewControllers;
{
	return [contentViewControllers copy];
}

- (void) layoutSubviews;
{
	if ([self wantsLayer])
		[NSAnimationContext beginGrouping];
	
	if ([contentViewControllers count] > 0) {
		[emptyContentView removeFromSuperview];
		
		NSMutableSet* okViews = [NSMutableSet set];
		
		CGFloat x = 0, selfHeight = [self frame].size.height;
		for (NSViewController* vc in contentViewControllers) {
			NSView* v = [vc view];
			
			CGFloat y = selfHeight - [v frame].size.height;
			
			id toUse = [self wantsLayer]? [v animator] : v;
			[toUse setFrameOrigin:NSMakePoint(x, y)];
			
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
	} else {
		for (NSView* v in [[self subviews] copy])
			[v removeFromSuperview];
		
		NSRect r = [self frame];
		r.size = self.contentSize;
		[super setFrame:r];
		
		if (emptyContentView) {
			[emptyContentView setFrame:[self bounds]];
			[self addSubview:emptyContentView];
		}
	}
	
	if ([self wantsLayer])
		[NSAnimationContext endGrouping];
}

// KVO support

- (NSMutableArray*) mutableContent;
{
	return [self mutableArrayValueForKey:@"mutableContent"];
}

- (NSViewController*) viewControllerForContentObject:(id) o;
{
	L0AbstractMethod(); return nil;
}

@synthesize content;

- (void) setContent:(NSArray *) c;
{
	content = [c copy];
	contentViewControllers = [NSMutableArray array];
	for (id o in c) {
		NSViewController* vc = [self viewControllerForContentObject:o];
		[vc setRepresentedObject:o];
		[contentViewControllers addObject:vc];
	}
	
	[self layoutSubviews];
}

@synthesize emptyContentView;

- (NSSize) contentSize;
{
	NSScrollView* sv = [self enclosingScrollView];
	if (sv)
		return [sv contentSize];
	else
		return [self frame].size;
}

@end


@implementation MvrDevicesLineView

- (id) viewControllerForContentObject:(id) o;
{
	return [[[MvrDeviceItem alloc] initWithChannel:(id <MvrChannel>) o] autorelease];
}

@end

