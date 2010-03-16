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

- (void) awakeFromNib;
{
	[self layoutSubviews];
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

#define L0Animatable(x) ([self wantsLayer]? [x animator] : x)

- (void) layoutSubviews;
{
	if ([self wantsLayer])
		[NSAnimationContext beginGrouping];
	
	[emptyContentView setWantsLayer:[self wantsLayer]];
	
	if ([contentViewControllers count] > 0) {
		[L0Animatable(emptyContentView) removeFromSuperview];
		
		NSMutableSet* okViews = [NSMutableSet set];
		
		CGFloat x = 0, selfHeight = [self frame].size.height;
		for (NSViewController* vc in contentViewControllers) {
			NSView* v = [vc view];
			[[vc view] setWantsLayer:[self wantsLayer]];
			
			CGFloat y = selfHeight - [v frame].size.height;
			
			[L0Animatable(v) setFrameOrigin:NSMakePoint(x, y)];
			
			if ([v superview] != self) {
				if ([v superview]) [v removeFromSuperview];
				[self addSubview:v];
			}
			
			[okViews addObject:v];
			x += [v frame].size.width;
		}
		
		for (NSView* v in [[self subviews] copy]) {
			if (![okViews containsObject:v])
				[L0Animatable(v) removeFromSuperview];
		}
		
		NSRect r = [self frame];
		r.size.width = MAX(x, self.contentSize.width);
		[super setFrame:r];
	} else {
		for (NSView* v in [[self subviews] copy])
			[L0Animatable(v) removeFromSuperview];
		
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
		
		if ([vc conformsToProtocol:@protocol(L0LineOfViewsItem)])
			[(id <L0LineOfViewsItem>)vc setLineOfViewsView:self];
		
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

- (void) setSelectedViewController:(NSViewController*) vc;
{
	if (![contentViewControllers containsObject:vc])
		return;
	
	if ([selectedController conformsToProtocol:@protocol(L0LineOfViewsItem)])
		[(id <L0LineOfViewsItem>)selectedController setSelected:NO];
	
	selectedController = vc;
	
	if ([selectedController conformsToProtocol:@protocol(L0LineOfViewsItem)])
		[(id <L0LineOfViewsItem>)selectedController setSelected:YES];
}

- (void) setSelectedObject:(id) o;
{
	NSInteger i = [content indexOfObject:o];
	if (i != NSNotFound)
		[self setSelectedViewController:[contentViewControllers objectAtIndex:i]];
}

@end


@implementation MvrDevicesLineView

- (id) viewControllerForContentObject:(id) o;
{
	return [[[MvrDeviceItem alloc] initWithChannel:(id <MvrChannel>) o] autorelease];
}

@end

