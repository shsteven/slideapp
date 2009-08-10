//
//  L0MoverAdController.m
//  Mover
//
//  Created by ∞ on 12/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0MoverAdController.h"


@implementation L0MoverAdController

@synthesize superview, origin;

+ (BOOL) isPaidVersion;
{
#if kMvrIsPaidVersion
	return YES;
#else
	return NO;
#endif
}

#if kL0MoverInsertAdvertising

L0ObjCSingletonMethod(sharedController)

- (void) start;
{
	L0Log(@"Advertisements on!");
	if (view) return;
	
	view = [[AdMobView requestAdWithDelegate:self] retain];
}

- (void) stop;
{
	L0Log(@"Ads being disabled.");
	if (view.superview)
		[view removeFromSuperview];
	[view release]; view = nil;
}

#pragma mark -
#pragma mark Managing the ad view.

- (void)didReceiveAd:(AdMobView*) adWhirlView;
{
	if (view.superview) return;
	if (!self.superview) {
		L0Log(@"Ad received but no view to display it in. Agh! Dropping it.");
		return;
	}
	
	view.userInteractionEnabled = YES;
	self.superview.userInteractionEnabled = YES;
	
	L0Log(@"Ad received with the view not attached to anything. Displaying.");
	
	CGRect frame = view.frame;
	frame.origin = self.origin;
	view.frame = frame;
	
	view.alpha = 0.0;
	[self.superview addSubview:view];
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.7];
	view.alpha = 1.0;
	[UIView commitAnimations];
}

- (void) didFailToReceiveAd:(AdMobView*) adView;
{
	L0Log(@"Looks like we have no ads. Will retry in two minutes.");
	[self stop];
	[self performSelector:@selector(start) withObject:nil afterDelay:120.0];
}

#pragma mark -
#pragma mark Administrivia

- (NSString*) publisherId;
{
	// Does nothing at runtime, but triggers a build error if we've forgotten the key.
	NSAssert(kL0MoverAdMobKey != nil, @"Need to have the AdMob key to build with ads");
	return kL0MoverAdMobKey;
}

// #717171
- (UIColor*) adBackgroundColor;
{
	return [UIColor colorWithRed:0x71/255.0 green:0x71/255.0 blue:0x71/255.0 alpha:1.0];
}

- (UIColor*) primaryTextColor;
{
	return [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
}

- (void) dealloc;
{
	[self stop];
	[super dealloc];
}

#if DEBUG && kL0MoverDebugWithRealAds
#warning Will include non-test advertisements in a debug build.
#endif

#if DEBUG && !kL0MoverDebugWithRealAds
- (BOOL) useTestAd;
{
	return YES;
}
#endif

- (UIBarStyle) embeddedWebViewBarStyle;
{
	return UIBarStyleBlackOpaque;
}

#else

+ sharedController;
{ 
	L0Log(@"Advertisements disabled for this copy of Mover");
	return nil;
}
- (void) start {}

#endif


@end
