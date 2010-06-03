//
//  MvrVideoItemController.m
//  Mover3-iPad
//
//  Created by ∞ on 30/05/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MvrVideoItemController.h"
#import "MvrVideoItem.h"
#import "MvrItemAction.h"

#import "MvrShadowBackdropDraggableView.h"

static CGSize MvrAspectRatioSizeWithMaximumSide(CGSize original, CGFloat side) {
	if (original.width < side && original.height < side)
		return original;
	
	CGSize newSize;
	if (original.width > original.height) {
		newSize.width = side;
		// nw/nh = w/h
		// 1/nh = w/h / nw
		// nh = nw / w/h
		newSize.height = side / (original.width / original.height);
	} else {
		newSize.height = side;
		// nw/nh = w/h
		// nw = w/h * nh
		newSize.width = (original.width / original.height) * side;
	}
	
	return newSize;
}

@interface MvrVideoItemController ()

- (void) repositionActionButton;

@end


@implementation MvrVideoItemController

- (id) initWithNibName:(NSString *)name bundle:(NSBundle *)b;
{
	if ((self = [super initWithNibName:name bundle:b])) {
		NSNotificationCenter* c = [NSNotificationCenter defaultCenter];
		
		[c addObserver:self selector:@selector(naturalSizeAvailable:) name:MPMovieNaturalSizeAvailableNotification object:nil];
		[c addObserver:self selector:@selector(willExitFullscreen:) name:MPMoviePlayerWillExitFullscreenNotification object:nil];
	}
	
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}


+ supportedItemClasses;
{
	return [NSSet setWithObject:[MvrVideoItem class]];
}

- (void) viewDidLoad;
{
	[super viewDidLoad];
	
	MvrShadowBackdropDraggableView* v = (MvrShadowBackdropDraggableView*) self.view;
	v.contentAreaBackgroundColor = [UIColor blackColor];
	
	[self repositionActionButton];
	[v addSubview:self.actionButton];
	
	[self addManagedOutletKeys:
	 @"pc",
//	 @"image",
	 nil];
}

- (void) repositionActionButton;
{
	MvrShadowBackdropDraggableView* v = (MvrShadowBackdropDraggableView*) self.view;
	CGRect bounds = v.contentBounds;
	CGRect buttonBounds = self.actionButton.bounds;
	self.actionButton.frame = CGRectMake(bounds.size.width - buttonBounds.size.width - 10,
										 bounds.origin.y + 10, buttonBounds.size.width, buttonBounds.size.height);	
}

- (void) itemDidChange;
{
	[pc.view removeFromSuperview];
	[pc stop];
	[pc release]; pc = nil;
	
	if (self.item) {
		pc = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL fileURLWithPath:[[self.item storage] path]]];
		pc.useApplicationAudioSession = NO;
		[pc prepareToPlay];
		// [pc requestThumbnailImagesAtTimes:[NSArray arrayWithObject:[NSNumber numberWithDouble:2.0]] timeOption:MPMovieTimeOptionNearestKeyFrame];
		
		MvrShadowBackdropDraggableView* v = (MvrShadowBackdropDraggableView*) self.view;
		pc.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		pc.view.frame = v.contentBounds;
		[v addSubview:pc.view];
		
		[self.actionButton.superview bringSubviewToFront:self.actionButton];
	}
}

- (void) itemDidFinishReceivingFromNetwork;
{
	if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum([[self.item storage] path]))
		UISaveVideoAtPathToSavedPhotosAlbum([[self.item storage] path], nil, NULL, NULL);
}

- (void) naturalSizeAvailable:(NSNotification*) n;
{
	if ([n object] != pc)
		return;
	
	L0Log(@"natural size available: %@", NSStringFromCGSize(pc.naturalSize));

	[UIView beginAnimations:nil context:NULL];
	
	CGPoint p = self.view.center;
	CGRect r = self.view.bounds;
	r.size = MvrAspectRatioSizeWithMaximumSide(pc.naturalSize, 450);
	
	MvrShadowBackdropDraggableView* v = (MvrShadowBackdropDraggableView*) self.view;

	v.bounds = r;
	v.center = p;
	pc.view.frame = v.contentBounds;
	[pc.view setNeedsLayout];
	
	[self repositionActionButton];
	
	[UIView commitAnimations];
}

- (void) willExitFullscreen:(NSNotification*) n;
{
	if ([n object] != pc)
		return;
	
	NSTimeInterval i = [[[n userInfo] objectForKey:MPMoviePlayerFullscreenAnimationDurationUserInfoKey] doubleValue];
	
	CGAffineTransform t = self.view.transform;
	self.view.transform = CGAffineTransformIdentity; // rotate upright

	[UIView beginAnimations:nil context:NULL];
	{
		[UIView setAnimationDuration:0.2];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
		[UIView setAnimationDelay:i];
	
		self.view.transform = t;
	}
	[UIView commitAnimations];
}

- (void) setActionButtonHidden:(BOOL)hidden animated:(BOOL)animated;
{
	L0Log(@"%d", hidden);
	[super setActionButtonHidden:hidden animated:animated];
}

- (NSArray*) defaultActions;
{
	MvrItemAction* playAction = [MvrItemAction actionWithDisplayName:NSLocalizedString(@"Play", @"Play action button for video items")
		block:^(MvrItem* i) {
			
			[pc play];
			[pc setFullscreen:YES animated:YES];
			
		}];
	
	return [NSArray arrayWithObjects:
			playAction,
			[self showOpeningOptionsMenuAction],
			nil];
}

@end
