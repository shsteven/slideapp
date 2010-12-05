//
//  MoverWaypointAppDelegate.m
//  MoverWaypoint
//
//  Created by ∞ on 23/02/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "MvrAppDelegate_Mac.h"
#import <Carbon/Carbon.h>

#if kMvrConnectTargetDeploymentEnvironment != kMvrConnectMacAppStore
	#import <Sparkle/Sparkle.h>
#endif

#import "MvrTransferController.h"

#import "NSAlert+L0Alert.h"

#import "PFMoveApplication.h"

#import <MuiKit/MuiKit.h>

#import "Network+Storage/MvrItem.h"
#import "Network+Storage/MvrItemStorage.h"
#import "MvrBookmarkItem.h"

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
	
#if kMvrConnectTargetDeploymentEnvironment != kMvrConnectMacAppStore
	PFMoveToApplicationsFolderIfNecessary();
#endif

    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(performOpenURL:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
	
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
	
#if kMvrConnectTargetDeploymentEnvironment != kMvrConnectMacAppStore
	
	[preferences restartAgentIfJustUpdated];
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	
	BOOL useDevelopmentByDefault = [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"ILShouldUseDevelopmentChannelByDefault"] boolValue];
	BOOL usingDevelopment = NO;
	
	if ((![ud objectForKey:@"MvrUseTesterUpdateChannel"] && useDevelopmentByDefault) || [ud boolForKey:@"MvrUseTesterUpdateChannel"]) {
		[[SUUpdater sharedUpdater] setFeedURL:[NSURL URLWithString:@"http://infinite-labs.net/mover/mac-dev.rss"]];
		usingDevelopment = YES;
	}
	
	[[SUUpdater sharedUpdater] setDelegate:self];

	NSMenuItem* i = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Check for Updates\u2026", @"Check for updates") action:@selector(checkForUpdates:) keyEquivalent:@""];
	[i setTarget:[SUUpdater sharedUpdater]];
	[applicationMenu insertItem:i atIndex:1];

	if (usingDevelopment) {
		NSMenuItem* sep = [NSMenuItem separatorItem];
		[applicationMenu insertItemWithTitle:@"Development channel" action:NULL keyEquivalent:@"" atIndex:1];
		[applicationMenu insertItem:sep atIndex:1];
	}
	
#endif
	
	NSProcessInfo* process = [NSProcessInfo processInfo];
	if ([process respondsToSelector:@selector(enableSuddenTermination)])
		[process enableSuddenTermination];
}

@synthesize transfer;

- (BOOL) applicationShouldHandleReopen:(NSApplication*) sender hasVisibleWindows:(BOOL) hasWindows;
{
	if (!hasWindows)
		[window makeKeyAndOrderFront:self];	
	
	return YES;
}

- (IBAction) showMainWindow:(id) sender;
{
	[window makeKeyAndOrderFront:self];
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
	NSString* alertName;
#if kMvrConnectTargetDeploymentEnvironment == kMvrConnectMacAppStore
	alertName = @"MvrNoContactsForNow_AppStore";
#else
	alertName = @"MvrNoContactsForNow";
#endif
	
	NSAlert* a = [NSAlert alertNamed:alertName];
	[a beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(warnedAboutContacts:didEndWithButton:context:) contextInfo:NULL];
}

- (void) warnedAboutContacts:(NSAlert*) a didEndWithButton:(NSInteger) b context:(void*) nothing;
{
#if kMvrConnectTargetDeploymentEnvironment != kMvrConnectMacAppStore

	if (b == NSAlertSecondButtonReturn)
		[[SUUpdater sharedUpdater] checkForUpdates:self];
	
#endif
}


#if kMvrConnectTargetDeploymentEnvironment != kMvrConnectMacAppStore

- (void)updater:(SUUpdater *)updater willInstallUpdate:(SUAppcastItem *)update;
{
	[preferences prepareAgentForUpdating];
}

#endif


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

- (void) performOpenURL:(NSAppleEventDescriptor*) event withReplyEvent:(NSAppleEventDescriptor*) reply;
{
    NSAssert(self.transfer, @"Not set");
	NSString* URLString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
	NSURL* URL = [NSURL URLWithString:URLString];
	
    if ([[URL scheme] isEqual:@"x-infinitelabs-mover"]) {
        if ([[URL resourceSpecifier] hasPrefix:@"add?"]) {
        
            NSDictionary* query = [URL dictionaryByDecodingQueryString];
            NSString* toSend = [query objectForKey:@"url"];
            NSURL* toSendURL = [NSURL URLWithString:toSend];

            MvrBookmarkItem* i = nil;
            if (toSendURL)
                i = [[MvrBookmarkItem alloc] initWithAddress:toSendURL];
            
            if (i)
                [self.transfer sendItem:i];
        }
    }
}

@end
