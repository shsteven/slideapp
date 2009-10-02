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

@property(readonly) CGRect regularBackdropFrame, regularArrowsStratumFrame, regularSlidesStratumBounds, shadowFrameWithClosedDrawer;
- (CGRect) backdropFrameWithDrawerHeight:(CGFloat) h;
- (CGRect) arrowsStratumFrameWithDrawerHeight:(CGFloat) h;
- (CGRect) shadowFrameWithDrawerHeight:(CGFloat) h;

- (void) slideDownAndRemoveDrawerView;
- (void) slideDownAndRemoveDrawerViewThenReplaceWith:(UIView*) newOne;
- (void) slideUpToRevealDrawerView:(UIView*) v;

@property(retain) UIView* currentDrawerView;

@end



@implementation MvrTableController

- (CGRect) regularBackdropFrame;
{
	return self.hostView.bounds;
}

- (CGRect) regularArrowsStratumFrame;
{
	CGRect r = self.hostView.bounds;
	r.size.height -= self.toolbar.bounds.size.height;
	return r;
}

- (CGRect) regularSlidesStratumBounds;
{
	return self.hostView.bounds;
}

- (void) setUp;
{
	NSAssert(self.currentMode, @"A mode must be made current before the table controller is set up.");
	
	// Set up the host view
	self.hostView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"DrawerBackdrop.png"]];
	
	// Set up the backdrop and arrows stratum
	CGRect r = self.regularBackdropFrame;
	UIView* backdrop = self.currentMode.backdropStratum;
	backdrop.frame = r;
	backdrop.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
	[self.hostView addSubview:backdrop];
	
	r = self.regularArrowsStratumFrame;
	UIView* arrows = self.currentMode.arrowsStratum;
	arrows.frame = r;
	arrows.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	[self.hostView insertSubview:arrows aboveSubview:backdrop];
	
	// Create and show the slides stratum
	self.slidesStratum = [[[MvrSlidesView alloc] initWithFrame:self.regularSlidesStratumBounds delegate:self] autorelease];
	[self.hostView addSubview:self.slidesStratum];
	
	// Create the correspondence maps
	itemsToViews = [L0Map new];
	viewsToItems = [L0Map new];
	transfersToViews = [L0Map new];
	
	// Put the edit button in the proper position in the toolbar
	NSMutableArray* a = [NSMutableArray arrayWithArray:self.toolbar.items];
	[a insertObject:self.editButtonItem atIndex:2]; // see NIB.
	self.toolbar.items = a;
	self.editButtonItem.enabled = NO; // overridden by the first addItem: call.
	
	// Set up KVO
	kvo = [[L0KVODispatcher alloc] initWithTarget:self];
	
	// -------- TESTING STUFF ---------
	// TODO remove me!
	MvrItemStorage* storage = [MvrItemStorage itemStorageWithData:[@"Ciao, mondo!" dataUsingEncoding:NSUTF8StringEncoding]];
	MvrItem* i = [MvrItem itemWithStorage:storage type:(id) kUTTypeUTF8PlainText metadata:[NSDictionary dictionaryWithObject:@"Ciao" forKey:kMvrItemTitleMetadataKey]];
	
	[self addItem:i animated:NO];
	
	// TODO remove me again!
	
	UIView* red = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 250)] autorelease];
	UIView* transparent = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 250)] autorelease];
	red.backgroundColor = [UIColor redColor];
	transparent.backgroundColor = [UIColor clearColor];
	transparent.opaque = NO;	
}

- (void) setCurrentMode:(MvrUIMode *) m;
{
	if (m != currentMode) {
		MvrUIMode* oldMode = currentMode;
		[oldMode modeWillStopBeingCurrent:NO]; // TODO animation
		[m modeWillBecomeCurrent:NO];
		
		currentMode.delegate = nil;
		
		[[currentMode retain] autorelease];
		[currentMode release];
		currentMode = [m retain];
		
		m.delegate = self;
		
		[currentMode modeDidBecomeCurrent:NO];
		[oldMode modeDidStopBeingCurrent:NO];
	}
}

@synthesize hostView, toolbar, currentMode, slidesStratum, shadowView;

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
	[shadowView release];
	
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
	[[MvrItemUI UIForItem:item] didStoreItem:item];
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

#pragma mark -
#pragma mark The Drawer.

- (CGRect) backdropFrameWithDrawerHeight:(CGFloat) h;
{
	CGRect r = self.regularBackdropFrame;
	r.origin.y -= (h + self.toolbar.frame.size.height);
	return r;
}

- (CGRect) arrowsStratumFrameWithDrawerHeight:(CGFloat) h;
{
	CGRect r = self.regularBackdropFrame;
	r.size.height -= (h + self.toolbar.frame.size.height);
	return r;
}

