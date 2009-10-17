//
//  MvrImageVisor.m
//  Mover3
//
//  Created by ∞ on 03/10/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrImageVisor.h"
#import "MvrImageItem.h"
#import "MvrAppDelegate.h"
#import "MvrItemUI.h"

@implementation MvrImageVisor

- (id) initWithItem:(MvrImageItem*) i;
{
	if (self = [super initWithItem:i]) {
		self.title = NSLocalizedString(@"Preview", @"Image preview pane title");
	}
	
	return self;
}

- (void) dealloc
{
	[super viewDidUnload];
    [super dealloc];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void) viewDidLoad;
{
    [super viewDidLoad];
	imageView.image = [self.item image];
	
	scrollView.minimumZoomScale = 1.0;
	scrollView.maximumZoomScale = 2.5;
}

- (void) viewDidUnload;
{
	[super viewDidUnload];
	[imageView release]; imageView = nil;
	[scrollView release]; scrollView = nil;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView;
{
	return imageView;
}

@end
