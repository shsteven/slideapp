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
	
	MvrItemStorage* storage = [MvrItemStorage itemStorageWithData:[@"Ciao, mondo!" dataUsingEncoding:NSUTF8StringEncoding]];
	MvrItem* i = [MvrItem itemWithStorage:storage type:(id) kUTTypeUTF8PlainText metadata:[NSDictionary dictionaryWithObject:@"Ciao" forKey:kMvrItemTitleMetadataKey]];
	
	[self addItem:i];
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
	[self.slidesStratum addDraggableSubview:slide];
	[slide release];
}

@end
