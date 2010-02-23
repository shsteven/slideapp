//
//  MoverWaypointAppDelegate.m
//  MoverWaypoint
//
//  Created by ∞ on 23/02/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "MoverWaypointAppDelegate.h"

@implementation MoverWaypointAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	originalWindowHeight = [window frame].size.height;
	
	[window center];
	[window makeKeyAndOrderFront:self];
}

- (BOOL) applicationShouldHandleReopen:(NSApplication*) sender hasVisibleWindows:(BOOL) noWindows;
{
	if (noWindows) {
		[window makeKeyAndOrderFront:self];
		return NO;
	}
	
	return YES;
}

- (void) dealloc
{
	[window release];
	[super dealloc];
}

- (NSSize) windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize;
{
	frameSize.height = originalWindowHeight;
	if (frameSize.width < 2.2 * originalWindowHeight)
		frameSize.width = 2.2 * originalWindowHeight;
	return frameSize;
}

- (NSArray*) prova;
{
	return [NSArray arrayWithObjects:@"1", @"2", @"3", @"4", @"5", nil];
}

@end
