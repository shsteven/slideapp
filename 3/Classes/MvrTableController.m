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
	
	// TODO remove me
	[self.slidesStratum testByAddingEmptySlide];
}

@synthesize hostView, backdropStratum, slidesStratum;

- (void) dealloc;
{
	[hostView release];
	[backdropStratum release];
	[slidesStratum release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Adding items

- (void) addItem:(MvrItem*) i;
{
	MvrSlide* slide = [[MvrSlide alloc] initWithFrame:CGRectZero];
	[slide sizeToFit];
	
	NSString* title = i.title ?: @"";
	slide.titleLabel.text = title;
	slide.imageView.image = [[MvrItemUI UIForItem:i] representingImageWithSize:slide.imageView.bounds.size forItem:i];
	
	[itemsToViews setObject:slide forKey:i];
	[self.slidesStratum addSubview:slide];
	[slide release];
}

@end