- (CGRect) slidesStratumFrameWithDrawerHeight:(CGFloat) h;
{
	CGRect r = self.regularSlidesStratumBounds;
	r.size.height -= (h + self.toolbar.frame.size.height);
	return r;
}

- (CGRect) shadowFrameWithClosedDrawer;
{
	return [self shadowFrameWithDrawerHeight:0];
}

- (CGRect) shadowFrameWithDrawerHeight:(CGFloat) h;
{
	CGRect b = [self backdropFrameWithDrawerHeight:h];
	CGRect r;
	r.origin = CGPointMake(b.origin.x, b.origin.y + b.size.height);
	r.size.width = b.size.width;
	r.size.height = self.shadowView.frame.size.height;
	return r;
}

@synthesize currentDrawerView;
- (void) setCurrentDrawerViewAnimating:(UIView*) v;
{
	if (currentDrawerView == v) return;
	
	if (!currentDrawerView && v)
		[self slideUpToRevealDrawerView:v];
	else if (currentDrawerView && !v)
		[self slideDownAndRemoveDrawerView];
	else if (currentDrawerView && v)
		[self slideDownAndRemoveDrawerViewThenReplaceWith:v];
}

- (void) slideDownAndRemoveDrawerView;
{
	[self slideDownAndRemoveDrawerViewThenReplaceWith:nil];
}

- (void) slideDownAndRemoveDrawerViewThenReplaceWith:(UIView*) newOne;
{
	NSArray* a = newOne ? [NSArray arrayWithObjects:currentDrawerView, newOne, nil] : [NSArray arrayWithObject:currentDrawerView];
	CFRetain(a); // balanced in the stop selector below.

	[UIView beginAnimations:nil context:(void*) a];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:0.2];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(slideDownAnimation:didEndByFinishing:context:)];
	
	self.currentMode.backdropStratum.frame = self.regularBackdropFrame;
	self.currentMode.arrowsStratum.frame = self.regularArrowsStratumFrame;
	self.slidesStratum.frame = self.regularSlidesStratumBounds;
	self.shadowView.frame = self.shadowFrameWithClosedDrawer;
	self.shadowView.alpha = 0.0;
	
	[UIView commitAnimations];
	
	self.currentDrawerView = nil;
}

- (void) slideDownAnimation:(NSString*) s didEndByFinishing:(BOOL) end context:(void*) context;
{
	NSArray* oldAndNew = (NSArray*) context;
	[/* the old view*/ [oldAndNew objectAtIndex:0] removeFromSuperview];
	
	if ([oldAndNew count] > 1)
		[self performSelector:@selector(slideUpToRevealDrawerView:) withObject:[oldAndNew objectAtIndex:1] afterDelay:0.4];
	
	CFRelease(oldAndNew); // balances the one in -slideDownAndRemoveDrawerViewThenReplaceWith
}

- (void) slideUpToRevealDrawerView:(UIView*) v;
{	
	CGRect backdropFrame = [self backdropFrameWithDrawerHeight:v.bounds.size.height];
	CGRect arrowsFrame = [self arrowsStratumFrameWithDrawerHeight:v.bounds.size.height];
	CGRect slidesStratumFrame = [self slidesStratumFrameWithDrawerHeight:v.bounds.size.height];
	
	CGRect frame = v.frame;
	frame.origin = CGPointMake(0, self.view.frame.size.height - frame.size.height - self.toolbar.frame.size.height);
	frame.size.width = self.view.frame.size.width;
	v.frame = frame;
	
	[self.hostView insertSubview:v belowSubview:self.currentMode.backdropStratum];
	
	self.shadowView.frame = self.shadowFrameWithClosedDrawer;
	self.shadowView.alpha = 0.0;
	[self.hostView insertSubview:self.shadowView aboveSubview:v];
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:1.0];
	[UIView setAnimationDelay:0.5];
	
	self.currentMode.backdropStratum.frame = backdropFrame;
	self.currentMode.arrowsStratum.frame = arrowsFrame;
	self.slidesStratum.frame = slidesStratumFrame;
	self.shadowView.frame = [self shadowFrameWithDrawerHeight:v.bounds.size.height];
	self.shadowView.alpha = 1.0;
	
	[UIView commitAnimations];
	
	[self.slidesStratum bounceBackAll];
	self.currentDrawerView = v;
}

- (IBAction) testByRemovingDrawer;
{
	[self setCurrentDrawerViewAnimating:nil];
}

- (IBAction) toggleConnectionDrawerVisible;
{
	UIView* current = self.currentDrawerView, * newOne = self.currentMode.connectionStateDrawerView;
	if (current != newOne)
		[self setCurrentDrawerViewAnimating:newOne];
	else
		[self setCurrentDrawerViewAnimating:nil];
}

#pragma mark -
#pragma mark Termination

- (void) tearDown;
{
	self.currentMode = nil;
}

@end

