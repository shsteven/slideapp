//
//  MoverWaypointAppDelegate.m
//  MoverWaypoint
//
//  Created by ∞ on 23/02/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "MoverWaypointAppDelegate.h"
#import <Carbon/Carbon.h>

#import "Network+Storage/MvrChannel.h"
#import "Network+Storage/MvrItem.h"
#import "Network+Storage/MvrItemStorage.h"
#import "Network+Storage/MvrPacketParser.h"

#import "NSAlert+L0Alert.h"

@implementation MoverWaypointAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
#if defined(kMvrMacPrereleaseTimeLimit)
	NSDate* limit = [NSDate dateWithTimeIntervalSince1970:kMvrMacPrereleaseTimeLimit];
	if ([limit timeIntervalSinceNow] < 0) {
		[[NSAlert alertNamed:@"PrereleaseExpired"] runModal];
		[NSApp terminate:self];
		return;
	}
#endif
	
	channels = [NSMutableSet new];
		
	[MvrPacketParser setAutomaticConsumptionThreshold:1024 * 1024];
	
	channelsByIncoming = [L0Map new];
	
	wifi = [[MvrModernWiFi alloc] initWithPlatformInfo:self serverPort:kMvrModernWiFiConduitPort options:kMvrUseConduitService|kMvrAllowBrowsingForConduitService|kMvrAllowConnectionsFromConduitService];
	[channelsController bind:NSContentSetBinding toObject:self withKeyPath:@"channels" options:nil];
	[devicesView bind:@"content" toObject:channelsController withKeyPath:@"arrangedObjects" options:nil];
	
	wifiObserver = [[MvrScannerObserver alloc] initWithScanner:wifi delegate:self];
	
	wifi.enabled = YES;
	
	originalWindowHeight = [window frame].size.height;
	
	NSString* autosaveKey = [NSString stringWithFormat:@"NSWindow Frame %@", [window frameAutosaveName]];
	if (![[NSUserDefaults standardUserDefaults] objectForKey:autosaveKey])
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

- (void) applicationWillTerminate:(NSNotification *)notification;
{
	wifi.enabled = NO;
}

- (NSSize) windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize;
{
	frameSize.height = originalWindowHeight;
	if (frameSize.width < 2.2 * originalWindowHeight)
		frameSize.width = 2.2 * originalWindowHeight;
	return frameSize;
}

#pragma mark Mover Platform info stuff.

- (NSString *) displayNameForSelf;
{
	NSString* name;
	NSHost* me = [NSHost currentHost];
	
	// 10.6-only
	if ([me respondsToSelector:@selector(localizedName)])
		name = [me localizedName];
	else
		name = [me name];
	
	return name;
}

- (L0UUID*) identifierForSelf;
{
	if (!identifier)
		identifier = [L0UUID UUID];
	
	return identifier;
}

- (MvrAppVariant) variant;
{
	return kMvrAppVariantNotMover;
}

- (NSString *) variantDisplayName;
{
	return @"Mover Waypoint";
}

- (id) platform;
{
	return kMvrAppleMacOSXPlatform;
}

- (double) version;
{
	return [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] doubleValue];
}

- (NSString *) userVisibleVersion;
{
	return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];	
}

#pragma mark App Store page

- (IBAction) openMoverPlusAppStore:(id) sender;
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://infinite-labs.net/mover/download-plus"]];
}

#pragma mark Handling incomings and outgoings

- (void) channel:(id <MvrChannel>) c didBeginReceivingWithIncomingTransfer:(id <MvrIncoming>) incoming;
{
	[channelsByIncoming setObject:c forKey:incoming];
}

- (void) incomingTransfer:(id <MvrIncoming>) incoming didEndReceivingItem:(MvrItem*) i;
{
	if (!i)
		return;
	
	MvrModernWiFiChannel* chan = [channelsByIncoming objectForKey:incoming];
	
	if (!chan.allowsConduitConnections)
		return;
	
	NSFileManager* fm = [NSFileManager defaultManager];
	
	NSArray* dirs = NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES);
	NSAssert([dirs count] != 0, @"We know where the downloads directory(/ies) is (are)");
	NSString* downloadDir = [dirs objectAtIndex:0];
	downloadDir = [downloadDir stringByAppendingPathComponent:@"Mover Items"];
	BOOL isDir;
		
	NSString* baseName = [i.metadata objectForKey:kMvrItemOriginalFilenameMetadataKey], * ext = nil;

	if (!baseName) {
		baseName = [NSString stringWithFormat:NSLocalizedString(@"From %@", @"Base for received filenames"), chan.displayName];
		ext = NSMakeCollectable(UTTypeCopyPreferredTagWithClass((CFStringRef) i.type, kUTTagClassFilenameExtension));
		
		if (!ext && [i.type isEqual:(id) kUTTypeUTF8PlainText])
			ext = @"txt";
	} else {
		ext = [baseName pathExtension];
		baseName = [baseName stringByDeletingPathExtension];
	}
	
	// !!! Check whether the sanitization of the path parts is sane or not.
	baseName = [baseName stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
	ext = [ext stringByReplacingOccurrencesOfString:@"/" withString:@"-"];

	BOOL goOn = ([fm fileExistsAtPath:downloadDir isDirectory:&isDir] && isDir) || [fm createDirectoryAtPath:downloadDir withIntermediateDirectories:YES attributes:nil error:NULL];

	if (goOn && ext) {
		NSString* attempt = baseName;
		
		int idx = 1;
		BOOL alreadyExists;
		NSString* targetPath;
		do {
			targetPath = [downloadDir stringByAppendingPathComponent:[attempt stringByAppendingPathExtension:ext]];
			alreadyExists = [fm fileExistsAtPath:targetPath];
			
			if (alreadyExists) {
				idx++;
				attempt = [baseName stringByAppendingFormat:@" (%d)", idx];
			}
		} while (alreadyExists);
		
		BOOL ok = [fm copyItemAtPath:i.storage.path toPath:targetPath error:NULL];
		
		if (ok) {
			[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.apple.DownloadFileFinished" object:targetPath];
			[[NSWorkspace sharedWorkspace] selectFile:targetPath inFileViewerRootedAtPath:@""];
		}
	}
	
	[channelsByIncoming removeObjectForKey:incoming];
	[i invalidate];
}

#pragma mark Channels

- (void) scanner:(id <MvrScanner>) s didAddChannel:(id <MvrChannel>) channel;
{
	MvrModernWiFiChannel* c = (MvrModernWiFiChannel*) channel;
	
	if (c.allowsConduitConnections)
		[[self mutableSetValueForKey:@"channels"] addObject:c];
}

- (void) scanner:(id <MvrScanner>)s didRemoveChannel:(id <MvrChannel>)channel;
{
	[[self mutableSetValueForKey:@"channels"] removeObject:channel];
}

@synthesize channels;

@end
