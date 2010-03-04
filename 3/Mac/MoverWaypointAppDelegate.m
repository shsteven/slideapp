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
		
	[MvrPacketParser setAutomaticConsumptionThreshold:1024 * 1024];
	
	channelsByIncoming = [L0Map new];
	
	wifi = [[MvrModernWiFi alloc] initWithPlatformInfo:self serverPort:kMvrModernWiFiPort];
	[channelsController bind:NSContentSetBinding toObject:wifi withKeyPath:@"channels" options:nil];
	[devicesView bind:@"content" toObject:channelsController withKeyPath:@"arrangedObjects" options:nil];
	
	wifiObserver = [[MvrScannerObserver alloc] initWithScanner:wifi delegate:self];
	
	wifi.enabled = YES;
	
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

#pragma mark Handling incomings and outgoings

- (void) channel:(id <MvrChannel>) c didBeginReceivingWithIncomingTransfer:(id <MvrIncoming>) incoming;
{
	[channelsByIncoming setObject:c forKey:incoming];
}

- (void) incomingTransfer:(id <MvrIncoming>) incoming didEndReceivingItem:(MvrItem*) i;
{
	if (!i)
		return;
	
	id <MvrChannel> chan = [channelsByIncoming objectForKey:incoming];
	
	NSFileManager* fm = [NSFileManager defaultManager];
	
	NSArray* dirs = NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES);
	NSAssert([dirs count] != 0, @"We know where the downloads directory(/ies) is (are)");
	NSString* downloadDir = [dirs objectAtIndex:0];
	downloadDir = [downloadDir stringByAppendingPathComponent:@"Mover Items"];
	BOOL isDir;
	BOOL goOn = ([fm fileExistsAtPath:downloadDir isDirectory:&isDir] && isDir) || [fm createDirectoryAtPath:downloadDir withIntermediateDirectories:YES attributes:nil error:NULL];
		
	NSString* ext = NSMakeCollectable(UTTypeCopyPreferredTagWithClass((CFStringRef) i.type, kUTTagClassFilenameExtension));
	
	if (!ext && [i.type isEqual:(id) kUTTypeUTF8PlainText])
		ext = @"txt";
	
	if (goOn && ext) {
		// !!! Check whether the sanitization of the channel name is sane or not.
		NSString* baseName = [NSString stringWithFormat:NSLocalizedString(@"From %@", @"Base for received filenames"), [chan.displayName stringByReplacingOccurrencesOfString:@"/" withString:@"-"]];
		
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

@end
