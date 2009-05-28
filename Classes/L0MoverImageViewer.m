//
//  L0MoverImageViewer.m
//  Mover
//
//  Created by ∞ on 16/05/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0MoverImageViewer.h"
#import <MuiKit/MuiKit.h>

@interface L0MoverImageViewer ()
- (void) clearOutlets;
@end


@implementation L0MoverImageViewer

- (id) initWithImage:(UIImage*) i;
{
	if (self = [super initWithNibName:@"L0MoverImageViewer" bundle:nil]) {
		self.image = i;
		self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismiss)] autorelease];
	}
	
	return self;
}

- (void) dealloc;
{
	[self clearOutlets];
	[image release];
	[super dealloc];
}

@synthesize imageView, scrollView, image;

- (void) viewDidLoad;
{
    [super viewDidLoad];
	self.imageView.image = self.image;
	self.scrollView.scrollsToTop = NO;
	self.scrollView.clipsToBounds = YES;
	self.scrollView.minimumZoomScale = 1.0;
	self.scrollView.maximumZoomScale = 3.0;
}

- (void) viewWillAppear:(BOOL) ani;
{
	[super viewWillAppear:ani];

	CGRect bounds = self.scrollView.bounds;
	CGSize imageSize = L0SizeFromSizeNotLargerThan(self.image.size, bounds.size);
	
//	CGFloat verticalInset = (bounds.size.height - imageSize.height) / 2;
//	CGFloat horizontalInset = (bounds.size.width - imageSize.width) / 2;

	self.imageView.frame = bounds;

	self.scrollView.contentSize = imageSize;
//	self.scrollView.contentInset = UIEdgeInsetsMake(-verticalInset, -horizontalInset, -verticalInset, -horizontalInset);

	
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 30000
	[self.scrollView setZoomScale:1.0 animated:NO];
#endif
	
	lastBarStyle = UIApp.statusBarStyle;
	hasBarStyle = YES;
	
	[UIApp setStatusBarStyle:UIBarStyleBlackOpaque animated:YES];
}

- (void) viewWillDisappear:(BOOL) ani;
{
	[super viewWillDisappear:ani];

	if (hasBarStyle) {
		[UIApp setStatusBarStyle:lastBarStyle animated:ani];
		hasBarStyle = NO;
	}
}

- (UIView*) viewForZoomingInScrollView:(UIScrollView*) scrollView;
{
	return self.imageView;
}

- (void) dismiss;
{
	if (hasBarStyle) {
		[UIApp setStatusBarStyle:lastBarStyle animated:YES];
		hasBarStyle = NO;
	}

	[self dismissModalViewControllerAnimated:YES];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) o;
{
	return o == UIInterfaceOrientationPortrait;
}

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 30000
- (void) viewDidUnload;
{
	[self clearOutlets];
}
#else
- (void) setView:(UIView*) v;
{
	if (!v)
		[self clearOutlets];
	[super setView:v];
}
#endif

- (void) clearOutlets;
{
	self.imageView = nil;
	self.scrollView = nil;
}

@end
