//
//  Mover3_iPadViewController.m
//  Mover3-iPad
//
//  Created by ∞ on 14/04/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "MvrTableController_iPad.h"
#import <QuartzCore/QuartzCore.h>

#import "MvrAppDelegate_iPad.h"
#import "MvrInertia.h"
#import "MvrArrowView_iPad.h"
#import "MvrAddPane.h"
#import "MvrAboutPane.h"
#import "MvrWiFiNetworkStatePane.h"

#import "PLActionSheet.h"

#define kMvrMaximumAngleRange (30)
static CGAffineTransform MvrConcatenateRandomRotationToTransform(CGAffineTransform transform)
{
	srandomdev();
	CGFloat angle = ((random() % kMvrMaximumAngleRange) - kMvrMaximumAngleRange / 2.0) * M_PI/180.0;
	return CGAffineTransformRotate(transform, angle);
}

enum {
	kMvrNorthEdge,
	kMvrSouthEdge,
	kMvrWestEdge,
	kMvrEastEdge,
};
typedef NSInteger MvrEdge;

// This function computes start and end points for a sliding entrance for a draggable view.
// - view is the aforementioned view. It must already be correctly transformed and all.
// - edge is the edge the view should be coming in (n, s, w, e).
// - coord is a coordinate along that edge the view will pass near when entering. N and S edge take X coordinates (left-to-right), W and E take Y coordinates (top-to-bottom).
// on return, *start is the starting center for the view, while *end is the ending position.
// start and end CANNOT be NULL.
@interface MvrTableController_iPad ()

- (void) getStartingPoint:(CGPoint*) start endingPoint:(CGPoint*) end toAnimateSlidingEntranceOfView:(MvrDraggableView*) view alongEdge:(MvrEdge) edge atCoordinate:(CGFloat) coord;

- (void) addArrowViewForChannel:(id <MvrChannel>) chan;
- (void) removeArrowViewForChannel:(id <MvrChannel>) chan;
- (void) clearArrowViews;

- (void) layoutArrowViews;
- (void) layoutArrowViewsInSuperviewBounds:(CGRect)draggableBounds;

- (void) getStartCoordinate:(CGFloat*) coord edge:(NSInteger*) edge forArrowView:(MvrArrowView_iPad*) arrow;

- (void) bounceBackViewOfControllerIfNeeded:(MvrItemController*) ic;
- (BOOL) checkControllerForSending:(MvrItemController *)ic;

- (id <MvrChannel>) channelForArrowView:(MvrArrowView_iPad*) arrow;
- (id <MvrChannel>) channelAtEdge:(MvrEdge) edge coordinate:(NSInteger) i;
- (id <MvrChannel>) channelForViewWithCenter:(CGPoint) center;

- (void) userDidEndDraggingController:(MvrItemController*) ic;

@property(nonatomic, retain) MvrScannerObserver* currentObserver;

- (void) setupObservationForCurrentScanner;

@end


@implementation MvrTableController_iPad

- (ILRotationStyle) rotationStyle;
{
	return kILRotateAny;
}

- (void) getStartCoordinate:(CGFloat*) coord edge:(NSInteger*) edge forArrowView:(MvrArrowView_iPad*) arrow;
{
	CGPoint center = arrow.center;
	CGRect bounds = draggableViewsLayer.bounds;
	
	CGFloat northDistance, southDistance, westDistance, eastDistance;
	northDistance = center.y;
	southDistance = bounds.size.height - center.y;
	westDistance = center.x;
	eastDistance = bounds.size.width - center.x;
	
	CGFloat leastDistance = (MIN(MIN(northDistance, southDistance), MIN(westDistance, eastDistance)));
	
	if (leastDistance == northDistance)
		*edge = kMvrNorthEdge;
	else if (leastDistance == southDistance)
		*edge = kMvrSouthEdge;		
	else if (leastDistance == eastDistance)
		*edge = kMvrEastEdge;		
	else
		*edge = kMvrWestEdge;		

	if (*edge == kMvrNorthEdge || *edge == kMvrSouthEdge)
		*coord = center.x;
	else
		*coord = center.y;
}

