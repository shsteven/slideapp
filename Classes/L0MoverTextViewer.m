//
//  L0MoverTextViewer.m
//  Mover
//
//  Created by ∞ on 15/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0MoverTextViewer.h"


@implementation L0MoverTextViewer

- (id) initWithItem:(L0TextItem*) i delegate:(id) d didDismissSelector:(SEL) s;
{
	if (self = [super initWithNibName:@"L0MoverTextViewer" bundle:nil]) {
		item = [i retain];
		self.title = item.title;
		delegate = d;
		didDismissSelector = s;
	}
	
	return self;
}

- (void) viewDidLoad;
{
	self.textView.text = item.text;
}

- (void) didReceiveMemoryWarning;
{
	[super didReceiveMemoryWarning];
	[item clearCache];
}

@synthesize textView;

- (void) viewDidUnload;
{
	self.textView = nil;
}

- (void) dealloc;
{
	[item release];
    [super dealloc];
}

@end
