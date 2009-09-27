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

@interface MvrTableController ()

- (void) receiveItem:(MvrItem*) item withSlide:(MvrSlide*) slide;

@end



@implementation MvrTableController

- (void) setUp;
{
	NSAssert(self.currentMode, @"A mode must be made current before the table controller is set up.");
	
	CGRect r = [self.hostView convertRect:[UIScreen mainScreen].bounds fromView:nil];
	UIView* backdrop = self.currentMode.backdropStratum;
	backdrop.frame = r;
	backdrop.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
	[self.hostView addSubview:backdrop];
	
	r = [self.hostView convertRect:[UIScreen mainScreen].applicationFrame fromView:nil];
	r.size.height -= self.toolbar.bounds.size.height;
	UIView* arrows = self.currentMode.arrowsStratum;
	arrows.frame = r;
	arrows.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	[self.hostView insertSubview:arrows aboveSubview:backdrop];
	
	self.slidesStratum = [[[MvrSlidesView alloc] initWithFrame:self.hostView.bounds delegate:self] autorelease];
	[self.hostView addSubview:self.slidesStratum];
	
	itemsToViews = [L0Map new];
	viewsToItems = [L0Map new];
	transfersToViews = [L0Map new];
	
	NSMutableArray* a = [NSMutableArray arrayWithArray:self.toolbar.items];
	[a addObject:self.editButtonItem];
	self.toolbar.items = a;
	
	kvo = [[L0KVODispatcher alloc] initWithTarget:self];
	
	self.editButtonItem.enabled = NO;
	
	// TODO remove me!
	MvrItemStorage* storage = [MvrItemStorage itemStorageWithData:[@"Ciao, mondo!" dataUsingEncoding:NSUTF8StringEncoding]];
	MvrItem* i = [MvrItem itemWithStorage:storage type:(id) kUTTypeUTF8PlainText metadata:[NSDictionary dictionaryWithObject:@"Ciao" forKey:kMvrItemTitleMetadataKey]];
	
	[self addItem:i animated:NO];
}

- (void) setCurrentMode:(MvrUIMode *) m;
{
	if (m != currentMode) {
		currentMode.delegate = nil;
		
		[currentMode release];
		currentMode = [m retain];
		
		m.delegate = self;
	}
}

@synthesize hostView, toolbar, currentMode, slidesStratum;

- (void) viewDidUnload;
{
	self.toolbar = nil;
	self.hostView = nil;
}

- (void) dealloc;
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	
	[self viewDidUnload];
	[currentMode release];
	[slidesStratum release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Adding and removing slides from the table

- (void) setItem:(MvrItem*) i forSlide:(MvrSlide*) slide;
{
	[slide setActionButtonTarget:self selector:@selector(displayActionMenuForItemOfView:)];
	
	NSString* title = i.title ?: @"";
	slide.titleLabel.text = title;
	slide.imageView.image = [[MvrItemUI UIForItem:i] representingImageWithSize:slide.imageView.bounds.size forItem:i];
	
	[itemsToViews setObject:slide forKey:i];
	[viewsToItems setObject:i forKey:slide];
	
	self.editButtonItem.enabled = YES;
}

#pragma mark -
#pragma mark Adding items

- (void) addItem:(MvrItem*) i animated:(BOOL) ani;
{
	MvrSlide* slide = [[MvrSlide alloc] initWithFrame:CGRectZero];
	[slide sizeToFit];
	
	[self setItem:i forSlide:slide];
	
	if (ani)
		[self.slidesStratum addDraggableSubview:slide enteringFromDirection:kMvrDirectionSouth];
	else
		[self.slidesStratum addDraggableSubviewWithoutAnimation:slide];
	
	[slide release];
	self.editButtonItem.enabled = YES;
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
	MvrItem* item = [viewsToItems objectForKey:view];
	
	if (item)
		[MvrApp() displayActionMenuForItem:item withRemove:YES withMainAction:YES];
}

- (void) slidesView:(MvrSlidesView *)v didDoubleTapSubview:(L0DraggableView *)view;
{
	MvrItem* item = [viewsToItems objectForKey:view];
	[[[MvrItemUI UIForItem:item] mainActionForItem:item] performActionWithItem:item];
}

- (void) slidesView:(MvrSlidesView*) v didStartHolding:(L0DraggableView*) view;
{
	if (self.editing) return;
	
	MvrItem* item = [viewsToItems objectForKey:view];
	if (!item)
		return;
	
	[self performSelector:@selector(beginHighlightingView:) withObject:view afterDelay:0.2];
}

- (void) beginHighlightingView:(L0DraggableView*) view;
{
	if ([view isKindOfClass:[MvrSlide class]])
		[((MvrSlide*)view) setHighlighted:YES animated:YES animationDuration:view.pressAndHoldDelay - 0.2];
	
	[self performSelector:@selector(displayActionMenuForItemOfView:) withObject:view afterDelay:view.pressAndHoldDelay - 0.2];
}

- (void) slidesView:(MvrSlidesView*) v didCancelHolding:(L0DraggableView*) view;
{
	if ([view isKindOfClass:[MvrSlide class]])
		[((MvrSlide*)view) setHighlighted:NO animated:YES animationDuration:0.5];

	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(beginHighlightingView:) object:view];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(displayActionMenuForItemOfView:) object:view];
}