- (void) getStartingPoint:(CGPoint*) start endingPoint:(CGPoint*) end toAnimateSlidingEntranceOfView:(MvrDraggableView*) view alongEdge:(MvrEdge) edge atCoordinate:(CGFloat) coord;
{
	CGRect bounds = view.bounds, selfBounds = draggableViewsLayer.bounds;
	// excess approximation
	CGFloat safeDistanceForHidingView = MAX(bounds.size.width, bounds.size.height) * 1.41;
	
	switch (edge) {
		case kMvrNorthEdge: {
			*start = CGPointMake(coord, -safeDistanceForHidingView);
			*end = CGPointMake(coord, selfBounds.size.height * 0.2);
		}
			break;

		case kMvrSouthEdge: {
			*start = CGPointMake(coord, selfBounds.size.height + safeDistanceForHidingView);
			*end = CGPointMake(coord, selfBounds.size.height * 0.8);
		}
			break;
			
		case kMvrWestEdge: {
			*start = CGPointMake(-safeDistanceForHidingView, coord);
			*end = CGPointMake(selfBounds.size.width * 0.2, coord);
		}
			break;
			
		case kMvrEastEdge: {
			*start = CGPointMake(selfBounds.size.width + safeDistanceForHidingView, coord);
			*end = CGPointMake(selfBounds.size.width * 0.8, coord);
		}
			break;
			
		default:
			NSAssert(NO, @"Unknown edge constant");
			return;
	}
	
	const int maximumWiggle = 100;
	
	srandomdev();
	end->x += (double)(random() % maximumWiggle * 2) - (double) maximumWiggle;
	end->y += (double)(random() % maximumWiggle * 2) - (double) maximumWiggle;
}

- (void) viewDidLoad;
{
	[super viewDidLoad];
	
	if (!inited) {
		inited = YES;
		
		itemControllersSet = [NSMutableSet new];
		arrowViewsByChannel = [L0Map new];
		
		orderedArrowViews = [NSMutableArray new];
		
		[self setupObservationForCurrentScanner];
		
		appObserver = [[L0KVODispatcher alloc] initWithTarget:self];
		
		bluetoothControlsView.hidden = YES;
		bluetoothControlsView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"DrawerBackdrop.png"]];
		
		[appObserver observe:@"currentScanner" ofObject:MvrApp_iPad() options:0 usingBlock:^(id o, NSDictionary* change) {
			
#warning TODO
			// [self setupTableForScanner]; // switches from wifi to bt table
			[self setupObservationForCurrentScanner];
			
		}];
	}
}

- (void) setupObservationForCurrentScanner;
{
	[self clearArrowViews];
	
	for (id <MvrChannel> chan in MvrApp_iPad().currentScanner.channels)
		[self addArrowViewForChannel:chan];

	[self layoutArrowViews];
	
	self.currentObserver = [[[MvrScannerObserver alloc] initWithScanner:MvrApp_iPad().currentScanner delegate:self] autorelease];
	
	CATransition* fade = [CATransition animation];
	fade.type = kCATransitionFade;
	
	[backdropImageView.layer addAnimation:fade forKey:@"MvrTableController_iPad - Fade"];
	if ([MvrApp_iPad().currentScanner isKindOfClass:[MvrBTScanner class]]) {
		
		if (bluetoothControlsView.hidden) {
			bluetoothControlsView.alpha = 0.0;
			bluetoothControlsView.hidden = NO;
			
			[UIView beginAnimations:nil context:NULL];
			{
				bluetoothControlsView.alpha = 1.0;
			}
			[UIView commitAnimations];
		}
		
		if (networkPopover.popoverVisible)
			[networkPopover dismissPopoverAnimated:YES];
		
		networkBarItem.enabled = NO;
		
		backdropImageView.image = [UIImage imageNamed:@"Backdrop-Bluetooth-iPad.png"];
	} else {
		if (!bluetoothControlsView.hidden) {
			[UIView beginAnimations:nil context:NULL];
			{
				[UIView setAnimationDelegate:self];
				[UIView setAnimationDidStopSelector:@selector(fadeOutForBluetoothControls:finished:context:)];
			
				bluetoothControlsView.alpha = 0.0;
			}
			[UIView commitAnimations];
		}
		
		networkBarItem.enabled = YES;
		backdropImageView.image = [UIImage imageNamed:@"Backdrop-iPad.png"];
	}
}

