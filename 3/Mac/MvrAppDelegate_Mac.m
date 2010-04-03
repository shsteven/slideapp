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

@interface MvrAppDelegate_Mac () <NSUserInterfaceValidations>

- (BOOL) sendFile:(NSString*) file;

@end


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

	[self willChangeValueForKey:@"transfer"];
	transfer = [[MvrTransferController alloc] init];
	[self didChangeValueForKey:@"transfer"];
	
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

- (BOOL) application:(NSApplication *)sender openFile:(NSString *)filename;
{
	if (!transfer) {
		[self performSelector:@selector(sendFile:) withObject:filename afterDelay:3.0];
		return YES;
	} else
		return [self sendFile:filename];
}

- (BOOL) sendFile:(NSString*) file;
{
	if (![transfer canSendFile:file]) {
		NSBeep();
		return NO;
	}
	
	[transfer sendItemFile:file];
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

#pragma mark Sending from clipboard

- (IBAction) paste:(id) sender;
{
	[transfer sendContentsOfPasteboard:[NSPasteboard generalPasteboard]];
}

- (BOOL) validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>) anItem;
{
	if ([anItem action] == @selector(paste:))
		return [transfer canSendContentsOfPasteboard:[NSPasteboard generalPasteboard]];
	
	return NO;
}

- (void) beginPickingChannelWithDelegate:(id) delegate selector:(SEL) selector context:(id) ctx;
{
	if (channelPickerDelegate)
		return;
	
	channelPickerDelegate = delegate;
	channelPickerSelector = selector;
	channelPickerContext = ctx;
	
	[NSApp beginSheet:channelPicker modalForWindow:window modalDelegate:self didEndSelector:@selector(didEndPicking:result:context:) contextInfo:NULL];
}

- (void) didEndPicking:(NSPanel*) picker result:(NSInteger) result context:(void*) nothing;
{
	if (result == NSOKButton && [[pickerChannelsController selectedObjects] count] == 1) {
		[channelPickerDelegate performSelector:channelPickerSelector withObject:[[pickerChannelsController selectedObjects] objectAtIndex:0] withObject:channelPickerContext];
	}
	
	channelPickerDelegate = nil;
	channelPickerSelector = NULL;
	channelPickerContext = nil;
	
	[picker orderOut:self];
}

- (IBAction) cancelPicking:(id) sender;
{
	[NSApp endSheet:channelPicker returnCode:NSCancelButton];
}

- (IBAction) performPicking:(id) sender;
{
	[NSApp endSheet:channelPicker returnCode:NSOKButton];
}

@end
