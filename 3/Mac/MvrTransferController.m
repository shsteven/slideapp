//
//  MvrTransferController.m
//  Mover Connect
//
//  Created by ∞ on 01/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MvrTransferController.h"

#import "Network+Storage/MvrChannel.h"
#import "Network+Storage/MvrItem.h"
#import "Network+Storage/MvrItemStorage.h"
#import "Network+Storage/MvrPacketParser.h"

#import "Network+Storage/MvrGenericItem.h"
#import "Network+Storage/MvrItemStorage.h"


static NSArray* MvrTypeForExtension(NSString* ext) {
	if ([ext isEqual:@"m4v"])
		return [NSArray arrayWithObject:(id) kUTTypeMPEG4];
	
	return NSMakeCollectable(UTTypeCreateAllIdentifiersForTag(kUTTagClassFilenameExtension, (CFStringRef) ext, NULL));
}


@implementation MvrTransferController

L0ObjCSingletonMethod(transferController)

- (id) init;
{
	if (self = [super init]) {
		[MvrPacketParser setAutomaticConsumptionThreshold:1024 * 1024];
		
		channels = [NSMutableSet new];
		channelsByIncoming = [L0Map new];

		wifi = [[MvrModernWiFi alloc] initWithPlatformInfo:self serverPort:kMvrModernWiFiConduitPort options:kMvrUseConduitService|kMvrAllowBrowsingForConduitService|kMvrAllowConnectionsFromConduitService];
		wifiObserver = [[MvrScannerObserver alloc] initWithScanner:wifi delegate:self];
	}
	
	return self;
}

- (BOOL) enabled;
{
	return wifi.enabled;
}
- (void) setEnabled:(BOOL) e;
{
	wifi.enabled = e;
}

@synthesize channels;


#pragma mark Outgoing

- (void) sendItemFile:(NSString*) file throughChannel:(id <MvrChannel>) c;
{
	NSString* title = [[NSFileManager defaultManager] displayNameAtPath:file];
	
	NSString* ext = [file pathExtension];
	NSArray* types = MvrTypeForExtension(ext);
	
	NSString* filename = [file lastPathComponent];
	NSDictionary* md = [NSDictionary dictionaryWithObjectsAndKeys:
						title, kMvrItemTitleMetadataKey,
						filename, kMvrItemOriginalFilenameMetadataKey,
						nil];
	
	MvrItemStorage* is = [MvrItemStorage itemStorageFromFileAtPath:file options:kMvrItemStorageDoNotTakeOwnershipOfFile error:NULL];
	if (is && [types count] > 0) {
		MvrGenericItem* item = [[MvrGenericItem alloc] initWithStorage:is type:[types objectAtIndex:0] metadata:md];
		[c beginSendingItem:item];
	}
}

#pragma mark Incoming

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

@end