- (void) fadeOutForBluetoothControls:(NSString*) ani finished:(BOOL) finished context:(void*) nothing;
{
	bluetoothControlsView.hidden = YES;
}

- (IBAction) backToWiFi;
{
	[MvrApp_iPad() switchToWiFi];
}

#pragma mark Arrows

- (void) scanner:(id <MvrScanner>)s didAddChannel:(id <MvrChannel>)channel;
{
	[self addArrowViewForChannel:channel];
}

- (void) scanner:(id <MvrScanner>)s didRemoveChannel:(id <MvrChannel>)channel;
{
	[self removeArrowViewForChannel:channel];
}

- (void) addArrowViewForChannel:(id <MvrChannel>) chan;
{
	if ([arrowViewsByChannel objectForKey:chan])
		return;
	
	L0Log(@"Will add an arrow view for %@", chan);
	
	// TODO better constructor
	MvrArrowView_iPad* arrow = [[[MvrArrowView_iPad alloc] initWithFrame:CGRectZero] autorelease];
	
	arrow.mainLabel.text = [chan displayName];
	
	if ([MvrApp_iPad().currentScanner isKindOfClass:[MvrBTScanner class]])
		arrow.mainLabel.textColor = [UIColor whiteColor];
	
	[arrowViewsByChannel setObject:arrow forKey:chan];
	[orderedArrowViews addObject:arrow];
	
	[arrowsLayer addSubview:arrow];
	[self layoutArrowViews];
}

- (void) removeArrowViewForChannel:(id <MvrChannel>) chan;
{
	L0Log(@"Will remove an arrow view for %@", chan);

	MvrArrowView_iPad* arrow = [arrowViewsByChannel objectForKey:chan];
	[arrow removeFromSuperview]; // TODO animated
	[orderedArrowViews removeObject:arrow];
	[arrowViewsByChannel removeObjectForKey:chan];

	[self layoutArrowViews];
}

- (void) clearArrowViews;
{
	for (id <MvrChannel> c in [arrowViewsByChannel allKeys])
		[self removeArrowViewForChannel:c];
}

- (id <MvrChannel>) channelForArrowView:(MvrArrowView_iPad*) arrow;
{
	for (id <MvrChannel> c in [arrowViewsByChannel allKeys]) {
		if ([[arrowViewsByChannel objectForKey:c] isEqual:arrow])
			return c;
	}
	
	return nil;
}

- (id <MvrChannel>) channelAtEdge:(MvrEdge) edge coordinate:(NSInteger) i;
{
	switch (edge) {
		case kMvrWestEdge:
			return [orderedArrowViews count] >= 1? [self channelForArrowView:[orderedArrowViews objectAtIndex:0]] : nil;
		case kMvrNorthEdge:
			return [orderedArrowViews count] >= 2? [self channelForArrowView:[orderedArrowViews objectAtIndex:1]] : nil;
		case kMvrEastEdge:
			return [orderedArrowViews count] >= 3? [self channelForArrowView:[orderedArrowViews objectAtIndex:2]] : nil;
		default:
			return nil;
	}
}

- (id <MvrChannel>) channelForViewWithCenter:(CGPoint) center;
{
	if (center.y < 0)
		return [self channelAtEdge:kMvrNorthEdge coordinate:center.x];
	else if (center.x < 0)
		return [self channelAtEdge:kMvrWestEdge coordinate:center.y];
	else if (center.x > draggableViewsLayer.bounds.size.width)
		return [self channelAtEdge:kMvrEastEdge coordinate:center.y];
	else
		return nil;
}

- (void) layoutArrowViews;
{
	CGRect arrowBounds = arrowsLayer.bounds;
	[self layoutArrowViewsInSuperviewBounds:arrowBounds];
}

