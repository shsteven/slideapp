//
//  MoverWaypointAppDelegate.m
//  MoverWaypoint
//
//  Created by ∞ on 23/02/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "MvrAppDelegate_Mac.h"
#import <Carbon/Carbon.h>

#import "MvrTransferController.h"

#import "NSAlert+L0Alert.h"

@implementation MvrAppDelegate_Mac

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
#if defined(kMvrMacPrereleaseTimeLimit)
	NSDate* limit = [NSDate dateWithTimeIntervalSince1970:kMvrMacPrereleaseTimeLimit];
	if ([limit timeIntervalSinceNow] < 0) {
		[[NSAlert alertNamed:@"PrereleaseExpired"] runModal];
		[NSApp terminate:self];
		return;
	}
#endif
	
	transfer = [[MvrTransferController alloc] init];
	
	[channelsController bind:NSContentSetBinding toObject:transfer withKeyPath:@"channels" options:nil];
	[devicesView bind:@"content" toObject:channelsController withKeyPath:@"arrangedObjects" options:nil];
	
	originalWindowHeight = [window frame].size.height;
	
	NSString* autosaveKey = [NSString stringWithFormat:@"NSWindow Frame %@", [window frameAutosaveName]];
	if (![[NSUserDefaults standardUserDefaults] objectForKey:autosaveKey])
		[window center];
	[window makeKeyAndOrderFront:self];
	
	transfer.enabled = YES;
}

@synthesize transfer;

- (BOOL) applicationShouldHandleReopen:(NSApplication*) sender hasVisibleWindows:(BOOL) noWindows;
{
	if (noWindows) {
		[window makeKeyAndOrderFront:self];
		return NO;
	}
	
	return YES;
}

- (void) applicationWillTerminate:(NSNotification *)notification;
{
	transfer.enabled = NO;
}

- (NSSize) windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize;
{
	frameSize.height = originalWindowHeight;
	if (frameSize.width < 2.2 * originalWindowHeight)
		frameSize.width = 2.2 * originalWindowHeight;
	return frameSize;
}

#pragma mark App Store page

- (IBAction) openMoverPlusAppStore:(id) sender;
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://infinite-labs.net/mover/download-plus"]];
}

@end
