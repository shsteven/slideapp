//
//  MvrTableController.m
//  Mover3
//
//  Created by ∞ on 18/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrTableController.h"

#import "MvrSlidesView.h"
#import "MvrSlide.h"

#import "MvrItemUI.h"
#import "Network+Storage/MvrItem.h"
#import "Network+Storage/MvrItemStorage.h"
#import "Network+Storage/MvrUTISupport.h"

#import "MvrAppDelegate.h"

static CGPoint MvrCenterOf(CGRect r) {
	return CGPointMake(r.size.width / 2, r.size.height / 2);
}

@implementation MvrTableController

- (void) setUp;
{
	CGRect r = [self.hostView convertRect:[UIScreen mainScreen].bounds fromView:nil];
	self.backdropStratum.frame = r;
	[self.hostView addSubview:self.backdropStratum];
	
	self.slidesStratum = [[MvrSlidesView alloc] initWithFrame:self.hostView.bounds delegate:self];
	[self.hostView addSubview:self.slidesStratum];
	
	itemsToViews = [L0Map new];
	viewsToItems = [L0Map new];
	
	NSMutableArray* a = [NSMutableArray arrayWithArray:self.toolbar.items];
	[a addObject:self.editButtonItem];
	self.toolbar.items = a;
	
	// TODO remove me!
	MvrItemStorage* storage = [MvrItemStorage itemStorageWithData:[@"Ciao, mondo!" dataUsingEncoding:NSUTF8StringEncoding]];
	MvrItem* i = [MvrItem itemWithStorage:storage type:(id) kUTTypeUTF8PlainText metadata:[NSDictionary dictionaryWithObject:@"Ciao" forKey:kMvrItemTitleMetadataKey]];
	
	[self addItem:i animated:NO];
}

@synthesize hostView, toolbar, backdropStratum, slidesStratum;

- (void) viewDidUnload;
{
	self.toolbar = nil;
	self.hostView = nil;
}

- (void) dealloc;
{
	[self viewDidUnload];
	[backdropStratum release];
	[slidesStratum release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Adding items

- (void) addItem:(MvrItem*) i animated:(BOOL) ani;
{
	MvrSlide* slide = [[MvrSlide alloc] initWithFrame:CGRectZero];
	[slide sizeToFit];
	[slide setActionButtonTarget:self selector:@selector(displayActionMenuForItemOfView:)];
	
	NSString* title = i.title ?: @"";
	slide.titleLabel.text = title;
	slide.imageView.image = [[MvrItemUI UIForItem:i] representingImageWithSize:slide.imageView.bounds.size forItem:i];
	
	[itemsToViews setObject:slide forKey:i];
	[viewsToItems setObject:i forKey:slide];
	
	if (ani)
		[self.slidesStratum addDraggableSubviewFromSouth:slide];
	else
		[self.slidesStratum addDraggableSubviewWithoutAnimation:slide];
	
	[slide release];
}

#pragma mark -
#pragma mark Editing

- (void) setEditing:(BOOL) editing animated:(BOOL) animated;
{
	[self.slidesStratum setEditing:editing animated:animated];
	[super setEditing:editing animated:animated];
}

- (void) displayActionMenuForItemOfView:(id) view;
{
	// TODO
	[[view retain] autorelease];
	MvrItem* item = [viewsToItems objectForKey:view];
	
	if (item) {
		[MvrApp().storageCentral.mutableStoredItems removeObject:item];
		[itemsToViews removeObjectForKey:item];
	}
	
	[viewsToItems removeObjectForKey:view];
	[view removeFromSuperview];
}

@end