- (void) layoutArrowViewsInSuperviewBounds:(CGRect) draggableBounds;
{
	int i = 0;
	MvrEdge edges[] = {
		kMvrWestEdge,
		kMvrNorthEdge,
		kMvrEastEdge,
	};
	size_t edgeCount = 3;
	
	L0Log(@"%@ being laid out", orderedArrowViews);
	
	for (MvrArrowView_iPad* arrow in orderedArrowViews) {
		if (i >= edgeCount)
			break;
		
		// TODO more than three arrows.
		
		CGRect arrowBounds = arrow.bounds;
		
		switch (edges[i]) {
			case kMvrWestEdge:
				// first one, west slot
				arrow.transform = CGAffineTransformMakeRotation(270 * M_PI/180.0);
				
				arrow.center = CGPointMake(arrowBounds.size.height / 2, CGRectGetMidY(draggableBounds));
				arrowBounds.size.width = draggableBounds.size.height;
				arrow.bounds = arrowBounds;
								
				break;
			
			case kMvrNorthEdge:
				// second one, north slot
				arrow.transform = CGAffineTransformIdentity;
				
				arrow.center = CGPointMake(CGRectGetMidX(draggableBounds), arrowBounds.size.height / 2);
				arrowBounds.size.width = draggableBounds.size.width;
				arrow.bounds = arrowBounds;
				
				break;
				
			case kMvrEastEdge:
				// third one, east slot
				arrow.transform = CGAffineTransformMakeRotation(90 * M_PI/180.0);
				
				arrow.center = CGPointMake(CGRectGetMaxX(draggableBounds) - arrowBounds.size.height / 2, CGRectGetMidY(draggableBounds));
				arrowBounds.size.width = draggableBounds.size.height;
				arrow.bounds = arrowBounds;				
				
				break;
				
			default:
				return;
		}
		
		i++;
	}
}

#pragma mark Items