- (BOOL) slidesView:(MvrSlidesView*) v shouldAllowDraggingAfterHold:(L0DraggableView*) view;
{
	MvrItem* item = [viewsToItems objectForKey:view];
	return item == nil;
}

- (void) didEndDisplayingActionMenuForItem:(MvrItem*) i;
{
	L0DraggableView* view = [itemsToViews objectForKey:i];
	if ([view isKindOfClass:[MvrSlide class]])
		[((MvrSlide*)view) setHighlighted:NO animated:YES animationDuration:0.5];
}

- (void) removeItem:(MvrItem*) item;
{
	// avoid premature dealloc.
	L0DraggableView* view = [[[itemsToViews objectForKey:item] retain] autorelease];
	
	[MvrApp().storageCentral.mutableStoredItems removeObject:item];
	[itemsToViews removeObjectForKey:item];
	[viewsToItems removeObjectForKey:view];
	[self.slidesStratum removeDraggableSubviewByFadingAway:view];
	
	if ([itemsToViews count] == 0) {
		[self setEditing:NO animated:YES];
		self.editButtonItem.enabled = NO;
	}
}

#pragma mark -
#pragma mark Sending items

- (void) slidesView:(MvrSlidesView*) v subviewDidMove:(L0DraggableView*) view inBounceBackAreaInDirection:(MvrDirection) d;
{
	MvrItem* item = [viewsToItems objectForKey:view];
	
	// TODO fadeout della slide
	if (item && d != kMvrDirectionSouth && d != kMvrDirectionNone)
		[self.currentMode sendItem:item toDestinationAtDirection:d];
	
	[v performSelector:@selector(bounceBack:) withObject:view afterDelay:1.5];
}

- (void) UIMode:(MvrUIMode*) mode didFinishSendingItem:(MvrItem*) i;
{
	L0DraggableView* view = [itemsToViews objectForKey:i];
	if (view)
		[self.slidesStratum bounceBack:view];
}

#pragma mark -
#pragma mark Receiving items

- (void) UIMode:(MvrUIMode*) mode willBeginReceivingItemWithTransfer:(id <MvrIncoming>) i fromDirection:(MvrDirection) d;
{
	if (i.cancelled) return;
	
	MvrSlide* slide = [[MvrSlide alloc] initWithFrame:CGRectZero];
	[slide sizeToFit];
	slide.transferring = YES;
	[self.slidesStratum addDraggableSubview:slide enteringFromDirection:d];
	
	if (i.item) {
		[self receiveItem:i.item withSlide:slide];
	} else {
		[transfersToViews setObject:slide forKey:i];
		[kvo observe:@"cancelled" ofObject:i usingSelector:@selector(incomingTransfer:mayHaveFinishedWithChange:) options:0];
		[kvo observe:@"item" ofObject:i usingSelector:@selector(incomingTransfer:mayHaveFinishedWithChange:) options:0];
		[kvo observe:@"progress" ofObject:i usingSelector:@selector(incomingTransfer:didChangeProgress:) options:0];
	}
	
	[slide release];
}

- (void) receiveItem:(MvrItem*) item withSlide:(MvrSlide*) slide;
{
	[self setItem:item forSlide:slide];
	slide.transferring = NO;
	
	[[MvrItemUI UIForItem:item] didReceiveItem:item];
	[MvrApp().storageCentral.mutableStoredItems addObject:item];
}

- (void) incomingTransfer:(id <MvrIncoming>) i mayHaveFinishedWithChange:(NSDictionary*) change;
{
	if (!i.cancelled && !i.item) return;

	MvrSlide* slide = [transfersToViews objectForKey:i];
	NSAssert(slide, @"We are receiving transfer updates for a phantom transfer! Pull the brake!");
	
	if (i.cancelled)
		[self.slidesStratum removeDraggableSubviewByFadingAway:slide];
	else if (i.item)
		[self receiveItem:i.item withSlide:slide];
	
	[kvo endObserving:@"item" ofObject:i];
	[kvo endObserving:@"cancelled" ofObject:i];
	[kvo endObserving:@"progress" ofObject:i];
	[transfersToViews removeObjectForKey:i];
}

- (void) incomingTransfer:(id <MvrIncoming>)i didChangeProgress:(NSDictionary *)change;
{
	[[transfersToViews objectForKey:i] setProgress:i.progress];
}

@end

