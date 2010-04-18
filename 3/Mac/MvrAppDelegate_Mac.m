//
//  MoverWaypointAppDelegate.m
//  MoverWaypoint
//
//  Created by ∞ on 23/02/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "MvrAppDelegate_Mac.h"
#import <Carbon/Carbon.h>

#import <Sparkle/Sparkle.h>

#import "MvrTransferController.h"

#import "NSAlert+L0Alert.h"

#import "PFMoveApplication.h"

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
	
	PFMoveToApplicationsFolderIfNecessary();
	
	[aboutVersionLabel setStringValue:[NSString stringWithFormat:[aboutVersionLabel stringValue], [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]]];
	[legalitiesTextView readRTFDFromFile:[[NSBundle mainBundle] pathForResource:@"Legalities" ofType:@"rtf"]];

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
	
	[preferences restartAgentIfJustUpdated];
	[[SUUpdater sharedUpdater] setDelegate:self];
}

@synthesize transfer;

- (BOOL) applicationShouldHandleReopen:(NSApplication*) sender hasVisibleWindows:(BOOL) noWindows;
{
	if (noWindows)
		[window makeKeyAndOrderFront:self];
	
	return NO;
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
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://infinite-labs.net/mover/get/plus"]];
}

- (IBAction) openMoverLiteAppStore:(id) sender;
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://infinite-labs.net/mover/get/lite"]];
}

#pragma mark Sending from clipboard

- (IBAction) paste:(id) sender;
{
	[transfer sendContentsOfPasteboard:[NSPasteboard generalPasteboard]];
}

- (BOOL) validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>) anItem;
{
	SEL a = [anItem action];
	
	if (a == @selector(paste:) && ![transfer canSendContentsOfPasteboard:[NSPasteboard generalPasteboard]])
		return NO;
	
	if ((a == @selector(paste:) || a == @selector(open:)) && [transfer.channels count] == 0)
		return NO;
	
	return YES;
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

@synthesize preferences;

- (IBAction) open:(id) sender;
{
	[window makeKeyAndOrderFront:self];
	
	NSOpenPanel* open = [NSOpenPanel openPanel];
	[open beginSheetForDirectory:nil file:nil modalForWindow:window modalDelegate:self didEndSelector:@selector(openPanel:didPickFile:context:) contextInfo:NULL];
}

- (void) openPanel:(NSOpenPanel*) open didPickFile:(NSInteger) result context:(void*) context;
{
	[open orderOut:self];
	[self.transfer sendItemFile:[open filename]];
}

- (IBAction) revealDownloadsInFinder:(id) sender;
{
	NSString* path = preferences.selectedDownloadPath;
	
	if (preferences.shouldGroupStuffInMoverItemsFolder) {
		NSString* moverItemsPath = [path stringByAppendingPathComponent:@"Mover Items.localized"];
		if ([[NSFileManager defaultManager] fileExistsAtPath:moverItemsPath])
			path = moverItemsPath;
	}
	
	[[NSWorkspace sharedWorkspace] openFile:path];
}

- (void) warnAboutMissingContacts;
{
	NSAlert* a = [NSAlert alertNamed:@"MvrNoContactsForNow"];
	[a beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(warnedAboutContacts:didEndWithButton:context:) contextInfo:NULL];
}

- (void) warnedAboutContacts:(NSAlert*) a didEndWithButton:(NSInteger) b context:(void*) nothing;
{
	if (b == NSAlertSecondButtonReturn)
		[[SUUpdater sharedUpdater] checkForUpdates:self];
}

- (void)updater:(SUUpdater *)updater willInstallUpdate:(SUAppcastItem *)update;
{
	[preferences prepareAgentForUpdating];
}

- (IBAction) showAboutWindow:(id) sender;
{
	[aboutPanel center];
	[aboutPanel makeKeyAndOrderFront:self];
}

#define kMvrConnectFirstTimeFoundAlertShownKey @"MvrConnectFirstTimeFoundAlertShown"
- (void) showFirstTimeDeviceFoundAlertIfNeeded;
{	
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	if (![ud boolForKey:kMvrConnectFirstTimeFoundAlertShownKey]) {
		
		NSAlert* a = [NSAlert alertNamed:@"MvrConnectFirstTimeFound"];
		[a beginSheetModalForWindow:window modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
		
		[ud setBool:YES forKey:kMvrConnectFirstTimeFoundAlertShownKey];
		
	}
}

@end