- (void) addItem:(MvrItem*) item fromSource:(id) source ofType:(MvrItemSourceType) type;
{
	if (type == kMvrItemSourceChannel && source)
		[MvrApp_iPad().storage addStoredItemsObject:item];
	
	MvrItemController* ic = [MvrItemController itemControllerWithItem:item];
	if (!ic)
		return;
	
	ic.draggableView.hidden = YES;
	
	[self addItemController:ic];
	
	switch (type) {
		case kMvrItemSourceChannel:
		case kMvrItemSourceSelf: {
			NSInteger edge;
			CGFloat coord;
			
			MvrArrowView_iPad* arrow = nil;
			
			if (source)
				arrow = [arrowViewsByChannel objectForKey:source];
			
			if (type == kMvrItemSourceSelf || !arrow) {
				edge = kMvrSouthEdge;
				coord = CGRectGetMidX(draggableViewsLayer.bounds);
			} else
				[self getStartCoordinate:&coord edge:&edge forArrowView:arrow];
			
			CGPoint start, end;
			[self getStartingPoint:&start endingPoint:&end toAnimateSlidingEntranceOfView:ic.draggableView alongEdge:edge atCoordinate:coord];
			
			ic.draggableView.center = start;
			ic.draggableView.transform = MvrConcatenateRandomRotationToTransform(CGAffineTransformIdentity);
			ic.draggableView.hidden = NO;
			
			[UIView beginAnimations:nil context:NULL];
			{
				[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
				[UIView setAnimationDuration:1.25];
				ic.draggableView.center = end;
			}
			[UIView commitAnimations];
			
			if (type == kMvrItemSourceChannel) {
				[ic itemDidFinishReceivingFromNetwork];
				[ic beginShowingActionButton];
			}
			
		}
			break;
			
		case kMvrItemSourceUnknown: {
			
			ic.draggableView.alpha = 0.0;
			ic.draggableView.center = CGPointMake(CGRectGetMidX(draggableViewsLayer.bounds), CGRectGetMidY(draggableViewsLayer.bounds));
			ic.draggableView.hidden = NO;
			
			CGAffineTransform finished = MvrConcatenateRandomRotationToTransform(CGAffineTransformIdentity);
			ic.draggableView.transform = CGAffineTransformScale(finished, 1.1, 1.1);
			
			[UIView beginAnimations:nil context:NULL];
			{
				[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
				[UIView setAnimationDelay:0.5];
				[UIView setAnimationDuration:0.5];
				ic.draggableView.alpha = 1.0;
				ic.draggableView.transform = finished;
			}
			[UIView commitAnimations];
		}
			break;
	}
}

- (void) removeItem:(MvrItem*) item;
{
	for (MvrItemController* ic in self.itemControllers) {
		if (ic.item == item)
			[self removeItemController:ic];
	}
}

- (NSSet*) itemControllers;
{	
	return [[itemControllersSet copy] autorelease];
}

- (void) addItemController:(MvrItemController*) ic;
{
	[itemControllersSet addObject:ic];
	ic.itemsTable = self;
	[self addDraggableView:ic.draggableView];
}

- (void) removeItemController:(MvrItemController*) ic;
{
	if (ic.draggableView.superview == draggableViewsLayer)
		[ic.draggableView removeFromSuperview];
	
	if (ic.itemsTable == self)
		ic.itemsTable = nil;
	
	[itemControllersSet removeObject:ic];
}



- (void) addDraggableView:(MvrDraggableView*) v;
{
	v.autoresizingMask = UIViewAutoresizingNone;
	[draggableViewsLayer addSubview:v];
}


- (void) bounceBackViewOfControllerIfNeeded:(MvrItemController*) ic;
{
	MvrDraggableView* dv = ic.draggableView;
	
	if (dv.superview != draggableViewsLayer)
		return;
	
	// defect approxim.
	const CGFloat distance = MIN(200, 0.3 * MAX(dv.bounds.size.width, dv.bounds.size.height));
	
	CGRect bounds = draggableViewsLayer.bounds;
	CGPoint center = dv.center;
	
	if (center.x < 0)
		center.x = distance;
	else if (center.x > bounds.size.width)
		center.x = bounds.size.width - distance;
	
	if (center.y < 0)
		center.y = distance;
	else if (center.y > bounds.size.height)
		center.y = bounds.size.height - distance;
	
	[UIView beginAnimations:nil context:NULL];
	{
		[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
		[UIView setAnimationDuration:0.5];
		[UIView setAnimationDelay:0.1];
	
		dv.center = center;
	}
	[UIView commitAnimations];
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation;
{
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	
	for (MvrItemController* ic in itemControllersSet)
		[self bounceBackViewOfControllerIfNeeded:ic];	

	[self layoutArrowViews];
	
	if (aboutPopover.popoverVisible) {
		[aboutPopover dismissPopoverAnimated:YES];
		// TODO
		// [aboutPopover present...];
	}
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration;
{
	CGRect bounds = draggableViewsLayer.bounds;
	CGSize newSize;
	
	newSize.width = UIInterfaceOrientationIsPortrait(toInterfaceOrientation)? MIN(bounds.size.width, bounds.size.height) : MAX(bounds.size.width, bounds.size.height);
	newSize.height = UIInterfaceOrientationIsPortrait(toInterfaceOrientation)? MAX(bounds.size.width, bounds.size.height) : MIN(bounds.size.width, bounds.size.height);

	bounds.size = newSize;
	[self layoutArrowViewsInSuperviewBounds:bounds];
}

- (void) itemControllerViewDidFinishMoving:(MvrItemController *)ic velocity:(CGPoint) v;
{
	CGPoint end;
	NSTimeInterval time;
	
	if (MvrInertiaShouldBeginAnimationAtStartPointAndVelocity(ic.draggableView.center, v, 0.1, 0, nil, &end, &time)) {
		
		[ic retain]; // released in the did stop selector.
		[UIView beginAnimations:nil context:(void*) ic];
		{
			[UIView setAnimationDuration:time];
			[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
			
			[UIView setAnimationDelegate:self];
			[UIView setAnimationDidStopSelector:@selector(inertiaAnimation:didEnd:context:)];
			
			ic.draggableView.center = end;
		}
		[UIView commitAnimations];
		
		// TODO begin transfer if needed.
		
	} else
		[self userDidEndDraggingController:ic];
}

- (void) inertiaAnimation:(NSString*) ani didEnd:(BOOL) finished context:(MvrItemController*) retainedItemController;
{
	[self userDidEndDraggingController:retainedItemController];
	[retainedItemController release]; // balances the retain above.
}

- (void) removeItemOfControllerFromTable:(MvrItemController *)ic;
{
	MvrItem* i = [[ic.item retain] autorelease];
	ic.item = nil;
	[MvrApp_iPad().storage removeStoredItemsObject:i];
	[self removeItemController:ic];
}

#pragma mark Sending

- (void) userDidEndDraggingController:(MvrItemController*) ic;
{
	if ([self checkControllerForSending:ic]) {
		[self performSelector:@selector(bounceBackViewOfControllerIfNeeded:) withObject:ic afterDelay:0.5];
	 } else
		 [self bounceBackViewOfControllerIfNeeded:ic];
}

- (BOOL) checkControllerForSending:(MvrItemController*) ic;
{
	id <MvrChannel> c = [self channelForViewWithCenter:ic.draggableView.center];
	if (c && ic.item) {
		[c beginSendingItem:ic.item];
		return YES;
	}
	
	return NO;
}

- (IBAction) showAddPopover:(UIBarButtonItem*) sender;
{
	[aboutPopover dismissPopoverAnimated:YES];
	[networkPopover dismissPopoverAnimated:YES];
	
	if (!addPopover) {
		MvrAddPane* pane;
		addPopover = [[MvrAddPane popoverControllerForViewController:&pane] retain];
		pane.delegate = self;
	}
	
	[addPopover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void) addPaneDidPickItem:(MvrItem*) i;
{
	[MvrApp_iPad().storage addStoredItemsObject:i];
	[self addItem:i fromSource:nil ofType:kMvrItemSourceSelf];
}

- (void) addPaneDidFinishPickingItems;
{
	[addPopover dismissPopoverAnimated:YES];
}

- (IBAction) askForDeleteAll:(UIBarButtonItem*) sender;
{
	if (askDeleteIsShown)
		return;
	
	PLActionSheet* as = [[PLActionSheet new] autorelease];
	
	NSString* title = NSLocalizedString(@"You can remove a single item from the table by touching it, then using its Action button to delete it. You can also delete all items at once.", @""),
		* deleteAllButton = NSLocalizedString(@"Delete All Items", @"Delete All button");
	
	as.sheet.title = title;
	[as addDestructiveButtonWithTitle:deleteAllButton action:^{
		
		for (id x in [[itemControllersSet copy] autorelease])
			[self removeItemOfControllerFromTable:x];
		
	}];
	
	[as setFinishedAction:^{
		askDeleteIsShown = NO;
	}];
	
	askDeleteIsShown = YES;
	[as showFromBarButtonItem:sender animated:YES];
}

- (IBAction) showAboutPane:(UIButton*) infoButton;
{
	[addPopover dismissPopoverAnimated:YES];
	[networkPopover dismissPopoverAnimated:YES];
	
	if (!aboutPopover) {
		MvrAboutPane* about = [MvrAboutPane modalPane];
		aboutPopover = [[UIPopoverController alloc] initWithContentViewController:about];
	}
	
	[aboutPopover presentPopoverFromRect:infoButton.bounds inView:infoButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void) showNetworkPopover:(UIBarButtonItem *)sender;
{
	[addPopover dismissPopoverAnimated:YES];
	[aboutPopover dismissPopoverAnimated:YES];
	
	if (!networkPopover) {
		MvrWiFiNetworkStatePane* networkPane = [[MvrWiFiNetworkStatePane new] autorelease];
		networkPopover = [[UIPopoverController alloc] initWithContentViewController:networkPane];
	}
	
	[networkPopover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void) viewWillAppear:(BOOL)animated;
{
	[super viewWillAppear:animated];
	
	for (id x in itemControllersSet)
		[self bounceBackViewOfControllerIfNeeded:x];
}

- (void) didReceiveMemoryWarning;
{
	// never deallocate our view.
}

@synthesize currentObserver;

@end
